#!/bin/sh

# 复制配置文件
for file in /iptv-api-config/*; do
  filename=$(basename "$file")
  target_file="$APP_WORKDIR/config/$filename"
  if [ ! -e "$target_file" ]; then
    cp -r "$file" "$target_file"
  fi
done

# 激活虚拟环境
. /.venv/bin/activate

# 配置 Cron 任务（通过 crontab 命令）
if [ -n "$UPDATE_CRON" ]; then
  CRON_FILE=$(mktemp)
  echo "SHELL=/bin/sh" > "$CRON_FILE"
  echo "PATH=/.venv/bin:/usr/local/bin:/usr/bin:/bin" >> "$CRON_FILE"
  echo "$UPDATE_CRON . /etc/profile; cd $APP_WORKDIR && . /.venv/bin/activate && python main.py >> /var/log/cron.log 2>&1" >> "$CRON_FILE"
  crontab "$CRON_FILE"
  rm "$CRON_FILE"
fi

# dcron log level
# LOG_EMERG	0	[* system is unusable *]
# LOG_ALERT	1	[* action must be taken immediately *]
# LOG_CRIT	2	[* critical conditions *]
# LOG_ERR	3	[* error conditions *]
# LOG_WARNING	4	[* warning conditions *]
# LOG_NOTICE	5	[* normal but significant condition *]
# LOG_INFO	6	[* informational *]
# LOG_DEBUG	7	[* debug-level messages *]

# 启动 cron（日志统一到 /var/log/cron.log）
/usr/sbin/crond -l 4 -f -L /var/log/cron.log &

# 启动主应用（Gunicorn 作为主进程）
exec python -m gunicorn service.app:app -b 0.0.0.0:$APP_PORT --timeout=1000
