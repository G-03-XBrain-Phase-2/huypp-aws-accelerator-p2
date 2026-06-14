# Docker Basic Notes

## 1. Docker là gì?
Docker là một nền tảng giúp đóng gói ứng dụng và các phụ thuộc của nó thành **container**. Container nhẹ hơn máy ảo vì dùng chung kernel của máy host.

## 2. Docker hoạt động theo mô hình gì?
Docker dùng mô hình **client-server**:

- `docker` là client.
- `dockerd` là daemon xử lý yêu cầu.
- `containerd` quản lý vòng đời container.
- `runc` tạo container ở mức thấp nhất.

Luồng cơ bản:

`docker run` -> client gửi lệnh -> `dockerd` -> `containerd` -> `runc` -> container chạy.

## 3. Image, container và registry

- **Image**: bản mẫu chỉ đọc để tạo container.
- **Container**: instance đang chạy từ image.
- **Registry**: nơi lưu image, ví dụ Docker Hub hoặc private registry.

Một số lệnh hay dùng:

```bash
docker pull nginx
docker images
docker run -d --name web -p 8080:80 nginx
docker ps
docker logs web
docker exec -it web sh
docker stop web
docker rm web
docker rmi nginx
```

## 4. Vì sao macOS và Windows cần VM?
Trên Linux, Docker chạy trực tiếp vì có kernel Linux.  
Trên macOS và Windows, Docker Desktop thường dùng một máy ảo Linux nhỏ bên dưới để chạy container Linux.

## 5. Các thành phần quan trọng bên trong container

- **Namespaces**: cô lập tiến trình, network, mount, user...
- **cgroups**: giới hạn CPU, RAM, I/O cho container.
- **Union filesystem**: ghép nhiều layer image lại thành một filesystem hoàn chỉnh.

## 6. Dockerfile cơ bản

Ví dụ:

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

Các bước thường gặp:

- `FROM`: chọn image nền.
- `WORKDIR`: đặt thư mục làm việc.
- `COPY`: chép file vào image.
- `RUN`: chạy lệnh khi build.
- `CMD`: lệnh chạy mặc định khi container start.

## 7. Docker Compose
Compose dùng để chạy nhiều container cùng lúc bằng một file `docker-compose.yml`.

Lợi ích:

- dễ khởi động cả hệ thống local;
- tách backend, frontend, database rõ ràng;
- thuận tiện cho dev và test.

## 8. Docker Swarm
Swarm là tính năng orchestration có sẵn của Docker.

Khái niệm chính:

- **Manager**: điều phối cluster.
- **Worker**: chạy task/container.
- **Service**: mô tả ứng dụng cần chạy.
- **Task**: một instance của service.

Tính năng thường nhắc tới:

- **Replicated service**: chạy nhiều bản sao.
- **Global service**: mỗi node chạy một bản.
- **Overlay network**: network dùng giữa các node.
- **Routing mesh**: truy cập service qua một cổng, Swarm tự phân phối request.

Swarm dùng **Raft** để lưu trạng thái cluster và đồng bộ giữa các manager.

## 9. Ghi nhớ nhanh

- Image là khuôn mẫu, container là bản đang chạy.
- Docker trên Windows/macOS thường đi qua VM Linux.
- `cgroups` để giới hạn tài nguyên, `namespaces` để cô lập.
- Compose dùng cho môi trường nhiều service.
- Swarm dùng để scale và quản lý cụm container đơn giản.
