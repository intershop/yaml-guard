
FROM python:3.10-slim

# System dependencies and tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    ca-certificates \
    jq \
    gettext \  
    && apt-get clean

# install yamllint with pip (works fine in Python environment)
RUN pip install yamllint

# kustomize setup (old script commented out, using direct download instead)
# RUN curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash && \
#     mv kustomize /usr/local/bin/

RUN curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.3.0/kustomize_v5.3.0_linux_amd64.tar.gz | tar xz && \
    mv kustomize /usr/local/bin/

# # kubeval setup
# RUN curl -L "https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz" | tar xz && \
#     mv kubeval /usr/local/bin/ && \
#     chmod +x /usr/local/bin/kustomize /usr/local/bin/kubeval

# kubeconform setup (replacing kubeval)
RUN curl -L "https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz" | tar xz && \
    mv kubeconform /usr/local/bin/ && \
    chmod +x /usr/local/bin/kustomize /usr/local/bin/kubeconform

# Copy yamllint config to /src/.yamllint
COPY .yamllint /src/.yamllint
#COPY .yamllint_kustomize.yaml /src/.yamllint_kustomize.yaml



# Copy validate_kustomize.sh script and make it executable
COPY scripts/validate_kustomize.sh /usr/local/bin/validate_kustomize.sh
RUN chmod +x /usr/local/bin/validate_kustomize.sh

# work directory
WORKDIR /src

# Entry point left blank; direct commands can be executed
# You can also add ENTRYPOINT [‘bash’] if you want
