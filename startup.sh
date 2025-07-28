#!/bin/bash

set -e

# Start Xvfb
Xvfb :1 -screen 0 1024x768x24 &
export DISPLAY=:1
sleep 2

# Find IB Gateway installation
INSTALL_DIR="/root/Jts"
GATEWAY_VERSION=$(ls -1 ${INSTALL_DIR}/ibgateway/ | grep -E '^[0-9]+$' | sort -n | tail -1)

echo "Found IB Gateway version $GATEWAY_VERSION"

# Create jts.ini with TrustedIPs
mkdir -p ${INSTALL_DIR}
cat > ${INSTALL_DIR}/jts.ini << EOL
[IBGateway]
TrustedIPs=10.0.0.0/8
ApiOnly=true
[Logon]
s3store=true
Locale=en
displayedproxymsg=1
UseSSL=true
EOL

# Create comprehensive IBC configuration
mkdir -p /root/ibc
cat > /root/ibc/config.ini << EOL
# Authentication
IbLoginId=${TWS_USERID}
IbPassword=${TWS_PASSWORD}
TradingMode=${TRADING_MODE:-paper}
IbDir=${INSTALL_DIR}

# API Configuration
OverrideTwsApiPort=7497
AcceptIncomingConnectionAction=accept
AllowBlindTrading=yes
ReadOnlyLogin=no

# Dialog Handling - Critical for headless operation
ExistingSessionDetectedAction=primary
AcceptNonBrokerageAccountWarning=yes
AcceptSpreadBasedChargesDisclaimer=accept
DismissPasswordExpiryWarning=yes
DismissNSEComplianceNotice=yes
ConfirmExitSessionSetting=no

# Logging
LogToConsole=yes
IbAutoClosedown=no
ClosedownAt=

# Additional settings for stability
MinimizeMainWindow=no
FIX=no
EOL

echo "Starting IB Gateway..."
cd /opt/ibc
./gatewaystart.sh -inline &
IBC_PID=$!

# Monitor startup
for i in {1..60}; do
    if ! ps -p $IBC_PID > /dev/null; then
        echo "ERROR: IBC process died!"
        exit 1
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":7497"; then
        echo "✓ IB Gateway is listening on port 7497!"
        break
    fi
    
    echo "Waiting for IB Gateway to start... ($i/60)"
    sleep 5
done

echo "IB Gateway startup complete"
tail -f /dev/null
