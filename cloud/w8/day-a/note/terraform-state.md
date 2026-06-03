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

## Lưu ý về dữ liệu nhạy cảm trong Terraform state

### 1. `sensitive`

`sensitive` chỉ có tác dụng ẩn giá trị trên màn hình console để tránh lộ khi người khác nhìn vào màn hình.

Tuy nhiên:
- Dữ liệu vẫn có thể tồn tại trong `state`
- Nếu giá trị đó được Terraform quản lý bình thường, nó vẫn có thể bị lưu dưới dạng plaintext trong state

Nói ngắn gọn, `sensitive` giúp che khi hiển thị, nhưng không giải quyết triệt để việc rò rỉ bí mật khỏi state.

### 2. `ephemeral`

`ephemeral` dùng cho dữ liệu tạm thời, thường là dữ liệu bảo mật được đọc từ kho bí mật an toàn ở thời điểm chạy.

Đặc điểm:
- Chỉ tồn tại trong lúc Terraform thực thi
- Không được lưu lại trong `state`
- Không để lại dấu vết trong `plan`

Đây là cách tiếp cận tốt khi cần dùng secret làm đầu vào nhưng không muốn Terraform ghi nhớ giá trị đó sau khi chạy xong.

### 3. `write-only`

`write-only` là các tham số chỉ ghi, thường có hậu tố `_wo`.

Cách hoạt động:
- Terraform gửi thẳng giá trị bí mật tới hạ tầng cloud thông qua provider
- Sau khi gửi xong, giá trị không được giữ lại trong state

Điều này hữu ích khi cần truyền password, token hoặc secret vào tài nguyên, nhưng không muốn lưu lại trong file state.

### 4. Cách kết hợp hiện đại để bảo vệ secret

Sự kết hợp giữa:
- `ephemeral` ở phía đầu vào
- `write-only` ở phía đầu ra

được xem là cách làm hiện đại và chuẩn mực hơn so với chỉ dựa vào mã hóa file state.

Ý nghĩa của cách làm này:
- Secret không bị lưu trong `plan`
- Secret không bị lưu trong `state`
- Giảm đáng kể nguy cơ rò rỉ dữ liệu nhạy cảm khi làm việc nhóm hoặc lưu state từ xa

Nói cách khác, thay vì chỉ mã hóa file state rồi chấp nhận việc secret vẫn nằm bên trong đó, hướng tiếp cận mới là không để secret đi vào state ngay từ đầu.

## Ghi chú

- File `*.tfstate` và thư mục `.terraform/` không nên đưa lên GitHub
- `force_destroy = true` chỉ phù hợp cho môi trường học tập hoặc lab, không nên dùng trong production
