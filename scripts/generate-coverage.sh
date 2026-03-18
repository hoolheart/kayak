#!/bin/bash
# =============================================================================
# 覆盖率报告生成脚本
# 为前后端生成覆盖率报告
# =============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/kayak-backend"
FRONTEND_DIR="$PROJECT_DIR/kayak-frontend"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MODE="${1:-all}"  # all, backend, frontend

echo "=========================================="
echo "覆盖率报告生成"
echo "模式: $MODE"
echo "=========================================="
echo ""

# ============================================
# 后端覆盖率
# ============================================
generate_backend_coverage() {
    echo "生成后端覆盖率报告..."
    
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${YELLOW}⚠ 后端目录不存在${NC}"
        return 1
    fi
    
    if ! command -v cargo >/dev/null 2>&1; then
        echo -e "${RED}✗ Cargo 未安装${NC}"
        return 1
    fi
    
    # 安装 tarpaulin（如果需要）
    if ! command -v cargo-tarpaulin >/dev/null 2>&1; then
        echo "安装 cargo-tarpaulin..."
        cargo install cargo-tarpaulin --locked
    fi
    
    cd "$BACKEND_DIR"
    
    # 生成覆盖率报告
    cargo tarpaulin \
        --all-features \
        --workspace \
        --timeout 120 \
        --out Xml \
        --out Html \
        --output-dir ./coverage
    
    echo -e "${GREEN}✓ 后端覆盖率报告已生成: $BACKEND_DIR/coverage/${NC}"
    
    # 显示摘要
    if [ -f "coverage/cobertura.xml" ]; then
        echo ""
        echo "覆盖率摘要:"
        grep -o 'line-rate="[0-9.]*"' coverage/cobertura.xml | head -1 | sed 's/line-rate="\([0-9.]*\)"/\1/' | awk '{print "行覆盖率: " $1 * 100 "%"}'
    fi
}

# ============================================
# 前端覆盖率
# ============================================
generate_frontend_coverage() {
    echo "生成前端覆盖率报告..."
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo -e "${YELLOW}⚠ 前端目录不存在${NC}"
        return 1
    fi
    
    if ! command -v flutter >/dev/null 2>&1; then
        echo -e "${RED}✗ Flutter 未安装${NC}"
        return 1
    fi
    
    # 安装 lcov（如果需要）
    if ! command -v genhtml >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ lcov 未安装，尝试安装...${NC}"
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y lcov
        elif command -v brew >/dev/null 2>&1; then
            brew install lcov
        else
            echo -e "${RED}✗ 无法自动安装 lcov${NC}"
            return 1
        fi
    fi
    
    cd "$FRONTEND_DIR"
    
    # 获取依赖
    flutter pub get
    
    # 运行测试并生成覆盖率
    flutter test --coverage
    
    # 生成 HTML 报告
    if [ -f "coverage/lcov.info" ]; then
        genhtml coverage/lcov.info --output-directory coverage/html --title "Kayak Frontend Coverage"
        
        # 显示摘要
        echo ""
        echo "覆盖率摘要:"
        lcov --summary coverage/lcov.info 2>&1 | grep -E "(lines|functions).*%;" || true
    fi
    
    echo -e "${GREEN}✓ 前端覆盖率报告已生成: $FRONTEND_DIR/coverage/html/${NC}"
}

# ============================================
# 主逻辑
# ============================================
case "$MODE" in
    backend)
        generate_backend_coverage
        ;;
    frontend)
        generate_frontend_coverage
        ;;
    all)
        generate_backend_coverage
        echo ""
        generate_frontend_coverage
        ;;
    *)
        echo "用法: $0 [backend|frontend|all]"
        echo "  backend  - 仅生成后端覆盖率报告"
        echo "  frontend - 仅生成前端覆盖率报告"
        echo "  all      - 生成前后端覆盖率报告（默认）"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo -e "${GREEN}✓ 覆盖率报告生成完成${NC}"
echo "=========================================="
