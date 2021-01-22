#!/bin/bash
###########################################################
## Vars
###########################################################
export JOBS=$(nproc --all)
export FLAG_GRAPHIC=false
export BUILD_PREFIX=""

###########################################################
## Options
###########################################################
# Default
export VARS_ARCH=""
export VARS_KERNEL_CONFIG=""
export SYSTEM_CC_PREFIX=""
export BAREMETAL_CC_PREFIX=""
export PATH_TOOLCHAIN_LIBC=""
# arm 64
# export PATH=/mnt/storage/workspace/tools/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin:$PATH
# export VARS_ARCH=arm64
# export VARS_KERNEL_CONFIG=defconfig
# export SYSTEM_CC_PREFIX=aarch64-linux-gnu-
# export BAREMETAL_CC_PREFIX=aarch64-linux-gnu-
# export PATH_TOOLCHAIN_LIBC=/mnt/storage/workspace/tools/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/aarch64-linux-gnu/libc
# arm
# export VARS_ARCH=arm
# export VARS_KERNEL_CONFIG=vexpress_defconfig
# export SYSTEM_CC_PREFIX=arm-linux-gnueabihf-
# export BAREMETAL_CC_PREFIX=arm-none-eabi-
# export PATH_TOOLCHAIN_LIBC=""
###########################################################
## Options
###########################################################
export OPTION_DOWNLOAD_KERNEL=false
export OPTION_DOWNLOAD_ROOTFS=false
export OPTION_DOWNLOAD_UBOOT=false
export OPTION_BUILD_KERNEL=false
export OPTION_BUILD_ROOTFS=false
export OPTION_BUILD_UBOOT=false
export OPTION_RUN_EMULATION=false
export OPTION_RUN_GDB=false

