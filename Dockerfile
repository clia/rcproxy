# 第一阶段：构建Rust应用
FROM sinlov/rust-runtime-debian:latest AS builder

# 设置工作目录
WORKDIR /build

# 复制依赖配置文件
COPY Cargo.toml Cargo.lock* ./

# 复制源代码
COPY src ./src
COPY bin ./bin
COPY benches ./benches
COPY cli.yml ./

# 构建release版本
RUN cargo build --release

# 第二阶段：构建redis-cli
FROM redis:alpine AS redis-builder

# 第三阶段：最小化运行时镜像
FROM debian:bookworm-slim

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 从builder阶段复制编译好的二进制文件
COPY --from=builder /build/target/release/rcproxy /app/rcproxy

# 从redis-builder阶段复制redis-cli
COPY --from=redis-builder /usr/local/bin/redis-cli /usr/local/bin/redis-cli

# 复制配置文件
COPY default.toml /configs/default/default.toml
COPY cli.yml /app/cli.yml

# 设置工作目录
WORKDIR /app

# 设置可执行权限
RUN chmod +x /app/rcproxy

# 暴露端口（根据你的配置调整）
EXPOSE 9000

# 设置启动命令
CMD ["/app/rcproxy", "/configs/default/default.toml"]