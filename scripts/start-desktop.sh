#!/bin/bash
# Kayak Desktop Application Startup Script
# 桌面完整部署启动脚本

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

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    # 检查Rust
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}Error: Rust/Cargo is not installed${NC}"
        echo "Please install Rust: https://rustup.rs/"
        exit 1
    fi
    
    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Error: Flutter is not installed${NC}"
        echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    # 检查Flutter桌面支持
    if ! flutter config --enable-linux-desktop 2>/dev/null; then
        echo -e "${YELLOW}Warning: Flutter Linux desktop may not be fully configured${NC}"
    fi
    
    echo -e "${GREEN}All dependencies found${NC}"
}

# 检查系统依赖
check_system_deps() {
    echo -e "${YELLOW}Checking system dependencies...${NC}"
    
    # 检查 libsecret (flutter_secure_storage 需要)
    if ! pkg-config --exists libsecret-1 2>/dev/null; then
        echo -e "${YELLOW}Warning: libsecret-1 is not installed${NC}"
        echo -e "${YELLOW}This is required for secure token storage on Linux${NC}"
        echo ""
        echo "To fix, run:"
        echo "  sudo apt-get install libsecret-1-dev"
        echo ""
        echo "Or use web mode instead: ./scripts/start-web.sh"
        echo ""
        read -p "Try to install libsecret-1-dev now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get install libsecret-1-dev
        else
            echo -e "${RED}Cannot proceed without libsecret-1${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}System dependencies OK${NC}"
}

# 构建后端
build_backend() {
    echo -e "${YELLOW}Building backend...${NC}"
    cd "$BACKEND_DIR"
    
    # 检查是否需要构建
    if [ ! -f "$BACKEND_DIR/target/release/kayak-backend" ] || \
       [ "$BACKEND_DIR/Cargo.toml" -nt "$BACKEND_DIR/target/release/kayak-backend" ]; then
        cargo build --release
        echo -e "${GREEN}Backend built successfully${NC}"
    else
        echo -e "${GREEN}Backend is up to date${NC}"
    fi
}

# 启动后端
start_backend() {
    echo -e "${YELLOW}Starting backend server...${NC}"
    cd "$BACKEND_DIR"
    
    # 检查是否已经在运行
    if pgrep -f "kayak-backend" > /dev/null; then
        echo -e "${YELLOW}Backend is already running${NC}"
        return
    fi
    
    # 启动后端（后台运行）
    export KAYAK_DATA_DIR="$DATA_DIR"
    export KAYAK_LOG_LEVEL="info"
    export DATABASE_URL="sqlite://$DATA_DIR/kayak.db"
    export RUST_BACKTRACE=1
    
    nohup cargo run --release > "$LOG_DIR/backend.log" 2>&1 &
    
    # 等待后端启动
    echo "Waiting for backend to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8080/health > /dev/null; then
            echo -e "${GREEN}Backend started successfully on port 8080${NC}"
            return
        fi
        sleep 1
    done
    
    echo -e "${RED}Failed to start backend${NC}"
    echo "Check logs: $LOG_DIR/backend.log"
    exit 1
}

# 启动前端（桌面模式）
start_frontend() {
    echo -e "${YELLOW}Starting Flutter desktop app...${NC}"
    cd "$FRONTEND_DIR"
    
    # 获取依赖
    flutter pub get
    
    # 启动桌面应用
    echo -e "${YELLOW}Launching Flutter desktop (this may take a moment)...${NC}"
    flutter run -d linux
}

# 显示帮助
show_help() {
    cat << EOF
Kayak Desktop Startup Script

Usage: $0 [OPTIONS]

Options:
    --build-only    Build only, don't start
    --backend-only  Start backend only
    --help          Show this help message

Examples:
    $0              # Build and start everything
    $0 --build-only # Build only
    $0 --backend-only # Start backend only
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
            echo -e "${GREEN}Build completed${NC}"
            exit 0
            ;;
        --backend-only)
            check_dependencies
            build_backend
            start_backend
            echo -e "${GREEN}Backend is running at http://localhost:8080${NC}"
            echo "Logs: $LOG_DIR/backend.log"
            exit 0
            ;;
        "")
            check_dependencies
            build_backend
            start_backend
            check_system_deps
            start_frontend
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
}
trap cleanup SIGINT SIGTERM

main "$@"
