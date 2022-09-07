#!/bin/zsh

znotify() {
  local code=$? opt=$1 value=$2

  if [[ -z ${last_command} ]]; then
    local message=znotify
  else
    case $code in
    0) local text="Command Succeeded" ;;
    *) local text="Command Failed" ;;
    esac

    local message="${text}: ${last_command}"
  fi

  case $opt in
  -s | --service)
    case $value in
    telegram | line | slack | macos)
      _znotify_${value} ${message}
      ;;
    *)
      echo "znotify: unsupported service: ${value}" >&2
      return
      ;;
    esac
    ;;
  *)
    _znotify_usage
    return
    ;;
  esac
}

_znotify_usage() {
  echo "znotify - a simple Zsh plugin for sending notifications to other services

Usage: znotify [OPTION] [VALUE]

    -s, --service  Specify notification service
    "
}

_znotify_telegram() {
  if [[ -z ${ZNOTIFY_TELEGRAM_TOKEN} ]]; then
    echo "znotify: ZNOTIFY_TELEGRAM_TOKEN is required" >&2
    return
  fi

  if [[ -z ${ZNOTIFY_TELEGRAM_CHAT_ID} ]]; then
    echo "znotify: ZNOTIFY_TELEGRAM_CHAT_ID is required" >&2
    return
  fi

  curl -s -X POST \
    -d "chat_id=${ZNOTIFY_TELEGRAM_CHAT_ID}" \
    -d "text=$1" \
    https://api.telegram.org/bot${ZNOTIFY_TELEGRAM_TOKEN}/sendMessage
}

_znotify_line() {
  if [[ -z ${ZNOTIFY_LINE_TOKEN} ]]; then
    echo "znotify: ZNOTIFY_LINE_TOKEN is required" >&2
    return
  fi

  curl -s -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Authorization: Bearer ${ZNOTIFY_LINE_TOKEN}" \
    -d "message=$1" \
    https://notify-api.line.me/api/notify
}

_znotify_slack() {
  if [[ -z ${ZNOTIFY_SLACK_TOKEN} ]]; then
    echo "znotify: ZNOTIFY_SLACK_TOKEN is required" >&2
    return
  fi

  if [[ -z ${ZNOTIFY_SLACK_CHANNEL} ]]; then
    echo "znotify: ZNOTIFY_SLACK_CHANNEL is required" >&2
    return
  fi

  curl -s -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Authorization: Bearer ${ZNOTIFY_SLACK_TOKEN}" \
    -d "channel=$ZNOTIFY_SLACK_CHANNEL" \
    -d "text=$1" \
    https://slack.com/api/chat.postMessage
}

_znotify_macos() {
  osascript -e "display notification \"$1\" with title \"znotify\""
}

_znotify_preexec() {
  declare -g last_command=$(echo "$3" | head -n -1)
}

autoload -Uz add-zsh-hook

add-zsh-hook preexec _znotify_preexec

znotify_plugin_unload() {
  unfunction znotify $0

  add-zsh-hook -D preexec _znotify_preexec
}
