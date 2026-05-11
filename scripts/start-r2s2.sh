#!/bin/bash
# =============================================================================
# Sprint 2 开发环境一键启动脚本
# R2-S2-004-A: 启动后端 + 前端开发服务器 + Python SDK 环境检查
# =============================================================================

set -euo pipefail

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/kayak-backend"
FRONTEND_DIR="$PROJECT_ROOT/kayak-frontend"
PYTHON_SDK_DIR="$PROJECT_ROOT/kayak-python-client"
DATA_DIR="$PROJECT_ROOT/data"
LOG_DIR="$PROJECT_ROOT/logs"

# PID 文件（Sprint 2 统一使用 /tmp）
PID_FILE="/tmp/kayak-r2s2.pids"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 状态跟踪
CHECK_ONLY=0
ALL_CHECKS_PASSED=1

# 创建必要目录
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# =============================================================================
# 依赖检查函数
# =============================================================================

check_rust() {
    echo -e "${YELLOW}▶ 检查 Rust toolchain...${NC}"
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}  ✗ 错误: Rust/Cargo 未安装${NC}"
        echo "    请访问 https://rustup.rs/ 安装 Rust"
        ALL_CHECKS_PASSED=0
        return 1
    fi

    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}  ✗ 错误: rustc 未找到${NC}"
        ALL_CHECKS_PASSED=0
        return 1
    fi

    local rust_version
    rust_version=$(rustc --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}  ✓ Rust 已安装: $rust_version${NC}"
    return 0
}

check_flutter() {
    echo -e "${YELLOW}▶ 检查 Flutter...${NC}"
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}  ✗ 错误: Flutter 未安装${NC}"
        echo "    请访问 https://docs.flutter.dev/get-started/install 安装 Flutter"
        ALL_CHECKS_PASSED=0
        return 1
    fi

    local flutter_version
    flutter_version=$(flutter --version 2>/dev/null | head -n 1 || echo "unknown")
    echo -e "${GREEN}  ✓ Flutter 已安装: $flutter_version${NC}"
    return 0
}

check_hdf5() {
    echo -e "${YELLOW}▶ 检查 HDF5 库...${NC}"

    # 尝试多种方式检查 HDF5
    local hdf5_found=0

    # 方式1: pkg-config
    if command -v pkg-config &> /dev/null && pkg-config --exists hdf5 2>/dev/null; then
        local hdf5_version
        hdf5_version=$(pkg-config --modversion hdf5 2>/dev/null || echo "unknown")
        echo -e "${GREEN}  ✓ HDF5 库已安装 (pkg-config): $hdf5_version${NC}"
        hdf5_found=1
    fi

    # 方式2: 检查系统头文件
    if [ $hdf5_found -eq 0 ] && [ -f /usr/include/hdf5.h ]; then
        echo -e "${GREEN}  ✓ HDF5 头文件已找到 (/usr/include/hdf5.h)${NC}"
        hdf5_found=1
    fi

    # 方式3: 检查 Debian/Ubuntu 包
    if [ $hdf5_found -eq 0 ] && command -v dpkg &> /dev/null; then
        if dpkg -l | grep -q "libhdf5-dev" 2>/dev/null; then
            echo -e "${GREEN}  ✓ libhdf5-dev 包已安装${NC}"
            hdf5_found=1
        fi
    fi

    # 方式4: 检查 RPM 包
    if [ $hdf5_found -eq 0 ] && command -v rpm &> /dev/null; then
        if rpm -q hdf5-devel &> /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ hdf5-devel 包已安装${NC}"
            hdf5_found=1
        fi
    fi

    if [ $hdf5_found -eq 0 ]; then
        echo -e "${YELLOW}  ⚠ 警告: 未检测到 HDF5 开发库${NC}"
        echo "    后端编译可能需要 HDF5。如遇到编译错误，请安装:"
        echo "      Ubuntu/Debian: sudo apt-get install libhdf5-dev"
        echo "      Fedora/RHEL:   sudo dnf install hdf5-devel"
        echo "      macOS:         brew install hdf5"
        # HDF5 警告不阻止启动，因为可能是运行时链接
    fi

    return 0
}

