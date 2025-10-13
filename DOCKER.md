# rcproxy Docker 部署指南

## 镜像构建

### 使用多阶段构建

新的 Dockerfile 采用了三阶段构建策略：

1. **第一阶段（builder）**：使用 `sinlov/rust-runtime-debian:latest` 编译 Rust 应用
2. **第二阶段（redis-builder）**：从 Redis 官方镜像提取 redis-cli 工具
3. **第三阶段（final）**：使用 `debian:bookworm-slim` 作为最小化运行时镜像

这种方式可以显著减小最终镜像体积，只包含运行时必需的文件。

### 构建镜像

```bash
# 使用构建脚本（推荐）
./docker-build.sh

# 或手动构建
docker build -t clia/rcproxy:2.2.1 .
docker build -t clia/rcproxy:latest .
```

### 推送到 Docker Hub

```bash
# 登录 Docker Hub
docker login

# 推送镜像
docker push clia/rcproxy:2.2.1
docker push clia/rcproxy:latest
```

## 运行容器

### 基本运行

```bash
docker run -d \
  --name rcproxy \
  -p 9000:9000 \
  clia/rcproxy:latest
```

### 使用自定义配置

```bash
docker run -d \
  --name rcproxy \
  -p 9000:9000 \
  -v /path/to/your/config.toml:/configs/default/default.toml \
  clia/rcproxy:latest
```

### 查看日志

```bash
docker logs -f rcproxy
```

### 进入容器调试

```bash
docker exec -it rcproxy bash
```

## Docker Compose 部署

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  rcproxy:
    image: clia/rcproxy:latest
    container_name: rcproxy
    ports:
      - "9000:9000"
    volumes:
      - ./default.toml:/configs/default/default.toml
      - ./logs:/app/logs
    restart: unless-stopped
    networks:
      - redis-network

networks:
  redis-network:
    driver: bridge
```

启动：

```bash
docker-compose up -d
```

## 环境变量配置

如果需要通过环境变量配置，可以修改 Dockerfile 添加环境变量支持，或在运行时传递：

```bash
docker run -d \
  --name rcproxy \
  -p 9000:9000 \
  -e RUST_LOG=info \
  clia/rcproxy:latest
```

## 健康检查

可以添加健康检查到 docker-compose.yml：

```yaml
services:
  rcproxy:
    # ... 其他配置 ...
    healthcheck:
      test: ["CMD", "redis-cli", "-p", "9000", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## 性能优化建议

1. **资源限制**：
   ```bash
   docker run -d \
     --name rcproxy \
     --memory="1g" \
     --cpus="2" \
     -p 9000:9000 \
     clia/rcproxy:latest
   ```

2. **使用主机网络模式**（仅 Linux）：
   ```bash
   docker run -d \
     --name rcproxy \
     --network host \
     clia/rcproxy:latest
   ```

3. **持久化日志**：
   ```bash
   docker run -d \
     --name rcproxy \
     -p 9000:9000 \
     -v /var/log/rcproxy:/app/logs \
     clia/rcproxy:latest
   ```

## 故障排查

### 检查容器状态

```bash
docker ps -a | grep rcproxy
docker inspect rcproxy
```

### 查看资源使用

```bash
docker stats rcproxy
```

### 重启容器

```bash
docker restart rcproxy
```

## 镜像大小对比

使用多阶段构建后，镜像体积显著减小：

- 旧版本（包含完整构建环境）：~1.5GB+
- 新版本（多阶段构建）：预计 ~100-200MB

可以使用以下命令查看实际大小：

```bash
docker images clia/rcproxy
```

## 安全建议

1. 不要在容器中以 root 用户运行（可以在 Dockerfile 中添加非 root 用户）
2. 定期更新基础镜像
3. 扫描镜像漏洞：
   ```bash
   docker scan clia/rcproxy:latest
   ```

## 生产部署检查清单

- [ ] 配置文件已正确挂载
- [ ] 日志目录已持久化
- [ ] 设置了资源限制
- [ ] 配置了健康检查
- [ ] 设置了重启策略
- [ ] 网络配置正确
- [ ] 备份策略已制定
