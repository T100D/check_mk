#!/bin/bash
#
## Geschreven door Arie van den Heuvel
##
## Script voor MIVSP radar sensoren
##
## dd 12-09-2021 opc commando aangepast tbv MC3.5
## dd 16-09-2021 timeout toegevoed voor het geval een node getopt wordt en het script faalt
## dd 24-01-2024 herschreven voor mivsp radar
## dd 31-07-2026 vidio activity toegevoegd aan de controle en output van de check
##

timeout 5s /opt/vtmis/HTP/bin/x86_64-linux-gnu/ve4/opc localhost:htp_opc1 -c vp_status > /tmp/vp_status

#sync_frequency=$(cat /tmp/vp_status | grep sync_frequency | grep 0 | wc --lines)
sync_frequency=$(grep -cm1 'sync_frequency.*nok' /tmp/vp_status)
        if [ $sync_frequency -eq 0 ] ; then
        echo "0 Radar_sync_frequency status=$sync_frequency OK"
        else
        echo "2 Radar_sync_frequency status=$sync_frequency NOK"
        fi

#acp_frequency=$(cat /tmp/vp_status | grep acp_frequency | grep 0 | wc --lines)
acp_frequency=$(grep -cm1 'acp_frequency.*nok' /tmp/vp_status)
        if [ $acp_frequency -eq 0 ] ; then
        echo "0 Radar_acp_frequency status=$acp_frequency OK"
        else
        echo "2 Radar_acp_frequency status=$acp_frequency NOK"
        fi

videoactivity=$(grep -cm1 'video_activity.*nok' /tmp/vp_status)
       if [ $videoactivity -eq 1 ] ; then
       echo "2 Radar_Video_Activity status=0 NOK"
       else
       echo "0 Radar_Video_Activity status=1 OK"
       fi
