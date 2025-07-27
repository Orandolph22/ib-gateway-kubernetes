#!/bin/bash
echo "Starting IB Gateway with Kubernetes support..."

# Start Xvfb (virtual display)
Xvfb :1 -screen 0 1024x768x16 &
export DISPLAY=:1
sleep 2

# Start window manager
fluxbox &
sleep 2

# Ensure IB Gateway directory exists
IB_GATEWAY_DIR="$HOME/Jts"
mkdir -p "${IB_GATEWAY_DIR}"

# Create jts.ini with Kubernetes-friendly TrustedIPs
cat <<EOL > "${IB_GATEWAY_DIR}/jts.ini"
[IBGateway]
TrustedIPs=${TRUSTED_IPS}
LocalServerPort=7497
ApiOnly=true
EOL

echo "Created jts.ini with TrustedIPs=${TRUSTED_IPS}"

# Create IBC config
cat <<EOL > /opt/ibc/config.ini
IbLoginId=${TWS_USERID}
IbPassword=${TWS_PASSWORD}
TradingMode=${TRADING_MODE}
IbDir=${HOME}/Jts
IbAutoClosedown=no
AcceptIncomingConnectionAction=accept
AllowBlindTrading=yes
ReadOnlyLogin=no
AcceptNonBrokerageAccountWarning=yes
OverrideTwsApiPort=7497
LogToConsole=yes
FIX=no
EOL

echo "Starting IB Gateway..."

# Start IB Gateway using IBC
cd /opt/ibc
./gatewaystart.sh -inline &

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
tail -f $HOME/IBController/Logs/*.log 2>/dev/null || tail -f /dev/null
