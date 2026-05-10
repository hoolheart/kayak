#!/bin/bash
# =============================================================================
# Sprint 1 开发环境一键启动脚本
# R2-S1-003-A: 启动后端 + 前端开发服务器
# =============================================================================

set -e

# 路径配置
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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# PID 文件
BACKEND_PID_FILE="$LOG_DIR/backend.pid"
FRONTEND_PID_FILE="$LOG_DIR/frontend.pid"

# 创建必要目录
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# 检查 Rust toolchain
check_rust() {
    echo -e "${YELLOW}▶ 检查 Rust toolchain...${NC}"
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}✗ 错误: Rust/Cargo 未安装${NC}"
        echo "  请访问 https://rustup.rs/ 安装 Rust"
        exit 1
    fi
    
    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}✗ 错误: rustc 未找到${NC}"
        exit 1
    fi
    
    local rust_version
    rust_version=$(rustc --version)
    echo -e "${GREEN}✓ Rust 已安装: $rust_version${NC}"
}

# 检查 Flutter
check_flutter() {
    echo -e "${YELLOW}▶ 检查 Flutter...${NC}"
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}✗ 错误: Flutter 未安装${NC}"
        echo "  请访问 https://docs.flutter.dev/get-started/install 安装 Flutter"
        exit 1
    fi
    
    local flutter_version
    flutter_version=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓ Flutter 已安装: $flutter_version${NC}"
    
    # 检查 Chrome 设备是否可用
    if ! flutter devices | grep -q "Chrome"; then
        echo -e "${YELLOW}⚠ 警告: 未检测到 Chrome 设备${NC}"
        echo "  请确保已安装 Chrome 浏览器"
    fi
}

# 检查项目结构
check_project() {
    echo -e "${YELLOW}▶ 检查项目结构...${NC}"
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${RED}✗ 错误: 后端目录不存在: $BACKEND_DIR${NC}"
        exit 1
    fi
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo -e "${RED}✗ 错误: 前端目录不存在: $FRONTEND_DIR${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 项目结构检查通过${NC}"
}

# 启动后端开发服务器
start_backend() {
    echo -e "${YELLOW}▶ 启动后端开发服务器...${NC}"
    cd "$BACKEND_DIR"
    
    # 检查是否已有后端在运行
    if pgrep -f "kayak-backend" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 后端服务已在运行，尝试停止...${NC}"
        pkill -f "kayak-backend" || true
        sleep 2
    fi
    
    # 设置环境变量
    export KAYAK_DATA_DIR="$DATA_DIR"
    export DATABASE_URL="sqlite://$(realpath "$DATA_DIR")/kayak.db"
    export KAYAK_LOG_LEVEL="debug"
    export RUST_BACKTRACE=1
    
    # 启动后端（开发模式，非 release）
    echo "  工作目录: $BACKEND_DIR"
    echo "  数据目录: $DATA_DIR"
    echo "  日志文件: $LOG_DIR/backend.log"
    
    cargo run > "$LOG_DIR/backend.log" 2>&1 &
    local backend_pid=$!
    echo $backend_pid > "$BACKEND_PID_FILE"
    
    # 等待后端启动
    echo "  等待后端启动..."
    local attempts=0
    local max_attempts=60
    while [ $attempts -lt $max_attempts ]; do
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 后端启动成功 (PID: $backend_pid)${NC}"
            return 0
        fi
        
        # 检查进程是否还在运行
        if ! kill -0 $backend_pid 2>/dev/null; then
            echo -e "${RED}✗ 后端进程异常退出${NC}"
            echo "  查看日志: $LOG_DIR/backend.log"
            exit 1
        fi
        
        attempts=$((attempts + 1))
        sleep 1
    done
    
    echo -e "${RED}✗ 后端启动超时${NC}"
    echo "  查看日志: $LOG_DIR/backend.log"
    exit 1
}

