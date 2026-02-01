#!/bin/bash
OPTION_TOOLCHAIN=false
fHelp()
{
    echo "phenix setup"
    echo "[Options]"
    printf "    %- 16s\t%s\n" "-t|--tools" "Do all"
    printf "    %- 16s\t%s\n" "-s|--download-all" "Download all"
}
function fToolchain_arch()
{
    echo "Setup Toolchain for arch"
    local var_arm32=false

    if [ ${var_arm32} = true ]
    then
        echo "################################################################"
        echo "Stage 1"
        echo "################################################################"
        pikaur -S arm-linux-gnueabihf-binutils arm-linux-gnueabihf-gcc-stage1 arm-linux-gnueabihf-linux-api-headers

        echo "################################################################"
        echo "Stage 2"
        echo "################################################################"
        pikaur -S arm-linux-gnueabihf-glibc-headers arm-linux-gnueabihf-gcc-stage2

        echo "################################################################"
        echo "Stage 3"
        echo "################################################################"
        pikaur -S arm-linux-gnueabihf-glibc arm-linux-gnueabihf-gcc

        echo "################################################################"
        echo "Others"
        echo "################################################################"
        pikaur -S arm-linux-gnueabihf-gdb
    fi

}
function fToolchain_debian()
{
    echo "Setup Toolchain for debian"
    sudo apt-get install libssl-dev device-tree-compiler
}
function fmain()
{
    while [[ $# != 0 ]]
    do
        case $1 in
            # Options
            -t|--toolchain)
                OPTION_TOOLCHAIN=true
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

    if [ ${OPTION_TOOLCHAIN} = true ]
    then
        if command -v pacman; then
            fToolchain_arch
        elif command -v apt; then
            fToolchain_debian
        fi
    fi
}
fmain $@
