ARG STEAMRT_BASE_IMAGE=registry.gitlab.steamos.cloud/steamrt/steamrt4/sdk:latest
FROM ${STEAMRT_BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf-archive \
    gettext \
    autopoint \
    cargo \
    clang-format \
    curl \
    libltdl-dev \
    python3-venv \
    rustc \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o /tmp/conan.deb -L https://github.com/conan-io/conan/releases/download/2.32.0/conan-2.32.0-amd64.deb && \
    dpkg -i /tmp/conan.deb && rm /tmp/conan.deb

COPY run-build.sh /usr/local/bin/steamrt-build
RUN chmod +x /usr/local/bin/steamrt-build

WORKDIR /work/ofpr
ENTRYPOINT ["/usr/local/bin/steamrt-build"]
