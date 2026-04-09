FROM jenkins/jenkins:lts-jdk21

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Runtime packages needed by pipeline and NodeJS runtime dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        git \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 for deploy stages (aws s3 sync / cloudfront invalidation).
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# Quick sanity checks at build time.
RUN aws --version && java -version

USER jenkins
