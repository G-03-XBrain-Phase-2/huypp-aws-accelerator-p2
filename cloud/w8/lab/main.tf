provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix   = replace(lower(var.project_name), "_", "-")
  generated_dir = "${path.module}/.generated"
  az_count      = min(2, length(data.aws_availability_zones.available.names))
  common_tags = merge({
    Project   = var.project_name
    ManagedBy = "terraform"
    Lab       = "w8"
  }, var.tags)
}

resource "random_id" "suffix" {
  byte_length = 2
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${count.index + 1}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/lab-key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "lab" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = local.common_tags
}

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Allow Internet traffic to the ALB"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "instance" {
  name_prefix = "${local.name_prefix}-instance-"
  description = "Allow ALB to reach the kind node and optional SSH for operators"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description     = "App traffic from ALB"
    from_port       = var.host_port
    to_port         = var.host_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH for troubleshooting"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance-sg"
  })
}

resource "aws_instance" "kind_host" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.lab.key_name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_port  = var.app_port
    host_port = var.host_port
    node_port = var.node_port
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-host"
  })
}

resource "null_resource" "wait_for_bootstrap" {
  triggers = {
    instance_id = aws_instance.kind_host.id
  }

  connection {
    type        = "ssh"
    host        = aws_instance.kind_host.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.ssh.private_key_pem
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "test -x /usr/local/bin/kubectl || { sudo tail -n 200 /var/log/lab-bootstrap.log; exit 1; }",
      "test -f /opt/lab/bootstrap-ready || { sudo tail -n 200 /var/log/lab-bootstrap.log; exit 1; }",
      "/usr/local/bin/kubectl --kubeconfig=/home/ec2-user/.kube/config wait --for=condition=Ready nodes --all --timeout=180s"
    ]
  }
}

resource "aws_lb" "app" {
  name               = substr("${local.name_prefix}-${random_id.suffix.hex}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  name        = substr("${local.name_prefix}-${random_id.suffix.hex}-tg", 0, 32)
  port        = var.host_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.lab.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/"
    port                = var.host_port
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })
}

resource "aws_lb_target_group_attachment" "instance" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.kind_host.id
  port             = var.host_port

  depends_on = [null_resource.wait_for_bootstrap]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "null_resource" "fetch_kubeconfig" {
  triggers = {
    instance_id = aws_instance.kind_host.id
    public_ip   = aws_instance.kind_host.public_ip
  }

  depends_on = [
    null_resource.deploy_k8s_manifests,
    local_sensitive_file.ssh_private_key
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      New-Item -ItemType Directory -Force -Path '${local.generated_dir}' | Out-Null
      $keyPath = Join-Path $env:TEMP 'lab-key-scoped.pem'
      if (Test-Path $keyPath) { Remove-Item -Force $keyPath }
      Copy-Item -Force '${local_sensitive_file.ssh_private_key.filename}' $keyPath
      $currentUser = whoami
      icacls $keyPath /inheritance:r | Out-Null
      icacls $keyPath /remove 'NT AUTHORITY\Authenticated Users' 'BUILTIN\Users' 'Everyone' | Out-Null
      icacls $keyPath /grant:r "$${currentUser}:(R)" | Out-Null
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -i $keyPath ec2-user@${aws_instance.kind_host.public_ip}:/home/ec2-user/.kube/config '${local.generated_dir}/kubeconfig.yaml'
    EOT
  }
}

resource "null_resource" "deploy_k8s_manifests" {
  triggers = {
    instance_id = aws_instance.kind_host.id
    public_ip   = aws_instance.kind_host.public_ip
  }

  depends_on = [
    aws_lb_target_group_attachment.instance,
    null_resource.wait_for_bootstrap
  ]

  connection {
    type        = "ssh"
    host        = aws_instance.kind_host.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.ssh.private_key_pem
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /opt/lab/bootstrap-ready ]; do sleep 5; done",
      "cat <<'EOF' >/tmp/app-deploy.yaml\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: web-app\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: nginx\n  template:\n    metadata:\n      labels:\n        app: nginx\n    spec:\n      containers:\n        - name: nginx\n          image: nginx:alpine\n          ports:\n            - containerPort: ${var.app_port}\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: web-service\nspec:\n  type: NodePort\n  selector:\n    app: nginx\n  ports:\n    - protocol: TCP\n      port: 80\n      targetPort: ${var.app_port}\n      nodePort: ${var.node_port}\nEOF",
      "/usr/local/bin/kubectl --kubeconfig=/home/ec2-user/.kube/config apply -f /tmp/app-deploy.yaml",
      "/usr/local/bin/kubectl --kubeconfig=/home/ec2-user/.kube/config rollout status deployment/web-app --timeout=180s",
      "for i in $(seq 1 30); do curl --fail --silent http://127.0.0.1:${var.host_port}/ && exit 0; sleep 5; done; exit 1"
    ]
  }
}
