mkdir ~/sda2 || echo already have sda2
umount ~/sda2 || echo not mounted
mount /dev/sda2 ~/sda2
cp ~/sda2/android-2024-07-15/initrd_a.img.bkp ~/sda2/android-2024-07-15/initrd_real.img
find * | cpio -o -H newc | gzip -9 > ~/sda2/android-2024-07-15/initrd_a.img