#       21474836480 # 0x500000000 (20 GB)
#       17179869184 # 0x400000000 (16 GB)
#       12884901888 # 0x300000000 (12 GB)
#        8589934592 # 0x200000000 ( 8 GB)
#        6442450944 # 0x180000000 ( 6 GB)
#        5368709120 # 0x140000000 ( 5 GB)
#        4294967296 # 0x100000000 ( 4 GB)
#        1073741824 # 0x040000000 ( 1 GB)
#         536870912 # 0x020000000 (.5 GB)

#  4294967296 # 0x100000000 ( 4 GB)
echo options zfs zfs_arc_max=4294967296 >> /etc/modprobe.d/zfs.conf
echo zfs zfs_arc_max=4294967296 >> /etc/initramfs-tools/modules
#echo zfs zfs_arc_max=4294967296 >> /etc/modules

#  5368709120 # 0x140000000 ( 5 GB)
echo options zfs zfs_arc_max=4294967296 >> /etc/modprobe.d/zfs.conf
echo zfs zfs_arc_max=4294967296 >> /etc/initramfs-tools/modules
#echo zfs zfs_arc_max=4294967296 >> /etc/modules

# 17179869184 # 0x400000000 (16 GB)
echo options zfs zfs_arc_max=17179869184 >> /etc/modprobe.d/zfs.conf
echo zfs zfs_arc_max=17179869184 >> /etc/initramfs-tools/modules
#echo zfs zfs_arc_max=17179869184 >> /etc/modules

