#!/usr/bin/env bash
set -euo pipefail

matrix=(
    "E1 200mbit 0ms 0% 0"
    "E2 200mbit 0ms 0% 1"
    "E3 200mbit 0ms 10% 0"
    "E4 200mbit 0ms 10% 1"
    "E5 200mbit 50ms 0% 0"
    "E6 200mbit 50ms 0% 1"
    "E7 200mbit 50ms 10% 0"
    "E8 200mbit 50ms 10% 1"
    "E9 100mbit 0ms 0% 0"
    "E10 100mbit 0ms 0% 1"
    "E11 100mbit 0ms 10% 0"
    "E12 100mbit 0ms 10% 1"
    "E13 100mbit 50ms 0% 0"
    "E14 100mbit 50ms 0% 1"
    "E15 100mbit 50ms 10% 0"
    "E16 100mbit 50ms 10% 1"
)

mkdir -p capturas logs

for exp in "${matrix[@]}"; do
    read -r id rate delay loss bg <<< "$exp"
    echo "================================================="
    echo "Executando $id: Banda=$rate, Atraso=$delay, Perda=$loss, Tráfego Fundo=$bg"
    echo "================================================="

    # 1. Limpa regras tc
    ./clear_tc.sh >/dev/null 2>&1 || true

    # 2. Aplica condições tc
    tc_cmd="sudo ip netns exec ns-router tc qdisc add dev r-c1 root netem"
    tc_cmd="$tc_cmd rate $rate"
    [ "$delay" != "0ms" ] && tc_cmd="$tc_cmd delay $delay"
    [ "$loss" != "0%" ] && tc_cmd="$tc_cmd loss $loss"
    eval "$tc_cmd"

    # 3. Tráfego de fundo (iperf3)
    if [ "$bg" -eq 1 ]; then
        sudo ip netns exec ns-client1 iperf3 -s -D --logfile "logs/${id}_iperf_server.log" || true
        sleep 1
        sudo ip netns exec ns-bg iperf3 -c 10.0.11.2 -t 30 -b 50M > "logs/${id}_iperf_client.log" 2>&1 &
    fi

    # 4. Captura PCAP
    sudo ip netns exec ns-router tcpdump -i r-c1 -w "capturas/${id}_router.pcap" -c 10000 >/dev/null 2>&1 &
    PID_CAP_R=$!
    sudo ip netns exec ns-client1 tcpdump -i c1 -w "capturas/${id}_client1.pcap" -c 10000 >/dev/null 2>&1 &
    PID_CAP_C=$!

    # 5. Receptor FFmpeg
    sudo ip netns exec ns-client1 ffmpeg -i udp://@:1234 -f null - > "logs/${id}_ffmpeg_client.log" 2>&1 &
    PID_CLIENT=$!
    sleep 2

    # 6. Transmissão de Vídeo
    sudo ip netns exec ns-video ffmpeg -re -i videos/video.mp4 -f mpegts udp://10.0.11.2:1234 > "logs/${id}_ffmpeg_server.log" 2>&1 || true

    # 7. Limpeza do ciclo
    {
        sudo kill -9 $PID_CLIENT $PID_CAP_R $PID_CAP_C
        sudo pkill -f iperf3
    } >/dev/null 2>&1 || true

    ./clear_tc.sh >/dev/null 2>&1 || true
    sleep 2
done

echo "Todos os experimentos da matriz E1 a E16 foram concluídos!"
