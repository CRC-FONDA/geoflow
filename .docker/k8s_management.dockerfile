FROM ubuntu:latest

WORKDIR /root

ENV KUBECONFIG /murmel/.kubernetes/kubeconfig.yml
ENV PATH "$PATH:/root"

RUN apt update && \
    apt install -y ca-certificates curl openjdk-17-jre

RUN curl -s https://get.nextflow.io | bash

RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
    | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt update && \
    apt install -y kubectl openvpn git

WORKDIR /murmel

CMD ["bash"]
