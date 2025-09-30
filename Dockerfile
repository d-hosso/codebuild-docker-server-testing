FROM ubuntu:22.04

# Stage 1: Base development environment
FROM ubuntu:22.04 AS base
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Java environment
FROM base AS java
RUN apt-get update && \
    apt-get install -y \
    openjdk-17-jdk \
    maven \
    && rm -rf /var/lib/apt/lists/*

# Install common Java development tools
RUN mvn dependency:get -Dartifact=org.springframework.boot:spring-boot-starter-web:3.2.3 && \
    mvn dependency:get -Dartifact=org.springframework.boot:spring-boot-starter-data-jpa:3.2.3 && \
    mvn dependency:get -Dartifact=org.springframework.boot:spring-boot-starter-test:3.2.3 && \
    mvn dependency:get -Dartifact=org.projectlombok:lombok:1.18.30 && \
    mvn dependency:get -Dartifact=com.h2database:h2:2.2.224

# Stage 3: Database tools
FROM base AS db
RUN apt-get update && \
    apt-get install -y \
    postgresql-client \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Stage 4: Python environment (heavy ML libraries)
FROM base AS python
RUN apt-get update && \
    apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3-pip \
    python3.11-venv \
    && rm -rf /var/lib/apt/lists/*

# Install heavy Python packages for ML/AI
RUN python3.11 -m pip install --no-cache-dir \
    tensorflow==2.15.0 \
    torch==2.1.0 \
    torchvision==0.16.0 \
    torchaudio==2.1.0 \
    scikit-learn==1.3.2 \
    pandas==2.1.4 \
    numpy==1.24.4 \
    matplotlib==3.8.2 \
    seaborn==0.13.0 \
    jupyter==1.0.0 \
    opencv-python==4.8.1.78 \
    pillow==10.1.0 \
    requests==2.31.0 \
    beautifulsoup4==4.12.2 \
    flask==3.0.0 \
    django==4.2.7 \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    pydantic==2.5.0 \
    sqlalchemy==2.0.23 \
    alembic==1.13.1 \
    celery==5.3.4 \
    redis==5.0.1

# Stage 5: Node.js environment (for frontend development)
FROM base AS frontend
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install frontend development tools
RUN npm install -g npm@latest && \
    npm install -g yarn && \
    npm install -g @vue/cli && \
    npm install -g @angular/cli && \
    npm install -g create-react-app && \
    npm install -g typescript && \
    npm install -g webpack && \
    npm install -g gulp && \
    npm install -g grunt-cli

# Stage 6: Additional heavy tools (Rust, Go, .NET)
FROM base AS additional-tools
RUN apt-get update && \
    apt-get install -y \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (this is a heavy installation)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    /root/.cargo/bin/rustup update && \
    /root/.cargo/bin/cargo install --locked cargo-cache

# Install .NET SDK (heavy)
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/*

# Install additional database tools
RUN apt-get update && \
    apt-get install -y \
    postgresql-14 \
    postgresql-contrib-14 \
    mongodb-org \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Stage 7: Final image
FROM base
# Copy Java environment
COPY --from=java /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17-openjdk-amd64
COPY --from=java /usr/bin/mvn /usr/bin/mvn
COPY --from=java /root/.m2 /root/.m2

# Copy Python environment
COPY --from=python /usr/bin/python3.11 /usr/bin/python3.11
COPY --from=python /usr/lib/python3.11 /usr/lib/python3.11
COPY --from=python /usr/local/lib/python3.11/dist-packages /usr/local/lib/python3.11/dist-packages
COPY --from=python /usr/local/bin /usr/local/bin

# Copy Database tools
COPY --from=db /usr/bin/psql /usr/bin/psql
COPY --from=db /usr/bin/mysql /usr/bin/mysql

# Copy Node.js
COPY --from=frontend /usr/bin/node /usr/bin/node
COPY --from=frontend /usr/bin/npm /usr/bin/npm
COPY --from=frontend /usr/local/bin/yarn /usr/local/bin/yarn
COPY --from=frontend /usr/local/bin/vue /usr/local/bin/vue
COPY --from=frontend /usr/local/bin/ng /usr/local/bin/ng
COPY --from=frontend /usr/local/bin/create-react-app /usr/local/bin/create-react-app
COPY --from=frontend /usr/local/bin/tsc /usr/local/bin/tsc
COPY --from=frontend /usr/local/bin/webpack /usr/local/bin/webpack
COPY --from=frontend /usr/local/bin/gulp /usr/local/bin/gulp
COPY --from=frontend /usr/local/bin/grunt /usr/local/bin/grunt

# Copy additional tools
COPY --from=additional-tools /usr/bin/go /usr/bin/go
COPY --from=additional-tools /root/.cargo /root/.cargo
COPY --from=additional-tools /usr/share/dotnet /usr/share/dotnet
COPY --from=additional-tools /usr/bin/dotnet /usr/bin/dotnet
COPY --from=additional-tools /usr/lib/postgresql /usr/lib/postgresql
COPY --from=additional-tools /usr/bin/postgres /usr/bin/postgres
COPY --from=additional-tools /usr/bin/mongod /usr/bin/mongod
COPY --from=additional-tools /usr/bin/redis-server /usr/bin/redis-server

# Set up environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:/root/.cargo/bin:/usr/share/dotnet:$PATH
ENV GOROOT=/usr/lib/go
ENV GOPATH=/root/go
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PYTHONPATH=/usr/local/lib/python3.11/dist-packages

# Create workspace structure
RUN mkdir -p /workspace && \
    mkdir -p /workspace/src/main/java && \
    mkdir -p /workspace/src/main/resources && \
    mkdir -p /workspace/src/test/java && \
    mkdir -p /workspace/src/test/resources && \
    mkdir -p /workspace/frontend

# Create sample files
RUN echo 'package com.example.demo;\n\nimport org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\n\n@SpringBootApplication\npublic class DemoApplication {\n    public static void main(String[] args) {\n        SpringApplication.run(DemoApplication.class, args);\n    }\n}' > /workspace/src/main/java/com/example/demo/DemoApplication.java && \
    echo 'spring.datasource.url=jdbc:h2:mem:testdb\nspring.datasource.driverClassName=org.h2.Driver\nspring.datasource.username=sa\nspring.datasource.password=\nspring.jpa.database-platform=org.hibernate.dialect.H2Dialect\nspring.h2.console.enabled=true' > /workspace/src/main/resources/application.properties && \
    echo 'console.log("Frontend development environment ready")' > /workspace/frontend/index.js && \
    echo 'import tensorflow as tf\nimport torch\nimport numpy as np\nprint("Heavy ML libraries loaded successfully!")\nprint(f"TensorFlow version: {tf.__version__}")\nprint(f"PyTorch version: {torch.__version__}")\nprint(f"NumPy version: {np.__version__}")' > /workspace/test_ml.py && \
    echo 'package main\n\nimport "fmt"\n\nfunc main() {\n    fmt.Println("Go development environment ready!")\n}' > /workspace/main.go && \
    echo 'fn main() {\n    println!("Rust development environment ready!");\n}' > /workspace/main.rs

# Copy pom.xml
COPY pom.xml /workspace/pom.xml

# Set working directory
WORKDIR /workspace

# Final stage
CMD ["/bin/bash"] 