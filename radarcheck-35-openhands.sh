
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
# 06-06-2025 Rewritten with open-hands
#
# In case of a new non serial connected sensor remove antennestatus & transmitter status
#

LOGFILE=/tmp/radar_status.log

echo "$(date) - Starting radar status check" >> $LOGFILE

timeout 5s /HITT/build/htp/ve4/opc localhost:htp_opc1 -c vp_status > /tmp/vp_status 2> /tmp/radar_status.err
if [ $? -ne 0 ]; then
    echo "2 Radar_OPC_Command_Failed status=0 NOK"

    echo "OPC command failed. See /tmp/radar_status.err for details." >> $LOGFILE

fi

echo "$(date) - OPC command successful" >> $LOGFILE

    exit 1
fi


antennestatus=$(awk '/antenna/ && /on/ {print 1; exit} {print 0; exit}' /tmp/vp_status)
        if [ $antennestatus -eq 1 ] ; then
        echo "0 Radar_Antenne_Status status=$antennestatus OK"
        else
        echo "2 Radar_Antenne_Status status=$antennestatus NOK"
        fi

transmitterstatus=$(awk '/transmitter/ && /on/ {print 1; exit} {print 0; exit}' /tmp/vp_status)
        if [ $transmitterstatus -eq 1 ] ; then
        echo "0 Radar_Transmitter_Status status=$transmitterstatus OK"
        else
        echo "2 Radar_Transmitter_Status status=$transmitterstatus NOK"
        fi

videoactivity=$(awk '/video_activity/ && /nok/ {print 1; exit} {print 0; exit}' /tmp/vp_status)
        if [ $videoactivity -eq 1 ] ; then
        echo "2 Radar_Video_Activity status=0 NOK"
        else
        echo "0 Radar_Video_Activity status=1 OK"
        fi

northpulse=$(awk '/np_present/ && /yes/ {print 1; exit} {print 0; exit}' /tmp/vp_status)
        if [ $northpulse -eq 1 ] ; then
        echo "0 Radar_North_Pulse status=$northpulse OK"
        else
        echo "2 Radar_North_Pulse status=$northpulse NOK"
        fi

acp=$(awk '/acp_present/ && /yes/ {print 1; exit} {print 0; exit}' /tmp/vp_status)
        if [ $acp -eq 1 ] ; then
        echo "0 Radar_ACP_Present status=$acp OK"
        else
        echo "2 Radar_ACP_Present status=$acp NOK"
        fi
ascpcount=$(awk '/scan_acp_count/ {print $NF; exit}' /tmp/vp_status)

        echo "P Radar_ACP_Count Count=$ascpcount;4097"
echo "$(date) - Radar status check completed" >> $LOGFILE
