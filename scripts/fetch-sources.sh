#!/bin/bash
#
# fetch-sources.sh - Clone official Apple Open Source Darwin/XNU components
#

set -e

# Parse command line arguments
FORCE_FETCH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -h, --help          Show this help message"
      echo "  -f, --force         Force re-fetch even if sources exist"
      echo ""
      echo "Fetches XNU and related sources from Apple repositories."
      exit 0
      ;;
    -f|--force)
      FORCE_FETCH=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information."
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCES_DIR="$PROJECT_ROOT/sources"
CONFIG_FILE="$PROJECT_ROOT/BUILD_CONFIG.env"

# Source configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: BUILD_CONFIG.env not found. Run ./scripts/detect-env.sh first"
    exit 1
fi
. "$CONFIG_FILE"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Darwin/XNU Source Preparation ===${NC}\n"

# Create sources directory
mkdir -p "$SOURCES_DIR"

# Define repositories - XNU is the primary source (contains libkern, libc, BSD, I/O Kit)
REPO_LIST="xnu"
REPO_URL_XNU="https://github.com/coccinella-labs/darwin-xnu.git"

# Alternative sources
ALT_REPO_LIST="dyld cctools"
ALT_REPO_URL_DYLD="https://github.com/apple/dyld.git"
ALT_REPO_URL_CCTOOLS="https://github.com/tpoechtrager/cctools-port.git"

echo -e "${BLUE}Cloning core components from Apple Open Source...${NC}\n"
echo -e "${YELLOW}Note:${NC} XNU includes libkern, libc, BSD, and I/O Kit within its source tree"
echo -e "${YELLOW}Note:${NC} Using fixed XNU fork (fix-clang17-errors branch) for Clang 17 compatibility\n"

# Function to get repo URL
get_repo_url() {
    case "$1" in
        xnu) echo "$REPO_URL_XNU" ;;
        dyld) echo "$ALT_REPO_URL_DYLD" ;;
        cctools) echo "$ALT_REPO_URL_CCTOOLS" ;;
    esac
}

# Clone core repositories
for repo_name in $REPO_LIST; do
    repo_url=$(get_repo_url "$repo_name")
    target_dir="$SOURCES_DIR/$repo_name"

    if [ -d "$target_dir" ] && [ "$FORCE_FETCH" != true ]; then
        echo -e "${YELLOW}⚠${NC}  $repo_name already exists, skipping..."
    else
        if [ -d "$target_dir" ] && [ "$FORCE_FETCH" == true ]; then
            echo -e "${YELLOW}⚠${NC}  $repo_name exists, force re-fetching..."
            rm -rf "$target_dir"
        fi
        echo -e "${BLUE}→${NC}  Cloning $repo_name..."
        echo "    URL: $repo_url"

        if [ "$repo_name" = "xnu" ]; then
            git clone --depth 1 --branch fix-clang17-errors "$repo_url" "$target_dir" 2>/dev/null
        else
            git clone --depth 1 "$repo_url" "$target_dir" 2>/dev/null
        fi
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC}  $repo_name cloned successfully"
        else
            echo -e "${RED}✗${NC}  FAILED to clone $repo_name"
            exit 1
        fi
    fi
done

# Clone alternative/optional repositories
echo -e "\n${BLUE}Cloning supplementary components...${NC}\n"

for repo_name in $ALT_REPO_LIST; do
    repo_url=$(get_repo_url "$repo_name")
    target_dir="$SOURCES_DIR/$repo_name"

    if [ -d "$target_dir" ] && [ "$FORCE_FETCH" != true ]; then
        echo -e "${YELLOW}⚠${NC}  $repo_name already exists, skipping..."
    else
        if [ -d "$target_dir" ] && [ "$FORCE_FETCH" == true ]; then
            echo -e "${YELLOW}⚠${NC}  $repo_name exists, force re-fetching..."
            rm -rf "$target_dir"
        fi
        echo -e "${BLUE}→${NC}  Attempting to clone $repo_name..."
        
        if git clone --depth 1 "$repo_url" "$target_dir" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}  $repo_name cloned successfully"
        else
            echo -e "${YELLOW}⚠${NC}  Could not clone $repo_name (optional, proceeding)"
        fi
    fi
done

# Verify critical components
echo -e "\n${BLUE}=== Verifying Source Components ===${NC}\n"

# XNU is the critical component (contains libkern, libc, iokit, bsd)
if [ -d "$SOURCES_DIR/xnu" ]; then
    xnu_count=$(find "$SOURCES_DIR/xnu" -type f | wc -l)
    echo -e "${GREEN}✓${NC}  xnu: $xnu_count files"
    
    # Check for embedded components
    if [ -d "$SOURCES_DIR/xnu/libkern" ]; then
        echo -e "  ${GREEN}✓${NC}  libkern (embedded in xnu)"
    fi
    if [ -d "$SOURCES_DIR/xnu/bsd" ]; then
        echo -e "  ${GREEN}✓${NC}  BSD subsystem (embedded in xnu)"
    fi
    if [ -d "$SOURCES_DIR/xnu/iokit" ]; then
        echo -e "  ${GREEN}✓${NC}  I/O Kit (embedded in xnu)"
    fi
else
    echo -e "${RED}✗${NC}  xnu: MISSING - Critical component not found"
    exit 1
fi

# List all cloned sources
echo -e "\n${BLUE}=== Available Source Components ===${NC}\n"

for dir in "$SOURCES_DIR"/*; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")
        if [ -d "$dir/.git" ]; then
            commit=$(cd "$dir" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            echo "  $name (commit: $commit)"
        else
            echo "  $name"
        fi
    fi
done

echo -e "\n${GREEN}✓ Sources prepared successfully${NC}"
echo "Sources location: $SOURCES_DIR"

exit 0
