#!/bin/bash
# 不使用 set -e，确保容器始终运行，不会因为命令失败而退出

# Crontab持久化文件路径
CRONTAB_FILE="/app/config/crontab"

# 恢复crontab（如果存在）
if [ -f "$CRONTAB_FILE" ]; then
    echo "检测到已保存的定时任务，正在恢复..."
    crontab "$CRONTAB_FILE"
    echo "定时任务已恢复"
fi

# 保存crontab的函数
save_crontab() {
    if [ -d "/app/config" ]; then
        crontab -l > "$CRONTAB_FILE" 2>/dev/null || true
    fi
}

# 保存crontab并显示消息的函数
save_crontab_with_msg() {
    if [ -d "/app/config" ]; then
        crontab -l > "$CRONTAB_FILE" 2>/dev/null || true
        echo "定时任务已保存到 $CRONTAB_FILE"
    fi
}

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
    
    # 保存crontab
    save_crontab_with_msg
    
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
    
    # 保存crontab（如果有）
    save_crontab_with_msg
    
    # 显示当前cron任务
    echo ""
    echo "当前定时任务："
    crontab -l 2>/dev/null || echo "  无"
    echo ""
    
    if [ -n "$CRON_JOBS" ]; then
        echo "检测到已设置定时任务，启动cron服务并保持容器运行..."
        
        # 启动cron服务
        service cron start
        
        echo "容器将保持运行，定时任务将按计划执行"
    else
        echo "未设置定时任务，容器将保持运行"
        echo "您可以随时进入容器设置定时任务或运行脚本"
    fi
    
    echo ""
    echo "容器将保持运行"
    echo "定时任务已保存到 $CRONTAB_FILE，容器重启后会自动恢复"
    echo ""
    echo "使用以下命令管理容器："
    echo "  进入容器: docker exec -it <container_name> bash"
    echo "  运行脚本: docker exec -it <container_name> python3 /app/cloudflare_speedtest.py"
    echo "  查看定时任务: docker exec -it <container_name> crontab -l"
    echo "  编辑定时任务: docker exec -it <container_name> crontab -e"
    echo "  查看容器日志: docker logs <container_name>"
    echo ""
    
    # 设置定期保存crontab（每5分钟保存一次）
    while true; do
        sleep 300
        save_crontab
    done &
    
    # 保持容器运行
    tail -f /dev/null
fi

        # 保存crontab
        save_crontab
        
        # 显示当前cron任务
        echo "当前定时任务："
        crontab -l 2>/dev/null || echo "  无"
        echo ""
        echo "容器将保持运行，定时任务将按计划执行"
        echo "定时任务已保存到 $CRONTAB_FILE，容器重启后会自动恢复"
        echo ""
        echo "使用以下命令管理容器："
        echo "  查看定时任务: docker exec -it <container_name> crontab -l"
        echo "  编辑定时任务: docker exec -it <container_name> crontab -e"
        echo "  查看容器日志: docker logs <container_name>"
        echo "  后台运行容器: docker run -d --name <container_name> ..."
        echo ""
        
        # 设置定期保存crontab（每5分钟保存一次）
        while true; do
            sleep 300
            save_crontab
        done &
        
        # 保持容器运行
        tail -f /dev/null
    else
        # 没有设置定时任务，直接退出
        echo "未设置定时任务，容器将退出"
        exit 0
    fi
fi

