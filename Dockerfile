FROM ubuntu:22.04

ENV VERIFY_CHECKSUM=false
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    curl \
    git \
    awscli \
    python3 \
    pip \
    gh

# Install github cli
RUN pip install shyaml

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
