#!/bin/sh

## ---- To run this script with non-root 'ruser', need to set permssions for 'INS_PATH' folder first (as root or sudoers). 
## ---- Create user if not exist
## ---- useradd ruser && mkdir /home/ruser && chown -R ruser:ruser /home/ruser
## ---- INS_PATH=/opt/shiny && sudo mkdir -p ${INS_PATH} && sudo chown -R ruser:ruser -R ${INS_PATH}

# $1 VER version number,  master(defualt) or release tag 
# $2 DL_TOOL: wget or curl(defualt) 
# ---
# server is installed to /opt/shiny/server
# previous files/folders are moved to another place and will not be removed
# remember to set files/folders permssions if needed


# VER="master"
# VER="v0.94-beta.4"
VER="$1"

# DL_TOOL="wget"
# DL_TOOL="curl"
DL_TOOL="$2"

# VER should not be empty
if [ "${VER}" = "" ]; then
    VER="master"
fi


INS_PATH=/opt/shiny
DL_PATH=${INS_PATH}/download/${VER}



## remove previous DL_PATH 
if [ -d "${DL_PATH}" ]; then
    DATE=`date +%Y-%m-%d-%H-%M-%S`
    mv ${DL_PATH} "${DL_PATH}_${DATE}"
    echo "[Info] Previous folder ${PREV_VER_PATH} is moved to ${DL_PATH}_${DATE}"
fi

mkdir -p ${DL_PATH}
mkdir -p ${INS_PATH}

if [ -L "${INS_PATH}/server" ]; then
    # echo "[Info] Remove previous symbolic link to ${INS_PATH}/server"
    rm -rf "${INS_PATH}/server"
fi

if [ -d "${INS_PATH}/server" ]; then
    DATE=`date +%Y-%m-%d-%H-%M-%S`
    PREV_VER_PATH=${INS_PATH}/previous/${DATE}
    mkdir -p ${PREV_VER_PATH}
    mv -f ${INS_PATH}/server ${PREV_VER_PATH}
    echo "[Info] Previous files are moved to ${PREV_VER_PATH}"
fi


if [ "${DL_TOOL}" = "wget" ]; then
    wget --no-check-certificate -nv -O  ${DL_PATH}/${VER}.tar.gz https://github.com/statsplot/jshinyserver/archive/${VER}.tar.gz
else
    curl -L -s --insecure https://github.com/statsplot/jshinyserver/archive/${VER}.tar.gz > ${DL_PATH}/${VER}.tar.gz
fi


tar zxf ${DL_PATH}/${VER}.tar.gz -C ${DL_PATH}

ln -s  ${DL_PATH}/jshinyserver-*/source/Objects ${INS_PATH}/server 

if [ -L "${INS_PATH}/server" ] && [ -e "${INS_PATH}/server" ] ; then
    echo "[Done] jShiny server ${VER} installed to ${INS_PATH}/server"
else
    echo "[Error] Fail to installed jShiny server ${VER}"
fi

cd ${INS_PATH}

