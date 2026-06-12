FROM python:3.12-slim

RUN pip install --no-cache-dir flask prometheus-flask-exporter

COPY app.py /app/app.py
WORKDIR /app

EXPOSE 8080

CMD ["flask", "--app", "app.py", "run", "--host=0.0.0.0", "--port=8080"]