# 启动前端开发服务器
start_frontend() {
    echo -e "${YELLOW}▶ 启动前端开发服务器...${NC}"
    cd "$FRONTEND_DIR"
    
    # 检查是否已有 flutter run 在运行
    if pgrep -f "flutter run" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Flutter 开发服务器已在运行，尝试停止...${NC}"
        pkill -f "flutter run" || true
        sleep 2
    fi
    
    # 确保依赖已安装
    echo "  检查 Flutter 依赖..."
    flutter pub get > "$LOG_DIR/frontend-pubget.log" 2>&1
    
    # 启动前端（Chrome 设备）
    echo "  工作目录: $FRONTEND_DIR"
    echo "  日志文件: $LOG_DIR/frontend.log"
    
    # 使用 --web-port 5000 固定端口
    flutter run -d chrome --web-port 5000 > "$LOG_DIR/frontend.log" 2>&1 &
    local frontend_pid=$!
    echo $frontend_pid > "$FRONTEND_PID_FILE"
    
    # 等待前端启动
    echo "  等待前端启动..."
    local attempts=0
    local max_attempts=60
    while [ $attempts -lt $max_attempts ]; do
        # 检查进程是否还在运行
        if ! kill -0 $frontend_pid 2>/dev/null; then
            echo -e "${RED}✗ 前端进程异常退出${NC}"
            echo "  查看日志: $LOG_DIR/frontend.log"
            exit 1
        fi
        
        # 检查前端是否已启动（flutter run 会启动 web server）
        if curl -s http://localhost:5000 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 前端启动成功 (PID: $frontend_pid)${NC}"
            return 0
        fi
        
        attempts=$((attempts + 1))
        sleep 1
    done
    
    echo -e "${YELLOW}⚠ 前端启动等待超时，可能仍在启动中${NC}"
    echo "  查看日志: $LOG_DIR/frontend.log"
}

# 打印访问信息
print_access_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Sprint 1 开发环境启动成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}📡 后端 API:${NC}     http://localhost:8080"
    echo -e "${BLUE}📡 后端 Health:${NC}  http://localhost:8080/health"
    echo -e "${BLUE}🌐 前端应用:${NC}     http://localhost:5000"
    echo ""
    echo -e "${YELLOW}📋 日志文件:${NC}"
    echo "  后端: $LOG_DIR/backend.log"
    echo "  前端: $LOG_DIR/frontend.log"
    echo ""
    echo -e "${YELLOW}⌨️  操作:${NC}"
    echo "  • 按 Ctrl+C 优雅停止所有服务"
    echo "  • 或运行: ./scripts/stop-r2s1.sh"
    echo ""
}

# 优雅停止
cleanup() {
    echo ""
    echo -e "${YELLOW}▶ 收到停止信号，正在优雅关闭...${NC}"
    
    # 停止后端
    if [ -f "$BACKEND_PID_FILE" ]; then
        local backend_pid
        backend_pid=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$backend_pid" 2>/dev/null; then
            echo "  停止后端 (PID: $backend_pid)..."
            kill "$backend_pid" 2>/dev/null || true
            wait "$backend_pid" 2>/dev/null || true
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
    
    # 停止前端
    if [ -f "$FRONTEND_PID_FILE" ]; then
        local frontend_pid
        frontend_pid=$(cat "$FRONTEND_PID_FILE")
        if kill -0 "$frontend_pid" 2>/dev/null; then
            echo "  停止前端 (PID: $frontend_pid)..."
            kill "$frontend_pid" 2>/dev/null || true
            wait "$frontend_pid" 2>/dev/null || true
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi
    
    # 确保所有相关进程都被清理
    pkill -f "kayak-backend" 2>/dev/null || true
    pkill -f "flutter run" 2>/dev/null || true
    
    echo -e "${GREEN}✓ 所有服务已停止${NC}"
    exit 0
}

# 主流程
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Kayak Sprint 1 开发环境启动${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 注册信号处理
    trap cleanup SIGINT SIGTERM EXIT
    
    # 检查依赖
    check_rust
    check_flutter
    check_project
    
    echo ""
    
    # 启动服务
    start_backend
    start_frontend
    
    # 打印信息
    print_access_info
    
    # 保持脚本运行
    echo -e "${YELLOW}▶ 服务运行中...${NC}"
    while true; do
        # 检查后端是否还在运行
        if [ -f "$BACKEND_PID_FILE" ]; then
            local backend_pid
            backend_pid=$(cat "$BACKEND_PID_FILE")
            if ! kill -0 "$backend_pid" 2>/dev/null; then
                echo -e "${RED}✗ 后端进程已退出${NC}"
                cleanup
            fi
        fi
        
        # 检查前端是否还在运行
        if [ -f "$FRONTEND_PID_FILE" ]; then
            local frontend_pid
            frontend_pid=$(cat "$FRONTEND_PID_FILE")
            if ! kill -0 "$frontend_pid" 2>/dev/null; then
                echo -e "${RED}✗ 前端进程已退出${NC}"
                cleanup
            fi
        fi
        
        sleep 2
    done
}

main "$@"
