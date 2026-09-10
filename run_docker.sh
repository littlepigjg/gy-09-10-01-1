#!/bin/bash
set -e

# ========== 配置区 ==========
API_KEY="${API_KEY:-}"
IMAGE="adminfather/benzhi-claude-code:20260909-isolated-git"
# =============================

CONTAINER_NAME="claude-task"

# 1. 检查容器是否已存在
if docker ps -a --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
    if docker ps --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
        echo "⏳ 容器已在运行，直接进入对话..."
        docker exec -it "$CONTAINER_NAME" bash -lc "claude --resume || claude"
        exit 0
    else
        echo "⚠️  容器 $CONTAINER_NAME 已存在但未运行。"
        echo "   若需重建，请先执行: docker rm $CONTAINER_NAME"
        exit 1
    fi
fi

# 2. 获取 API Key
if [ -z "$API_KEY" ]; then
    read -rsp "请输入 API Key: " API_KEY
    echo
    if [ -z "$API_KEY" ]; then
        echo "❌ API Key 不能为空"
        exit 1
    fi
fi

# 3. 在当前目录下创建空 workspace 目录（不修改任何已有文件）
mkdir -p "$PWD/workspace"

# 4. 创建并启动容器
#    ./workspace → 容器 /workspace（空目录，满足容器入口检查）
#    Claude 在 /workspace/gy-09-10-01-1/ 下生成代码，双向同步到本机 ./workspace/gy-09-10-01-1/
echo "🚀 创建容器 $CONTAINER_NAME ..."
docker run -it --init \
    --restart=no \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --name "$CONTAINER_NAME" \
    --mount "type=bind,src=$PWD/workspace,dst=/workspace" \
    -e "apikey=$API_KEY" \
    "$IMAGE"
