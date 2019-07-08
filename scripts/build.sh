#!/bin/bash
##############################################
## Vars
##############################################
export JOBS=$(nproc --all)
export FLAG_FIRSTBUILD=false
export SYSTEM_CC_PREFIX=arm-linux-gnueabihf-
export BAREMETAL_CC_PREFIX=arm-none-eabi-
##############################################
## Alias
##############################################
alias make="make -j ${JOBS} "
##############################################
## Path
##############################################
export ROOT_PATH=${PWD}
export KERNEL_PATH=${ROOT_PATH}/linux
export BUSYBOX_PATH=${ROOT_PATH}/busybox
export BUILD_PATH=${ROOT_PATH}/build
export ROOTFS_PATH=${ROOT_PATH}/rootfs
##############################################
## Functions
##############################################
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
    if [ ! -d ${BUILD_PATH} ]
    then
        mkdir ${BUILD_PATH}
    fi
    if [ ! -d ${BUILD_PATH}/rootfs ]
    then
        mkdir ${BUILD_PATH}/rootfs
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
fDownloadBusybox()
{
    cd ${ROOTFS_PATH}
    fPrintHeader "Download Busybox"
    if [ -d ${KERNEL_PATH} ]
    then
        echo "Skip Busybox download."
    else
        git clone https://github.com/mirror/busybox.git
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

    if [ ${FLAG_FIRSTBUILD} = true ]
    then
        # menuconfig
        make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} menuconfig
    fi

    # this compiles the kernel, add "-j <number_of_cpus>" to it to use multiple CPUs to reduce build time
    make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} all
    # self decompressing gzip image on arch/arm/boot/zImage and arch/arm/boot/Image is the decompressed image.
    # update files
    cp -f ${KERNEL_PATH}/arch/arm/boot/zImage ${BUILD_PATH}/
    # cp -f ${KERNEL_PATH}/arch/arm/boot/dts/versatile-pb.dtb ${BUILD_PATH}/device_tree.dtb
    cp -f ${KERNEL_PATH}/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${BUILD_PATH}/device_tree.dtb
}
fBuildBusybox()
{
    fPrintHeader "Building busybox"
    cd ${BUSYBOX_PATH}
    if [ ${FLAG_FIRSTBUILD} = true ]
    then
        make ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} defconfig
        make ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} menuconfig
    fi
    make ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} install
    cp -rf ${BUSYBOX_PATH}/_install/* ${BUILD_PATH}/rootfs/
}
fBuildRootfs()
{
    fPrintHeader "Build rootfs"
    if false
    then
        cd ${ROOTFS_PATH}
        ${SYSTEM_CC_PREFIX}gcc -marm -O0 -static -o init init.c
        chmod +x init
        echo init | cpio -o --format=newc | gzip  > initramfs
        cp -f initramfs ${BUILD_PATH}/
    else
        fBuildBusybox
        cd ${BUILD_PATH}/rootfs
        cp -rf ${ROOTFS_PATH}/* ${BUILD_PATH}/rootfs
        find . | cpio -o -H newc | gzip > ${BUILD_PATH}/initramfs
        # cp -f initramfs ${BUILD_PATH}/
    fi
}
fRunQemu()
{
    fPrintHeader "Run Qemu"
    cd ${BUILD_PATH}
    # qemu-system-arm -M vexpress-a9 -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug console=ttyAMA0 rdinit=/bin/sh" -m 128M
    qemu-system-arm -M vexpress-a9 -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug console=ttyAMA0 rdinit=/sbin/init" -m 128M
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
            fRunQemu
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

