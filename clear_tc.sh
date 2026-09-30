#!/usr/bin/env bash
set -euo pipefail

for dev in r-vd r-bg r-c1 r-c2 r-c3; do
    sudo ip netns exec ns-router tc qdisc del dev "$dev" root 2>/dev/null || true
done

echo "Regras tc removidas do ns-router."
