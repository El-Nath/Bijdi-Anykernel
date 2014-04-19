#!/sbin/sh

# copy old kernel to sdcard
if [ ! -e /sdcard/bj_zImage ]; then
	cp /tmp/boot.img-zImage /sdcard/bj_zImage
fi

# decompress ramdisk
mkdir /tmp/ramdisk
cd /tmp/ramdisk
gunzip -c ../boot.img-ramdisk.gz | cpio -i

# add init.d support if not already supported
found=$(find init.rc -type f | xargs grep -oh "run-parts /system/etc/init.d");
if [ "$found" != 'run-parts /system/etc/init.d' ]; then
        #find busybox in /system
        bblocation=$(find /system/ -name 'busybox')
        if [ -n "$bblocation" ] && [ -e "$bblocation" ] ; then
                echo "BUSYBOX FOUND!";
                #strip possible leading '.'
                bblocation=${bblocation#.};
        else
                echo "NO BUSYBOX NOT FOUND! init.d support will not work without busybox!";
                echo "Setting busybox location to /system/xbin/busybox! (install it and init.d will work)";
                #set default location since we couldn't find busybox
                bblocation="/system/xbin/busybox";
        fi
		#append the new lines for this option at the bottom
        echo "" >> init.rc
        echo "service userinit $bblocation run-parts /system/etc/init.d" >> init.rc
        echo "    oneshot" >> init.rc
        echo "    class late_start" >> init.rc
        echo "    user root" >> init.rc
        echo "    group root" >> init.rc
fi
# append ak boot at the end of init.rc
if grep -q ak-post-boot init.rc; then
        echo "Found AK kernel settings into ramdisk, nothing to do";
else
        sed 's/system\/xbin.*/system\/xbin:\/data\/ak/' -i init.environ.rc
        echo "" >> init.rc
        echo "service ak-post-boot /data/ak/ak-post-boot.sh" >> init.rc
        echo "    class core" >> init.rc
        echo "    user root" >> init.rc
        echo "    oneshot" >> init.rc
fi

# move synapse files
rm -rf res/synapse
mkdir res/synapse
chmod 755 res/synapse
cp -vr ../extras/synapse/* res/synapse

find . | cpio -o -H newc | gzip > ../newramdisk.cpio.gz
cd /
