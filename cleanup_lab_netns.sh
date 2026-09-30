#!/usr/bin/env bash
set -euo pipefail

for ns in ns-video ns-bg ns-router ns-client1 ns-client2 ns-client3; do
    sudo ip netns del "$ns" 2>/dev/null || true
done

echo "Ambiente removido."
