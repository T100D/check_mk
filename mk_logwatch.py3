#!/usr/bin/env python3
# -*- encoding: utf-8; py-indent-offset: 4 -*-
# +------------------------------------------------------------------+
# |             ____ _               _        __  __ _  __           |
# |            / ___| |__   ___  ___| | __   |  \/  | |/ /           |
# |           | |   | '_ \ / _ \/ __| |/ /   | |\/| | ' /            |
# |           | |___| | | |  __/ (__|   <    | |  | | . \            |
# |            \____|_| |_|\___|\___|_|\_\___|_|  |_|_|\_\           |
# |                                                                  |
# | Copyright Mathias Kettner 2014             mk@mathias-kettner.de |
# +------------------------------------------------------------------+
#
# This file is part of Check_MK.
# The official homepage is at http://mathias-kettner.de/check_mk.
#
# check_mk is free software;  you can redistribute it and/or modify it
# under the  terms of the  GNU General Public License  as published by
# the Free Software Foundation in version 2.  check_mk is  distributed
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;  with-
# out even the implied warranty of  MERCHANTABILITY  or  FITNESS FOR A
# PARTICULAR PURPOSE. See the  GNU General Public License for more de-
# tails. You should have  received  a copy of the  GNU  General Public
# License along with GNU Make; see the file  COPYING.  If  not,  write
# to the Free Software Foundation, Inc., 51 Franklin St,  Fifth Floor,
# Boston, MA 02110-1301 USA.

# 19-12-2024 This is a fixed file from check_mk 1.2.8p27 that is
# rewriiten to work with python3
# Many Thanks to https://galaxy.ai/ai-python-code-fixer

# Call with -d for debug mode: colored output, no saving of status


import sys
import os
import re
import time
import glob
import shutil

# Check for debug mode
debug = '-d' in sys.argv[1:] or '--debug' in sys.argv[1:]

# Define terminal colors for debug output
tty_red = '\033[1;31m' if debug else ''
tty_green = '\033[1;32m' if debug else ''
tty_yellow = '\033[1;33m' if debug else ''
tty_blue = '\033[1;34m' if debug else ''
tty_normal = '\033[0m' if debug else ''

# Determine logwatch directory
logwatch_dir = os.getenv("LOGWATCH_DIR") or os.getenv("MK_CONFDIR") or "."
mk_vardir =  os.getenv("MK_VARDIR") or logwatch_dir
mk_confdir = os.getenv("MK_CONFDIR") or os.getenv("LOGWATCH_DIR") or "."

print("<<<logwatch>>>")

config_filename = os.path.join(logwatch_dir, "logwatch.cfg")
config_dir = os.path.join(logwatch_dir, "logwatch.d", "*.cfg")

# Determine the name of the state file
remote_hostname = os.getenv("REMOTE", "")
if remote_hostname:
    status_filename = os.path.join(mk_vardir, f"logwatch.state.{remote_hostname}")
else:
    status_filename = os.path.join(mk_vardir, "logwatch.state.local" if sys.stdout.isatty() else "logwatch.state")

# Copy last known state if necessary
if not os.path.exists(status_filename) and os.path.exists(os.path.join(mk_vardir, "logwatch.state")):
    shutil.copy(os.path.join(mk_vardir, "logwatch.state"), status_filename)

def is_not_comment(line):
    return not (line.lstrip().startswith('#') or line.strip() == '')

def parse_filenames(line):
    return line.split()

def parse_pattern(level, pattern, line):
    if level not in ['C', 'W', 'I', 'O']:
        raise ValueError(f"Invalid pattern line '{line}'")
    try:
        compiled = re.compile(pattern)
    except re.error:
        raise ValueError(f"Invalid regular expression in line '{line}'")
    return level, compiled

def read_config():
    with open(mk_confdir + "/logwatch.cfg", "r") as config_file:
        config_lines = [line.rstrip() for line in filter(is_not_comment, config_file.readlines())]
    for config_file in glob.glob(config_dir):
        config_lines += [line.rstrip() for line in filter(is_not_comment, open(config_file).readlines())]

    have_filenames = False
    config = []
    patterns = []

    for line in config_lines:
        if line[0].isspace():  # pattern line
            if not have_filenames:
                raise ValueError("Missing logfile names")
            level, pattern = line.split(None, 1)
            if level == 'A':
                cont_list.append(parse_cont_pattern(pattern))
            elif level == 'R':
                rewrite_list.append(pattern)
            else:
                level, compiled = parse_pattern(level, pattern, line)
                cont_list = []  # List of continuation patterns
                rewrite_list = []  # List of rewrite patterns
                patterns.append((level, compiled, cont_list, rewrite_list))
        else:  # filename line
            patterns = []
            config.append((parse_filenames(line), patterns))
            have_filenames = True
    return config

def parse_cont_pattern(pattern):
    try:
        return int(pattern)
    except ValueError:
        try:
            return re.compile(pattern)
        except re.error:
            raise ValueError(f"Invalid regular expression in line '{pattern}'")

def read_status():
    status = {}
    with open(status_filename) as f:
        for line in f:
            parts = line.split('|')
            filename = parts[0]
            offset = parts[1]
            inode = parts[2] if len(parts) >= 3 else -1
            status[filename] = (int(offset), int(inode))
    return status

def save_status(status):
    with open(status_filename, "w") as f:
        for filename, (offset, inode) in status.items():
            f.write(f"{filename}|{offset}|{inode}\n")

pushed_back_line = None

