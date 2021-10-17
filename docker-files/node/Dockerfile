FROM node:fermium-alpine

ENV KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release"

# Installing some basics
RUN apk add --no-cache curl git unzip bash

# Installing Terraform
RUN curl -LO https://releases.hashicorp.com/terraform/1.0.9/terraform_1.0.9_linux_amd64.zip
RUN unzip terraform_1.0.9_linux_amd64.zip
RUN rm -rf terraform_1.0.9_linux_amd64.zip
RUN mv terraform /usr/bin

# Installing bash
RUN apk add --no-cache bash
RUN sed -i "s/ash/bash/g" /etc/passwd

# Installing AWS CLI
RUN apk add --no-cache python3
RUN pip3 install awscli

# Installing Kubctl
RUN curl -LO "${KUBECTL_URL}/$(curl -s ${KUBECTL_URL}/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl
