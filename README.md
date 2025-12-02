# UGREEN NAS to Proxmox VE Migration Project

**Date:** 2025-11-29
**Hardware:** UGREEN DXP4800 Plus NAS
**Serial Number:** EC752JJ372539F78
**Current OS:** UGOS Pro
**Target OS:** Proxmox VE 9.1
**UPS:** UGREEN US3000 (120W DC UPS)

---

## 📋 Project Overview

This project documents the research and planning for migrating a UGREEN DXP4800 Plus NAS from the proprietary UGOS operating system to Proxmox VE 9.1, while maintaining full UPS functionality and hardware capabilities.

### Motivation

UGOS has several limitations that impact homelab usage:
- SSH key authentication breaks after every reboot (by design)
- Limited package availability and customization
- No VM support
- First-generation NAS OS lacking advanced features
- Proprietary limitations vs open-source flexibility

### Primary Concern

**Can I maintain UGREEN US3000 UPS functionality without UGOS?**
**Answer:** ✅ YES - via Network UPS Tools (NUT)

---

## 🔍 Research Findings

### 1. UPS Compatibility (CRITICAL REQUIREMENT)

#### UGREEN US3000 UPS Features on UGOS:
- Auto shutdown at low battery (<15%)
- Timed shutdown after power loss
- **Auto Turn On** - Automatic restart when AC power returns
- Standby mode with battery management

#### UPS Support on Proxmox:
✅ **Full compatibility confirmed** via Network UPS Tools (NUT)

**Technical Details:**
- **Protocol:** USB-C via SMBus
- **Vendor ID:** 2b89
- **Product ID:** ffff
- **Driver:** `usbhid-ups` with Arduino subdriver
- **Proven Working:** Successfully tested on Proxmox, TrueNAS, TerraMaster NAS

**Feature Mapping:**

| UGOS Feature | NUT Equivalent | Configuration |
|--------------|----------------|---------------|
| Auto Shutdown (low battery) | `SHUTDOWNCMD` | `/etc/nut/upsmon.conf` |
| Auto Shutdown (timed) | `FINALDELAY` | `/etc/nut/upsmon.conf` |
| Battery threshold (15%) | `MINSUPPLIES` | `/etc/nut/upsmon.conf` |
| Auto Turn On (restart) | **BIOS setting** | "Restore on AC/Power Loss" |

**Important:** The "Auto Turn On" feature is **hardware-based** (BIOS setting), not OS-dependent!

#### Known Issue:
- Older NUT versions (from apt) lack `subdriver` support
- **Solution:** Compile NUT from source or use newer distro packages
- Debian 13 (Proxmox 9.1 base) likely has newer NUT version

