#!/bin/bash
# S1-002 Flutter前端工程初始化 - 自动化测试执行脚本
# 使用方法: ./run_tests.sh [windows|macos|linux|all]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================"
echo "Flutter Frontend Initialization Tests"
echo "S1-002 Test Execution Script"
echo "========================================"
echo ""

# 检查Flutter环境
check_flutter() {
    echo -e "${YELLOW}Checking Flutter environment...${NC}"
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}ERROR: Flutter not found in PATH${NC}"
        exit 1
    fi
    
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓ Flutter found: $FLUTTER_VERSION${NC}"
    echo ""
}

# 获取依赖
get_dependencies() {
    echo -e "${YELLOW}Getting dependencies...${NC}"
    flutter pub get
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Dependencies fetched successfully${NC}"
    else
        echo -e "${RED}✗ Failed to fetch dependencies${NC}"
        exit 1
    fi
    echo ""
}

# 运行Widget测试
run_widget_tests() {
    echo -e "${YELLOW}Running Widget Tests...${NC}"
    flutter test --coverage
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ All Widget tests passed${NC}"
    else
        echo -e "${RED}✗ Some Widget tests failed${NC}"
        return 1
    fi
    echo ""
}

# 构建测试
build_test() {
    local platform=$1
    echo -e "${YELLOW}Building for $platform...${NC}"
    
    case $platform in
        windows)
            flutter build windows
            ;;
        macos)
            flutter build macos
            ;;
        linux)
            flutter build linux
            ;;
        *)
            echo -e "${RED}Unknown platform: $platform${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $platform build successful${NC}"
    else
        echo -e "${RED}✗ $platform build failed${NC}"
        return 1
    fi
    echo ""
}

# 分析代码
analyze_code() {
    echo -e "${YELLOW}Analyzing code...${NC}"
    flutter analyze
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Code analysis passed${NC}"
    else
        echo -e "${RED}✗ Code analysis found issues${NC}"
        return 1
    fi
    echo ""
}

# 格式化检查
format_check() {
    echo -e "${YELLOW}Checking code formatting...${NC}"
    flutter format --set-exit-if-changed lib test
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Code formatting OK${NC}"
    else
        echo -e "${RED}✗ Code formatting issues found. Run: flutter format lib test${NC}"
        return 1
    fi
    echo ""
}

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# 主函数
main() {
    check_flutter
    
    local platform=${1:-"current"}
    local current_os=$(detect_os)
    
    # 获取依赖
    get_dependencies
    
    # 分析代码
    analyze_code
    
    # 格式化检查
    format_check
    
    # 运行Widget测试
    run_widget_tests
    
    # 构建测试
    echo "========================================"
    echo "Build Tests"
    echo "========================================"
    
    case $platform in
        windows|macos|linux)
            build_test $platform
            ;;
        all)
            echo -e "${YELLOW}Building for all platforms...${NC}"
            build_test "windows"
            build_test "macos"
            build_test "linux"
            ;;
        current)
            echo -e "${YELLOW}Building for current platform ($current_os)...${NC}"
            if [ "$current_os" != "unknown" ]; then
                build_test "$current_os"
            else
                echo -e "${YELLOW}Skipping build test - Unknown OS${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Unknown platform: $platform${NC}"
            echo "Usage: $0 [windows|macos|linux|all|current]"
            exit 1
            ;;
    esac
    
    echo "========================================"
    echo -e "${GREEN}All tests completed successfully!${NC}"
    echo "========================================"
}

# 运行主函数
main "$@"
