
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0

FROM python:3.10-slim AS base

FROM base AS builder

RUN apt-get update -o Acquire::Retries=3 \
    && apt-get install -y --no-install-recommends \
        wget g++ \
    && rm -rf /var/lib/apt/lists/*

# Download the grpc health probe
ENV GRPC_HEALTH_PROBE_VERSION=v0.4.18

RUN wget -qO/bin/grpc_health_probe \
    https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 \
    && chmod +x /bin/grpc_health_probe

# Install packages
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM base AS without-grpc-health-probe-bin

ENV PYTHONUNBUFFERED=1

WORKDIR /recommendationservice

COPY --from=builder /usr/local/lib/python3.10/ /usr/local/lib/python3.10/

COPY . .

ENV PORT="8080"

EXPOSE 8080

ENTRYPOINT ["python", "recommendation_server.py"]

FROM without-grpc-health-probe-bin

COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
