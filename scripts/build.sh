#!/bin/bash
##############################################
## Vars
##############################################
export JOBS=$(nproc --all)
export FLAG_FIRSTBUILD=false
export FLAG_GRAPHIC=false
export SYSTEM_CC_PREFIX=arm-linux-gnueabihf-
export BAREMETAL_CC_PREFIX=arm-none-eabi-

export OPTION_BUILD_ALL=false
export OPTION_BUILD_KERNEL=false
export OPTION_BUILD_ROOTFS=false
export OPTION_BUILD_UBOOT=false
export OPTION_RUN_EMULATION=false
##############################################
## Path
##############################################
export ROOT_PATH=${PWD}
export UBOOT_PATH=${ROOT_PATH}/u-boot
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
fErrControl()
{
    local ret_var=$?
    local func_name=${1}
    local line_num=${2}
    if [[ ${ret_var} == 0 ]]
    then
        return ${ret_var}
    else
        echo ${func_name} ${line_num}
        exit ${ret_var}
    fi
}
fHelp()
{
    fPrintHeader "Help"
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
fDownloadUBoot()
{
    cd ${ROOT_PATH}
    fPrintHeader "Download UBoot srouce code"
    if [ -d ${UBOOT_PATH} ]
    then
        echo "Skip UBoot download."
    else
        git clone https://github.com/u-boot/u-boot.git; fErrControl ${FUNCNAME[0]} ${LINENO}
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
        git clone https://github.com/torvalds/linux.git; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
}
fDownloadBusybox()
{
    fPrintHeader "Download Busybox"
    cd ${ROOT_PATH}
    if [ -d ${BUSYBOX_PATH} ]
    then
        echo "Skip Busybox download."
    else
        git clone https://github.com/mirror/busybox.git; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
}
fBuildUBoot()
{
    fPrintHeader "Building U-Boot"
    cd ${UBOOT_PATH}
    make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} vexpress_ca9x4_defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} -j ${JOBS}; fErrControl ${FUNCNAME[0]} ${LINENO}
    cp ${UBOOT_PATH}/u-boot ${BUILD_PATH}/zImage; fErrControl ${FUNCNAME[0]} ${LINENO}
}
fBuildLinux()
{
    fPrintHeader "Building Linux Kernel"
    cd ${KERNEL_PATH}

    if [ ${FLAG_FIRSTBUILD} = true ]
    then
        # you can get a list of predefined configs for ARM under arch/arm/configs/
        # this configures the kernel compilation parameters
        # make ARCH=arm versatile_defconfig
        make ARCH=arm vexpress_defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}

        # menuconfig
        make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    # this compiles the kernel, add "-j <number_of_cpus>" to it to use multiple CPUs to reduce build time
    make -j ${JOBS} ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} all; fErrControl ${FUNCNAME[0]} ${LINENO}
    # self decompressing gzip image on arch/arm/boot/zImage and arch/arm/boot/Image is the decompressed image.
    # update files
    cp -f ${KERNEL_PATH}/arch/arm/boot/zImage ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    # cp -f ${KERNEL_PATH}/arch/arm/boot/dts/versatile-pb.dtb ${BUILD_PATH}/device_tree.dtb
    cp -f ${KERNEL_PATH}/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${BUILD_PATH}/device_tree.dtb; fErrControl ${FUNCNAME[0]} ${LINENO}
}
fBuildBusybox()
{
    fPrintHeader "Building busybox"
    cd ${BUSYBOX_PATH}
    if [ ${FLAG_FIRSTBUILD} = true ]
    then
        make ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
        make ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
    make -j ${JOBS} ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} install; fErrControl ${FUNCNAME[0]} ${LINENO}
    cp -rf ${BUSYBOX_PATH}/_install/* ${BUILD_PATH}/rootfs/; fErrControl ${FUNCNAME[0]} ${LINENO}
}
fBuildRootfs()
{
    fPrintHeader "Build rootfs"
    if false
    then
        cd ${ROOTFS_PATH}
        ${SYSTEM_CC_PREFIX}gcc -marm -O0 -static -o init init.c; fErrControl ${FUNCNAME[0]} ${LINENO}
        chmod +x init; fErrControl ${FUNCNAME[0]} ${LINENO}
        echo init | cpio -o --format=newc | gzip  > initramfs; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp -f initramfs ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    else
        fBuildBusybox
        cd ${BUILD_PATH}/rootfs
        cp -rf ${ROOTFS_PATH}/* ${BUILD_PATH}/rootfs; fErrControl ${FUNCNAME[0]} ${LINENO}
        find . | cpio -o -H newc | gzip > ${BUILD_PATH}/initramfs; fErrControl ${FUNCNAME[0]} ${LINENO}
        # cp -f initramfs ${BUILD_PATH}/
    fi
}
fRunEmulation()
{
    fPrintHeader "Run Qemu"
    cd ${BUILD_PATH}
    if [ ${FLAG_GRAPHIC} = true ]
    then
        # graphic
        qemu-system-arm -M vexpress-a9 -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug rdinit=/sbin/init" -m 128M; fErrControl ${FUNCNAME[0]} ${LINENO}
    else
        qemu-system-arm -M vexpress-a9 -kernel ./zImage -dtb device_tree.dtb -initrd initramfs -nographic -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug console=ttyAMA0 rdinit=/sbin/init" -m 128M; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

}
while true
do
    case $1 in
        -r|--rebuild)
            OPTION_BUILD_KERNEL=true
            OPTION_BUILD_ROOTFS=true
            OPTION_RUN_EMULATION=true
            shift 1
            ;;
        -a|--all)
            FLAG_FIRSTBUILD=true
            OPTION_BUILD_ALL=true
            shift 1
            ;;
        -u|--uboot)
            OPTION_BUILD_UBOOT=true
            shift 1
            ;;
        -q|--qemu)
            OPTION_RUN_EMULATION=true
            shift 1
            ;;
        -h|--help)
            fHelp
            exit 0
            ;;
        *)
            break;
            ;;
    esac
done
fSetupEnv
if [ ${OPTION_BUILD_ALL} = true ]
then
    fDownloadUBoot
    fDownloadLinux
    fDownloadBusybox
    fBuildLinux
    fBuildRootfs
    fRunEmulation
    exit 0
fi
if [ ${OPTION_BUILD_KERNEL} = true ]
then
    fBuildLinux
fi
if [ ${OPTION_BUILD_ROOTFS} = true ]
then
    fBuildRootfs
fi
if [ ${OPTION_BUILD_UBOOT} = true ]
then
    fBuildUBoot
fi
if [ ${OPTION_RUN_EMULATION} = true ]
then
    fRunEmulation
fi
