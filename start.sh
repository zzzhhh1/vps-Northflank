#!/bin/bash

# 1. 动态替换 UUID
if [ -n "$UUID" ]; then
    echo "正在注入专属 UUID..."
    sed -i "s/your-uuid-here/${UUID}/g" /app/config.json
fi

# 2. 启动 sing-box 核心服务 (同时拉起本地 WS 与 gRPC 双节点)
echo "启动 sing-box 核心服务..."
sing-box run -c /app/config.json &

# 3. 检查并拉起 Cloudflare Argo 隧道
if [ -z "$ARGO_TOKEN" ]; then
    echo "警告: 未检测到 ARGO_TOKEN。节点仅在本地多端口状态下运行。"
    # 阻塞主进程，保持容器常驻不退出
    wait -n
else
    # 4. 在日志中直出经过隧道加速的 WS 节点链接
    if [ -n "$ARGO_DOMAIN" ] && [ -n "$UUID" ]; then
        echo "=================================================================="
        echo "🎉 容器部署成功！已成功将隧道提速聚焦于 WS 协议节点："
        echo "=================================================================="
        echo "【CF 隧道加速 - WS 节点链接】 (请直接复制下方链接):"
        echo "vless://${UUID}@${ARGO_DOMAIN}:443?encryption=none&security=tls&type=ws&path=%2Fvless-ws#NF-Argo-WS"
        echo "=================================================================="
        echo "💡 提示：gRPC 节点目前隔离在内部 8081 端口运行，未分配加速域名。"
        echo "=================================================================="
    fi

    echo "正在启动 Cloudflare Argo 隧道守护进程..."
    cloudflared tunnel --no-autoupdate run --token ${ARGO_TOKEN}
fi
