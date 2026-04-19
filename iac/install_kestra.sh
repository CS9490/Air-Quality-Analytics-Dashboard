#!/usr/bin/env bash
set -euxo pipefail

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
apt-get update
apt-get install -y docker-compose-plugin

# Ensure Docker is enabled and ready before Compose is used.
systemctl enable docker
systemctl start docker

until docker info >/dev/null 2>&1; do
  sleep 2
done

# Create necessary directories for kestra
if ! id -u kestra >/dev/null 2>&1; then
  useradd --system --create-home --shell /usr/sbin/nologin kestra
fi

mkdir -p /opt/kestra
chown -R kestra:kestra /opt/kestra

cat <<'EOF' > /opt/kestra/docker-compose.yml
${docker_compose}
EOF

sleep 30

# cd to Kestra installation directory
cd /opt/kestra

# Start Kestra services in the background so the startup script can complete.
docker compose up -d