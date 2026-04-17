#!/bin/bash
#
# Geschreven door Arie van den Heuvel
# dd 12-09-2021 opc commando aangepast tbv MC3.5
# dd 16-09-2021 timeout toegevoed voor het geval een node getopt wordt en het script faalt
# dd 25-02-2024 aangepast voor MC 4.x software
# dd 16-04-2026 Omgeschreven van file based naar memory based met variable vpstatus
#

vpstatus=$(timeout 5s /opt/vtmis/HTP/bin/x86_64-linux-gnu/ve4/opc localhost:htp_opc1 -c vp_status)

antennestatus=$(echo $vpstatus | grep antenna | grep on | wc --lines)
    if [ $antennestatus -eq 1 ] ; then
    echo "0 Radar_Antenne_Status status=$antennestatus OK"
    else
    echo "2 Radar_Antenne_Status status=$antennestatus NOK"
    fi

transmitterstatus=$(echo $vpstatus | grep transmitter | grep on | wc --lines)
        if [ $transmitterstatus -eq 1 ] ; then
        echo "0 Radar_Transmitter_Status status=$transmitterstatus OK"
        else
        echo "2 Radar_Transmitter_Status status=$transmitterstatus NOK"
        fi

videoactivity=$(echo $vpstatus | grep video_activity | grep 'nok' | wc --lines)
        if [ $videoactivity -eq 1 ] ; then
        echo "2 Radar_Video_Activity status=0 NOK"
        else
        echo "0 Radar_Video_Activity status=1 OK"
        fi

northpulse=$(echo $vpstatus | grep np_present | grep yes | wc --lines)
        if [ $northpulse -eq 1 ] ; then
        echo "0 Radar_North_Pulse status=$northpulse OK"
        else
        echo "2 Radar_North_Pulse status=$northpulse NOK"
        fi

acp=$(echo $vpstatus | grep acp_present | grep yes | wc --lines)
        if [ $acp -eq 1 ] ; then
        echo "0 Radar_ACP_Present status=$acp OK"
        else
        echo "2 Radar_ACP_Present status=$acp NOK"
        fi

sync=$(echo $vpstatus | grep sync_present | grep yes | wc --lines)
        if [ $acp -eq 1 ] ; then
        echo "0 Radar_SYNC_Present status=$acp OK"
        else
        echo "2 Radar_SYNC_Present status=$acp NOK"
        fi
