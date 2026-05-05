#!/bin/bash
#
# Geschreven door Arie van den Heuvel
# dd 12-09-2021 opc commando aangepast tbv MC3.5
# dd 16-09-2021 timeout toegevoed voor het geval een node getopt wordt en het script faalt
# dd 25-02-2024 aangepast voor MC 4.x software
# dd 16-04-2026 Omgeschreven van file based naar memory based met variable vpstatus
# dd 05-05-2026 Verwerking uitlezen statusvariabele verbeterd met Claude Sonnet 4.6
#

vpstatus=$(timeout 5s /opt/vtmis/HTP/bin/x86_64-linux-gnu/ve4/opc localhost:htp_opc1 -c vp_status | tr -d '\r' | tr ' ' '\n')

antennestatus=$(echo "$vpstatus" | awk -F': ' '/antenna/{print $NF}' | tr -d ' \r')
if [ "$antennestatus" = "on" ]; then
    echo "0 Radar_Antenne_Status status=$antennestatus OK"
    else
    echo "2 Radar_Antenne_Status status=$antennestatus NOK"
fi

transmitterstatus=$(echo "$vpstatus" | awk -F': ' '/transmitter/{print $NF}' | tr -d ' \r')
if [ "$transmitterstatus" = "on" ]; then
   echo "0 Radar_Transmitter_Status status=$transmitterstatus OK"
   else
   echo "2 Radar_Transmitter_Status status=$transmitterstatus NOK"
fi

videoactivity=$(echo "$vpstatus" | awk -F': ' '/video_activity/{print $NF}' | tr -d ' \r')
if [ "$videoactivity" = "on" ]; then
    echo "0 Radar_Video_Activity status=$videoactivity OK"
    else
    echo "2 Radar_Video_Activity status=$videoactivity NOK"
fi

northpulse=$(echo "$vpstatus" | awk -F': ' '/np_present/{print $NF}' | tr -d ' \r')
if [ "$northpulse" = "yes" ]; then
    echo "0 Radar_North_Pulse status=$northpulse OK"
    else
    echo "2 Radar_North_Pulse status=$northpulse NOK"
fi

acp=$(echo "$vpstatus" | awk -F': ' '/acp_present/{print $NF}' | tr -d ' \r')
if [ "$acp" = "yes" ]; then
    echo "0 Radar_ACP_Present status=$acp OK"
    else
    echo "2 Radar_ACP_Present status=$acp NOK"
fi

sync=$(echo "$vpstatus" || awk -F': ' '/sync_present/{print $NF}' | tr -d ' \r')
if [ "$sync" = "yes" ]; then
    echo "0 Radar_SYNC_Present status=$acp OK"
    else
    echo "2 Radar_SYNC_Present status=$acp NOK"
fi

