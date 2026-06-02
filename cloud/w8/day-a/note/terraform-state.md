# Ghi chú về Terraform State

## Terraform state có chức năng gì?

### 1. Ánh xạ với thế giới thực

State là cầu nối giữa tài nguyên trong code và tài nguyên thực tế trên AWS.

Ví dụ:
- Trong cấu hình, bạn viết `aws_s3_bucket.demo`
- Nhưng trên AWS, hệ thống chỉ biết bucket thực tế có tên cụ thể, ví dụ `tf-series-bai4-2026`

Nhờ có state, Terraform biết resource trong code đang đại diện cho đối tượng nào ngoài thực tế.

### 2. Metadata về sự phụ thuộc

State lưu trữ thông tin về mối quan hệ phụ thuộc giữa các resource.

Điều này đặc biệt quan trọng khi `destroy` hoặc khi có thay đổi phức tạp, vì Terraform cần biết thứ tự tạo, cập nhật và xóa tài nguyên cho đúng.

### 3. Hiệu năng

State lưu cache các thuộc tính của mọi resource.

Với các hệ thống hạ tầng lớn, việc chạy `terraform plan` sẽ rất chậm nếu lần nào cũng phải gọi API AWS để đọc lại toàn bộ trạng thái, chưa kể giới hạn mạng và API rate limit. State giúp Terraform tính toán plan từ dữ liệu đã lưu và chỉ làm mới khi cần.

### 4. Đồng bộ hóa khi làm việc nhóm

Khi nhiều người cùng làm việc trên một hạ tầng, state nên được đặt ở một vị trí dùng chung.

Lợi ích:
- Đảm bảo mọi người đều làm việc trên cùng một bản sao state
- Giảm rủi ro ghi đè lẫn nhau khi apply
- Có thể kết hợp với cơ chế khóa state để tránh hai người cùng apply tại một thời điểm

## Ghi chú

- File `*.tfstate` và thư mục `.terraform/` không nên đưa lên GitHub
- `force_destroy = true` chỉ phù hợp cho môi trường học tập hoặc lab, không nên dùng trong production
