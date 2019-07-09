#!/usr/bin/env bash

function spawn {
    if [[ -z ${PIDS+x} ]]; then PIDS=(); fi
    "$@" &
    PIDS+=($!)
}

function join {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            wait "${pid}"
        done
    fi
}

function on_kill {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            kill "${pid}" 2> /dev/null
        done
    fi
    kill "${ENTRYPOINT_PID}" 2> /dev/null
}

export ENTRYPOINT_PID="${BASHPID}"

trap "on_kill" EXIT
trap "on_kill" SIGINT

if [ -z ${OPENVPN_CONFIG+x} ]; then
    echo "Error: \$OPENVPN_CONFIG not set!"
    exit 1
fi

if [ ! -f "${OPENVPN_CONFIG}" ]; then
    echo "Error: ${OPENVPN_CONFIG} is not a valid file!"
    exit 1
fi

export OPENVPN_CONFIG=$(readlink -f "${OPENVPN_CONFIG}")

mkfifo /openvpn-fifo

SUBNET=$(ip -o -f inet addr show dev eth0 | awk '{print $4}')
IPADDR=$(echo "${SUBNET}" | cut -f1 -d'/')
GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
eval $(ipcalc -np "${SUBNET}")

ip rule add from "${IPADDR}" table 128
ip route add table 128 to "${NETWORK}/${PREFIX}" dev eth0
ip route add table 128 default via "${GATEWAY}"

SAVED_DIR="${PWD}"
cd $(dirname "${OPENVPN_CONFIG}")
spawn openvpn \
    --script-security 2 \
    --config "${OPENVPN_CONFIG}" \
    --up /usr/local/bin/openvpn-up.sh
cd "${SAVED_DIR}"

cat /openvpn-fifo > /dev/null
rm -f /openvpn-fifo

if [[ -n "${OPENVPN_UP}" ]]; then
    spawn "${OPENVPN_UP}" "$@"
elif [[ $# -gt 0 ]]; then
    "$@"
fi

if [[ $# -eq 0 || "${DAEMON_MODE}" == true ]]; then
    join
fi
