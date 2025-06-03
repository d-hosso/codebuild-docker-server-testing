FROM ubuntu:22.04

# Stage 1: Base development environment
FROM ubuntu:22.04 AS base
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
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

# Stage 4: Node.js environment (for frontend development)
FROM base AS frontend
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install frontend development tools
RUN npm install -g npm@latest && \
    npm install -g yarn && \
    npm install -g @vue/cli

# Stage 5: Final image
FROM base
# Copy Java environment
COPY --from=java /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17-openjdk-amd64
COPY --from=java /usr/bin/mvn /usr/bin/mvn
COPY --from=java /root/.m2 /root/.m2

# Copy Database tools
COPY --from=db /usr/bin/psql /usr/bin/psql
COPY --from=db /usr/bin/mysql /usr/bin/mysql

# Copy Node.js
COPY --from=frontend /usr/bin/node /usr/bin/node
COPY --from=frontend /usr/bin/npm /usr/bin/npm
COPY --from=frontend /usr/local/bin/yarn /usr/local/bin/yarn
COPY --from=frontend /usr/local/bin/vue /usr/local/bin/vue

# Set up Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

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
    echo 'console.log("Frontend development environment ready")' > /workspace/frontend/index.js

# Copy pom.xml
COPY pom.xml /workspace/pom.xml

# Set working directory
WORKDIR /workspace

# Final stage
CMD ["/bin/bash"] 