# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
apt-get update
apt-get install -y docker-compose-plugin

# Create necessary directories for kestra
mkdir -p /opt/kestra
chown -R kestra:kestra /opt/kestra

cat <<EOF > /opt/kestra/docker-compose.yml
volumes:
  purple_air_postgres_data:
    driver: local
  kestra_postgres_data:
    driver: local
  kestra_data:
    driver: local
  kestra_tmp:
    driver: local

services:
  pgdatabase:
    image: postgres:18
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: CHANGE_ME_PG_PASSWORD
      POSTGRES_DB: purple_air
    ports:
      - "5432:5432"
    volumes:
      - purple_air_postgres_data:/var/lib/postgresql
    depends_on:
      kestra:
        condition: service_started

  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=CHANGE_ME_PGADMIN_PASSWORD
    ports:
      - "8085:80"
    depends_on:
      pgdatabase:
        condition: service_started

  kestra_postgres:
    image: postgres:18
    volumes:
      - kestra_postgres_data:/var/lib/postgresql
    environment:
      POSTGRES_DB: kestra
      POSTGRES_USER: kestra
      POSTGRES_PASSWORD: CHANGE_ME_KESTRA_DB_PASSWORD
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 10

  kestra:
    image: kestra/kestra:v1.1
    pull_policy: always
    # Note that this setup with a root user is intended for development purpose.
    # Our base image runs without root, but the Docker Compose implementation needs root to access the Docker socket
    # To run Kestra in a rootless mode in production, see: https://kestra.io/docs/installation/podman-compose
    user: "root"
    command: server standalone
    volumes:
      - kestra_data:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - kestra_tmp:/tmp/kestra-wd
    environment:
      KESTRA_CONFIGURATION: |
        datasources:
          postgres:
            url: jdbc:postgresql://kestra_postgres:5432/kestra
            driverClassName: org.postgresql.Driver
            username: kestra
            password: CHANGE_ME_KESTRA_DB_PASSWORD
        kestra:
          server:
            basicAuth:
              username: "admin@kestra.io" # it must be a valid email address
              password: CHANGE_ME_KESTRA_ADMIN_PASSWORD
          repository:
            type: postgres
          storage:
            type: local
            local:
              basePath: "/app/storage"
          queue:
            type: postgres
          tasks:
            tmpDir:
              path: /tmp/kestra-wd/tmp
          url: http://localhost:8080/
    ports:
      - "8080:8080"
      - "8081:8081"
    depends_on:
      kestra_postgres:
        condition: service_started
EOF

sleep 30

# cd to Kestra installation directory
cd /opt/kestra

# Start Kestra services
sudo docker compose up