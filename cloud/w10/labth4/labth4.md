# Hand-on: Detect sensitive data in Amazon S3 buckets and send notifications using Amazon Macie

## Mục tiêu

Phát hiện dữ liệu nhạy cảm (sensitive data) trong Amazon S3 bằng Amazon Macie, sau đó gửi cảnh báo qua email thông qua Amazon SNS và Amazon EventBridge.

## Kiến trúc

```
User → Login AWS Console → Create & Configure Resources
         S3 Bucket ← Upload Sample Files
         S3 Bucket → Amazon Macie Job → Amazon Macie → Findings
         EventBridge (Rule created for alerts) → SNS → Alerts on Email
```

---

## Các bước thực hiện

### Bước 1: Tạo S3 Bucket và Upload file mẫu

- Tạo S3 Bucket để lưu trữ các file mẫu chứa dữ liệu nhạy cảm.
- Upload các sample files (CSV, JSON, v.v. chứa thông tin như số thẻ tín dụng, số CMND, email...) lên S3 Bucket.

![Tạo S3 Bucket và upload file mẫu](./image/Screenshot%202026-06-19%20160204.png)

---

### Bước 2: Tạo SNS Topic và Subscription (Email)

- Tạo SNS Topic để nhận cảnh báo.
- Thêm Subscription với protocol **Email**, nhập địa chỉ email nhận alert.
- Xác nhận email subscription qua hòm thư.

![Tạo SNS Topic và Subscription](./image/Screenshot%202026-06-19%20160534.png)

---

### Bước 3: Bật Amazon Macie và tạo Macie Job

- Vào **Amazon Macie** → Enable Macie cho account.
- Tạo **Macie Job** để scan S3 Bucket vừa tạo:
  - Chọn S3 Bucket cần scan.
  - Chọn loại job: One-time hoặc Scheduled.
  - Cấu hình các managed data identifiers để phát hiện sensitive data.

![Tạo Macie Job scan S3](./image/Screenshot%202026-06-19%20161017.png)

---

### Bước 4: Tạo EventBridge Rule để bắt Macie Findings

- Vào **Amazon EventBridge** → Tạo Rule mới.
- Event source: **AWS services** → chọn **Macie**.
- Event type: **Macie Finding**.
- Target: chọn **SNS Topic** đã tạo ở Bước 2.
- Rule này sẽ tự động forward Macie findings đến SNS → gửi email alert.

![Tạo EventBridge Rule cho Macie Findings](./image/Screenshot%202026-06-19%20161150.png)

![Cấu hình EventBridge Rule - Event Pattern](./image/Screenshot%202026-06-19%20163842.png)

![EventBridge Rule đã tạo thành công](./image/Screenshot%202026-06-19%20163855.png)

---

### Bước 5: Kiểm tra kết quả - Macie Findings và Email Alert

- Sau khi Macie Job hoàn thành, vào **Macie → Findings** để xem các sensitive data đã được phát hiện.
- Kiểm tra email: đã nhận được cảnh báo từ SNS với thông tin về finding.

![Macie Findings và Email Alert nhận được](./image/Screenshot%202026-06-19%20163425.png)

---

## Kết quả đạt được

| Thành phần | Trạng thái |
|---|---|
| S3 Bucket với sample files | ✅ Đã tạo và upload |
| Amazon Macie enabled | ✅ Đã bật |
| Macie Job scan S3 | ✅ Đã tạo và chạy |
| Macie Findings | ✅ Phát hiện sensitive data |
| SNS Topic + Email Subscription | ✅ Đã tạo và xác nhận |
| EventBridge Rule → SNS | ✅ Đã cấu hình |
| Email Alert nhận được | ✅ Nhận được cảnh báo |

---

## Tổng kết

Bài lab đã thực hiện thành công việc:
1. **Phát hiện dữ liệu nhạy cảm** trong S3 bucket bằng Amazon Macie.
2. **Tự động gửi cảnh báo** qua email khi có findings thông qua EventBridge + SNS.

Giải pháp này phù hợp cho các tổ chức cần giám sát và bảo vệ dữ liệu nhạy cảm lưu trữ trên AWS S3 theo yêu cầu compliance (GDPR, PCI-DSS, HIPAA...).
