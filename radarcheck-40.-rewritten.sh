#!/bin/bash
#
# Created by Arie
#
# To monitori radar status remotely
#
# 01-01-2016 created for monitoring radar sensor info
#
# 12-09-2021 V1.1 adjested for MC3.5 OPC command
# 16-09-2021 Adjusted for stopped applciation (timout added)
# 25-02-2024 aangepast voor MC 4.x software
# 06-06-2025 Rewritten with help of open-hands to be faster
#
# In case of a new non serial connected sensor remove antennestatus & transmitter status
#


timeout 5s /opt/vtmis/HTP/bin/x86_64-linux-gnu/ve4/opc localhost:htp_opc1 -c vp_status > /tmp/vp_status
antennestatus=$(grep -cm1 'antenna.*on' /tmp/vp_status)
        if [ $antennestatus -eq 1 ] ; then
        echo "0 Radar_Antenne_Status status=$antennestatus OK"
        else
        echo "2 Radar_Antenne_Status status=$antennestatus NOK"
        fi

transmitterstatus=$(grep -cm1 'transmitter.*on' /tmp/vp_status)
        if [ $transmitterstatus -eq 1 ] ; then
        echo "0 Radar_Transmitter_Status status=$transmitterstatus OK"
        else
        echo "2 Radar_Transmitter_Status status=$transmitterstatus NOK"
        fi

videoactivity=$(grep -cm1 '/video_activity.*nok' /tmp/vp_status)
        if [ $videoactivity -eq 1 ] ; then
        echo "2 Radar_Video_Activity status=0 NOK"
        else
        echo "0 Radar_Video_Activity status=1 OK"
        fi

northpulse=$(grep -cm1 'np_present.*yes' /tmp/vp_status)
        if [ $northpulse -eq 1 ] ; then
        echo "0 Radar_North_Pulse status=$northpulse OK"
        else
        echo "2 Radar_North_Pulse status=$northpulse NOK"
        fi

acp=$(grep -cm1 'acp_present.*yes' /tmp/vp_status)
        if [ $acp -eq 1 ] ; then
        echo "0 Radar_ACP_Present status=$acp OK"
        else
        echo "2 Radar_ACP_Present status=$acp NOK"
        fi

sync=$(grep -cm1 'sync_present.*yes' /tmp/vp_status)
        if [ $acp -eq 1 ] ; then
        echo "0 Radar_SYNC_Present status=$acp OK"
        else
        echo "2 Radar_SYNC_Present status=$acp NOK"
        fi
