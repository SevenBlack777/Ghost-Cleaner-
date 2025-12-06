#!/system/bin/sh
MODDIR=${0%/*}
CONFIG_FILE="$MODDIR/config.conf"
PATH_LIST="$MODDIR/paths.list"
LOG_FILE="$MODDIR/run.log"
PROP_FILE="$MODDIR/module.prop"

# 日志函数
log_msg() {
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    # 限制日志行数：因为现在记录成功了，日志量会变大，保留最近300行
    if [ $(wc -l < "$LOG_FILE") -gt 300 ]; then
        tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}

# 等待系统启动
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done

# 初始化配置
if [ ! -f "$CONFIG_FILE" ]; then
    echo 'ENABLED="false"' > "$CONFIG_FILE"
    echo 'INTERVAL="60"' >> "$CONFIG_FILE"
fi

if [ ! -f "$PATH_LIST" ]; then
    touch "$PATH_LIST"
fi

log_msg "Ghost Cleaner v3.0 服务已启动 (By 酷安柒黑)"

# ===========================
# 🔄 核心循环
# ===========================
while true; do

  # --- 🛡️ 防篡改保护 ---
  # 依然认准 "酷安柒黑"
  if ! grep -q "^author=酷安柒黑$" "$PROP_FILE"; then
      sed -i 's/^author=.*/author=酷安柒黑/' "$PROP_FILE"
      log_msg "⚠️ 作者名被篡改，已强制恢复为 酷安柒黑。"
  fi

  # 读取配置与执行
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    
    if [ "$ENABLED" == "true" ]; then
        if [ -s "$PATH_LIST" ]; then
            while IFS= read -r target_path || [ -n "$target_path" ]; do
                # 跳过空行和注释
                if [ -z "$target_path" ] || [ "${target_path:0:1}" = "#" ]; then continue; fi
                
                # 多线程并发执行
                (
                    if [ -e "$target_path" ]; then
                        rm -rf "$target_path" >/dev/null 2>&1
                        
                        # 检查结果并反馈
                        if [ ! -e "$target_path" ]; then
                             # ✅ 这里改了：成功也记录日志
                             log_msg "✅ 已清理: $target_path"
                        else
                             log_msg "❌ 失败: $target_path"
                        fi
                    fi
                ) & 
            done < "$PATH_LIST"
            # 等待本轮所有清理任务结束
            wait
        fi
    fi
    
    if [ -z "$INTERVAL" ] || [ "$INTERVAL" -lt 5 ]; then INTERVAL=60; fi
  else
    INTERVAL=60
  fi

  sleep "$INTERVAL"
done