#!/bin/bash
#
# Tautulli Backup from UGREEN NAS
# Backs up Tautulli configuration before Proxmox migration
#
# Created: 2025-12-02
# Source: UGREEN NAS (192.168.40.60) /volume1/docker/tautulli
# Destination: ai-terminal shared ZFS storage /home/slesz/shared/
#

set -e  # Exit on error

# Configuration
UGREEN_HOST="192.168.40.60"
UGREEN_USER="Nearness0143"
SOURCE_PATH="/volume1/docker/tautulli"
BACKUP_DIR="/home/slesz/shared/projects/ugreen_proxmox/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="tautulli_backup_${TIMESTAMP}.tar.gz"

echo "=========================================="
echo "Tautulli Backup Script"
echo "=========================================="
echo "Source: ${UGREEN_USER}@${UGREEN_HOST}:${SOURCE_PATH}"
echo "Destination: ${BACKUP_DIR}/${BACKUP_FILE}"
echo ""

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Check if source directory exists on UGREEN
echo "[1/4] Checking source directory..."
if ! ssh "${UGREEN_USER}@${UGREEN_HOST}" "[ -d '${SOURCE_PATH}' ]"; then
    echo "ERROR: Source directory ${SOURCE_PATH} does not exist on UGREEN!"
    exit 1
fi
echo "✓ Source directory exists"

# Get source directory size
echo ""
echo "[2/4] Calculating source size..."
SOURCE_SIZE=$(ssh "${UGREEN_USER}@${UGREEN_HOST}" "du -sh '${SOURCE_PATH}'" | awk '{print $1}')
echo "✓ Tautulli data size: ${SOURCE_SIZE}"

# Create compressed backup via SSH
echo ""
echo "[3/4] Creating compressed backup..."
echo "This may take a few minutes depending on size..."
ssh "${UGREEN_USER}@${UGREEN_HOST}" "tar czf - '${SOURCE_PATH}'" > "${BACKUP_DIR}/${BACKUP_FILE}"
echo "✓ Backup created"

# Verify backup file
echo ""
echo "[4/4] Verifying backup..."
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}/${BACKUP_FILE}" | awk '{print $1}')
echo "✓ Backup file size: ${BACKUP_SIZE}"

# List contents of backup (first 20 files)
echo ""
echo "Backup contents (first 20 files):"
tar tzf "${BACKUP_DIR}/${BACKUP_FILE}" | head -20

echo ""
echo "=========================================="
echo "✅ BACKUP COMPLETED SUCCESSFULLY"
echo "=========================================="
echo "Backup file: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "Original size: ${SOURCE_SIZE}"
echo "Compressed size: ${BACKUP_SIZE}"
echo ""
echo "To restore on Proxmox:"
echo "  1. Extract: tar xzf ${BACKUP_FILE}"
echo "  2. Place in new Tautulli container volume"
echo "  3. Set ownership: chown -R 1000:1000 /path/to/tautulli/config"
echo ""
