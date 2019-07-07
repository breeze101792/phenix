
export JOBS=$(nproc --all)
export ROOT_PATH=${PWD}
export KERNEL_PATH=${ROOT_PATH}/linux
export LAB_PATH=${ROOT_PATH}/lab
export ROOTFS_PATH=${ROOT_PATH}/rootfs
fPrintHeader()
{
    local msg=${1}
    echo "##############################################"
    echo "##############################################"
    echo "## ${msg} "
    echo "##############################################"
    echo "##############################################"
}
fSetupEnv()
{
    if [ ! -d ${LAB_PATH} ]
    then
        mkdir ${LAB_PATH}
    fi
}
fDownloadLinux()
{
    cd ${ROOT_PATH}
    fPrintHeader "Download Linux srouce code"
    if [ -d ${KERNEL_PATH} ]
    then
        echo "Skip Linux kernel download."
    else
        git clone https://github.com/torvalds/linux.git
    fi
}
fBuildLinux()
{
    fPrintHeader "Building Linux Kernel"
    cd ${KERNEL_PATH}

    # you can get a list of predefined configs for ARM under arch/arm/configs/
    # this configures the kernel compilation parameters
    # make ARCH=arm versatile_defconfig
    make ARCH=arm vexpress_defconfig

    # menuconfig
    # make ARCH=arm CROSS_COMPILE=arm-none-eabi- menuconfig -j ${JOBS}

    # this compiles the kernel, add "-j <number_of_cpus>" to it to use multiple CPUs to reduce build time
    make ARCH=arm CROSS_COMPILE=arm-none-eabi- all -j ${JOBS}
    # self decompressing gzip image on arch/arm/boot/zImage and arch/arm/boot/Image is the decompressed image.
    # update files
    cp -f ${KERNEL_PATH}/arch/arm/boot/zImage ${LAB_PATH}
    # cp -f ${KERNEL_PATH}/arch/arm/boot/dts/versatile-pb.dtb ${LAB_PATH}/device_tree.dtb
    cp -f ${KERNEL_PATH}/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${LAB_PATH}/device_tree.dtb
}
fBuildRootfs()
{
    fPrintHeader "Build rootfs"
    cd ${ROOTFS_PATH}
    # arm-unknown-linux-uclibcgnueabi-gcc -static -march=armv5te -mtune=xscale -Wa,-mcpu=xscale main.c -o init
    # arm-linux-gnueabi-gcc -marm -march=armv5 -O0 -static -o init init.c
    arm-linux-gnueabihf-gcc -marm -O0 -static -o init init.c
    chmod +x init
    # echo init | cpio -o --format=newc | gzip  > initramfs
    echo init | cpio -o --format=newc  > initramfs
    # cpio -o -H newc | gzip > ../versatile-initrd
    cp -f initramfs ${LAB_PATH}
}
fRunQemu()
{
    cd ${LAB_PATH}
    # qemu-system-arm -M versatilepb -kernel ./zImage -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug"
    # qemu-system-arm -M versatilepb -kernel ./zImage -dtb versatile-pb.dtb -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug"
    # qemu-system-arm -M versatilepb -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug" -m 128M
    # qemu-system-arm -M vexpress-a9 -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug console=ttyAMA0" -m 128M
    qemu-system-arm -M vexpress-a9 -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug console=ttyAMA0" -m 128M
}
while true
do
    case $1 in
        -r|--rebuild)
            fBuildLinux
            fBuildRootfs
            fRunQemu
            exit 0
            ;;
        -a|--all)
            fSetupEnv
            fDownloadLinux
            fBuildLinux
            fBuildRootfs
            exit 0
            ;;
        -q|--qemu)
            fRunQemu
            exit 0
            ;;
        -h|--help)
            echo Help function
            exit 0
            ;;
        *)
            break;
            ;;
    esac
done


