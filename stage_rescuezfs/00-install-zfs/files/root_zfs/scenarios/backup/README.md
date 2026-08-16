
## Backup/Replace whole root pool

### Disable Services
Disable all services mutating important data
on the old pool while performing back-and-forth backup.
- systemctl stop fetchmail
- systemctl stop sendmail
- systemctl stop dovecot
- systemctl disable fetchmail
- systemctl disable sendmail
- systemctl disable dovecot
- systemctl status dovecot
- systemctl status sendmail
- systemctl status fetchmail

### Order
- Boot into old pool
  - Disable services (see above)
  - new_gpt_efi_disk.single.sh
  - new_backup_pool.sh
  - zsync-pool2backuppool.sh
  - GRUB UPDATE
- Boot into backup-pool
  - new_gpt_efi_disk.pool.sh
  - new_full_zpool.sh
  - destroy_named_snapshots.sh backupsax backup2
  - zsync-backuppool2pool.sh
  - GRUB UPDATE

