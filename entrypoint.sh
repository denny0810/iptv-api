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

# 删除现有的 crontab 文件（如果有）
crontab -r 2>/dev/null || true

# 如果 UPDATE_CRON 环境变量存在，则添加新的 cron 任务
if [ -n "$UPDATE_CRON" ]; then
  echo "$UPDATE_CRON cd $APP_WORKDIR && /.venv/bin/python main.py" | crontab -
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

# 启动 dcron 并设置日志级别
/usr/sbin/crond -b -L /tmp/dcron.log -l 4 &

# 启动主应用程序
python $APP_WORKDIR/main.py &

# 启动 Gunicorn
python -m gunicorn service.app:app -b 0.0.0.0:$APP_PORT --timeout=1000
