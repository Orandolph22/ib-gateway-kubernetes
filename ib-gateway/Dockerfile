FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-11-jre \
    curl \
    unzip \
    wget \
    xvfb \
    x11vnc \
    fluxbox \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /opt/ibc /opt/ibgateway /root

# Download and install IB Gateway
RUN cd /tmp && \
    wget -q https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-linux-x64.sh && \
    chmod +x ibgateway-stable-standalone-linux-x64.sh && \
    yes '' | ./ibgateway-stable-standalone-linux-x64.sh && \
    rm ibgateway-stable-standalone-linux-x64.sh

# Download and extract IBC
RUN cd /opt/ibc && \
    wget -q https://github.com/IbcAlpha/IBC/releases/download/3.15.2/IBCLinux-3.15.2.zip && \
    unzip IBCLinux-3.15.2.zip && \
    rm IBCLinux-3.15.2.zip && \
    chmod -R +x /opt/ibc/*.sh && \
    chmod -R +x /opt/ibc/scripts/*.sh

# Fix IBC version mismatch - CRITICAL FIX
RUN sed -i 's/^TWS_MAJOR_VRSN=.*/TWS_MAJOR_VRSN=1030/' /opt/ibc/gatewaystart.sh

# Copy custom entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set environment defaults
ENV DISPLAY=:1
ENV TRUSTED_IPS=10.0.0.0/8
ENV TRADING_MODE=paper
ENV IBC_PATH=/opt/ibc

EXPOSE 7497 7498

ENTRYPOINT ["/entrypoint.sh"]
