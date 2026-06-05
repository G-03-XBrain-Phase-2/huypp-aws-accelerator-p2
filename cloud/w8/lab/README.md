# K8s on AWS - Terraform 1-Click

Lab này dùng 1 EC2 để chạy `kind`, deploy app trong Kubernetes, và expose ra Internet qua ALB.

## Lệnh chạy

Yêu cầu local:

- Terraform `>= 1.5`
- AWS credentials hợp lệ
- `ssh` và `scp` có trong `PATH`

Chạy:

```bash
terraform init
terraform apply -auto-approve
```

Sau khi apply xong:

- Lấy URL app từ output `alb_url`
- Kubeconfig được tải về `./.generated/kubeconfig.yaml`
- Có thể SSH vào EC2 bằng key local `./lab-key.pem`

Kiểm tra nhanh:

```bash
kubectl --kubeconfig ./.generated/kubeconfig.yaml get nodes
kubectl --kubeconfig ./.generated/kubeconfig.yaml get pods,svc
```

Xóa tài nguyên:

```bash
terraform destroy -auto-approve
```

## Sơ đồ kiến trúc

```text
Internet
   |
   v
AWS ALB :80
   |
   v
EC2 :8080
   |
   v
kind extraPortMappings
hostPort 8080 -> containerPort 30080
   |
   v
Kubernetes Service type NodePort :30080
   |
   v
Pod nginx:alpine :80
```

Thành phần chính:

- Terraform tự dựng `VPC`, `2 public subnet`, `IGW`, `route table`, `security group`, `EC2`, `ALB`, `target group`, `listener`
- `kind` chạy trên EC2 bằng `user_data`
- App `nginx:alpine` được deploy vào cluster bằng `kubectl` qua SSH

## Cách wire provider

Lab này dùng nhiều provider trong cùng một `terraform apply`:

- `aws`: dựng hạ tầng AWS như `VPC`, `EC2`, `ALB`, `target group`, `listener`
- `tls`: sinh SSH private key/public key ngay trong Terraform
- `local`: ghi private key ra file local `lab-key.pem`
- `null`: dùng `remote-exec` và `local-exec` để điều phối các bước ngoài AWS
- `random`: sinh suffix cho tên ALB và target group để tránh trùng tên

Luồng wire provider:

1. `tls_private_key` sinh key SSH.
2. `local_sensitive_file` ghi key đó ra máy local.
3. `aws_key_pair` đưa public key lên AWS để EC2 có thể đăng nhập bằng key vừa sinh.
4. `aws_instance.kind_host` tạo EC2 và bootstrap `kind` bằng `user_data`.
5. `null_resource.wait_for_bootstrap` SSH vào EC2, đợi cluster sẵn sàng.
6. `aws_lb_target_group_attachment` gắn EC2 vào target group sau khi cluster đã lên.
7. `null_resource.deploy_k8s_manifests` SSH vào EC2, chạy `kubectl apply` để deploy app.
8. `null_resource.fetch_kubeconfig` dùng `scp` kéo kubeconfig từ EC2 về local.

Ý nghĩa của phần "wire provider" trong bài này:

- Terraform không chỉ dùng 1 provider `aws` để tạo hạ tầng
- Terraform còn phối hợp `tls`, `local`, `null`, `random` để nối liền các bước sinh key, bootstrap host, deploy app, và lấy kubeconfig trong cùng 1 lần apply

## Biến quan trọng

- `aws_region`: mặc định `ap-southeast-1`
- `instance_type`: mặc định `t3.small`
- `host_port`: mặc định `8080`
- `node_port`: mặc định `30080`
- `ssh_ingress_cidrs`: mặc định `0.0.0.0/0`, chỉ nên dùng cho lab

## Ghi chú thiết kế

- Không dùng EKS; yêu cầu bài là Kubernetes chạy trên EC2, và `kind` đáp ứng được.
- Không cần cài AWS Load Balancer Controller trong cluster.
- ALB target trực tiếp vào EC2, còn `kind` map `hostPort 8080` vào `NodePort 30080`.
- Cách này đơn giản, dễ giải thích, và phù hợp bài 1-click automation bằng Terraform.
