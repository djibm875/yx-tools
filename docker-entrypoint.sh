#!/bin/bash
set -e

# 启动cron服务
service cron start

# 如果提供了命令参数，直接执行
if [ $# -gt 0 ]; then
    exec "$@"
fi

# 否则保持容器运行，等待定时任务
echo "容器已启动，cron服务正在运行..."
echo "使用以下命令在容器内设置定时任务："
echo "  docker exec -it <container_name> python3 /app/cloudflare_speedtest.py"
echo "  docker exec -it <container_name> crontab -e"
echo ""
echo "或者使用环境变量 CRON_SCHEDULE 和 CRON_COMMAND 自动设置定时任务"

# 如果设置了环境变量，自动配置cron
if [ -n "$CRON_SCHEDULE" ] && [ -n "$CRON_COMMAND" ]; then
    echo "检测到环境变量，自动设置定时任务..."
    (crontab -l 2>/dev/null || true; echo "$CRON_SCHEDULE $CRON_COMMAND") | crontab -
    echo "定时任务已设置: $CRON_SCHEDULE $CRON_COMMAND"
fi

# 显示当前cron任务
echo "当前定时任务："
crontab -l 2>/dev/null || echo "  无"
echo ""

# 保持容器运行
tail -f /dev/null

