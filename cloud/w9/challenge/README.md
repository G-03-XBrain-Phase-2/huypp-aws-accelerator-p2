# W9 Challenge

Thư mục này dùng riêng cho bài tập lớn `Ship Smartly`.

Mục tiêu của challenge:

1. Mọi thay đổi qua Git, ArgoCD tự sync
2. Có 1 SLO + 1 alert khi chất lượng tụt
3. Canary bản tốt lên 100%, bản lỗi tự abort
4. Có thể rollback lâu dài bằng `git revert`

## Khung tối thiểu

```text
challenge/
  argocd/
    apps/
  k8s-api/
  app/
```

## Ý nghĩa từng thư mục

- `argocd/apps/`
  - đặt `Application` riêng cho challenge nếu bạn muốn chạy challenge như một app tách biệt

- `k8s-api/`
  - đặt manifest Kubernetes/Argo Rollouts cho challenge
  - ví dụ: `api.yaml`, `servicemonitor.yaml`, `analysis-template.yaml`, `prometheusrule.yaml`

- `app/`
  - đặt source code app nếu bạn muốn tách challenge ra khỏi app lab hiện tại

## Cách làm challenge trên khung này

### Bước 1. Chọn chiến lược

Bạn có 2 hướng:

- Hướng nhanh:
  - tái sử dụng app `api` đã làm ở lab cũ
  - chỉ sao chép các file cần thiết vào `challenge/`

- Hướng sạch:
  - tạo app challenge riêng hoàn toàn
  - có `Application` riêng, manifest riêng, app riêng

Nếu mục tiêu là hoàn thành bài trong 24h, nên chọn hướng nhanh.

### Bước 2. Những file tối thiểu cần có

Trong `challenge/k8s-api/`, tối thiểu nên có:

- `api.yaml`
- `servicemonitor.yaml`
- `analysis-template.yaml`
- `prometheusrule.yaml`

Trong `challenge/argocd/apps/`, tối thiểu nên có:

- `api-challenge.yaml`

Nếu app code cần tách riêng, thêm:

- `challenge/app/app.py`
- `challenge/app/Dockerfile`

### Bước 3. Tiêu chí đạt challenge

Phải chứng minh được 4 điều:

1. Thay đổi qua Git, ArgoCD `Synced`
2. `git revert` rollback được
3. Alert fire khi inject lỗi
4. Canary bản lỗi tự abort

### Bước 4. SLI / SLO gợi ý

SLI:

- tỷ lệ lỗi 5xx của service `api`

Query gợi ý:

```promql
sum(rate(flask_http_request_total{service="api",status=~"5.."}[5m]))
/
sum(rate(flask_http_request_total{service="api"}[5m]))
```

SLO gợi ý:

- error rate < 5%

### Bước 5. Alert gợi ý

Tạo `PrometheusRule` khi error rate > 5% trong 2-5 phút.

### Bước 6. Auto-abort gợi ý

Trong `analysis-template.yaml`, dùng query 5xx:

```promql
sum(rate(flask_http_request_total{service="api",status=~"5.."}[2m])) or on() vector(0)
```

Ngưỡng ví dụ:

- pass nếu `< 0.1`
- fail nếu `>= 0.1`

### Bước 7. Kịch bản demo nên chuẩn bị

Kịch bản tốt:

- `ERROR_RATE=0`
- rollout pass
- app `Healthy`

Kịch bản xấu:

- `ERROR_RATE=0.3` hoặc `1`
- analysis fail
- rollout abort
- stable version vẫn phục vụ

### Bước 8. Chứng minh rollback

Sau khi có commit xấu:

```powershell
git revert HEAD --no-edit
git push
```

ArgoCD sẽ sync về trạng thái tốt.

## Gợi ý trình bày

Bạn có thể present theo flow:

1. GitOps: mọi thay đổi qua Git
2. Observability: Prometheus scrape `/metrics`
3. Canary: `Rollout` thả 25%
4. Analysis: dùng metric để chấm bản mới
5. Xấu thì auto-abort, lâu dài thì `git revert`
