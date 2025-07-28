#!/bin/bash

echo "Starting IB Gateway with Kubernetes support..."

# Start Xvfb (virtual display)
Xvfb :1 -screen 0 1024x768x16 &
export DISPLAY=:1
sleep 2

# Start window manager
fluxbox &
sleep 2

# IB Gateway is installed at /root/Jts/ibgateway/VERSION
IB_GATEWAY_ROOT="/root/Jts"
IB_GATEWAY_VERSION=$(ls -1 ${IB_GATEWAY_ROOT}/ibgateway/ | grep -E '^[0-9]+$' | sort -n | tail -1)
IB_GATEWAY_DIR="${IB_GATEWAY_ROOT}/ibgateway/${IB_GATEWAY_VERSION}"

echo "Found IB Gateway version ${IB_GATEWAY_VERSION} at: ${IB_GATEWAY_DIR}"

# Create jts.ini with Kubernetes-friendly TrustedIPs
cat <<EOL > "${IB_GATEWAY_ROOT}/jts.ini"
[IBGateway]
TrustedIPs=${TRUSTED_IPS}
LocalServerPort=7497
ApiOnly=true
EOL

echo "Created jts.ini with TrustedIPs=${TRUSTED_IPS}"

# Create IBC config in the correct location - IBC expects it at ~/ibc/config.ini
mkdir -p /root/ibc
cat <<EOL > /root/ibc/config.ini
IbLoginId=${TWS_USERID}
IbPassword=${TWS_PASSWORD}
TradingMode=${TRADING_MODE}
IbDir=${IB_GATEWAY_ROOT}
IbAutoClosedown=no
AcceptIncomingConnectionAction=accept
AllowBlindTrading=yes
ReadOnlyLogin=no
AcceptNonBrokerageAccountWarning=yes
OverrideTwsApiPort=7497
LogToConsole=yes
FIX=no
EOL

echo "Created IBC config at /root/ibc/config.ini"

echo "Starting IB Gateway..."

# Start IB Gateway using IBC
cd /opt/ibc
./gatewaystart.sh -inline --tws-path ${IB_GATEWAY_ROOT} &

# Wait for IB Gateway to start
sleep 30

# Check if port is listening
for i in {1..30}; do
    if netstat -an | grep -q "0.0.0.0:7497.*LISTEN"; then
        echo "IB Gateway is listening on port 7497"
        break
    fi
    echo "Waiting for IB Gateway to start... ($i/30)"
    sleep 10
done

# Keep container running and show logs
tail -f /root/ibc/logs/*.txt 2>/dev/null || tail -f /dev/null