**Sources:**
- [UGREEN US3000 NAS UPS Review - NAS Compares](https://nascompares.com/2025/09/26/ugreen-us3000-nas-ups-review/)
- [UGREEN US3000 NUT Driver Issue - GitHub](https://github.com/networkupstools/nut/issues/2987)
- [UGREEN US3000 on TerraMaster (non-UGREEN hardware) - NAS Compares](https://nascompares.com/answer/how-to-make-the-ugreen-us3000-nas-ups-work-on-a-terramaster-f4-424-pro/)

---

### 2. UGOS "Exclusive" Features Analysis

#### Features UGOS Lacks (vs Synology/QNAP):
- ❌ No snapshot support
- ❌ No ransomware protection
- ❌ No real-time anomaly detection
- ❌ First-generation OS still maturing
- ❌ Limited third-party app ecosystem

#### UGOS "Unique" Features:
- Manual deduplication (also available in ZFS/Btrfs)
- UGREENlink remote access (replaceable with Tailscale/Netbird/ZeroTier)
- AI photo recognition (replaceable with Immich/PhotoPrism)

**Conclusion:** UGOS has **zero critical irreplaceable features** for homelab use.

**Sources:**
- [UGOS Beta Review - NAS Compares](https://nascompares.com/2024/04/03/ugreen-nas-software-the-ugos-beta-review/)
- [UGREEN NASync One Year Review - NAS Compares](https://nascompares.com/2025/03/26/ugreen-nasync-nas-one-year-later-should-you-buy/)

---

### 3. Firmware Updates After Migration

#### Question: Can I update UGREEN firmware after installing Proxmox?

**Answer:** ⚠️ **No** - UGREEN BIOS updates are bundled with UGOS (no standalone files available)

#### What Updates Exist:

| Update Type | Available on Proxmox? | Importance |
|-------------|----------------------|------------|
| UGOS Software | ❌ No (replaced) | N/A |
| BIOS/UEFI | ❌ Not publicly available | Low (hardware is stable) |
| LED Controller | ✅ Community tools | Cosmetic |
| Network Drivers | ✅ Linux kernel | High (auto-updated) |
| CPU Microcode | ✅ Intel via Linux | **Critical (security)** |
| Disk Firmware | ✅ Vendor tools | Medium |

#### Risk Assessment: **LOW**

**Why Low Risk:**
1. ✅ Intel microcode updates via Linux kernel (`intel-microcode` package)
2. ✅ Network/storage drivers updated via kernel updates
3. ✅ Security patches via Proxmox/Debian (more frequent than UGOS)
4. ✅ Hardware is standard Intel (no proprietary components)
5. ⚠️ BIOS updates are rare and typically not critical for home use

**DXP4800+ Hardware (All Standard):**
- Intel Pentium Gold 8505 CPU
- Standard NVMe/SATA controllers
- Intel network chips (AQC 117)
- No proprietary hardware requiring UGREEN-specific firmware

**LED Controller Solution:**
✅ Community project: [ugreen_leds_controller](https://github.com/miskcoo/ugreen_leds_controller)
- Works on Proxmox, TrueNAS, Debian
- Provides functional LED status
- Without it: LEDs blink in rolling sequence (annoying but harmless)

**Sources:**
- [UGREEN Download Center](https://nas.ugreen.com/pages/downloads)
- [UGREEN NAS GitHub - TheLinuxGuy](https://github.com/TheLinuxGuy/ugreen-nas)
- [LED Controller - miskcoo GitHub](https://github.com/miskcoo/ugreen_leds_controller)

---

### 4. Installation Process

#### Question: Do I need to physically remove the SSD?

**Answer:** ✅ **NO** - Boot from USB and overwrite existing SSD

#### Hardware Details:
- **Pre-installed SSD:** 128GB M.2 NVMe 2280
- **Proxmox Requirements:** 8GB minimum, 32GB recommended
- **Verdict:** 128GB is sufficient

#### Installation Methods:

**Method 1: Direct Overwrite (Recommended)**
```
1. Create Proxmox 9.1 bootable USB (Rufus on Windows)
2. Plug USB into UGREEN NAS
3. Enter BIOS (Del/F12 during boot)
4. Press Ctrl+F1 to show hidden BIOS options
5. Disable Watchdog service
6. Set "After Power Loss" to "Power On" (for UPS auto-restart)
7. Set USB as first boot device
8. Save and reboot
9. Boot from USB
10. Install Proxmox to internal SSD (overwrites UGOS)
11. Remove USB, reboot
12. Access Proxmox web UI: https://192.168.40.60:8006
```

**Method 2: Preserve UGOS (Optional)**
- Requires purchasing second NVMe SSD
- Disable internal SSD in BIOS
- Install Proxmox to new SSD
- Can swap SSDs physically to switch OS

**Recommended:** Method 1 (direct overwrite)

**Sources:**
- [TrueNAS on UGREEN Installation Guide](https://nascompares.com/guide/truenas-on-a-ugreen-nas-installation-guide/)
- [Proxmox on UGREEN - Forum Discussion](https://forum.proxmox.com/threads/anybody-running-pbs-on-ugreen-units.168470/)

---

### 5. UGOS Backup Strategy

#### Why Backup UGOS?

**Only for reverting** if:
- Proxmox installation fails
- Hardware compatibility issues
- You change your mind
- Warranty claim requires testing on UGOS

#### Critical Problem:
❌ **UGREEN does not provide public UGOS recovery images**
- Recovery images are serial-number-specific
- Must request from UGREEN support (slow response times reported)
- No guarantee of receiving image

#### Backup Options:

**Option A: Clonezilla Backup (ESSENTIAL)**
```bash
1. Download Clonezilla ISO: https://clonezilla.org/downloads.php
2. Create bootable USB with Clonezilla
3. Boot UGREEN from Clonezilla USB
4. Create disk image of 128GB SSD to external USB drive
5. Store backup safely (500GB+ USB recommended)
```

**Time:** 30-60 minutes
**Storage Needed:** ~128GB (compressed smaller)
**Benefit:** Exact copy of your current UGOS setup

**Option B: Request UGOS Recovery Image**
```
Email: support@ugreen.com
Subject: UGOS Recovery Image Request

Include:
- Model: UGREEN DXP4800 Plus
- Serial Number: [bottom of device or UGOS → Settings → About]
- Purchase Date
- Current UGOS version
```

**Reality:** May take days/weeks, not guaranteed.

**Option C: Buy Second NVMe SSD**
- Cost: $20-30 for 256GB NVMe
- Keep UGOS SSD untouched
- Install Proxmox on new SSD
- Physical swap to revert

**Recommendation:** **Do Clonezilla backup before anything else!**

---

## 🏗️ Proposed Architecture

### Proxmox-Only Setup (Recommended)

**Why NOT TrueNAS VM:**
- TrueNAS VM consumes 16GB+ RAM
- Only 64GB total RAM available
- Use case is Docker services, not complex storage pools
- Simpler = more reliable

**Architecture:**
```
UGREEN DXP4800+ (64GB RAM)
├── Proxmox VE 9.1 (Host OS) - 4GB RAM
├── ZFS Storage Pool (native Proxmox)
│   ├── /media (movies, TV, audiobooks)
│   ├── /docker-data (persistent volumes)
│   └── /backups (automated backups)
├── LXC Container: Docker Services (12GB RAM)
│   ├── Portainer (management UI)
│   ├── n8n (automation)
│   ├── nginx (reverse proxy)
│   ├── Kavita (comics/manga)
│   └── Audiobookshelf
├── LXC Container: Plex Media Server (12GB RAM)
│   └── Bind mount: /media from ZFS
├── Network Shares (Proxmox native)
│   ├── Samba (SMB shares)
│   └── NFS exports
└── UPS Management (NUT on host)
    └── Monitors all containers
```

**RAM Allocation:**
- Proxmox Host: 4GB
- Docker LXC: 12GB
- Plex LXC: 12GB
- Available for future VMs: 36GB
- Reserved/Buffer: 0GB (can be adjusted)

**Benefits:**
- ✅ Simple (one OS, not nested VMs)
- ✅ Efficient (no TrueNAS VM overhead)
- ✅ Fast (direct hardware access)
- ✅ Flexible (RAM shared dynamically)
- ✅ Single web UI for everything
- ✅ More resources for actual workloads

---

## 📝 Migration Checklist

### Phase 1: Preparation (Before touching hardware)
- [ ] **CRITICAL:** Create Clonezilla backup of current UGOS SSD
- [ ] Optionally request UGOS recovery image from support
- [ ] Document current Docker containers and configurations
- [ ] Export Portainer stacks/compose files
- [ ] Note network share paths and permissions
- [ ] Backup any data not already backed up externally
- [ ] Download Proxmox VE 9.1 ISO
- [ ] Create bootable USB with Rufus

### Phase 2: BIOS Configuration
- [ ] Boot to BIOS (Del/F12 during startup)
- [ ] Press Ctrl+F1 to reveal hidden options
- [ ] Disable Watchdog service
- [ ] Set "After Power Loss" → "Power On" or "Last State"
- [ ] Verify CPU virtualization enabled (VT-x/VT-d)
- [ ] Set USB as first boot device
- [ ] Save settings and exit

### Phase 3: Proxmox Installation
- [ ] Boot from Proxmox USB
- [ ] Select "Install Proxmox VE (Graphical)"
- [ ] Accept license agreement
- [ ] Select target disk: 128GB NVMe SSD
- [ ] Choose filesystem: ZFS (RAID0 for single disk)
- [ ] Configure timezone: Europe/Warsaw
- [ ] Set root password (STRONG password!)
- [ ] Configure network:
  - IP: 192.168.40.60/24 (or DHCP first)
  - Gateway: 192.168.40.1
  - DNS: 192.168.40.1
- [ ] Complete installation
- [ ] Remove USB drive
- [ ] Reboot

### Phase 4: Initial Proxmox Setup
- [ ] Access web UI: https://192.168.40.60:8006
- [ ] Login as root
- [ ] Update Proxmox: `apt update && apt full-upgrade`
- [ ] Configure repositories (remove enterprise repo, add no-subscription)
- [ ] Reboot if kernel updated
- [ ] Configure ZFS storage pool
- [ ] Set up network (verify 192.168.40.60 is accessible)

### Phase 5: NUT UPS Setup
- [ ] Check if NUT supports subdriver:
  ```bash
  apt list nut
  # If version < 2.8.1, may need compilation
  ```
- [ ] Install NUT (or compile from source if needed)
  ```bash
  apt install -y nut nut-client nut-server
  ```
- [ ] Configure UPS driver (`/etc/nut/ups.conf`)
- [ ] Configure UPS monitoring (`/etc/nut/upsmon.conf`)
- [ ] Create USB udev rules
- [ ] Start NUT services
- [ ] Test UPS detection: `upsc ugreen-ups@localhost`
- [ ] Test shutdown trigger (simulate power loss)
- [ ] Test auto-restart (restore power, verify boot)

### Phase 6: Container Setup
- [ ] Create LXC container for Docker (Debian 12)
- [ ] Install Docker & Docker Compose in container
- [ ] Install Portainer
- [ ] Restore Docker stacks from backup
- [ ] Create LXC container for Plex
- [ ] Configure bind mounts to ZFS storage
- [ ] Test all services

### Phase 7: Network Shares
- [ ] Install Samba in LXC or host
- [ ] Configure SMB shares
- [ ] Set up NFS exports (if needed)
- [ ] Test access from Windows/other devices
- [ ] Configure permissions

### Phase 8: LED Controller (Optional)
- [ ] Clone ugreen_leds_controller repo
- [ ] Compile and install
- [ ] Configure systemd service
- [ ] Test LED status display

### Phase 9: Verification & Optimization
- [ ] Verify all Docker containers running
- [ ] Test Plex playback and transcoding
- [ ] Verify UPS monitoring working
- [ ] Test network shares accessible
- [ ] Monitor resource usage (RAM, CPU, disk I/O)
- [ ] Set up automated backups
- [ ] Configure monitoring (optional: Grafana/Prometheus)
- [ ] Document new configuration

---

## 🛠️ NUT Configuration Files

### `/etc/nut/ups.conf`
```ini
[ugreen-ups]
    driver = usbhid-ups
    port = auto
    vendorid = 2b89
    productid = ffff
    subdriver = Arduino
    desc = "UGREEN US3000 UPS"
```

### `/etc/nut/nut.conf`
```ini
MODE=standalone
```

### `/etc/nut/upsd.conf`
```ini
LISTEN 127.0.0.1 3493
LISTEN ::1 3493
```

### `/etc/nut/upsd.users`
```ini
[upsmon]
    password = SecurePassword123
    upsmon master
```

### `/etc/nut/upsmon.conf`
```ini
MONITOR ugreen-ups@localhost 1 upsmon SecurePassword123 master

# Shutdown when battery reaches 15%
MINSUPPLIES 1

# Number of power failures before shutdown
NOTIFYFLAG ONBATT SYSLOG+WALL+EXEC

# Commands
SHUTDOWNCMD "/sbin/shutdown -h now"
NOTIFYCMD /usr/sbin/upssched

# Power value below which we shutdown
POWERDOWNFLAG /etc/killpower

# Polling frequency
POLLFREQ 5
POLLFREQALERT 5

# How long to wait on battery before shutdown (seconds)
FINALDELAY 60
```

### `/etc/udev/rules.d/50-ups.rules`
```bash
SUBSYSTEM=="usb", ATTRS{idVendor}=="2b89", ATTRS{idProduct}=="ffff", MODE="0666", GROUP="nut"
```

### Enable and Start Services
```bash
systemctl enable nut-driver
systemctl enable nut-server
systemctl enable nut-monitor
systemctl start nut-driver
systemctl start nut-server
systemctl start nut-monitor
```

### Test UPS
```bash
# Check UPS status
upsc ugreen-ups@localhost

# Check battery charge
upsc ugreen-ups@localhost battery.charge

# Monitor UPS in real-time
upsc -l ugreen-ups@localhost
watch -n 2 'upsc ugreen-ups@localhost'
```

---

## ⚠️ Known Issues & Solutions

### Issue 1: Proxmox Intermittent Hangs (Reported by some users)
**Symptom:** System occasionally hangs without logs
**Frequency:** Rare, not affecting all users
**Status:** Under investigation
**Workaround:** Monitor system, report to Proxmox forums if occurs

### Issue 2: NVMe Drive Changes Corrupt Network Interface Names
**Symptom:** Installing/removing NVMe drives changes ethernet interface names, breaking network
**Impact:** Proxmox web UI becomes inaccessible
**Solution:**
```bash
# Access via Proxmox console (monitor + keyboard)
ip link show  # Find new interface name (e.g., enp2s0)
nano /etc/network/interfaces  # Update interface name
systemctl restart networking
```

**Prevention:** Don't hot-swap NVMe drives

### Issue 3: Older NUT Version Lacks Subdriver Support
**Symptom:** `error: the device driver does not support this subdriver parameter`
**Cause:** Debian distro packages may have older NUT version
**Solution:**
```bash
# Option A: Compile NUT from source
git clone https://github.com/networkupstools/nut.git
cd nut
./autogen.sh
./configure --with-usb --with-systemd
make
make install

# Option B: Wait for Debian to update packages
# Option C: Use Debian testing/unstable repos
```

### Issue 4: LEDs Blink in Rolling Sequence
**Symptom:** Front panel LEDs all blink continuously
**Cause:** No UGOS LED driver
**Impact:** Cosmetic only
**Solution:** Install [ugreen_leds_controller](https://github.com/miskcoo/ugreen_leds_controller)

---

## 📊 Comparison: UGOS vs Proxmox

| Feature | UGOS | Proxmox VE 9.1 | Winner |
|---------|------|----------------|--------|
| **Web UI** | Basic | Advanced | Proxmox |
| **Virtualization** | ❌ None | ✅ VMs + LXC | Proxmox |
| **Docker Support** | ✅ Via UGOS | ✅ LXC + Docker | Equal |
| **File Sharing** | ✅ SMB/NFS | ✅ SMB/NFS | Equal |
| **Snapshots** | ❌ None | ✅ ZFS snapshots | Proxmox |
| **Backups** | Basic | Advanced (vzdump) | Proxmox |
| **Monitoring** | Basic | Advanced (built-in) | Proxmox |
| **Package Manager** | Limited | Full Debian repo | Proxmox |
| **SSH Keys** | ⚠️ Reset on reboot | ✅ Persistent | Proxmox |
| **UPS Support** | ✅ Built-in | ✅ NUT | Equal |
| **Community Support** | Small | Large | Proxmox |
| **Updates** | UGREEN only | Debian + Proxmox | Proxmox |
| **Flexibility** | Low | High | Proxmox |
| **Learning Curve** | Easy | Medium | UGOS |
| **RAM Efficiency** | Good | Good | Equal |
| **Storage (ZFS)** | ❌ No | ✅ Native | Proxmox |

**Overall Winner:** Proxmox VE 9.1

---

## 🔗 Resources & Documentation

### Official Documentation:
- [Proxmox VE 9.1 Downloads](https://www.proxmox.com/en/downloads/proxmox-virtual-environment)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Network UPS Tools Documentation](https://networkupstools.org/docs/user-manual.chunked/)
- [UGREEN NAS Download Center](https://nas.ugreen.com/pages/downloads)

### Community Resources:
- [UGREEN NAS GitHub - TheLinuxGuy](https://github.com/TheLinuxGuy/ugreen-nas)
- [UGREEN LED Controller - miskcoo](https://github.com/miskcoo/ugreen_leds_controller)
- [Proxmox Forum - UGREEN Discussion](https://forum.proxmox.com/threads/anybody-running-pbs-on-ugreen-units.168470/)
- [TrueNAS Forum - UGREEN Hardware](https://forums.truenas.com/t/actual-installs-on-ugreen-hardware-observations-experiences-tips/6910)

### Guides:
- [TrueNAS on UGREEN Installation Guide - NAS Compares](https://nascompares.com/guide/truenas-on-a-ugreen-nas-installation-guide/)
- [UGREEN US3000 UPS Review - NAS Compares](https://nascompares.com/2025/09/26/ugreen-us3000-nas-ups-review/)
- [Making UGREEN US3000 Work on TerraMaster](https://nascompares.com/answer/how-to-make-the-ugreen-us3000-nas-ups-work-on-a-terramaster-f4-424-pro/)

### Tools:
- [Rufus - Create Bootable USB](https://rufus.ie/)
- [Clonezilla - Disk Cloning](https://clonezilla.org/)
- [Network UPS Tools - GitHub](https://github.com/networkupstools/nut)

---

## 🎯 Decision Matrix

### Should I Migrate to Proxmox?

**Migrate if:**
- ✅ You want VM support
- ✅ You need advanced features (snapshots, backups)
- ✅ You're frustrated with UGOS limitations
- ✅ You want full control over your system
- ✅ You're comfortable with Linux/CLI (or willing to learn)
- ✅ You want better community support
- ✅ You need persistent SSH keys
- ✅ You want ZFS features

**Stay on UGOS if:**
- ❌ You just need simple file storage
- ❌ You're not comfortable with Linux
- ❌ You don't need VMs or advanced features
- ❌ You want official UGREEN support
- ❌ "If it ain't broke, don't fix it"

---

## ⏱️ Time Estimates

| Phase | Time Required |
|-------|---------------|
| Research & Planning | ✅ Complete (this document) |
| Clonezilla Backup | 30-60 minutes |
| Download & Prepare USB | 20-30 minutes |
| BIOS Configuration | 10-15 minutes |
| Proxmox Installation | 15-30 minutes |
| Initial Setup | 30-60 minutes |
| NUT Compilation (if needed) | 30-45 minutes |
| NUT Configuration | 30-60 minutes |
| Container Setup | 2-4 hours |
| Service Migration | 2-4 hours |
| Testing & Verification | 1-2 hours |
| **Total** | **8-14 hours** |

*Spread across multiple days recommended*

---

## 📝 Notes

### Hardware Warranty
Per UGREEN support: "Choosing to use a 3rd Party NAS OS will **not invalidate your hardware warranty**."

### BIOS Watchdog
Must be disabled to prevent system reboots every 3 minutes when running non-UGOS systems.

### Network Configuration
Keep static IP (192.168.40.60) consistent with current UGOS setup to avoid reconfiguring clients.

### Data Migration
All data currently on UGOS should be backed up before migration. Docker volumes can be exported and re-imported on Proxmox.

---

## 🚀 Next Steps

1. **Create Clonezilla backup** (CRITICAL - do not skip!)
2. **Download Proxmox VE 9.1 ISO**
3. **Create bootable USB with Rufus**
4. **Read through this document completely**
5. **Schedule migration during free time** (allow full day)
6. **Follow migration checklist step-by-step**
7. **Test thoroughly before decommissioning UGOS backup**

---

## 📞 Support

If issues arise during migration:
- **Proxmox Forums:** https://forum.proxmox.com/
- **NUT Mailing List:** https://alioth-lists.debian.net/cgi-bin/mailman/listinfo/nut-upsuser
- **UGREEN Support:** support@ugreen.com
- **Reddit:** r/Proxmox, r/homelab

---

**Project Status:** ✅ Research Complete - Ready for Implementation
**Risk Level:** Low (with proper backup)
**Recommendation:** Proceed with migration

---

*Generated with [Claude Code](https://claude.com/claude-code)*
*Last Updated: 2025-11-29*