check_python() {
    echo -e "${YELLOW}▶ 检查 Python 3.9+...${NC}"

    local python_cmd=""
    local python_version=""

    # 查找可用的 Python 命令
    if command -v python3 &> /dev/null; then
        python_cmd="python3"
    elif command -v python &> /dev/null; then
        python_cmd="python"
    else
        echo -e "${RED}  ✗ 错误: 未找到 Python 解释器${NC}"
        echo "    请安装 Python 3.9 或更高版本: https://www.python.org/downloads/"
        ALL_CHECKS_PASSED=0
        return 1
    fi

    # 获取并解析版本
    python_version=$($python_cmd --version 2>&1 | awk '{print $2}')
    local major minor
    major=$(echo "$python_version" | cut -d. -f1)
    minor=$(echo "$python_version" | cut -d. -f2)

    if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 9 ]; }; then
        echo -e "${RED}  ✗ 错误: Python 版本过低 ($python_version)，需要 3.9+${NC}"
        ALL_CHECKS_PASSED=0
        return 1
    fi

    echo -e "${GREEN}  ✓ Python 已安装: $python_version (命令: $python_cmd)${NC}"
    return 0
}

check_poetry() {
    echo -e "${YELLOW}▶ 检查 Poetry (Python SDK 依赖管理)...${NC}"
    if ! command -v poetry &> /dev/null; then
        echo -e "${YELLOW}  ⚠ 警告: Poetry 未安装${NC}"
        echo "    Python SDK 开发需要 Poetry。安装方式:"
        echo "      curl -sSL https://install.python-poetry.org | python3 -"
        echo "    或: pip install poetry"
        # Poetry 警告不阻止启动（只是 SDK 开发需要）
        return 0
    fi

    local poetry_version
    poetry_version=$(poetry --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}  ✓ Poetry 已安装: $poetry_version${NC}"

    # 检查 Python SDK 目录是否存在且配置正确
    if [ -d "$PYTHON_SDK_DIR" ] && [ -f "$PYTHON_SDK_DIR/pyproject.toml" ]; then
        echo -e "${GREEN}  ✓ Python SDK 项目已找到: $PYTHON_SDK_DIR${NC}"
    elif [ -d "$PYTHON_SDK_DIR" ]; then
        echo -e "${YELLOW}  ⚠ Python SDK 目录存在但缺少 pyproject.toml${NC}"
    else
        echo -e "${YELLOW}  ⚠ Python SDK 目录不存在: $PYTHON_SDK_DIR${NC}"
    fi

    return 0
}

check_project_structure() {
    echo -e "${YELLOW}▶ 检查项目结构...${NC}"
    local missing=0

    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${RED}  ✗ 错误: 后端目录不存在: $BACKEND_DIR${NC}"
        missing=1
    else
        echo -e "${GREEN}  ✓ 后端目录: $BACKEND_DIR${NC}"
    fi

    if [ ! -d "$FRONTEND_DIR" ]; then
        echo -e "${RED}  ✗ 错误: 前端目录不存在: $FRONTEND_DIR${NC}"
        missing=1
    else
        echo -e "${GREEN}  ✓ 前端目录: $FRONTEND_DIR${NC}"
    fi

    if [ $missing -eq 1 ]; then
        ALL_CHECKS_PASSED=0
        return 1
    fi

    return 0
}

# =============================================================================
# 服务启动函数
# =============================================================================

write_pid_file() {
    local backend_pid="${1:-}"
    local frontend_pid="${2:-}"

    {
        echo "# Kayak Sprint 2 PID file"
        echo "# Generated: $(date -Iseconds)"
        echo "backend=$backend_pid"
        echo "frontend=$frontend_pid"
    } > "$PID_FILE"
}

read_pid_file() {
    local var_name="$1"
    local key="$2"

    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(grep "^${key}=" "$PID_FILE" 2>/dev/null | cut -d= -f2 || true)
        eval "$var_name='$pid'"
    else
        eval "$var_name=''"
    fi
}

start_backend() {
    echo -e "${YELLOW}▶ 启动后端开发服务器...${NC}"
    cd "$BACKEND_DIR"

    # 检查是否已有后端在运行
    if pgrep -f "kayak-backend" > /dev/null 2>&1; then
        echo -e "${YELLOW}  ⚠ 后端服务已在运行，尝试停止...${NC}"
        pkill -f "kayak-backend" || true
        sleep 2
    fi

    # 设置环境变量
    export KAYAK_DATA_DIR="$DATA_DIR"
    export DATABASE_URL="sqlite://$(realpath "$DATA_DIR")/kayak.db"
    export KAYAK_LOG_LEVEL="debug"
    export RUST_BACKTRACE=1

    echo "    工作目录: $BACKEND_DIR"
    echo "    数据目录: $DATA_DIR"
    echo "    日志文件: $LOG_DIR/backend-r2s2.log"

    # 使用 nohup 后台运行
    nohup cargo run > "$LOG_DIR/backend-r2s2.log" 2>&1 &
    local backend_pid=$!

    # 等待后端启动
    echo "    等待后端启动..."
    local attempts=0
    local max_attempts=60
    while [ $attempts -lt $max_attempts ]; do
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ 后端启动成功 (PID: $backend_pid)${NC}"
            return 0
        fi

        # 检查进程是否还在运行
        if ! kill -0 $backend_pid 2>/dev/null; then
            echo -e "${RED}  ✗ 后端进程异常退出${NC}"
            echo "    查看日志: $LOG_DIR/backend-r2s2.log"
            exit 1
        fi

        attempts=$((attempts + 1))
        sleep 1
    done

    echo -e "${RED}  ✗ 后端启动超时${NC}"
    echo "    查看日志: $LOG_DIR/backend-r2s2.log"
    exit 1
}

