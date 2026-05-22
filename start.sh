#!/bin/bash

# 1. 动态替换 UUID
if [ -n "$UUID" ]; then
    echo "正在注入专属 UUID..."
    sed -i "s/your-uuid-here/${UUID}/g" /app/config.json
fi

# 2. 启动 sing-box 核心服务 (拉起本地 WS 与 gRPC 双节点)
echo "启动 sing-box 核心服务..."
sing-box run -c /app/config.json &

# 3. 检查并直出混合双打节点链接
if [ -n "$ARGO_DOMAIN" ] && [ -n "$UUID" ]; then
    echo "=================================================================="
    echo "🎉 容器部署成功！YouTube 科技共享 恭喜您 专属备双节点已生成："
    echo "=================================================================="
    echo "【1. CF 隧道提速 - WS 节点】 (无公网端口，极高隐蔽性):"
    echo "vless://${UUID}@${ARGO_DOMAIN}:443?encryption=none&security=tls&type=ws&path=%2Fvless-ws#NF-Argo-WS"
    echo "------------------------------------------------------------------"
    
    # 判断是否填写了 Northflank 直连域名
    if [ -n "$NF_DOMAIN_GRPC" ]; then
        echo "【2. 官方直连性能 - gRPC 节点】 (原生 HTTP/2，极低延迟):"
        echo "vless://${UUID}@${NF_DOMAIN_GRPC}:443?encryption=none&security=tls&type=grpc&serviceName=vless-grpc#NF-Direct-gRPC"
    else
        echo "【2. 官方直连性能 - gRPC 节点】 (等待配置):"
        echo "💡 提示：请在 Northflank 面板公开 8081 端口，并将分配的直连域名填入环境变量 [NF_DOMAIN_GRPC] 即可在此处生成链接。"
    fi
    echo "=================================================================="
fi

# 4. 拉起 Cloudflare Argo 隧道守护进程 (仅代理内部 8080 端口)
if [ -z "$ARGO_TOKEN" ]; then
    echo "警告: 未检测到 ARGO_TOKEN。WS 节点无隧道支持。"
    wait -n
else
    echo "正在启动 Cloudflare Argo 隧道守护进程..."
    cloudflared tunnel --no-autoupdate run --token ${ARGO_TOKEN}
fi
