
echo PRE
echo /sys/module/zfs/parameters/zfs_resilver_disable_defer 
cat /sys/module/zfs/parameters/zfs_resilver_disable_defer 

echo /sys/module/zfs/parameters/zfs_resilver_min_time_ms 
cat /sys/module/zfs/parameters/zfs_resilver_min_time_ms 

echo 1 >  /sys/module/zfs/parameters/zfs_resilver_disable_defer 
echo 5000 > /sys/module/zfs/parameters/zfs_resilver_min_time_ms 

echo POST
echo /sys/module/zfs/parameters/zfs_resilver_disable_defer 
cat /sys/module/zfs/parameters/zfs_resilver_disable_defer 

echo /sys/module/zfs/parameters/zfs_resilver_min_time_ms 
cat /sys/module/zfs/parameters/zfs_resilver_min_time_ms 

