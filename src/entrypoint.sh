#!/bin/bash

# Exit immediately on error
set -e

ENV="${HOME}/env.sh"

# Write cronjob env to file, fill in sensible defaults, and read them back in
cat <<EOF > "${ENV}"
PATH=${PATH}

AWS_EXTRA_ARGS="${AWS_EXTRA_ARGS:-}"
AWS_GLACIER_VAULT_NAME="${AWS_GLACIER_VAULT_NAME:-}"
AWS_S3_BUCKET_NAME="${AWS_S3_BUCKET_NAME:-}"
BACKUP_ARCHIVE="${BACKUP_ARCHIVE:-/archive}"
BACKUP_CRON_EXPRESSION="${BACKUP_CRON_EXPRESSION:-@daily}"
BACKUP_CUSTOM_LABEL="${BACKUP_CUSTOM_LABEL:-}"
BACKUP_FILENAME=${BACKUP_FILENAME:-"%Y%m%dT%H%M%S-backup.tar.gz"}
BACKUP_UID="${BACKUP_UID:-0}"
BACKUP_GID="${BACKUP_GID:-${BACKUP_UID}}"
BACKUP_HOSTNAME="${BACKUP_HOSTNAME:-$(hostname)}"
BACKUP_SOURCES="${BACKUP_SOURCES:-/backup}"
BACKUP_WAIT_SECONDS="${BACKUP_WAIT_SECONDS:-0}"
CHECK_HOST="${CHECK_HOST:-"false"}"
DEBUG="${DEBUG:-false}"
DOCKER_SOCK="${DOCKER_SOCK:-/var/run/docker.sock}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
GPG_PASSPHRASE_FILE="${GPG_PASSPHRASE_FILE:-}"
INFLUXDB_API_TOKEN="${INFLUXDB_API_TOKEN:-$(cat "${INFLUXDB_API_TOKEN_FILE:-/dev/null}" 2>/dev/null || true)}"
INFLUXDB_API_TOKEN_FILE=${INFLUXDB_API_TOKEN_FILE:-}"
INFLUXDB_BUCKET="${INFLUXDB_BUCKET:-}"
INFLUXDB_CREDENTIALS="${INFLUXDB_CREDENTIALS:-$(cat "${INFLUXDB_CREDENTIALS_FILE:-/dev/null}" 2>/dev/null || true)}"
INFLUXDB_CREDENTIALS_FILE="${INFLUXDB_CREDENTIALS_FILE:-}"
INFLUXDB_DB="${INFLUXDB_DB:-}
INFLUXDB_MEASUREMENT="${INFLUXDB_MEASUREMENT:-docker_volume_backup}"
INFLUXDB_ORGANIZATION="${INFLUXDB_ORGANIZATION:-}"
INFLUXDB_URL="${INFLUXDB_URL:-}"
POST_BACKUP_COMMAND="${POST_BACKUP_COMMAND:-}"
POST_SCP_COMMAND="${POST_SCP_COMMAND:-}"
PRE_BACKUP_COMMAND="${PRE_BACKUP_COMMAND:-}"
PRE_SCP_COMMAND="${PRE_SCP_COMMAND:-}"
SCP_DIRECTORY="${SCP_DIRECTORY:-}"
SCP_HOST="${SCP_HOST:-}"
SCP_USER="${SCP_USER:-}"
SSH_KEY_FILE="${SSH_KEY_FILE:-/ssh/id_rsa}"
EOF
chmod a+x "${ENV}"
source "${ENV}"

# Configure AWS CLI
mkdir -p "${HOME}/.aws"
cat <<EOF >"${AWS_CONFIG_DIR}/credentials"
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID:-$(cat "${AWS_ACCESS_KEY_ID_FILE:-/dev/null}" 2>/dev/null || true)}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY:-$(cat "${AWS_SECRET_ACCESS_KEY_FILE:-/dev/null}" 2>/dev/null || true)}
EOF
if [ ! -z "$AWS_DEFAULT_REGION" ]; then
cat <<EOF > "${HOME}/.aws/config"
[default]
region = ${AWS_DEFAULT_REGION}
EOF
fi

# Add our cron entry, and direct stdout & stderr to Docker commands stdout
echo "Installing cron.d entry: docker-volume-backup"
echo "${BACKUP_CRON_EXPRESSION} root /root/backup.sh > /proc/1/fd/1 2>&1" > /etc/cron.d/docker-volume-backup

# Let cron take the wheel
echo "Starting cron in foreground with expression: ${BACKUP_CRON_EXPRESSION}"
cron -f