start_frontend() {
    echo -e "${YELLOW}▶ 启动前端开发服务器...${NC}"
    cd "$FRONTEND_DIR"

    # 检查是否已有 flutter run 在运行
    if pgrep -f "flutter run" > /dev/null 2>&1; then
        echo -e "${YELLOW}  ⚠ Flutter 开发服务器已在运行，尝试停止...${NC}"
        pkill -f "flutter run" || true
        sleep 2
    fi

    # 确保依赖已安装
    echo "    检查 Flutter 依赖..."
    flutter pub get > "$LOG_DIR/frontend-pubget-r2s2.log" 2>&1

    echo "    工作目录: $FRONTEND_DIR"
    echo "    日志文件: $LOG_DIR/frontend-r2s2.log"

    # 使用 web-server 设备 + 固定端口 5000（适合后台运行）
    nohup flutter run -d web-server --web-port 5000 > "$LOG_DIR/frontend-r2s2.log" 2>&1 &
    local frontend_pid=$!

    # 等待前端启动
    echo "    等待前端启动..."
    local attempts=0
    local max_attempts=60
    while [ $attempts -lt $max_attempts ]; do
        # 检查进程是否还在运行
        if ! kill -0 $frontend_pid 2>/dev/null; then
            echo -e "${RED}  ✗ 前端进程异常退出${NC}"
            echo "    查看日志: $LOG_DIR/frontend-r2s2.log"
            exit 1
        fi

        # 检查前端是否已启动（flutter web-server 会启动 HTTP 服务）
        if curl -s http://localhost:5000 > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ 前端启动成功 (PID: $frontend_pid)${NC}"
            return 0
        fi

        attempts=$((attempts + 1))
        sleep 1
    done

    echo -e "${YELLOW}  ⚠ 前端启动等待超时，可能仍在启动中${NC}"
    echo "    查看日志: $LOG_DIR/frontend-r2s2.log"
}

# =============================================================================
# 输出信息
# =============================================================================

print_access_info() {
    local backend_pid="$1"
    local frontend_pid="$2"

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Sprint 2 开发环境启动成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${CYAN}📡 后端 API:${NC}      http://localhost:8080/api/v1"
    echo -e "${CYAN}📡 后端 Health:${NC}   http://localhost:8080/health"
    echo -e "${CYAN}🌐 前端 (后端服务):${NC} http://localhost:8080"
    echo -e "${CYAN}🔧 Flutter Dev:${NC}   http://localhost:5000"
    echo ""
    echo -e "${YELLOW}📋 进程信息:${NC}"
    echo "    后端 PID: $backend_pid"
    echo "    前端 PID: $frontend_pid"
    echo "    PID 文件: $PID_FILE"
    echo ""
    echo -e "${YELLOW}📋 日志文件:${NC}"
    echo "    后端: $LOG_DIR/backend-r2s2.log"
    echo "    前端: $LOG_DIR/frontend-r2s2.log"
    echo "    依赖: $LOG_DIR/frontend-pubget-r2s2.log"
    echo ""
    echo -e "${YELLOW}⌨️  操作:${NC}"
    echo "    • 按 Ctrl+C 优雅停止所有服务"
    echo "    • 或运行: ./scripts/stop-r2s2.sh"
    echo ""
}

