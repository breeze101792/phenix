#!/bin/bash
OPTION_TOOLCHAIN=false
fHelp()
{
    echo "phenix setup"
    echo "[Options]"
    printf "    %- 16s\t%s\n" "-t|--tools" "Do all"
    printf "    %- 16s\t%s\n" "-s|--download-all" "Download all"
}
function fToolchain()
{
    echo "Setup Toolchain"
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
        fToolchain
    fi
}
fmain $@
