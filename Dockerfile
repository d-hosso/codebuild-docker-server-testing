# Stage 1: Base development environment with security improvements
FROM ubuntu:22.04 AS base

# Install security updates and essential packages only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Stage 2: Java environment with better caching
FROM base AS java

# Install Java and Maven in separate layers for better caching
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Maven separately for better layer caching
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    maven \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Pre-download dependencies for better caching (this layer will be cached)
COPY pom.xml /tmp/pom.xml
WORKDIR /tmp
RUN mvn dependency:go-offline -B && \
    mvn dependency:get -Dartifact=org.springframework.boot:spring-boot-starter-web:3.2.3 && \
    mvn dependency:get -Dartifact=org.springframework.boot:spring-boot-starter-data-jpa:3.2.3 && \
    mvn dependency:get -Dartifact=org.springframework.boot:spring-boot-starter-test:3.2.3 && \
    mvn dependency:get -Dartifact=org.projectlombok:lombok:1.18.30 && \
    mvn dependency:get -Dartifact=com.h2database:h2:2.2.224

# Stage 3: Database tools (minimal installation)
FROM base AS db
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Stage 4: Node.js environment (for frontend development) - optional
FROM base AS frontend
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install frontend tools in separate layer for better caching
RUN npm install -g npm@latest && \
    npm install -g yarn && \
    npm install -g @vue/cli

# Stage 5: Final optimized image
FROM base

# Copy Java environment with proper permissions
COPY --from=java /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17-openjdk-amd64
COPY --from=java /usr/bin/mvn /usr/bin/mvn
COPY --from=java /root/.m2 /root/.m2

# Copy Database tools
COPY --from=db /usr/bin/psql /usr/bin/psql

# Copy Node.js (optional - can be removed if not needed)
COPY --from=frontend /usr/bin/node /usr/bin/node
COPY --from=frontend /usr/bin/npm /usr/bin/npm
COPY --from=frontend /usr/local/bin/yarn /usr/local/bin/yarn
COPY --from=frontend /usr/local/bin/vue /usr/local/bin/vue

# Set up Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Create workspace structure with proper permissions
RUN mkdir -p /workspace && \
    mkdir -p /workspace/src/main/java && \
    mkdir -p /workspace/src/main/resources && \
    mkdir -p /workspace/src/test/java && \
    mkdir -p /workspace/src/test/resources && \
    mkdir -p /workspace/frontend && \
    chown -R appuser:appuser /workspace

# Create sample files (this layer will be cached unless files change)
RUN echo 'package com.example.demo;\n\nimport org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\n\n@SpringBootApplication\npublic class DemoApplication {\n    public static void main(String[] args) {\n        SpringApplication.run(DemoApplication.class, args);\n    }\n}' > /workspace/src/main/java/com/example/demo/DemoApplication.java && \
    echo 'spring.datasource.url=jdbc:h2:mem:testdb\nspring.datasource.driverClassName=org.h2.Driver\nspring.datasource.username=sa\nspring.datasource.password=\nspring.jpa.database-platform=org.hibernate.dialect.H2Dialect\nspring.h2.console.enabled=true' > /workspace/src/main/resources/application.properties && \
    echo 'console.log("Frontend development environment ready")' > /workspace/frontend/index.js && \
    chown -R appuser:appuser /workspace

# Copy pom.xml (this layer will be cached unless pom.xml changes)
COPY --chown=appuser:appuser pom.xml /workspace/pom.xml

# Set working directory
WORKDIR /workspace

# Switch to non-root user for security
USER appuser

# Final stage
CMD ["/bin/bash"] 