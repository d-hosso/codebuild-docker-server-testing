FROM public.ecr.aws/amazonlinux/amazonlinux:latest 

# 基本的なツールをインストール
RUN yum update -y && \
    yum install -y --allowerasing \
    curl \
    wget \
    unzip \
    tar \
    git \
    vim \
    && yum clean all

# 作業ディレクトリを設定
WORKDIR /app

# アプリケーションの実行
RUN echo "Hello World"