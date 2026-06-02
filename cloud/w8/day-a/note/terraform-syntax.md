# Ghi chú về cú pháp Terraform

## Mục tiêu của phần này

Mục tiêu là đọc một file `.tf` và hiểu chính xác từng dòng đang làm gì:
- Dòng nào là `block`
- Dòng nào là `argument`
- Giá trị đang dùng thuộc kiểu dữ liệu nào
- Biểu thức đó sẽ cho ra kết quả gì

Ngoài ra, cần hiểu block `terraform {}` có thể khai báo những gì ngoài `required_providers`.

## Hai thành phần chính của cú pháp HCL

HCL (HashiCorp Configuration Language) được xây dựng chủ yếu từ hai thành phần:
- `argument`
- `block`

### 1. Argument

`Argument` là một phép gán giá trị cho một tên.

Ví dụ:

```hcl
region = "ap-southeast-1"
```

Trong đó:
- Bên trái dấu `=` là `identifier`
- Bên phải dấu `=` là một `expression`

Có thể hiểu ngắn gọn: argument là `tên = giá trị`.

### 2. Block

`Block` là một khối dùng để chứa nội dung khác bên trong.

Một block gồm:
- `type`: loại block
- `label`: zero, one hoặc nhiều nhãn
- `body`: phần nội dung nằm trong dấu `{ }`

Ví dụ:

```hcl
resource "aws_s3_bucket" "first" {
  bucket_prefix = "tf-series-bai2-"

  tags = {
    Project = "terraform-series"
  }
}
```

Phân tích:
- `resource` là `block type`
- `"aws_s3_bucket"` là `label 1`, nghĩa là loại resource
- `"first"` là `label 2`, nghĩa là tên cục bộ của resource
- Phần nằm trong `{ }` là `body`

Trong body:

```hcl
bucket_prefix = "tf-series-bai2-"
```

Đây là một `argument`, gồm:
- `bucket_prefix`: identifier
- `"tf-series-bai2-"`: expression

### Ý nghĩa của label phụ thuộc vào loại block

Số lượng và ý nghĩa của `label` phụ thuộc vào từng loại block:
- `resource` cần 2 label: loại resource và tên cục bộ
- `provider` thường cần 1 label, ví dụ `"aws"`
- `terraform` không có label

Vì vậy, trong:

```hcl
resource "aws_s3_bucket" "first" { ... }
```

Hai chuỗi `"aws_s3_bucket"` và `"first"` không phải là tham số, mà là các label nhận diện block.

## Identifier và comment

`Identifier` như tên argument, tên variable, tên local:
- Có thể chứa chữ cái, chữ số, dấu gạch dưới `_`, dấu gạch ngang `-`
- Không được bắt đầu bằng chữ số

Terraform hỗ trợ 3 kiểu comment:
- `#` cho comment một dòng, đây là kiểu nên dùng
- `//` cũng là comment một dòng, nhưng `terraform fmt` thường sẽ đổi thành `#`
- `/* ... */` cho comment nhiều dòng

## Terraform console: nơi thử expression nhanh nhất

`terraform console` là môi trường tương tác để thử trực tiếp các expression của HCL mà không cần tạo resource thật.

Ví dụ:

```bash
echo 'upper("hello")' | terraform console
```

Kết quả:

```text
"HELLO"
```

Ví dụ khác:

```bash
echo '5 + 3 * 2' | terraform console
```

Kết quả:

```text
11
```

Terraform vẫn tuân theo thứ tự ưu tiên toán tử:
- `3 * 2` được tính trước
- sau đó mới cộng với `5`

## Sáu kiểu giá trị trong Terraform

Terraform có 6 nhóm kiểu giá trị chính.

### 1. string

Chuỗi ký tự Unicode, đặt trong dấu ngoặc kép.

Ví dụ:

```hcl
"ap-southeast-1"
```

### 2. number

Giá trị số, bao gồm:
- số nguyên như `15`
- số thực như `6.283`

### 3. bool

Giá trị đúng hoặc sai:

```hcl
true
false
```

Ví dụ:

```bash
echo 'true && false' | terraform console
```

Kết quả:

```text
false
```

### 4. list / tuple

Đây là nhóm dữ liệu có thứ tự, truy cập theo chỉ số bắt đầu từ `0`.

Ví dụ:

```hcl
["us-east-1a", "us-east-1c"]
```

### 5. map / object

Đây là nhóm dữ liệu dạng key-value.

Ví dụ:

```hcl
{
  name = "web"
  port = 443
}
```

Khác biệt giữa hai cặp kiểu:
- `list` và `map` yêu cầu các phần tử cùng kiểu dữ liệu
- `tuple` và `object` cho phép các phần tử khác kiểu

Trong thực tế viết cấu hình, ta chỉ cần dùng:
- `[...]`
- `{...}`

Terraform sẽ tự suy ra kiểu phù hợp.

### 6. null

`null` là giá trị biểu thị sự vắng mặt của giá trị.

Nếu gán `null` cho một argument, Terraform sẽ hiểu như thể argument đó không được khai báo.

