#!/bin/bash
# Kayak Stop Script
# 停止所有Kayak服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping Kayak services...${NC}"

# 停止后端服务
if pgrep -f "kayak-backend" > /dev/null; then
    echo "Stopping backend..."
    pkill -f "kayak-backend" || true
    sleep 2
fi

# 停止Docker容器
if command -v docker &> /dev/null; then
    if docker ps | grep -q "kayak"; then
        echo "Stopping Docker containers..."
        docker-compose down 2>/dev/null || true
    fi
fi

# 停止Flutter进程（开发模式）
if pgrep -f "flutter" > /dev/null; then
    echo "Stopping Flutter..."
    pkill -f "flutter" || true
fi

echo -e "${GREEN}All services stopped${NC}"
