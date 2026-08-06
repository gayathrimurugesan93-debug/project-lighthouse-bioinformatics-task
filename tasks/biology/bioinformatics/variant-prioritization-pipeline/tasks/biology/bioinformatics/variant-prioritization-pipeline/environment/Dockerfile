FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    numpy==2.2.5 \
    scipy==1.15.3 \
    pandas==2.2.3 \
    matplotlib==3.10.1 \
    seaborn==0.13.2

COPY . /app/

RUN chmod +x /app/solution/solve.sh

ENTRYPOINT ["bash", "/app/solution/solve.sh"]
