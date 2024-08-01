#!/bin/bash
#
# Check to read and store the contents of https://status.cloud.microsoft from the shell
# Install chromium to proceed
#
# Door AHE 31-07-2024
#
chromium-browser --headless --no-sandbox --dump-dom --virtual-time-budget=10000 --timeout=10000 --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)\
Ubuntu Chromium/126.0.6478.114 Chrome/126.0.6478.114 Safari/537.36" https://status.cloud.microsoft/ > /tmp/file.html

