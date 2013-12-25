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

# @name_file:   lightlogger_merge.tcl
# @author:      Giovanni Toso
# @last_update: 2013.12.25
# --
# @brief_description: This program counts the number of records in each hour.
#
# the next line restarts using tclsh \
exec expect -f "$0" -- "$@"

set log(tmp) "/tmp/lightlogger.tmp"

if {$argc != 3} {
    puts -nonewline stderr "\
    The input parameters are not corrects.\n\
    Use:\n\
    param 1: the name of input log file (e.g. lightlogger.log)\n\
    param 2: the name of output log file (e.g. lightlogger.processed)\n\
    param 3: the period in seconds to be used to write the log file on disk (e.g. 5)\n\
    Exiting ...\n"
    exit 1
} else {
    set log(file_name_input) [lindex $argv 0]
    set log(file_name_output) [lindex $argv 1]
    if {![string is integer -strict [lindex $argv 2]]} {
        puts -nonewline stderr "The period to be sed to update the log file on the hard drive is not an integer values. Please run the script with an integer number of seconds. Exiting ...\n"
        exit 1
    } else {
        set log(write_period) [expr [lindex $argv 2] * 1000] ;# Input in s, variable in ms
    }
}

proc extract_relevant_values {} {
    global log
    puts -nonewline stdout "Checking for ${log(file_name_input)} ...\n"
    # Convert the input from seconds to hours
    if {[file exists ${log(file_name_input)}]} {
        puts -nonewline stdout "Analyzing the input file ...\n"
        set fsize [file size ${log(file_name_input)}]
        if {${fsize} <= 0} {
            puts -nonewline stderr "${log(file_name_input)} is empty. Exiting ...\n"
            exit 1
        }
        if {[catch {exec cat ${log(file_name_input)} | wc -l} res] == 1} {
            puts -nonewline stderr "Error opening ${log(file_name_input)}. Exiting ...\n"
            exit 1
        }
        puts -nonewline stderr "Analyzing ${fsize} bytes ...\n"
        puts -nonewline stderr "Discovered ${res} lines\n"
        set fp [open ${log(file_name_input)} r]
        set file_data [read $fp]
        set data [split $file_data "\n"]
        if {[file exists ${log(tmp)}]} {
            puts -nonewline stdout "Output file ${log(tmp)} already there. Removing ...\n"
            exec rm -f ${log(tmp)}
        }
        if {[catch {open ${log(tmp)} "w+"} res]} {
            puts -nonewline stderr "Error opening ${log(tmp)}. Details: ${res}. Exiting ...\n"
            close ${fp}
            exit 1
        }
        set log(file_name) ${log(tmp)}
        set log(list_to_log) {}
        foreach line $data {
            set line_split [split ${line} "\n"]
            set line_timestamp [lindex ${line_split} 0]
            # From seconds to hours
            if {[string is integer -strict ${line_timestamp}]} {
                set line_timestamp_hours [expr (${line_timestamp} / (3600)) * 3600]
                set tmp_string [format "%s" ${line_timestamp_hours}]
                lappend log(list_to_log) ${tmp_string}
            }
            unset line_timestamp
        }
        close ${fp}
        set fo ${res}
        foreach line ${log(list_to_log)} {
            puts -nonewline ${fo} "${line}\n"
        }
        close ${fo}
        puts -nonewline stdout "File ${log(tmp)} created\n"
    } else {
        puts -nonewline stderr "Impossible to open ${log(file_name_input)}. Exiting ...\n"
        exit 1
    }
    if {[file exists ${log(tmp)}]} {
        if {[catch {exec uniq ${log(tmp)}} res] == 0} {
            set list_uniq ${res}
            if {[file exists ${log(file_name_output)}]} {
                puts -nonewline stdout "Output file ${log(file_name_output)} already there. Removing ...\n"
                exec rm -f ${log(file_name_output)}
            }
            if {[catch {open ${log(file_name_output)} "w+"} res]} {
                puts -nonewline stderr "Error opening ${log(file_name_output)}. Details: ${res}. Exiting ...\n"
                exit 1
            }
            set fo ${res}
            puts -nonewline stdout "Creating ${log(file_name_output)} ...\n"
            foreach element ${list_uniq} {
                catch {exec grep -o ${element} ${log(tmp)} | wc -l} res
                puts -nonewline ${fo} "${element}\t${res}\n"
            }
            close ${fo}
            puts -nonewline stdout "Created ${log(file_name_output)}\n"
        } else {
            puts -nonewline stderr "Error analyzing ${log(tmp)}. Details: ${res}. Exiting ...\n"
            exit 1
        }
    } else {
        puts -nonewline stderr "Impossible to open ${log(tmp)}. Exiting ...\n"
        exit 1
    }
}

extract_relevant_values
