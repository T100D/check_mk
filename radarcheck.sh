#!/bin/bash

/HITT/build/htp/ve4/opc localhost:htp_opc1 -c vp_status > /tmp/vp_status

antennestatus=$(cat /tmp/vp_status | grep antenna | grep on | wc --lines)
        if [ $antennestatus -eq 1 ] ; then
        echo "0 Radar_Antenne_Status status=$antennestatus OK"
        else
        echo "2 Radar_Antenne_Status status=$antennestatus NOK"
        fi

transmitterstatus=$(cat /tmp/vp_status | grep transmitter | grep on | wc --lines)
        if [ $transmitterstatus -eq 1 ] ; then
        echo "0 Radar_Transmitter_Status status=$transmitterstatus OK"
        else
        echo "2 Radar_Transmitter_Status status=$transmitterstatus NOK"
        fi

videoactivity=$(cat /tmp/vp_status | grep video_activity | grep 'nok' | wc --lines)
        if [ $videoactivity -eq 1 ] ; then
        echo "2 Radar_Video_Activity status=0 NOK"
        else
        echo "0 Radar_Video_Activity status=1 OK"
        fi

northpulse=$(cat /tmp/vp_status | grep np_present | grep yes | wc --lines)
        if [ $northpulse -eq 1 ] ; then
        echo "0 Radar_North_Pulse status=$northpulse OK"
        else
        echo "2 Radar_North_Pulse status=$northpulse NOK"
        fi

acp=$(cat /tmp/vp_status | grep acp_present | grep yes | wc --lines)
        if [ $acp -eq 1 ] ; then
        echo "0 Radar_ACP_Present status=$acp OK"
        else
        echo "2 Radar_ACP_Present status=$acp NOK"
        fi