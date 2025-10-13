#!/bin/bash

# Docker镜像构建和推送脚本
# 用法: ./docker-build.sh [版本号]

set -e

# 从Cargo.toml读取版本号，或使用命令行参数
VERSION=${1:-$(grep '^version' Cargo.toml | head -1 | cut -d'"' -f2)}
IMAGE_NAME="clia/rcproxy"

echo "========================================="
echo "构建 rcproxy Docker 镜像"
echo "版本: $VERSION"
echo "========================================="

# 构建镜像
echo "正在构建镜像..."
docker build -t ${IMAGE_NAME}:${VERSION} .
docker build -t ${IMAGE_NAME}:latest .

echo "========================================="
echo "镜像构建完成！"
echo "镜像标签:"
echo "  - ${IMAGE_NAME}:${VERSION}"
echo "  - ${IMAGE_NAME}:latest"
echo "========================================="

# 询问是否推送到Docker Hub
read -p "是否推送到Docker Hub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "正在推送镜像到Docker Hub..."
    docker push ${IMAGE_NAME}:${VERSION}
    docker push ${IMAGE_NAME}:latest
    echo "========================================="
    echo "镜像推送完成！"
    echo "========================================="
else
    echo "跳过推送。"
fi

# 显示镜像信息
echo ""
echo "镜像信息:"
docker images ${IMAGE_NAME}
