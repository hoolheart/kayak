#!/bin/bash
# Kayak Web Application Startup Script
# 单容器Web部署启动脚本（开发模式）

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/kayak-backend"
FRONTEND_DIR="$PROJECT_ROOT/kayak-frontend"
DATA_DIR="$PROJECT_ROOT/data"
LOG_DIR="$PROJECT_ROOT/logs"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 创建必要目录
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$FRONTEND_DIR/web-build"

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}Error: Rust/Cargo is not installed${NC}"
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Error: Flutter is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies found${NC}"
}

# 构建前端Web应用
build_frontend() {
    echo -e "${YELLOW}Building Flutter web app...${NC}"
    cd "$FRONTEND_DIR"
    
    flutter pub get
    flutter build web --release
    
    echo -e "${GREEN}Frontend built successfully${NC}"
}

# 构建后端
build_backend() {
    echo -e "${YELLOW}Building backend...${NC}"
    cd "$BACKEND_DIR"
    cargo build --release
    echo -e "${GREEN}Backend built successfully${NC}"
}

# 启动Web服务（后端提供静态文件服务）
start_web() {
    echo -e "${YELLOW}Starting web server...${NC}"
    cd "$BACKEND_DIR"
    
    # 检查是否已经在运行
    if pgrep -f "kayak-backend" > /dev/null; then
        echo -e "${YELLOW}Server is already running${NC}"
        return
    fi
    
    export KAYAK_DATA_DIR="$DATA_DIR"
    export KAYAK_LOG_LEVEL="info"
    export DATABASE_URL="sqlite://$DATA_DIR/kayak.db"
    export KAYAK_SERVE_STATIC="$FRONTEND_DIR/build/web"
    export RUST_BACKTRACE=1
    
    nohup cargo run --release > "$LOG_DIR/web.log" 2>&1 &
    
    # 等待启动
    echo "Waiting for server to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8080/health > /dev/null; then
            echo -e "${GREEN}Web server started successfully${NC}"
            echo -e "${GREEN}Access: http://localhost:8080${NC}"
            return
        fi
        sleep 1
    done
    
    echo -e "${RED}Failed to start web server${NC}"
    echo "Check logs: $LOG_DIR/web.log"
    exit 1
}

# 使用Docker Compose启动
start_docker() {
    echo -e "${YELLOW}Starting with Docker Compose...${NC}"
    cd "$PROJECT_ROOT"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    docker-compose up --build -d
    
    echo -e "${GREEN}Services started with Docker${NC}"
    echo -e "${GREEN}Access: http://localhost:80${NC}"
}

# 显示帮助
show_help() {
    cat << EOF
Kayak Web Startup Script

Usage: $0 [OPTIONS]

Options:
    --build-only    Build only, don't start
    --docker        Use Docker Compose
    --help          Show this help message

Examples:
    $0              # Build and start web server
    $0 --build-only # Build frontend and backend
    $0 --docker     # Start with Docker Compose
EOF
}

# 主逻辑
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --build-only)
            check_dependencies
            build_backend
            build_frontend
            echo -e "${GREEN}Build completed${NC}"
            exit 0
            ;;
        --docker)
            start_docker
            exit 0
            ;;
        "")
            check_dependencies
            build_backend
            build_frontend
            start_web
            echo "Logs: $LOG_DIR/web.log"
            echo "Press Ctrl+C to stop"
            
            # 保持脚本运行
            while true; do
                sleep 1
            done
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 捕获退出信号
cleanup() {
    echo -e "${YELLOW}\nShutting down...${NC}"
    pkill -f "kayak-backend" || true
    exit 0
trap cleanup SIGINT SIGTERM

main "$@"