def next_line(file_handle):
    global pushed_back_line
    if pushed_back_line is not None:
        line = pushed_back_line
        pushed_back_line = None
        return line
    else:
        line = file_handle.readline()
        if not line:
            return None
        if not line.endswith(os.linesep):
            pushed_back_line = line
            return None
        return line

def process_logfile(logfile, patterns):
    global pushed_back_line
    offset, prev_inode = status.get(logfile, (-1, -1))
    try:
        file_desc = os.open(logfile, os.O_RDONLY)
        inode = os.fstat(file_desc).st_ino
    except OSError:
        if debug:
            raise
        print(f"[[[{logfile}:cannotopen]]]")
        return

    print(f"[[[{logfile}]]]")
    current_end = os.lseek(file_desc, 0, os.SEEK_END)
    status[logfile] = (current_end, inode)

    if offset == -1:
        if not debug:
            return
        else:
            offset = 0

    if prev_inode >= 0 and inode != prev_inode:
        offset = 0

    if offset == current_end:
        return

    if offset > current_end:
        offset = 0

    os.lseek(file_desc, offset, os.SEEK_SET)
    file_handle = os.fdopen(file_desc)
    worst = -1
    outputtxt = ""
    lines_parsed = 0
    start_time = time.time()

    while True:
        line = next_line(file_handle)
        if line is None:
            break

        lines_parsed += 1
        if opt_maxlines is not None and lines_parsed > opt_maxlines:
            outputtxt += f"{opt_overflow} Maximum number ({opt_maxlines}) of new log messages exceeded.\n"
            worst = max(worst, opt_overflow_level)
            os.lseek(file_desc, 0, os.SEEK_END)
            break

        level = "."
        for lev, pattern, cont_patterns, replacements in patterns:
            if pattern.search(line[:-1]):
                level = lev
                levelint = {'C': 2, 'W': 1, 'O': 0, 'I': -1, '.': -1}[lev]
                worst = max(levelint, worst)

                for cont_pattern in cont_patterns:
                    if isinstance(cont_pattern, int):
                        for _ in range(cont_pattern):
                            cont_line = next_line(file_handle)
                            if cont_line is None:
                                break
                            line = line[:-1] + "\1" + cont_line
                    else:
                        while True:
                            cont_line = next_line(file_handle)
                            if cont_line is None:
                                break
                            elif cont_pattern.search(cont_line[:-1]):
                                line = line[:-1] + "\1" + cont_line
                            else:
                                pushed_back_line = cont_line
                                break

                for replace in replacements:
                    line = replace.replace('\\0', line.rstrip()) + "\n"
                    for nr, group in enumerate(matches.groups()):
                        line = line.replace(f'\\{nr+1}', group)

                break

        color = {'C': tty_red, 'W': tty_yellow, 'O': tty_green, 'I': tty_blue, '.': ''}[level]
        if debug:
            line = line.replace("\1", "\nCONT:")
        if level == "I":
            level = "."
        if opt_nocontext and level == '.':
            continue
        outputtxt += f"{color}{level} {line[:-1]}{tty_normal}\n"

    new_offset = os.lseek(file_desc, 0, os.SEEK_CUR)
    status[logfile] = (new_offset, inode)

    if worst > -1:
        sys.stdout.write(outputtxt)
        sys.stdout.flush()

    if opt_maxfilesize is not None and (offset / opt_maxfilesize) < (new_offset / opt_maxfilesize):
        sys.stdout.write(f"{tty_yellow}W Maximum allowed logfile size ({opt_maxfilesize} bytes) exceeded for the {new_offset / opt_maxfilesize}th time.{tty_normal}\n")

try:
    config = read_config()
except Exception as e:
    if debug:
        raise
    print(f"CANNOT READ CONFIG FILE: {e}")
    sys.exit(1)

try:
    status = read_status()
except Exception:
    status = {}

logfile_patterns = {}
for filenames, patterns in config:
    opt_maxlines = opt_maxtime = opt_maxlinesize = opt_maxfilesize = None
    opt_regex = None
    opt_overflow = 'C'
    opt_overflow_level = 2
    opt_nocontext = False
    try:
        options = [o.split('=', 1) for o in filenames if '=' in o]
        for key, value in options:
            if key == 'maxlines':
                opt_maxlines = int(value)
            elif key == 'maxtime':
                opt_maxtime = float(value)
            elif key == 'maxlinesize':
                opt_maxlinesize = int(value)
            elif key == 'maxfilesize':
                opt_maxfilesize = int(value)
            elif key == 'overflow':
                if value not in ['C', 'I', 'W', 'O']:
                    raise ValueError(f"Invalid value {value} for overflow. Allowed are C, I, O and W")
                opt_overflow = value
                opt_overflow_level = {'C': 2, 'W': 1, 'O': 0, 'I': 0}[value]
            elif key == 'regex':
                opt_regex = re.compile(value)
            elif key == 'iregex':
                opt_regex = re.compile(value, re.I)
            elif key == 'nocontext':
                opt_nocontext = True
            else:
                raise ValueError(f"Invalid option {key}")
    except Exception as e:
        if debug:
            raise
        print(f"INVALID CONFIGURATION: {e}")
        sys.exit(1)

    for glob_pattern in filenames:
        if '=' in glob_pattern:
            continue
        logfiles = glob.glob(glob_pattern)
        if opt_regex:
            logfiles = [f for f in logfiles if opt_regex.search(f)]
        if not logfiles:
            print(f'[[[{glob_pattern}:missing]]]')
        else:
            for logfile in logfiles:
                logfile_patterns[logfile] = logfile_patterns.get(logfile, []) + patterns

for logfile, patterns in logfile_patterns.items():
    process_logfile(logfile, patterns)

if not debug:
    save_status(status)