export OPTION_ARCH=arm64
export OPTION_COPY_CONFIG=false
export OPTION_CLEAN_BUILD=false
export OPTION_ENABLE_MENUCONFIG=false
###########################################################
## Path
###########################################################
export ROOT_PATH=${PWD}
export UBOOT_PATH=${ROOT_PATH}/u-boot
export KERNEL_PATH=${ROOT_PATH}/linux
export BUSYBOX_PATH=${ROOT_PATH}/busybox
# will be Seted latter
export BUILD_PATH=""
export ROOTFS_PATH=""
###########################################################
## Functions
###########################################################
fPrintHeader()
{
    local msg=${1}
    echo "###########################################################"
    echo "###########################################################"
    echo "## ${msg} "
    echo "###########################################################"
    echo "###########################################################"
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
    echo "phenix"
    echo "Example:"
    echo "run arm64: phenix.sh -a"
    echo "run arm: phenix.sh -a --arch arm"
    echo "[Options]"
    printf "    %s\t%s\n" "-b|--build" "Do build"
    printf "    %s\t%s\n" "-a|--all" "Do all"
    printf "    %s\t%s\n" "-u|--uboot" "Compile uboot"
    printf "    %s\t%s\n" "-l|--linux" "Compile linux"
    printf "    %s\t%s\n" "-r|--rootfs" "Compile rootfs"
    printf "    %s\t%s\n" "-q|--qemu" "Run with qemu"
    printf "    %s\t%s\n" "-d|--debug" "enable debug"
    printf "    %s\t%s\n" "--download-all" "Download all"
    echo [Config]
    printf "    %s\t%s\n" "-j|--job" "Jobs Thread"
    printf "    %s\t%s\n" "--copy-config" "Copy config"

}
fInfo()
{
    printf "###########################################################\n"
    printf "## Options\n"
    printf "###########################################################\n"
    printf "##  %s\t: %s\n" "Arch" "${VARS_ARCH}"
    printf "##  %s\t: %s\n" "BUILD_PATH" "${BUILD_PATH}"
    printf "##  %s\t: %s\n" "ROOTFS_PATH" "${ROOTFS_PATH}"
    printf "###########################################################\n"

}
fSetupEnv()
{
    BUILD_PATH=${ROOT_PATH}/build/${VARS_ARCH}
    ROOTFS_PATH=${BUILD_PATH}/rootfs

    if [ ! -d ${BUILD_PATH} ]
    then
        mkdir -p ${BUILD_PATH}
    fi
    if [ ! -d ${BUILD_PATH}/rootfs ]
    then
        mkdir -p ${BUILD_PATH}/rootfs
    fi
    cd ${BUILD_PATH}
    if [ ! -f disk.img ]
    then
        qemu-img create -f qcow2 disk.img 4G
    fi
}
fSelectArch()
{
    local arch=$1
    case ${arch} in
        arm|arm32)
            echo "ARM 32"
            VARS_ARCH=arm
            VARS_KERNEL_CONFIG=vexpress_defconfig
            SYSTEM_CC_PREFIX=arm-linux-gnueabihf-
            BAREMETAL_CC_PREFIX=arm-none-eabi-
            ;;
        arm64)
            echo "ARM 64"
            export PATH=/mnt/storage/workspace/tools/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin:$PATH
            VARS_ARCH=arm64
            VARS_KERNEL_CONFIG=defconfig
            SYSTEM_CC_PREFIX=aarch64-linux-gnu-
            BAREMETAL_CC_PREFIX=aarch64-linux-gnu-
            ;;
    esac
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
    if [ "${VARS_ARCH}" = "arm" ]
    then
        make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} vexpress_ca9x4_defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
        ${BUILD_PREFIX} make ARCH=arm CROSS_COMPILE=${BAREMETAL_CC_PREFIX} -j ${JOBS}; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp ${UBOOT_PATH}/u-boot ${BUILD_PATH}/zImage; fErrControl ${FUNCNAME[0]} ${LINENO}
    else
        echo Uboot not support in ${VARS_ARCH}
    fi
}
fBuildLinux()
{
    fPrintHeader "Building Linux Kernel"
    cd ${KERNEL_PATH}

    if [ ${OPTION_COPY_CONFIG} = true ]
    then
        # you can get a list of predefined configs for ARM under arch/arm/configs/
        # this configures the kernel compilation parameters
        # make ARCH=arm versatile_defconfig
        make ARCH=${VARS_ARCH} ${VARS_KERNEL_CONFIG}; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    if [ ${OPTION_ENABLE_MENUCONFIG} = true ]
    then
        # menuconfig
        make ARCH=${VARS_ARCH} CROSS_COMPILE=${BAREMETAL_CC_PREFIX} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    # this compiles the kernel, add "-j <number_of_cpus>" to it to use multiple CPUs to reduce build time
    if [ ${OPTION_CLEAN_BUILD} = true ]
    then
        ${BUILD_PREFIX} make -j ${JOBS} ARCH=${VARS_ARCH} CROSS_COMPILE=${BAREMETAL_CC_PREFIX} clean; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    ${BUILD_PREFIX} make -j ${JOBS} ARCH=${VARS_ARCH} CROSS_COMPILE=${BAREMETAL_CC_PREFIX} all; fErrControl ${FUNCNAME[0]} ${LINENO}
    ${BUILD_PREFIX} make modules_install INSTALL_MOD_PATH=${ROOTFS_PATH} ARCH=${VARS_ARCH}
    # self decompressing gzip image on arch/arm/boot/zImage and arch/arm/boot/Image is the decompressed image.
    # update files
    if [ ${VARS_ARCH} = "arm" ]
    then
        cp -f ${KERNEL_PATH}/arch/arm/boot/Image ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp -f ${KERNEL_PATH}/arch/arm/boot/zImage ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
        # cp -f ${KERNEL_PATH}/arch/arm/boot/uImage ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
        # cp -f ${KERNEL_PATH}/arch/arm/boot/dts/versatile-pb.dtb ${BUILD_PATH}/device_tree.dtb
        cp -f ${KERNEL_PATH}/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${BUILD_PATH}/device_tree.dtb; fErrControl ${FUNCNAME[0]} ${LINENO}
    elif [ ${VARS_ARCH} = "arm64" ]
    then
        cp -f ${KERNEL_PATH}/arch/arm64/boot/Image ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
}
fBuildBusybox()
{
    fPrintHeader "Building busybox"
    cd ${BUSYBOX_PATH}
    if [ ${OPTION_COPY_CONFIG} = true ]
    then
        make ARCH=${VARS_ARCH} CROSS_COMPILE=${SYSTEM_CC_PREFIX} defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}

        # patch for static library
        # FIXME 
        echo "Please do Busybox Settings –> Build Options. If you don't have libc library"
        echo "Patch for ARM"
        sed -i "s/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g" .config
    fi

    if [ ${OPTION_ENABLE_MENUCONFIG} = true ]
    then
        make ARCH=${VARS_ARCH} CROSS_COMPILE=${SYSTEM_CC_PREFIX} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    if [ ${OPTION_CLEAN_BUILD} = true ]
    then
        ${BUILD_PREFIX} make -j ${JOBS} ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} clean; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
    ${BUILD_PREFIX} make -j ${JOBS} ARCH=arm CROSS_COMPILE=${SYSTEM_CC_PREFIX} install; fErrControl ${FUNCNAME[0]} ${LINENO}
    cp -rf ${BUSYBOX_PATH}/_install/* ${BUILD_PATH}/rootfs/; fErrControl ${FUNCNAME[0]} ${LINENO}
}
fBuildRootfs_struct()
{
    fPrintHeader "Create root structure"
    mkdir -pv ${ROOTFS_PATH}/{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
    mkdir -pv ${ROOTFS_PATH}/{media/{floppy,cdrom},sbin,srv,var}
    install -dv -m 0750 ${ROOTFS_PATH}/root
    install -dv -m 1777 ${ROOTFS_PATH}/tmp /var/tmp
    mkdir -pv ${ROOTFS_PATH}/usr/{,local/}{bin,include,lib,sbin,src}
    mkdir -pv ${ROOTFS_PATH}/usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -v  ${ROOTFS_PATH}/usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -v  ${ROOTFS_PATH}/usr/libexec
    mkdir -pv ${ROOTFS_PATH}/usr/{,local/}share/man/man{1..8}

    # case $(uname -m) in
    #  x86_64) ln -sv lib /lib64
    #          ln -sv lib /usr/lib64
    #          ln -sv lib /usr/local/lib64 ;;
    # esac

    mkdir -v ${ROOTFS_PATH}/var/{log,mail,spool}
    ln -sv /run ${ROOTFS_PATH}/var/run
    ln -sv /run/lock ${ROOTFS_PATH}/var/lock
    mkdir -pv ${ROOTFS_PATH}/var/{opt,cache,lib/{color,misc,locate},local}

    touch /var/log/{btmp,lastlog,wtmp}
}
fBuildRootfs_libc()
{
    if [ "${PATH_TOOLCHAIN_LIBC}" != "" ] && [ -d "${PATH_TOOLCHAIN_LIBC}" ]
    then
        cp -rf ${PATH_TOOLCHAIN_LIBC}/* ${ROOTFS_PATH}; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
}
fBuildRootfs()
{
    fPrintHeader "Build rootfs"
    local rootfs_type="busybox"
    if [ "${rootfs_type}" = "tiny" ]
    then
        cd ${ROOT_PATH}/init
        ${SYSTEM_CC_PREFIX}gcc -marm -O0 -static -o init init.c; fErrControl ${FUNCNAME[0]} ${LINENO}
        chmod +x init; fErrControl ${FUNCNAME[0]} ${LINENO}
        echo init | cpio -o --format=newc | gzip  > initramfs; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp -f initramfs ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    elif [ "${rootfs_type}" = "busybox" ]
    then
        fBuildRootfs_struct
        fBuildBusybox
        fBuildRootfs_libc
        cd ${ROOTFS_PATH}
        cp -rf ${ROOT_PATH}/rootfs/* ${ROOTFS_PATH}; fErrControl ${FUNCNAME[0]} ${LINENO}
        find . | fakeroot cpio -o -H newc | gzip > ${BUILD_PATH}/initramfs; fErrControl ${FUNCNAME[0]} ${LINENO}
        # fakeroot "find . | cpio -o -H newc | gzip > ${BUILD_PATH}/initramfs"; fErrControl ${FUNCNAME[0]} ${LINENO}
        # cp -f initramfs ${BUILD_PATH}/
    fi
}
fRunGDB()
{
    case $1 in
        kernel)
            # kernel dbg
            cd ${KERNEL_PATH}
            arm-linux-gnueabihf-gdb vmlinux; fErrControl ${FUNCNAME[0]} ${LINENO}
            # connect to target with gdb
            # target remote localhost:9000
            ;;
        busybox)
            cd ${BUSYBOX_PATH}
            arm-linux-gnueabihf-gdb busybox_unstripped; fErrControl ${FUNCNAME[0]} ${LINENO}
            ;;
        *)
            echo "Wrong target $1"
            ;;
    esac

}
fRunEmulation()
{
    if [ "${VARS_ARCH}" = "arm" ]
    then
        fPrintHeader "Run Qemu arm"
        cd ${BUILD_PATH}
        local kernel_command="ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug console=ttyAMA0 "
        kernel_command+="rdinit=/sbin/init"

        local qemu_cmd=(qemu-system-arm )
        qemu_cmd+=(-machine vexpress-a9)
        qemu_cmd+=(-kernel ./zImage)
        qemu_cmd+=(-dtb device_tree.dtb)
        qemu_cmd+=(-nographic)
        qemu_cmd+=(-m 128M)
        qemu_cmd+=(-initrd ./initramfs)

        qemu_cmd+=(-s)
        qemu_cmd+=(-hda disk.img)
        # qemu_cmd+=(-device e1000,netdev=eth0)
        # qemu_cmd+=(-s -S)
    elif [ "${VARS_ARCH}" = "arm64" ]
    then
        fPrintHeader "Run Qemu arm64"
        cd ${BUILD_PATH}
        local kernel_command="console=ttyAMA0 root=/dev/vda oops=panic panic_on_warn=1 panic=-1 ftrace_dump_on_oops=orig_cpu debug earlyprintk=serial slub_debug=UZ "
        kernel_command+="rdinit=/sbin/init"

        local qemu_cmd=(qemu-system-aarch64)
        qemu_cmd+=(-machine virt)
        qemu_cmd+=(-cpu cortex-a57)
        qemu_cmd+=(-nographic)
        qemu_cmd+=(-smp 1)
        qemu_cmd+=(-initrd ./initramfs)
        # qemu_cmd+=(-kernel ../linux/arch/arm64/boot/Image)
        qemu_cmd+=(-kernel ./Image)
        qemu_cmd+=(-m 2048)
        qemu_cmd+=(-net user,hostfwd=tcp::10023-:22 -net nic)

    fi
    echo "${qemu_cmd[@]} -append \"${kernel_command}\""
    eval "${qemu_cmd[@]} -append \"${kernel_command}\""
}
function fmain()
{
    while [[ $# != 0 ]]
    do
        case $1 in
            --arch)
                OPTION_ARCH=$2
                shift 2
                ;;
            -m|--menuconfig)
                OPTION_ENABLE_MENUCONFIG=true
                shift 1
                ;;
            --copy-config)
                OPTION_COPY_CONFIG=true
                shift 1
                ;;
            -b|--build)
                OPTION_BUILD_KERNEL=true
                OPTION_BUILD_ROOTFS=true
                OPTION_RUN_EMULATION=true
                shift 1
                ;;
            --download-all)
                OPTION_DOWNLOAD_KERNEL=true
                OPTION_DOWNLOAD_ROOTFS=true
                OPTION_DOWNLOAD_UBOOT=true
                shift 1
                ;;
            -a|--all)
                OPTION_COPY_CONFIG=true

                OPTION_DOWNLOAD_KERNEL=true
                OPTION_DOWNLOAD_ROOTFS=true
                # OPTION_DOWNLOAD_UBOOT=true

                # OPTION_BUILD_UBOOT=true
                OPTION_BUILD_KERNEL=true
                OPTION_BUILD_ROOTFS=true

                OPTION_RUN_EMULATION=true
                shift 1
                ;;
            -u|--uboot)
                OPTION_BUILD_UBOOT=true
                shift 1
                ;;
            -l|--linux)
                OPTION_BUILD_KERNEL=true
                shift 1
                ;;
            -r|--rootfs)
                OPTION_BUILD_ROOTFS=true
                shift 1
                ;;
            -c|--clean)
                OPTION_CLEAN_BUILD=true
                shift 1
                ;;
            -q|--qemu)
                OPTION_RUN_EMULATION=true
                shift 1
                ;;
            -d|--debug)
                OPTION_RUN_GDB=true
                DEBUG_TARGET=$2
                shift 2
                ;;
            -j|--job)
                JOBS=$2
                shift 2
                ;;
            --build-prefix)
                BUILD_PREFIX=$2
                shift 2
                ;;
            -h|--help)
                fHelp
                exit 0
                ;;
            *)
                echo "Unknown Options: ${1}"
                fHelp
                exit 1
                ;;
        esac
    done

    # Preset
    fSelectArch ${OPTION_ARCH}

    # Post settings
    fSetupEnv

    fInfo

    ## Download
    if [ ${OPTION_DOWNLOAD_KERNEL} = true ]
    then
        fDownloadUBoot
    fi
    if [ ${OPTION_DOWNLOAD_ROOTFS} = true ]
    then
        fDownloadLinux
    fi
    if [ ${OPTION_DOWNLOAD_UBOOT} = true ]
    then
        fDownloadBusybox
    fi

    ## build
    if [ ${OPTION_BUILD_UBOOT} = true ]
    then
        fBuildUBoot
    fi
    if [ ${OPTION_BUILD_KERNEL} = true ]
    then
        fBuildLinux
    fi
    if [ ${OPTION_BUILD_ROOTFS} = true ]
    then
        fBuildRootfs
    fi
    if [ ${OPTION_RUN_EMULATION} = true ]
    then
        fRunEmulation
    fi
    if [ ${OPTION_RUN_GDB} = true ]
    then
        fRunGDB ${DEBUG_TARGET}
    fi
}

fmain $@
