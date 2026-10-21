#!/usr/bin/env bash
if command -v nvidia-smi >/dev/null 2>&1; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)
    if [ -n "$usage" ]; then
        echo "$usage"
        exit 0
    fi
fi

if sensors -j 2>/dev/null | grep -q 'nouveau-pci-0800'; then
    usage=$(sensors -j 2>/dev/null | jq -r '."nouveau-pci-0800".power1.power1_input as $p | 15 as $idle | 150 as $max | (($p - $idle) / ($max - $idle) * 100) | if . < 0 then 0 elif . > 100 then 100 else . end | round' 2>/dev/null)
    if [ -n "$usage" ] && [ "$usage" != "null" ]; then
        echo "$usage"
        exit 0
    fi
fi

if command -v intel_gpu_top >/dev/null 2>&1; then
    val=$(timeout 0.8s intel_gpu_top -J -s 500 2>/dev/null | grep -A 1 '"Render/3D' | grep '"busy"' | head -n 1 | awk -F': ' '{print $2}' | tr -d ',')
    if [ -n "$val" ]; then
        printf "%.0f\n" "$val"
        exit 0
    fi
fi

echo "0"
