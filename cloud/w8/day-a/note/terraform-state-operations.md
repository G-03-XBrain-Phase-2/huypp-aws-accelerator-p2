# Ghi chú về các thao tác Terraform state phổ biến

## 1. Import block

`import block` dùng để tiếp quản một tài nguyên đã tồn tại sẵn ngoài thực tế và đưa nó vào phạm vi quản lý của Terraform.

Sau khi import, có thể để Terraform tự động sinh cấu hình tham chiếu bằng:

```bash
terraform plan -generate-config-out=generated.tf
```

File `generated.tf` được tạo ra để bạn xem lại, tinh chỉnh, rồi hợp nhất vào cấu hình chính nếu cần.

## 2. `terraform state mv`

`terraform state mv` dùng để đổi tên hoặc di chuyển địa chỉ của một tài nguyên bên trong file state.

Nếu chỉ đổi tên resource trong code rồi chạy `plan`, Terraform thường sẽ hiểu là:
- tài nguyên cũ bị xóa
- tài nguyên mới cần được tạo lại

`terraform state mv` giải quyết việc này bằng cách đổi ánh xạ trong state, để cùng một tài nguyên thực tế bây giờ mang địa chỉ mới trong Terraform.

Điểm quan trọng:
- Lệnh này không xóa tài nguyên thực tế
- Lệnh này không tạo tài nguyên mới
- Lệnh này chỉ thay đổi dữ liệu trong state

Sau khi chạy `state mv`, vẫn cần đổi tên resource trong code cho khớp với địa chỉ mới trong state.

## 3. `terraform state rm`

`terraform state rm` dùng để loại bỏ một tài nguyên khỏi sự quản lý của Terraform mà không tác động đến hạ tầng thực tế.

Khi chạy lệnh này:
- tài nguyên sẽ bị xóa khỏi file state
- tài nguyên thật trên AWS vẫn còn nguyên

Rủi ro cần lưu ý:
- `state rm` dễ tạo ra tài nguyên "mồ côi"
- các tài nguyên đó không còn được Terraform theo dõi
- rất dễ bị quên và tiếp tục phát sinh chi phí

Chỉ nên dùng `state rm` khi bạn thực sự muốn Terraform ngừng quản lý tài nguyên đó và đã có cách theo dõi tài nguyên bên ngoài state.
