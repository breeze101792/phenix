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
# download
export OPTION_DOWNLOAD_KERNEL=false
export OPTION_DOWNLOAD_ROOTFS=false
export OPTION_DOWNLOAD_UBOOT=false
# patch
export OPTION_PATCH_UBOOT=false
export OPTION_PATCH_LINUX=false
export OPTION_PATCH_BUSYBOX=false
# build
export OPTION_BUILD_CLEAN=false
export OPTION_BUILD_UBOOT=false
export OPTION_BUILD_KERNEL=false
export OPTION_BUILD_ROOTFS=false
export OPTION_BUILD_IMAGE=false
# run
export OPTION_RUN_EMULATION=false
export OPTION_RUN_GDB=false
# arch
export OPTION_ARCH=arm64 # arm/arm64
export OPTION_COPY_CONFIG=false
export OPTION_CLEAN_BUILD=false
export OPTION_ENABLE_MENUCONFIG=false
export OPTION_EMULATION_RUNTIME="disk" # kernel/uboot//disk
###########################################################
## Path
###########################################################
export ROOT_PATH=${PWD}
export UBOOT_PATH=${ROOT_PATH}/u-boot
export KERNEL_PATH=${ROOT_PATH}/linux
export BUSYBOX_PATH=${ROOT_PATH}/busybox