print_check_only_results() {
    echo ""
    if [ $ALL_CHECKS_PASSED -eq 1 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  ✓ 所有依赖检查通过${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "可以正常运行: ./scripts/start-r2s2.sh"
        exit 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  ✗ 部分依赖检查失败${NC}"
        echo -e "${RED}========================================${NC}"
        echo ""
        echo "请修复上述错误后重试。"
        exit 1
    fi
}

# =============================================================================
# 优雅停止
# =============================================================================

cleanup() {
    echo ""
    echo -e "${YELLOW}▶ 收到停止信号，正在优雅关闭...${NC}"

    local backend_pid=""
    local frontend_pid=""

    # 从 PID 文件读取
    if [ -f "$PID_FILE" ]; then
        backend_pid=$(grep "^backend=" "$PID_FILE" 2>/dev/null | cut -d= -f2 || true)
        frontend_pid=$(grep "^frontend=" "$PID_FILE" 2>/dev/null | cut -d= -f2 || true)
    fi

    # 停止后端
    if [ -n "$backend_pid" ] && kill -0 "$backend_pid" 2>/dev/null; then
        echo "    停止后端 (PID: $backend_pid)..."
        kill "$backend_pid" 2>/dev/null || true
        local attempts=0
        while kill -0 "$backend_pid" 2>/dev/null && [ $attempts -lt 10 ]; do
            sleep 1
            attempts=$((attempts + 1))
        done
        if kill -0 "$backend_pid" 2>/dev/null; then
            echo "    强制终止后端进程..."
            kill -9 "$backend_pid" 2>/dev/null || true
        fi
    fi

    # 停止前端
    if [ -n "$frontend_pid" ] && kill -0 "$frontend_pid" 2>/dev/null; then
        echo "    停止前端 (PID: $frontend_pid)..."
        kill "$frontend_pid" 2>/dev/null || true
        local attempts=0
        while kill -0 "$frontend_pid" 2>/dev/null && [ $attempts -lt 10 ]; do
            sleep 1
            attempts=$((attempts + 1))
        done
        if kill -0 "$frontend_pid" 2>/dev/null; then
            echo "    强制终止前端进程..."
            kill -9 "$frontend_pid" 2>/dev/null || true
        fi
    fi

    # 兜底清理
    pkill -f "kayak-backend" 2>/dev/null || true
    pkill -f "flutter run" 2>/dev/null || true

    # 清理 PID 文件
    rm -f "$PID_FILE"

    echo -e "${GREEN}✓ 所有服务已停止${NC}"
    exit 0
}

# =============================================================================
# 主流程
# =============================================================================

show_help() {
    cat << EOF
Kayak Sprint 2 开发环境启动脚本

用法: $0 [选项]

选项:
    --check-only    仅检查依赖，不启动服务
    --help, -h      显示此帮助信息

示例:
    $0              # 检查依赖并启动所有服务
    $0 --check-only # 仅检查环境依赖

访问地址:
    后端 API:     http://localhost:8080/api/v1
    前端(生产):   http://localhost:8080
    Flutter Dev:  http://localhost:5000
EOF
}

main() {
    # 解析参数
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --check-only)
            CHECK_ONLY=1
            ;;
        "")
            CHECK_ONLY=0
            ;;
        *)
            echo -e "${RED}错误: 未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Kayak Sprint 2 开发环境启动${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # 依赖检查
    check_rust
    check_flutter
    check_hdf5
    check_python
    check_poetry
    check_project_structure

    echo ""

    # 如果是仅检查模式，输出结果并退出
    if [ $CHECK_ONLY -eq 1 ]; then
        print_check_only_results
    fi

    # 如果有检查失败，询问是否继续
    if [ $ALL_CHECKS_PASSED -eq 0 ]; then
        echo -e "${YELLOW}⚠ 部分依赖检查未通过，是否继续启动? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "已取消启动。"
            exit 1
        fi
        echo ""
    fi

    # 注册信号处理
    trap cleanup SIGINT SIGTERM EXIT

    # 启动服务
    start_backend
    local backend_pid=$!

    start_frontend
    local frontend_pid=$!

    # 写入 PID 文件
    write_pid_file "$backend_pid" "$frontend_pid"

    # 打印访问信息
    print_access_info "$backend_pid" "$frontend_pid"

    # 保持脚本运行并监控进程
    echo -e "${YELLOW}▶ 服务运行中，按 Ctrl+C 停止...${NC}"
    while true; do
        local backend_alive=0
        local frontend_alive=0

        if [ -n "$backend_pid" ] && kill -0 "$backend_pid" 2>/dev/null; then
            backend_alive=1
        fi

        if [ -n "$frontend_pid" ] && kill -0 "$frontend_pid" 2>/dev/null; then
            frontend_alive=1
        fi

        if [ $backend_alive -eq 0 ]; then
            echo -e "${RED}✗ 后端进程已退出${NC}"
            cleanup
        fi

        if [ $frontend_alive -eq 0 ]; then
            echo -e "${RED}✗ 前端进程已退出${NC}"
            cleanup
        fi

        sleep 2
    done
}

main "$@"
