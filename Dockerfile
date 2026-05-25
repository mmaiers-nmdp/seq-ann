FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim
LABEL maintainer="NMDP Bioinformatics"

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        clustalo \
        default-libmysqlclient-dev \
        ncbi-blast+ \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN uv pip install --system seq-ann==1.1.0