# will setup latter with arch select
export BUILD_PATH=""
export ROOTFS_PATH=""
export BOOTFS_PATH=""

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
    echo "Phenix: A tool for building and running Linux on QEMU"
    echo "[Example]"
    printf "    %s\n" "run arm(with uboot): phenix.sh -a"
    printf "    %s\n" "run arm64(without uboot): phenix.sh -a --arch arm64 -q kernel"
    echo "[Options]"
    printf "    %- 16s\t%s\n" "-a|--all" "Do all (download, patch, build, run)"
    printf "    %- 16s\t%s\n" "-s|--download-all" "Download all source code"
    printf "    %- 16s\t%s\n" "-P|--patch" "Patch all source code"
    printf "    %- 16s\t%s\n" "-b|--build" "Build all (uboot, linux, rootfs, image)"
    printf "    %- 16s\t%s\n" "-u|--uboot" "Compile uboot"
    printf "    %- 16s\t%s\n" "-l|--linux" "Compile linux"
    printf "    %- 16s\t%s\n" "-r|--rootfs" "Compile rootfs"
    printf "    %- 16s\t%s\n" "-i|--image" "Build disk image"
    printf "    %- 16s\t%s\n" "-q|--qemu" "Run with qemu, Accept: disk, kernel, uboot. default disk."
    printf "    %- 16s\t%s\n" "-d|--debug" "Enable gdb debug. target: kernel, busybox"
    printf "    %- 16s\t%s\n" "-h|--help" "Show this help message"
    echo [Config]
    printf "    %- 16s\t%s\n" "-c|--clean" "Do clean build (remove build folder)"
    printf "    %- 16s\t%s\n" "-m|--menuconfig" "Run menuconfig for kernel/busybox"
    printf "    %- 16s\t%s\n" "-j|--job" "Number of parallel jobs, default ${JOBS}"
    printf "    %- 16s\t%s\n" "--arch" "Select architecture. Accept: arm64, arm. Default ${OPTION_ARCH}"
    printf "    %- 16s\t%s\n" "--copy-config" "Copy default config file before build"
    printf "    %- 16s\t%s\n" "-p|--build-prefix" "Add prefix before compile command (e.g. 'sudo')"
}
fInfo()
{
    printf "###########################################################\n"
    printf "## Options\n"
    printf "###########################################################\n"
    printf "##  %s\t: %s\n" "Arch" "${VARS_ARCH}"
    printf "##  %s\t: %s\n" "BUILD_PATH" "${BUILD_PATH}"
    printf "##  %s\t: %s\n" "ROOTFS_PATH" "${ROOTFS_PATH}"
    printf "##  %s\t: %s\n" "BOOTFS_PATH" "${BOOTFS_PATH}"
    printf "###########################################################\n"

}
fSetupEnv()
{
    BUILD_PATH=${ROOT_PATH}/build/${VARS_ARCH}
    ROOTFS_PATH=${BUILD_PATH}/rootfs
    BOOTFS_PATH=${BUILD_PATH}/bootfs

    if [ ${OPTION_BUILD_CLEAN} = true ]
    then
        printf "Clean Output Folder :${BUILD_PATH}"
        rm -rf ${BUILD_PATH}
    fi

    if [ ! -d ${BUILD_PATH} ]
    then
        mkdir -p ${BUILD_PATH}
    fi
    if [ ! -d ${ROOTFS_PATH} ]
    then
        mkdir -p ${ROOTFS_PATH}
    fi
    if [ ! -d ${BOOTFS_PATH} ]
    then
        mkdir -p ${BOOTFS_PATH}
    fi
    cd ${BUILD_PATH}
    if [ ! -f data.img ]
    then
        # this is for data image.
        qemu-img create -f qcow2 data.img 4G
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
fPatchUBoot()
{
    fPrintHeader "Patching U-Boot"
    cd ${UBOOT_PATH}
}
fPatchLinux()
{
    fPrintHeader "Patching Linux Kernel"
    cd ${KERNEL_PATH}
}
fPatchBusybox()
{
    fPrintHeader "Patching busybox"
    cd ${BUSYBOX_PATH}
    if test -f "scripts/kconfig/lxdialog/check-lxdialog.sh"; then
        sed -i "s/^main() {}/int main() {}/g" scripts/kconfig/lxdialog/check-lxdialog.sh
    else
        echo "lxdialog not found."
    fi
}
fBuildUBoot()
{
    fPrintHeader "Building U-Boot"
    cd ${UBOOT_PATH}
    if [ ${OPTION_BUILD_CLEAN} = true ]
    then
        make clean
    fi
    if [ "${VARS_ARCH}" = "arm" ]
    then
        if [ ${OPTION_COPY_CONFIG} = true ] || ! test -f .config; then
            echo "Do defconfig"
            ${BUILD_PREFIX} make ARCH=${VARS_ARCH} CROSS_COMPILE=${BAREMETAL_CC_PREFIX} vexpress_ca9x4_defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
        fi
        ## Patch for bootcmd
        ###########################################################
        sed -i "s/run distro_bootcmd; run bootflash/load mmc 0:1 0x60008000 zImage;load mmc 0:1 0x61000000 device_tree.dtb;bootz 0x60008000 - 0x61000000/g" .config
        sed -i "s/# CONFIG_USE_BOOTARGS is not set/CONFIG_USE_BOOTARGS=y/g" .config
        sed -i "s/CONFIG_USE_BOOTARGS=n/CONFIG_USE_BOOTARGS=y/g" .config
        sed -i "s/CONFIG_BOOTDELAY=.*/CONFIG_BOOTDELAY=0/g" .config

        # sed -i 's/CONFIG_BOOTARGS=""/CONFIG_BOOTARGS="root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait earlycon console=tty0 console=ttyAMA0 init=/linuxrc LOGLEVEL=8"/g' .config
        sed -i '/CONFIG_USE_BOOTARGS/a CONFIG_BOOTARGS="root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait earlycon console=tty0 console=ttyAMA0 init=/linuxrc LOGLEVEL=8"' .config
        ###########################################################
        ${BUILD_PREFIX} make ARCH=${VARS_ARCH} CROSS_COMPILE=${BAREMETAL_CC_PREFIX} -j ${JOBS}; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp ${UBOOT_PATH}/u-boot ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    elif [ "${VARS_ARCH}" = "arm64" ]
    then
        ## Patch for bootcmd
        ###########################################################
        # BAREMETAL_CC_PREFIX=arm-none-eabi-
        ###########################################################
        if [ ${OPTION_COPY_CONFIG} = true ] || ! test -f .config; then
            echo "Do defconfig"
            ${BUILD_PREFIX} make CROSS_COMPILE=${BAREMETAL_CC_PREFIX} qemu_arm64_defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
        fi
        ## Patch for bootcmd
        ###########################################################
        # 1. Modify Boot Command
        # Logic: Scan VirtIO -> Load Image to RAM (0x40080000) -> Boot (using fdt_addr passed by QEMU)
        # Note: 0x40080000 is a safe start address for QEMU virt; the original 0x60000000 might be out of range or cause conflicts.
        sed -i 's/CONFIG_BOOTCOMMAND=.*/CONFIG_BOOTCOMMAND="virtio scan; load virtio 0:1 0x40080000 Image; booti 0x40080000 - ${fdt_addr}"/g' .config

        # If the original file uses indirect methods like "run distro_bootcmd", use this line to force override (choose one of two; the above line is generally effective, or add it to the end of the file).
        # sed -i "s/run distro_bootcmd/virtio scan; load virtio 0:1 0x40080000 Image; booti 0x40080000 - \$\{fdt_addr\}/g" .config

        # 2. Force enable BootArgs feature
        sed -i "s/# CONFIG_USE_BOOTARGS is not set/CONFIG_USE_BOOTARGS=y/g" .config
        sed -i "s/CONFIG_USE_BOOTARGS=n/CONFIG_USE_BOOTARGS=y/g" .config

        # 3. Set Boot Delay to 0 (instant boot)
        sed -i "s/CONFIG_BOOTDELAY=.*/CONFIG_BOOTDELAY=0/g" .config

        # 4. Modify BootArgs (Kernel parameters)
        # Changes:
        #   root=/dev/mmcblk0p2 -> root=/dev/vda1 (VirtIO disks are usually identified as vda, assuming partition 1)
        #   console=ttyAMA0     -> This is correct (PL011)
        #   init=/linuxrc       -> Ensure this file exists in your rootfs, otherwise change back to /sbin/init
        sed -i '/CONFIG_USE_BOOTARGS/a CONFIG_BOOTARGS="root=/dev/vda2 rw rootfstype=ext4 rootwait earlycon console=ttyAMA0 init=/linuxrc LOGLEVEL=8"' .config
        ###########################################################
        if [ ${OPTION_ENABLE_MENUCONFIG} = true ]
        then
            # menuconfig
            ${BUILD_PREFIX} make CROSS_COMPILE=${BAREMETAL_CC_PREFIX} -j ${JOBS} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
        fi
        ${BUILD_PREFIX} make CROSS_COMPILE=${BAREMETAL_CC_PREFIX} -j ${JOBS}; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp ${UBOOT_PATH}/u-boot ${BUILD_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    else
        echo Uboot not support in ${VARS_ARCH}
    fi
}
fBuildLinux()
{
    fPrintHeader "Building Linux Kernel"
    cd ${KERNEL_PATH}
    if [ ${OPTION_BUILD_CLEAN} = true ]
    then
        make clean
    fi

    if [ ${OPTION_COPY_CONFIG} = true ] || ! test -f .config; then
        echo "Do defconfig"
        # you can get a list of predefined configs for ARM under arch/arm/configs/
        # this configures the kernel compilation parameters
        # make ARCH=arm versatile_defconfig
        ${BUILD_PREFIX} make ARCH=${VARS_ARCH} ${VARS_KERNEL_CONFIG}; fErrControl ${FUNCNAME[0]} ${LINENO}
        ${BUILD_PREFIX} make ARCH=${VARS_ARCH} olddefconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    if [ ${OPTION_ENABLE_MENUCONFIG} = true ]
    then
        # menuconfig
        ${BUILD_PREFIX} make ARCH=${VARS_ARCH} CROSS_COMPILE=${BAREMETAL_CC_PREFIX} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
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
        cp -f ${KERNEL_PATH}/arch/arm/boot/Image ${BOOTFS_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
        cp -f ${KERNEL_PATH}/arch/arm/boot/zImage ${BOOTFS_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
        # cp -f ${KERNEL_PATH}/arch/arm/boot/uImage ${BOOTFS_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
        # cp -f ${KERNEL_PATH}/arch/arm/boot/dts/versatile-pb.dtb ${BOOTFS_PATH}/device_tree.dtb
        cp -f ${KERNEL_PATH}/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${BOOTFS_PATH}/device_tree.dtb; fErrControl ${FUNCNAME[0]} ${LINENO}
    elif [ ${VARS_ARCH} = "arm64" ]
    then
        cp -f ${KERNEL_PATH}/arch/arm64/boot/Image ${BOOTFS_PATH}/; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
}
fBuildBusybox()
{
    fPrintHeader "Building busybox"
    cd ${BUSYBOX_PATH}
    if [ ${OPTION_BUILD_CLEAN} = true ]
    then
        make clean
    fi
    if [ ${OPTION_COPY_CONFIG} = true ] || ! test -f .config; then
        echo "Do defconfig"
        ${BUILD_PREFIX} make ARCH=${VARS_ARCH} CROSS_COMPILE=${SYSTEM_CC_PREFIX} defconfig; fErrControl ${FUNCNAME[0]} ${LINENO}

        # patch for static library
        # echo "Please do Busybox Settings –> Build Options. If you don't have libc library"
        # echo "Patch for ARM"
        # sed -i "s/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g" .config

        # TODO, remove me, it's just avoid compile fail.
        sed -i "s/CONFIG_TC=y/# CONFIG_TC is not set/g" .config
    fi

    if [ ${OPTION_ENABLE_MENUCONFIG} = true ]
    then
        ${BUILD_PREFIX} make ARCH=${VARS_ARCH} CROSS_COMPILE=${SYSTEM_CC_PREFIX} menuconfig; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi

    if [ ${OPTION_CLEAN_BUILD} = true ]
    then
        ${BUILD_PREFIX} make -j ${JOBS} ARCH=${VARS_ARCH} CROSS_COMPILE=${SYSTEM_CC_PREFIX} dist-clean; fErrControl ${FUNCNAME[0]} ${LINENO}
    fi
    ${BUILD_PREFIX} make -j ${JOBS} ARCH=${VARS_ARCH} CROSS_COMPILE=${SYSTEM_CC_PREFIX} install; fErrControl ${FUNCNAME[0]} ${LINENO}
    cp -rf ${BUSYBOX_PATH}/_install/* ${BUILD_PATH}/rootfs/; fErrControl ${FUNCNAME[0]} ${LINENO}
}
fBuildRootfs_struct()
{
    fPrintHeader "Create root structure"
    mkdir -pv ${ROOTFS_PATH}/{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt,dev}
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
    # if [ "${PATH_TOOLCHAIN_LIBC}" != "" ] && [ -d "${PATH_TOOLCHAIN_LIBC}" ]
    # then
    #     cp -rf ${PATH_TOOLCHAIN_LIBC}/* ${ROOTFS_PATH}; fErrControl ${FUNCNAME[0]} ${LINENO}
    # fi

    local target_rootfs=${ROOTFS_PATH}
    local target_lib_dir="${target_rootfs}/lib"
    
    # 1. Determine which compiler to use for querying
    # If SYSTEM_CC_PREFIX has a value (e.g., aarch64-linux-gnu-), use it
    # If it's empty (native compilation on ARM64), use gcc directly
    local cc_cmd="${SYSTEM_CC_PREFIX}gcc"

    echo "Fetching libs using: ${cc_cmd}"

    # 2. Define the core library list (these are the minimum requirements for BusyBox and basic C programs to run)
    # ld-linux is the dynamic linker, absolutely required
    # libc, libm are standard libraries
    # libdl, libpthread, librt are common dependencies
    local lib_list="ld-linux-aarch64.so.1 libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 libresolv.so.2"

    mkdir -p ${target_lib_dir}

    for lib in ${lib_list}; do
        # 3. Ask GCC where this library is located
        # -print-file-name returns the absolute path (Cross) or system path (Native)
        local lib_path=$(${cc_cmd} -print-file-name=${lib})

        # Check if it was actually found (if not found, gcc will only return the filename itself)
        if [ "${lib_path}" = "${lib}" ]; then
            echo "Warning: Library ${lib} not found by ${cc_cmd}!"
            continue
        fi

        # 4. Get the directory where the file is located (since ld-linux and libc are usually in the same folder)
        # This allows us to grab compatible files in that directory (e.g., ld-2.31.so) together
        local src_dir=$(dirname ${lib_path})
        
        echo "  Installing ${lib} from ${src_dir}..."
        # 5. Copy strategy
        # Use cp -a (Archive) to preserve attributes and links
        # Here we only copy files matching the name pattern to avoid copying thousands of files from the host /lib
        # For example: copy libc.so.6 and libc-2.31.so
        local lib_name_pattern=$(echo ${lib} | sed 's/\.so.*/.so*/') # libc.so.6 -> libc.so*
        
        sudo cp -a ${src_dir}/${lib_name_pattern} ${target_lib_dir}/
    done
    echo "Library installation complete."
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
fBuildImage()
{
    fPrintHeader "Build Image"
    local var_ava_loop=$(sudo losetup -f)
    local var_disk_name=${BUILD_PATH}/system.img
    local var_disk_path=${BUILD_PATH}/disk
    local var_bootfs_size_m=64
    local var_rooffs_size_m=512
    local var_disk_size_m=1024
    local var_error=0

    local mpt_bootfs="kernel"
    local mpt_rootfs="rootfs"

    cd ${BUILD_PATH}
    # dynamic image size.
    var_bootfs_size_m=$(du -sm ${BOOTFS_PATH} | awk '{print int($1 * 1.1) }' 2> /dev/null)
    var_rooffs_size_m=$(du -sm ${ROOTFS_PATH} | awk '{print int($1 * 1.1 + 32) }' 2> /dev/null)

    var_disk_size_m=$((${var_bootfs_size_m} + ${var_rooffs_size_m}))
    echo "Create boot disk to ${var_disk_size_m}, FS: ${var_bootfs_size_m}/${var_rooffs_size_m}"
    # create image
    dd if=/dev/zero of=${var_disk_name} bs=1M count=${var_disk_size_m}

    # create partition
    sgdisk -n 1:0:+${var_bootfs_size_m}M -t 1:ef00 -c 1:kernel ${var_disk_name}
    sgdisk -n 2:0:0 -t 2:8300 -c 2:rootfs ${var_disk_name}

    # check disk info
    sgdisk -p ${var_disk_name}; fErrControl ${FUNCNAME[0]} ${LINENO}

    # mapping disk
    sudo losetup ${var_ava_loop} ${var_disk_name}; fErrControl ${FUNCNAME[0]} ${LINENO}
    # info system about part table changed
    sudo partprobe ${var_ava_loop}; fErrControl ${FUNCNAME[0]} ${LINENO}

    # create file system
    # sudo mkfs.vfat -F 32 -n KERNEL ${var_ava_loop}p1
    sudo mkfs.vfat -F 32 -n KERNEL ${var_ava_loop}p1
    # disable journal for accurate size.
    sudo mkfs.ext4 -O ^has_journal -L ROOTFS ${var_ava_loop}p2

    # create dirs
    mkdir -p ${var_disk_path}/${mpt_bootfs}/
    mkdir -p ${var_disk_path}/${mpt_rootfs}/

    # mount disk
    sudo mount -t vfat ${var_ava_loop}p1  ${var_disk_path}/${mpt_bootfs}/
    sudo mount -t ext4 ${var_ava_loop}p2  ${var_disk_path}/${mpt_rootfs}/

    # set up disk
    # if [ "${VARS_ARCH}" = "arm64" ]; then
    #     sudo cp  ${BUILD_PATH}/Image ${var_disk_path}/${mpt_bootfs}/
    # elif [ "${VARS_ARCH}" = "arm" ]; then
    #     sudo cp  ${BUILD_PATH}/zImage ${var_disk_path}/${mpt_bootfs}/
    #     sudo cp  ${BUILD_PATH}/device_tree.dtb ${var_disk_path}/${mpt_bootfs}/
    # else
    #     echo "Unknown arch: ${VARS_ARCH}"
    # fi
    sudo cp -rf ${BOOTFS_PATH}/* ${var_disk_path}/${mpt_bootfs}/ || var_error=1
    sudo cp -rf ${ROOTFS_PATH}/* ${var_disk_path}/${mpt_rootfs}/ || var_error=1

    # list content
    tree ${var_disk_path}/${mpt_bootfs}/
    tree ${var_disk_path}/${mpt_rootfs}/

    sync
    # deallocate resource
    sudo umount ${var_disk_path}/${mpt_bootfs}/
    sudo umount ${var_disk_path}/${mpt_rootfs}/
    sudo losetup -d ${var_ava_loop}
    if [ "${var_error}" != 0 ]; then
        echo "An erorr detect, please check the image logs."
        exit ${var_error}
    else
        echo "Image create successfully."
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
    fPrintHeader "Run Qemu in ${OPTION_EMULATION_RUNTIME} mode"
    if [ "${OPTION_EMULATION_RUNTIME}" = "kernel" ]
    then
        fRunEmulation_kernel
        return
    elif [ "${OPTION_EMULATION_RUNTIME}" = "uboot" ] && [ "${VARS_ARCH}" = "arm" ]
    then
        fPrintHeader "Run Qemu Uboot"
        cd ${BUILD_PATH}
        local kernel_command=""
        local qemu_cmd=(qemu-system-arm )
        qemu_cmd+=(-machine vexpress-a9)
        qemu_cmd+=(-kernel ./u-boot)
        # qemu_cmd+=(-dtb device_tree.dtb)
        qemu_cmd+=(-nographic)
        qemu_cmd+=(-m 128M)
        # qemu_cmd+=(-initrd ./initramfs)

        qemu_cmd+=(-s)
        # qemu_cmd+=(-device e1000,netdev=eth0)
    elif [ "${OPTION_EMULATION_RUNTIME}" = "disk" ] && [ "${VARS_ARCH}" = "arm" ]
    then
        fPrintHeader "Run Qemu disk"
        cd ${BUILD_PATH}
        local kernel_command=""
        local qemu_cmd=(qemu-system-arm )
        qemu_cmd+=(-machine vexpress-a9)
        qemu_cmd+=(-kernel u-boot)
        # qemu_cmd+=(-dtb device_tree.dtb)
        qemu_cmd+=(-nographic)
        qemu_cmd+=(-m 128M)
        qemu_cmd+=(-sd system.img)

        qemu_cmd+=(-s)
        # qemu_cmd+=(-device e1000,netdev=eth0)
        # echo "This function is not done yet. Please do the following things in uboot."
        # echo "setenv bootcmd 'load mmc 0:1 0x60008000 zImage;load mmc 0:1 0x61000000 device_tree.dtb;bootz 0x60008000 - 0x61000000'"
        # echo "setenv bootargs 'root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait earlycon console=tty0 console=ttyAMA0 init=/linuxrc LOGLEVEL=8'"
        # echo "saveenv; reset"
        # printf "Press Enter to Continue."
        # read tmp_test
    elif [ "${OPTION_EMULATION_RUNTIME}" = "disk" ] && [ "${VARS_ARCH}" = "arm64" ]
    then
        fPrintHeader "Run Qemu arm64"
        cd ${BUILD_PATH}

        # Create QEMU command array
        local qemu_cmd=(qemu-system-aarch64)
        qemu_cmd+=(-machine virt)
        qemu_cmd+=(-cpu cortex-a57)
        qemu_cmd+=(-nographic)
        qemu_cmd+=(-smp 1)
        qemu_cmd+=(-m 2048)

        # Load U-Boot
        qemu_cmd+=(-kernel u-boot)

        # Use VirtIO to mount system.img ---
        # This will simulate system.img as a VirtIO disk, which U-Boot identifies as "virtio 0"
        qemu_cmd+=(-drive if=none,file=system.img,format=raw,id=hd0)
        qemu_cmd+=(-device virtio-blk-device,drive=hd0)
        # -------------------------------------------

        # (Optional) Add VirtIO network card for future tftp experiments
        qemu_cmd+=(-device virtio-net-device,netdev=net0)
        qemu_cmd+=(-netdev user,id=net0)
    elif [ "${OPTION_EMULATION_RUNTIME}" = "disk" ] && [ "${VARS_ARCH}" = "arm64old" ]
    then
        fPrintHeader "Run Qemu arm64"
        cd ${BUILD_PATH}
        # local kernel_command="console=ttyAMA0 root=/dev/vda oops=panic panic_on_warn=1 panic=-1 ftrace_dump_on_oops=orig_cpu debug earlyprintk=serial slub_debug=UZ "
        # kernel_command+="rdinit=/sbin/init"

        local qemu_cmd=(qemu-system-aarch64)
        qemu_cmd+=(-machine virt)
        qemu_cmd+=(-cpu cortex-a57)
        qemu_cmd+=(-nographic)
        qemu_cmd+=(-smp 1)
        qemu_cmd+=(-kernel u-boot)
        # qemu_cmd+=(-initrd ./initramfs)

        # qemu_cmd+=(-sd system.img)
        qemu_cmd+=(-device sdhci-pci  -device sd-card,drive=mydrive -drive id=mydrive,if=none,format=raw,file=system.img)
        # qemu_cmd+=(-drive file=system.img,format=raw,index=0,media=disk)
        qemu_cmd+=(-m 2048)
        echo "This function is not done yet. Emmc not support in uboot."
        printf "Press Enter to Continue."
        read tmp_test
    else
        echo "Unsupport Options: ${OPTION_EMULATION_RUNTIME}:${VARS_ARCH}"
    fi
    echo "${qemu_cmd[@]}"
    eval "${qemu_cmd[@]}"
}
fRunEmulation_kernel()
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
        qemu_cmd+=(-hda data.img)
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
        # qemu_cmd+=(-net user,hostfwd=tcp::10023-:22 -net nic)

    fi
    echo "${qemu_cmd[@]} -append \"${kernel_command}\""
    eval "${qemu_cmd[@]} -append \"${kernel_command}\""
}
function fmain()
{
    while [[ $# != 0 ]]
    do
        case $1 in
            # Options
            -c|--clean)
                OPTION_BUILD_CLEAN=true
                ;;
            -a|--all)
                # OPTION_COPY_CONFIG=true

                OPTION_DOWNLOAD_KERNEL=true
                OPTION_DOWNLOAD_ROOTFS=true
                OPTION_DOWNLOAD_UBOOT=true

                OPTION_PATCH_UBOOT=true
                OPTION_PATCH_LINUX=true
                OPTION_PATCH_BUSYBOX=true

                OPTION_BUILD_UBOOT=true
                OPTION_BUILD_KERNEL=true
                OPTION_BUILD_ROOTFS=true
                OPTION_BUILD_IMAGE=true

                OPTION_RUN_EMULATION=true
                ;;
            -s|--download-all|download)
                OPTION_DOWNLOAD_KERNEL=true
                OPTION_DOWNLOAD_ROOTFS=true
                OPTION_DOWNLOAD_UBOOT=true
                ;;
            -P|--patch|patch)
                OPTION_PATCH_UBOOT=true
                OPTION_PATCH_LINUX=true
                OPTION_PATCH_BUSYBOX=true
                ;;
            -b|--build|build)
                OPTION_BUILD_UBOOT=true
                OPTION_BUILD_KERNEL=true
                OPTION_BUILD_ROOTFS=true
                OPTION_BUILD_IMAGE=true
                ;;
            -u|--uboot)
                OPTION_BUILD_UBOOT=true
                ;;
            -l|--linux)
                OPTION_BUILD_KERNEL=true
                ;;
            -r|--rootfs)
                OPTION_BUILD_ROOTFS=true
                ;;
            -i|--image)
                OPTION_BUILD_IMAGE=true
                ;;
            -c|--clean)
                OPTION_CLEAN_BUILD=true
                ;;
            -q|--qemu)
                OPTION_RUN_EMULATION=true
                if [ "${2}" = "kernel" ]
                then
                    OPTION_EMULATION_RUNTIME="kernel"
                elif [ "${2}" = "uboot" ]
                then
                    OPTION_EMULATION_RUNTIME="uboot"
                elif [ "${2}" = "disk" ]
                then
                    OPTION_EMULATION_RUNTIME="disk"
                fi
                shift 1
                ;;
            -d|--debug)
                OPTION_RUN_GDB=true
                DEBUG_TARGET=$2
                shift 1
                ;;
            # Config
            -j|--job)
                JOBS=$2
                shift 1
                ;;
            --arch)
                OPTION_ARCH=$2
                shift 1
                ;;
            -m|--menuconfig)
                OPTION_ENABLE_MENUCONFIG=true
                ;;
            --copy-config)
                OPTION_COPY_CONFIG=true
                ;;
            -p|--build-prefix)
                BUILD_PREFIX=$2
                shift 1
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
        shift 1
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

    ## patch
    if [ ${OPTION_PATCH_UBOOT} = true ]
    then
        fPatchUBoot
    fi
    if [ ${OPTION_PATCH_LINUX} = true ]
    then
        fPatchLinux
    fi
    if [ ${OPTION_PATCH_BUSYBOX} = true ]
    then
        fPatchBusybox
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
    if [ ${OPTION_BUILD_IMAGE} = true ]
    then
        fBuildImage
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
