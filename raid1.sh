###SETUP SOFTWARE RAID1###

#work as root
sudo -i

####create partitions

#https://unix.stackexchange.com/questions/29078/how-to-partition-22tb-disk


parted /dev/sda mklabel gpt
parted -a optimal -- /dev/sda mkpart primary xfs 1 -1

parted /dev/sdb mklabel gpt
parted -a optimal -- /dev/sdb mkpart primary xfs 1 -1
#https://unix.stackexchange.com/questions/411286/linux-raid-disappears-after-reboot


####set up raid1

#https://www.xmodulo.com/create-software-raid1-array-mdadm-linux.html

#create raid1
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

#format raid1
mkfs.ext4 /dev/md0

#mount array
mkdir /mnt/20TB_raid1
mount /dev/md0 /mnt/20TB_raid1

#check
ls -l /dev/disk/by-uuid

lrwxrwxrwx 1 root root 15 Apr 20 10:10 3216-FCBC -> ../../nvme1n1p1
lrwxrwxrwx 1 root root 15 Apr 20 10:10 b7a34390-7c4f-4c1c-b8a4-187a1fde8771 -> ../../nvme1n1p3
lrwxrwxrwx 1 root root 15 Apr 20 10:10 efde0231-5ebe-4a51-971a-fabe6ec109fe -> ../../nvme1n1p2
lrwxrwxrwx 1 root root 15 Apr 20 10:10 f63718c6-1f37-4530-9684-8a2c61a68f89 -> ../../nvme0n1p1
lrwxrwxrwx 1 root root  9 Apr 21 09:05 fefe082c-5eb3-438d-a5ba-54f15e66dea8 -> ../../md0


#add to /etc/fstab
nano /etc/fstab
#append following line
UUID=fefe082c-5eb3-438d-a5ba-54f15e66dea8 /mnt/20TB_raid1 ext4 auto,rw,x-gvfs-show,x-gvfs-name=20TB_raid1 0 0

#change ownership
sudo chown niek:niek /mnt/20TB_raid1





