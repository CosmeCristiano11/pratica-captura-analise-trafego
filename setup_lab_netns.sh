#!/usr/bin/env bash
set -euo pipefail

echo "[1/8] Limpando ambiente anterior, se existir..."
for ns in ns-video ns-bg ns-router ns-client1 ns-client2 ns-client3; do
    sudo ip netns del "$ns" 2>/dev/null || true
done

echo "[2/8] Criando namespaces..."
for ns in ns-video ns-bg ns-router ns-client1 ns-client2 ns-client3; do
    sudo ip netns add "$ns"
    sudo ip netns exec "$ns" ip link set lo up
done

echo "[3/8] Criando pares veth..."
sudo ip link add v-vd type veth peer name r-vd
sudo ip link add v-bg type veth peer name r-bg
sudo ip link add c1 type veth peer name r-c1
sudo ip link add c2 type veth peer name r-c2
sudo ip link add c3 type veth peer name r-c3

echo "[4/8] Movendo interfaces para os namespaces..."
sudo ip link set v-vd netns ns-video
sudo ip link set r-vd netns ns-router

sudo ip link set v-bg netns ns-bg
sudo ip link set r-bg netns ns-router

sudo ip link set c1 netns ns-client1
sudo ip link set r-c1 netns ns-router

sudo ip link set c2 netns ns-client2
sudo ip link set r-c2 netns ns-router

sudo ip link set c3 netns ns-client3
sudo ip link set r-c3 netns ns-router

echo "[5/8] Configurando endereços IP..."
sudo ip netns exec ns-video ip addr add 10.0.1.2/24 dev v-vd
sudo ip netns exec ns-router ip addr add 10.0.1.1/24 dev r-vd

sudo ip netns exec ns-bg ip addr add 10.0.3.2/24 dev v-bg
sudo ip netns exec ns-router ip addr add 10.0.3.1/24 dev r-bg

sudo ip netns exec ns-client1 ip addr add 10.0.11.2/24 dev c1
sudo ip netns exec ns-router ip addr add 10.0.11.1/24 dev r-c1

sudo ip netns exec ns-client2 ip addr add 10.0.12.2/24 dev c2
sudo ip netns exec ns-router ip addr add 10.0.12.1/24 dev r-c2

sudo ip netns exec ns-client3 ip addr add 10.0.13.2/24 dev c3
sudo ip netns exec ns-router ip addr add 10.0.13.1/24 dev r-c3

echo "[6/8] Ativando interfaces..."
sudo ip netns exec ns-video ip link set v-vd up
sudo ip netns exec ns-bg ip link set v-bg up
sudo ip netns exec ns-client1 ip link set c1 up
sudo ip netns exec ns-client2 ip link set c2 up
sudo ip netns exec ns-client3 ip link set c3 up

sudo ip netns exec ns-router ip link set r-vd up
sudo ip netns exec ns-router ip link set r-bg up
sudo ip netns exec ns-router ip link set r-c1 up
sudo ip netns exec ns-router ip link set r-c2 up
sudo ip netns exec ns-router ip link set r-c3 up

echo "[7/8] Configurando rotas..."
sudo ip netns exec ns-video ip route add default via 10.0.1.1
sudo ip netns exec ns-bg ip route add default via 10.0.3.1
sudo ip netns exec ns-client1 ip route add default via 10.0.11.1
sudo ip netns exec ns-client2 ip route add default via 10.0.12.1
sudo ip netns exec ns-client3 ip route add default via 10.0.13.1

echo "[8/8] Habilitando encaminhamento IP no roteador..."
sudo ip netns exec ns-router sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo
echo "Ambiente criado com sucesso."
