# stage 1 as builder
FROM ubuntu:16.04 as builder

RUN apt-get update
RUN apt-get install -y wget git make curl

# Install Cloud Foundry cli v6 & v7
RUN if [ `uname -m` = "aarch64" ] ; then \
       wget -q https://dl.google.com/go/go1.13.linux-arm64.tar.gz && \
       tar -xf go1.13.linux-arm64.tar.gz && \
       mv go /usr/local && \
       export GOROOT=/usr/local/go && \
       export GOPATH=/root/go && \
       export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
       git clone https://github.com/cloudfoundry/cli && \
       cd cli && \
       git checkout v6 && \
       make build && \
       mv out/cf /usr/local/bin/cf && \
       git checkout v7 && \
       make build && \
       cp out/cf /usr/local/bin/cf7; \
    else \
       curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github&version=v6" | tar -zx && \
       mv cf /usr/local/bin && \
       curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v7&source=github" | tar -zx && \
       mv cf7 /usr/local/bin; \
    fi

# Install yaml cli
RUN if [ `uname -m` = "aarch64" ] ; then \
       wget -q https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_arm64 && \
       cp yq_linux_arm64 /usr/local/bin/yq; \
    else \
       wget -q https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
       cp yq_linux_amd64 /usr/local/bin/yq; \
    fi

FROM alpine:3.11

ADD resource/ /opt/resource/
ADD itest/ /opt/itest/

# Install uuidgen
RUN apk add --no-cache ca-certificates curl bash jq util-linux

# Install Cloud Foundry cli v6
COPY --from=builder /usr/local/bin/cf .
RUN install cf /usr/local/bin/cf && \
  cf --version && \
  rm -f cf

# Install Cloud Foundry cli v7
COPY --from=builder /usr/local/bin/cf7 .
RUN install cf7 /usr/local/bin/cf7 && \
  cf7 --version && \
  rm -f cf7

# Install yaml cli
COPY --from=builder /usr/local/bin/yq .
RUN install yq /usr/local/bin/yq && \
  yq --version && \
  rm -f yq
