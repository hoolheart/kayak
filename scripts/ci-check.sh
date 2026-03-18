#!/bin/bash
# =============================================================================
# CI 本地验证脚本
# 在提交前本地运行此脚本验证CI检查
# =============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/kayak-backend"
FRONTEND_DIR="$PROJECT_DIR/kayak-frontend"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "CI 本地验证脚本"
echo "=========================================="
echo ""

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 运行步骤
run_step() {
    local name="$1"
    local cmd="$2"
    local dir="${3:-$PROJECT_DIR}"
    
    echo -e "${YELLOW}▶ $name${NC}"
    if (cd "$dir" && eval "$cmd"); then
        echo -e "${GREEN}✓ $name 通过${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ $name 失败${NC}"
        echo ""
        return 1
    fi
}

FAILED=0

# ============================================
# 后端检查
# ============================================
echo "=========================================="
echo "后端检查 (Rust)"
echo "=========================================="

if [ -d "$BACKEND_DIR" ]; then
    if command_exists cargo; then
        # Format check
        run_step "Rust 格式化检查" "cargo fmt -- --check" "$BACKEND_DIR" || FAILED=1
        
        # Clippy check
        run_step "Rust Clippy 检查" "cargo clippy --all-targets --all-features -- -D warnings" "$BACKEND_DIR" || FAILED=1
        
        # Test
        run_step "Rust 单元测试" "cargo test --all-features" "$BACKEND_DIR" || FAILED=1
        
        # Build
        run_step "Rust 构建" "cargo build --release" "$BACKEND_DIR" || FAILED=1
    else
        echo -e "${YELLOW}⚠ Cargo 未安装，跳过后端检查${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ 后端目录不存在，跳过${NC}"
    echo ""
fi

# ============================================
# 前端检查
# ============================================
echo "=========================================="
echo "前端检查 (Flutter)"
echo "=========================================="

if [ -d "$FRONTEND_DIR" ]; then
    if command_exists flutter; then
        # Format check
        run_step "Dart 格式化检查" "dart format --output=none --set-exit-if-changed ." "$FRONTEND_DIR" || FAILED=1
        
        # Analyze
        run_step "Dart 代码分析" "flutter analyze --fatal-infos" "$FRONTEND_DIR" || FAILED=1
        
        # Test
        run_step "Flutter 单元测试" "flutter test" "$FRONTEND_DIR" || FAILED=1
        
        # Build Web
        run_step "Flutter Web 构建" "flutter build web --release" "$FRONTEND_DIR" || FAILED=1
    else
        echo -e "${YELLOW}⚠ Flutter 未安装，跳过前端检查${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ 前端目录不存在，跳过${NC}"
    echo ""
fi

# ============================================
# 总结
# ============================================
echo "=========================================="
echo "验证总结"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！可以安全提交。${NC}"
    exit 0
else
    echo -e "${RED}✗ 部分检查失败，请修复后重试。${NC}"
    exit 1
fi
