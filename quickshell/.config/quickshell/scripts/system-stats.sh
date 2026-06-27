#!/bin/sh

set -eu

read_cpu_mem() {
  awk '
    /^cpu / {
      idle = $5 + $6
      total = 0
      for (i = 2; i <= NF; i++) total += $i
    }
    /^MemTotal:/ { mem_total = $2 }
    /^MemAvailable:/ { mem_available = $2 }
    END {
      mem = mem_total > 0 ? (mem_total - mem_available) / mem_total : 0
      printf "%s %s %.4f", total, idle, mem
    }
  ' /proc/stat /proc/meminfo
}

busy_value() {
  gpu="$1"
  if [ -r "$gpu/device/gpu_busy_percent" ]; then
    value=$(cat "$gpu/device/gpu_busy_percent" 2>/dev/null || printf '0')
    value=${value%%.*}
    case "$value" in
      ''|*[!0-9]*) value=0 ;;
    esac
    awk "BEGIN { v = $value / 100; if (v > 1) v = 1; printf \"%.4f\", v }"
  else
    printf '0.0000'
  fi
}

temp_value() {
  path="$1"
  if [ -r "$path" ]; then
    value=$(cat "$path" 2>/dev/null || printf '0')
    case "$value" in
      ''|*[!0-9]*) value=0 ;;
    esac
    awk "BEGIN { printf \"%.2f\", $value / 1000 }"
  else
    printf '0.00'
  fi
}

cpu_temp=$(
  sensors 2>/dev/null |
  awk '/Package id 0:/ {
    gsub(/[+°C]/, "", $4)
    print $4
    exit
  }'
)

case "${cpu_temp:-}" in
  ''|*[!0-9.]*)
    cpu_temp=0
    ;;
esac

gpu0_busy=0.0000
gpu1_busy=0.0000
gpu0_temp=0.00
gpu1_temp=0.00

idx=0
for gpu in /sys/class/drm/card*; do
  [ -d "$gpu" ] || continue

  temp_file=$(find "$gpu/device" -path '*/hwmon/*/temp*_input' -type f 2>/dev/null | head -n1 || true)

  case "$idx" in
    0)
      gpu0_busy=$(busy_value "$gpu")
      [ -n "$temp_file" ] && gpu0_temp=$(temp_value "$temp_file")
      ;;
  esac

  idx=$((idx + 1))
  [ "$idx" -ge 2 ] && break
done

# Get NVIDIA GPU temperature and utilization using nvidia-smi
nvidia_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || printf '0.000')
gpu1_busy=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1/100}')
case "${nvidia_temp:-}" in
  ''|*[!0-9]*) nvidia_temp=0 ;;
esac

# Use nvidia temp for the second GPU (MX350)
gpu1_temp="${nvidia_temp}"

read_cpu_mem
printf ' %s %s %s %s %s\n' \
  "$gpu0_busy" \
  "$gpu1_busy" \
  "$cpu_temp" \
  "$gpu0_temp" \
  "$gpu1_temp"
