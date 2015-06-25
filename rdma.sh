#!/bin/bash
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
##     A simple shell script to call the rdma-client.fio and
##     rdma-server.fio scripts with enviroment variables setup.
##
########################################################################

  # Parameters for running FIO
MODE=server
FILENAME=/sys/bus/pci/devices/0000:06:00.0/resource4
NUM_JOBS=1
SIZE=1G
IO_DEPTH=1
BLOCK_SIZE=512
FIOEXE=fio
RUNTIME=10
PORT=12345

  # Accept some key parameter changes from the command line.
while getopts "x:t:b:n:f:i:s:p:m" opt; do
    case "$opt" in
	x)  FIOEXE=${OPTARG}
            ;;
	t)  RUNTIME=${OPTARG}
            ;;
	b)  BLOCK_SIZE=${OPTARG}
            ;;
	n)  NUM_JOBS=${OPTARG}
            ;;
	f)  FILENAME=${OPTARG}
            ;;
	i)  IO_DEPTH=${OPTARG}
            ;;
	s)  SIZE=${OPTARG}
            ;;
	p)  PORT=${OPTARG}
            ;;
    m)  MODE=client
            ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
	    ;;
    esac
done

if [ ! -e "$FILENAME" ]; then
     echo "rdma.sh: You must specify an existing file or block IO device"
     exit 1
fi
if [ ! -b "$FILENAME" ]; then
    if [ ! -f "$FILENAME" ]; then
	echo "rdma.sh: Only block devices or regular files are permitted"
	exit 1
    fi
    if [ ! -r "$FILENAME" ] && [ ! -w "$FILENAME" ]; then
	echo "rdma.sh: Do not have read and write access to the target file"
	exit 1
    fi
fi

if [ ${MODE}='master' ]; then
    MEM=mmap:${FILENAME} SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} \
        BLOCK_SIZE=${BLOCK_SIZE} PORT=${PORT} IO_DEPTH=${IO_DEPTH} \
        ${FIOEXE} ./fio-scripts/rdma-${MODE}.fio
else
    SIZE=${SIZE} NUM_JOBS=${NUM_JOBS} IO_DEPTH=${IO_DEPTH} \
        BLOCK_SIZE=${BLOCK_SIZE} RUNTIME=${RUNTIME} PORT=${PORT} \
        ${FIOEXE} ./fio-scripts/rdma-${MODE}.fio
fi
