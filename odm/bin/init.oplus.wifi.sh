#! /vendor/bin/sh

# Copyright (c) 2010-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# This script will load and unload the wifi driver to put the wifi in
# in deep sleep mode so that there won't be voltage leakage.
# Loading/Unloading the driver only incase if the Wifi GUI is not going
# to Turn ON the Wifi. In the Script if the wlan driver status is
# ok(GUI loaded the driver) or loading(GUI is loading the driver) then
# the script won't do anything. Otherwise (GUI is not going to Turn On
# the Wifi) the script will load/unload the driver
# This script will get called after post bootup.

target="$1"
serialno="$2"

btsoc=""
#ifdef OPLUS_FEATURE_WIFI_BDF
#WuGuotian@CONNECTIVITY.WIFI.HARDWARE.BDF.1065227 , 2021/05/26, copy bdf
#Add for make bin Rom-update.
function load_bdf() {
if [ ! -s /mnt/vendor/persist/bdwlan.bin ]; then
    cp /odm/etc/wifi/bdwlan.bin /mnt/vendor/persist/bdwlan.bin
    sync
fi

if [ ! -s /mnt/vendor/persist/hardware_debug ] ; then
    persistbdf=`md5sum /mnt/vendor/persist/bdwlan.bin |cut -d" " -f1`
    vendorbdf=`md5sum /odm/etc/wifi/bdwlan.bin |cut -d" " -f1`
    if [ x"$vendorbdf" != x"$persistbdf" ]; then
        cp /odm/etc/wifi/bdwlan.bin /mnt/vendor/persist/bdwlan.bin
        sync
        echo "bdf check"
    fi
fi
}

if [ -s /odm/etc/wifi/init.project.wifi.sh ]; then
    echo "init.project.wifi.sh"
    source /odm/etc/wifi/init.project.wifi.sh
else
    load_bdf
fi

chmod 666 /mnt/vendor/persist/bdwlan.bin
chown system:wifi /mnt/vendor/persist/bdwlan.bin


#WuGuotian@CONNECTIVITY.WIFI.HARDWARE.BDF.1065227, 2021/05/26, copy regbd
if [ ! -s /mnt/vendor/persist/regdb.bin ]; then
    cp /odm/etc/wifi/regdb.bin /mnt/vendor/persist/regdb.bin
    sync
fi

if [ ! -s /mnt/vendor/persist/hardware_debug ] ; then
    vendorRegdb=`md5sum /mnt/vendor/persist/regdb.bin |cut -d" " -f1`
    persistRegdb=`md5sum /odm/etc/wifi/regdb.bin |cut -d" " -f1`
    if [ x"$vendorRegdb" != x"$persistRegdb" ]; then
        cp /odm/etc/wifi/regdb.bin /mnt/vendor/persist/regdb.bin
        sync
        echo "regdb check"
    fi
fi

chmod 666 /mnt/vendor/persist/regdb.bin
chown system:wifi /mnt/vendor/persist/regdb.bin

#LiJunlong@CONNECTIVITY.WIFI.NETWORK.1065227,2020/08/07
mkdir /mnt/vendor/persist/wlan 0777 system system

reg_info=`getprop ro.vendor.oplus.euex.country`
if [ "w${reg_info}" = "wUA" ]; then
    sourceFile=/odm/vendor/etc/wifi/WCNSS_qcom_cfg_ua.ini
    echo "export UA file dir config"
else
    sourceFile=/odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini
fi
targetFile=/mnt/vendor/persist/wlan/WCNSS_qcom_cfg.ini
#Yuan.Huang@PSW.CN.Wifi.Network.internet.1065227, 2016/11/09,
#Add for make WCNSS_qcom_cfg.ini Rom-update.
if [ -s "$sourceFile" ]; then
	system_version=`head -1 "$sourceFile" | grep OplusVersion | cut -d= -f2`
	if [ "${system_version}x" = "x" ]; then
		system_version=1
	fi
else
	system_version=1
fi

#LiJunlong@CONNECTIVITY.WIFI.NETWORK,1065227,2020/07/29,Add for rus ini
if [ -s /mnt/vendor/persist/wlan/qca_cld/WCNSS_qcom_cfg.ini ]; then
    cp  /mnt/vendor/persist/wlan/qca_cld/WCNSS_qcom_cfg.ini \
        $targetFile
    sync
    chown system:wifi $targetFile
    chmod 666 $targetFile
    rm -rf /mnt/vendor/persist/wlan/qca_cld
fi

if [ -s "$targetFile" ]; then
	persist_version=`head -1 "$targetFile" | grep OplusVersion | cut -d= -f2`
	if [ "${persist_version}x" = "x" ]; then
		persist_version=0
	fi
else
	persist_version=0
fi


if [ ! -s "$targetFile" -o $system_version -gt $persist_version ] || [ "w${reg_info}" = "wUA" ]; then
    cp $sourceFile  $targetFile
    sync
    chown system:wifi $targetFile
    chmod 666 $targetFile
fi

persistini=`cat "$targetFile" | grep -v "#" | grep -wc "END"`
if [ x"$persistini" = x"0" ]; then
    cp $sourceFile  $targetFile
    sync
    chown system:wifi $targetFile
    chmod 666 $targetFile
    echo "ini check"
fi
#endif /* OPLUS_FEATURE_WIFI_BDF */
