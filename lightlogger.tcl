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

# @name_file:   lightlogger.tcl
# @author:      Giovanni Toso
# @last_update: 2013.12.25
# --
# @brief_description: Main application of the lightlogger software
#
# the next line restarts using tclsh \
exec expect -f "$0" -- "$@"

# Source
source lightlogger_log.tcl

# Variables
set opt(verbose) 0
set opt(serial_spawn) ""
set arduino(measure) 0
set arduino(measure_threshold) 930
set arduino(peak_validity_time) 1

if {$argc != 3} {
    puts -nonewline stderr "\
    The input parameters are not corrects.\n\
    Use:\n\
    param 1: the serial port (e.g. /dev/ttyACM0)\n\
    param 2: the name of log file (e.g. /tmp/logfile)\n\
    param 3: the period in seconds to be used to write the log file on disk (e.g. 5)\n\
    Exiting ...\n"
    exit 1
} else {
    set opt(serial_port)  [lindex $argv 0]
    set log(file_name)    [lindex $argv 1]
    if {![string is integer -strict [lindex $argv 2]]} {
        puts -nonewline stderr "The period to be sed to update the log file on the hard drive is not an integer values. Please run the script with an integer number of seconds. Exiting ...\n"
        exit 1
    } else {
        set log(write_period) [expr [lindex $argv 2] * 1000] ;# Input in s, variable in ms
    }
}

# Expect variables
exp_internal 0
log_user 0
set timeout -1
remove_nulls -d 0

# Input and Output configuration
if {${opt(verbose)}} {
    debug_app "${opt(module_name)}: starting\n"
}

# Open the connection
spawn -open [open ${opt(serial_port)} r+]
set opt(serial_spawn) ${spawn_id}
fconfigure ${opt(serial_spawn)} -blocking 0 -buffering none -translation binary -eofchar {}
#fconfigure ${opt(serial_spawn)} -mode "9600,n,8,1"

proc main_loop {} {
    global opt modem arduino
    exp_internal 0
    log_user 0
    set state(value) 0 ;# 0 is LOW, 1 is HIGH
    set state(transition_time) 0

    expect {
        -i ${opt(serial_spawn)} -re {(.*?)\r\n} {
            regexp {^(\d+)} $expect_out(1,string) -> \
            arduino(measure)
            if {[info exists arduino(measure)] && [string length ${arduino(measure)}] > 0} {
                # Possible state change:
                # LOW - HIGH: if a value above the threshold is received
                # HIGH - LOW: if a value below the threashold is received or the peak_validity_time expired
                puts ${arduino(measure)}
                if {${state(value)} == 0 && ${arduino(measure)} < ${arduino(measure_threshold)}} {
                    exp_continue
                }
                if {${state(value)} == 0 && ${arduino(measure)} >= ${arduino(measure_threshold)}} {
                    set state(value) 1
                    set state(transition_time) [clock seconds]
                    exp_continue
                } elseif {${state(value)} == 1} {
                    if {${arduino(measure)} < ${arduino(measure_threshold)}} {
                        set switch_time [clock seconds]
                        set state(value) 0
                        if {${switch_time} - ${state(transition_time)} <= ${arduino(peak_validity_time)}} {
                            # Switch from HIGH to LOW and the duration of the peak is valid: new peak
                            log_string "${switch_time}\n"
                        }
                    } else {
                        set state(value) 1
                    }
                } else {
                    puts -nonewline stderr "Wrong state: ${state(value)}. Exiting ...\n"
                    exit 1
                }
            }
            exp_continue
        }
        -i any_spawn_id eof {
            exit 1
        }
    }
}
main_loop