Điều này khác hoàn toàn với:
- chuỗi rỗng `""`
- số `0`

`null` nghĩa là: không có giá trị.

## Expression trong Terraform

`Expression` cho phép tính toán hoặc tạo giá trị từ dữ liệu khác.

### Toán tử số học, so sánh và logic

Các toán tử hoạt động theo cách quen thuộc.

Ví dụ:

```hcl
1 == 1 ? "yes" : "no"
```

Đây là toán tử điều kiện dạng:

```hcl
condition ? a : b
```

Nếu điều kiện đúng thì lấy `a`, ngược lại lấy `b`.

Kiểu biểu thức này rất hay dùng để bật/tắt cấu hình theo môi trường, ví dụ `prod` và `dev`.

### Nội suy chuỗi

Terraform cho phép chèn expression vào trong chuỗi bằng cú pháp `${...}`.

Ví dụ:

```hcl
"web-${1 + 1}"
```

Kết quả là:

```hcl
"web-2"
```

Trong thực tế có thể viết:

```hcl
"${var.env}-web"
```

Terraform sẽ tính phần `${...}` trước rồi ghép vào chuỗi.

### Hàm dựng sẵn

Terraform có rất nhiều hàm dựng sẵn cho:
- chuỗi
- số
- collection
- encoding
- networking
- time

Ví dụ:

```bash
echo 'length(["a", "b", "c"])' | terraform console
```

Kết quả:

```text
3
```

Ví dụ:

```bash
echo 'tostring(42)' | terraform console
```

Kết quả:

```text
"42"
```

Ví dụ:

```bash
echo 'cidrsubnet("10.0.0.0/16", 8, 2)' | terraform console
```

Kết quả:

```text
"10.0.2.0/24"
```

Hàm `cidrsubnet` rất quan trọng khi làm network, vì nó giúp chia subnet tự động thay vì phải tự tính tay từng dải IP.

Terraform không cho tự định nghĩa hàm riêng. Khi cần, ta dùng các hàm dựng sẵn của hệ thống.

## Block `terraform {}`

Block `terraform {}` không mô tả hạ tầng, mà khai báo các thiết lập liên quan đến chính Terraform.

Block này nhận các giá trị tĩnh, không dùng để khai báo hạ tầng động bằng variable theo cách thông thường.

Các thành phần có thể xuất hiện trong `terraform {}`:

### 1. `required_version`

Xác định phiên bản Terraform CLI nào được phép chạy cấu hình này.

Mục đích:
- chặn người dùng chạy bằng version quá cũ
- đảm bảo môi trường chạy đồng nhất

### 2. `required_providers`

Khai báo các provider plugin mà cấu hình cần dùng.

Ví dụ:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

### 3. `backend`

Xác định nơi lưu file state.

Mặc định Terraform dùng local backend, nhưng trong thực tế nhóm thường chuyển sang remote backend như S3.

### 4. `cloud`

Dùng để cấu hình HCP Terraform thay cho `backend`.

### 5. `experiments`

Bật các tính năng ngôn ngữ đang ở trạng thái thử nghiệm.

### 6. `provider_meta`

Lưu metadata cho provider, ít dùng trực tiếp trong bài học cơ bản.

Trong chuỗi bài học, ba phần thường gặp nhất là:
- `required_version`
- `required_providers`
- `backend`

## Vì sao thứ tự các dòng không quan trọng?

Một điểm dễ nhầm với người mới là: Terraform không chạy từ trên xuống dưới như ngôn ngữ mệnh lệnh.

Thứ tự khai báo block trong file không quyết định thứ tự thực thi.

Ví dụ:
- có thể viết `output` trước `resource`
- có thể khai báo một bucket sau resource đang tham chiếu tới nó

Kết quả vẫn không đổi, vì Terraform sẽ:
- đọc toàn bộ cấu hình
- xây dependency graph từ các tham chiếu giữa resource
- sau đó mới quyết định thứ tự tạo, sửa, xóa

Nghĩa là với Terraform, ta mô tả cái gì cần tồn tại, chứ không viết từng bước thủ công để hệ thống làm theo tuần tự.

## Ghi chú thêm

Terraform còn có một biến thể cú pháp JSON là `.tf.json`.

Biến thể này phù hợp khi cấu hình được sinh tự động bằng chương trình. Còn khi viết tay, nên dùng cú pháp HCL gốc vì dễ đọc và dễ bảo trì hơn.

## Tóm tắt

Những ý quan trọng nhất:
- HCL có hai thành phần chính là `argument` và `block`
- `argument` có dạng `name = expression`
- `block` gồm `type`, `label`, và `body`
- Terraform có các nhóm kiểu dữ liệu chính như `string`, `number`, `bool`, `list/tuple`, `map/object`, `null`
- `expression` giúp tính toán giá trị thông qua toán tử, nội suy chuỗi và hàm dựng sẵn
- `terraform console` là công cụ nhanh nhất để thử expression
- Block `terraform {}` dùng để khai báo version, provider, backend và các thiết lập liên quan đến Terraform
- Thứ tự các dòng trong file không quyết định thứ tự chạy, vì Terraform dựa trên dependency graph
