#!/bin/bash
# ============================================================
#  NanoSys Syslog Auto Setup v1.0
#  Author: Mehdi Dehghan Kiadehi (NanoSys)
#  Target: Ubuntu Server 22.04 LTS
#  Purpose: Install and configure rsyslog as Syslog server
# ============================================================

TIMEZONE="Asia/Tehran"
LOG_DIR="/var/log/nanosys_syslog"

echo "=== Step 1: Updating system packages ==="
apt update -y && apt upgrade -y

echo "=== Step 2: Installing rsyslog ==="
apt install -y rsyslog

echo "=== Step 3: Enabling remote log reception (UDP & TCP 514) ==="
sed -i 's/^#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
sed -i 's/^#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

grep -q 'imtcp' /etc/rsyslog.conf || cat <<EOF >> /etc/rsyslog.conf

# Enable TCP log reception
module(load="imtcp")
input(type="imtcp" port="514")
EOF

echo "=== Step 4: Creating NanoSys log directory ==="
mkdir -p ${LOG_DIR}
chown syslog:adm ${LOG_DIR}
chmod 750 ${LOG_DIR}

echo "=== Step 5: Adding FortiGate log separation rule ==="
cat <<EOF > /etc/rsyslog.d/40-fortigate.conf
if \$fromhost-ip startswith "192.168." then /var/log/nanosys_syslog/fortigate.log
& stop
EOF

echo "=== Step 6: Setting timezone ==="
timedatectl set-timezone ${TIMEZONE}

echo "=== Step 7: Restarting rsyslog ==="
systemctl restart rsyslog
systemctl enable rsyslog

echo "=== Step 8: Opening firewall ports ==="
ufw allow 514/tcp
ufw allow 514/udp
ufw reload

echo "=== Step 9: Testing status ==="
systemctl status rsyslog --no-pager | head -n 10

echo "==============================================="
echo "✅ Syslog server installed and configured!"
echo "📁 Logs path: ${LOG_DIR}"
echo "🌐 Listening on UDP/TCP port 514"
echo "🕒 Timezone: ${TIMEZONE}"
echo "==============================================="
