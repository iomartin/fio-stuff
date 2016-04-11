#!/usr/bin/env python
########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0 Unless required by
## applicable law or agreed to in writing, software distributed under the
## License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
## CONDITIONS OF ANY KIND, either express or implied. See the License for
## the specific language governing permissions and limitations under the
## License.
##
########################################################################

########################################################################
##
##   Description:
##     A post-processor for the f2fs scripting stuff.
##
########################################################################

from __future__ import print_function
from __future__ import unicode_literals

import re
import subprocess as sp

class ParseException(Exception):
    pass

def fibmap(inp_file):
    """A post-processing file for the fibmap output."""

    fin = open(inp_file,'r')
    fout = open(inp_file+'.out','w')

    rhdr = re.compile(r"^filesystem blocksize (?P<blocksize>\d+), "
                      "begins at LBA (?P<lba_start>\d+); "
                      "assuming (?P<sector_size>\d+) byte sectors.$")

    hdr = None
    for l in fin:
        l = l.strip()
        m = rhdr.match(l)
        if m:
            hdr = m.groupdict()
            hdr = {k: int(v) for k, v in hdr.items()}
            continue
        if l.startswith("byte_offset"):
            break

    if not hdr:
        raise ParseException("Unable to parse fibmap file. No valid header.")

    def output_line(*args):
        fout.write("{} {}\n".format(*args))

    for l in fin:
        offset, lba_start, lba_end, sectors = [int(x) for x in l.split()]

        output_line(offset, lba_start)
        output_line(offset + (sectors-1)*hdr["sector_size"], lba_end)


def blktrace(inp_file):
    """A post-processing file for the blktrace output."""

    fin = open(inp_file, "r")
    fout = open(inp_file+".out", "w")
    p = sp.Popen(["blkparse", "-q", "-f", "%T.%9t %a %d %S %n\n", "-i", "-"],
                 stdin=fin, stdout=sp.PIPE)
    lines, _ = p.communicate()

    for l in lines.split("\n"):
        if not l: continue
        timestamp, cmd, rw, sector, count = l.split()

        if cmd != "C": continue

        sector = int(sector)
        count = int(count)
        last = sector + count - 1
        direction = 1 if "R" in rw else 0

        if not count: continue

        fout.write("{} {} {} {}\n".format(timestamp, sector, last, direction))

if __name__=="__main__":
    import sys
    import argparse

    parser = argparse.ArgumentParser(description=
                                     "post process f2fs_test script output")
    parser.add_argument("-f", "--fibmap", required=True,
                        help="the fibmap file")
    parser.add_argument("-b", "--blktrace", required=True,
                        help="the blktrace file")
    args = parser.parse_args()

    try:
        fibmap(args.fibmap)
        blktrace(args.blktrace)
    except Exception as e:
        print(e)
