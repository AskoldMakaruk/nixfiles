{ pkgs }:
pkgs.writeShellScript "telegram-notify" ''
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    --data-urlencode "chat_id=$CHAT_ID" \
    --data-urlencode "message_thread_id=$TOPIC_ID" \
    --data-urlencode "text=$1" \
    > /dev/null || true
''
