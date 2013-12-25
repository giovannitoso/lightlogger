#!/bin/sh
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University of Padova (SIGNET lab) nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# @name_file:   boot.sh
# @author:      Giovanni Toso
# @last_update: 2013.12.25
# --
# @brief_description: Shell script used to run at boot time the lightlogger software

# Note: please remember to add this script at boot by forking the shell
# e.g. (while :; do cd /root/lightlogger/ && ./boot.sh  > /dev/null 2> /dev/null; sleep 10; done ) &

# List of the possible serial ports
SERIAL_PORT_0=/dev/ttyACM0
SERIAL_PORT_1=/dev/ttyACM1

# Default path with the source files
PATH_PROJECT=/root/lightlogger
LOGFILE=boot.log

if [ -d "${PATH_PROJECT}" ]; then
    cd ${PATH_PROJECT}
else
    exit 1
fi

do_log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $*" >> ${LOGFILE}
}

# Check if the arduino is connected
if [ -e ${SERIAL_PORT_0} ]; then
    SERIAL_PORT=${SERIAL_PORT_0}
elif [ -e ${SERIAL_PORT_1} ]; then
    SERIAL_PORT=${SERIAL_PORT_1}
else
    do_log "Arduino not connected. Exiting ..."
    cd - > /dev/null
    exit 1
fi

# Check if the needed software is installed in the system
which tclsh > /dev/null 2> /dev/null
if [ $? -ne 0 ]; then
    do_log "tclsh not found. Exiting ..."
    cd - > /dev/null
    exit 1
    exit 1
fi

which expect  > /dev/null 2> /dev/null
if [ $? -ne 0 ]; then
    do_log "expect not found. Exiting ..."
    cd - > /dev/null
    exit 1
fi

# Run the software
chmod +x *.tcl
chmod +x *.sh
if [ -e "lightlogger.tcl" ]; then
    do_log "Starting ./lightlogger.tcl ${SERIAL_PORT} lightlogger.log 10 >> /dev/null 2>> lightlogger.err"
    ./lightlogger.tcl ${SERIAL_PORT} lightlogger.log 10 >> /dev/null 2>> lightlogger.err
    #./lightlogger.tcl ${SERIAL_PORT} lightlogger.log 10 >> lightlogger.out 2>> lightlogger.err
fi
cd - > /dev/null
