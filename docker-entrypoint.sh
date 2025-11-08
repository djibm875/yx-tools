#!/bin/bash
set -e

# 如果提供了命令参数，直接执行
if [ $# -gt 0 ]; then
    exec "$@"
fi

# 如果设置了环境变量 CRON_SCHEDULE 和 CRON_COMMAND，启动cron服务并设置定时任务
if [ -n "$CRON_SCHEDULE" ] && [ -n "$CRON_COMMAND" ]; then
    echo "检测到环境变量，启动cron服务并设置定时任务..."
    
    # 启动cron服务
    service cron start
    
    # 设置定时任务
    (crontab -l 2>/dev/null || true; echo "$CRON_SCHEDULE $CRON_COMMAND") | crontab -
    echo "定时任务已设置: $CRON_SCHEDULE $CRON_COMMAND"
    
    # 显示当前cron任务
    echo "当前定时任务："
    crontab -l 2>/dev/null || echo "  无"
    echo ""
    
    # 保持容器运行
    tail -f /dev/null
else
    # 没有设置环境变量，运行交互模式
    # 运行Python脚本（交互模式）
    python3 /app/cloudflare_speedtest.py
    
    # 脚本运行完成后，检查是否设置了定时任务
    CRON_JOBS=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' || true)
    
    if [ -n "$CRON_JOBS" ]; then
        echo ""
        echo "检测到已设置定时任务，启动cron服务并保持容器运行..."
        
        # 启动cron服务
        service cron start
        
        # 显示当前cron任务
        echo "当前定时任务："
        crontab -l 2>/dev/null || echo "  无"
        echo ""
        echo "容器将保持运行，定时任务将按计划执行"
        echo "使用 'docker exec -it <container_name> crontab -l' 查看定时任务"
        echo "使用 'docker exec -it <container_name> crontab -e' 编辑定时任务"
        echo ""
        
        # 保持容器运行
        tail -f /dev/null
    else
        # 没有设置定时任务，直接退出
        echo "未设置定时任务，容器将退出"
        exit 0
    fi
fi

