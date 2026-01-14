#!/bin/bash

# Function to flush DNS for macOS 10.10.4+
flush_dns_new() {
    sudo killall -HUP mDNSResponder
}

# Function to flush DNS for macOS 10.10 - 10.10.3
flush_dns_old() {
    sudo discoveryutil mdnsflushcache
    sudo discoveryutil udnsflushcaches
}

# Function to flush DNS for macOS 10.7 - 10.9
flush_dns_lion() {
    sudo killall -HUP mDNSResponder
}

# Function to flush DNS for macOS 10.6
flush_dns_snow_leopard() {
    sudo dscacheutil -flushcache
}

# Determine macOS version
OS_VERSION=$(sw_vers -productVersion)

# Flush DNS based on macOS version
if [[ "$OS_VERSION" == 10.6.* ]]; then
    flush_dns_snow_leopard
elif [[ "$OS_VERSION" == 10.7.* || "$OS_VERSION" == 10.8.* || "$OS_VERSION" == 10.9.* ]]; then
    flush_dns_lion
elif [[ "$OS_VERSION" == 10.10.* ]]; then
    flush_dns_old
else
    flush_dns_new
fi

# Check if the DNS flush was successful
if [ $? -eq 0 ]; then
    # Speak "DNS Flushed" if successful
    # say "DNS Flushed"
    echo "DNS Flushed"
else
    # Error handling
    echo "Error: Unable to flush DNS cache"
    exit 1
fi
