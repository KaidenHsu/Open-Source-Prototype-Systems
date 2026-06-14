#!/usr/bin/env bash
set -euo pipefail

# get script directory instead of current directory
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# check verilator is in PATH
if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator binary not found in PATH" >&2
    exit 1
fi

# avoid locale warnings in minimal containers (en_US.UTF-8 not installed)
export LANG=C.utf8
export LC_ALL=C.utf8
unset LANGUAGE

echo "============================"
echo "           build"
echo "============================"
make -C $ROOT_DIR clean
make -C $ROOT_DIR all

printf "\n\n"
echo "============================"
echo "           QEMU"
echo "============================"
bash /opt/osp-xhist/scripts/run_qemu_baseline.sh 
bash /opt/osp-xhist/scripts/run_qemu_xhist.sh

printf "\n\n"
echo "============================"
echo "           gem5"
echo "============================"
bash /opt/osp-xhist/scripts/run_gem5_baseline.sh 
bash /opt/osp-xhist/scripts/run_gem5_xhist.sh

printf "\n\n"
echo "============================"
echo "       parse stats"
echo "============================"
echo "*** baseline ***"
grep -E "simInsts|numCycles|ipc|overallMisses" results/gem5_baseline/uniform/stats.txt 
 
printf "\n"
echo "*** xhist ***"
grep -E "simInsts|numCycles|ipc|overallMisses" results/gem5_xhist/uniform/stats.txt

printf "\n"
python3 /opt/osp-xhist/scripts/collect_stats.py results/gem5_baseline/uniform/stats.txt results/gem5_xhist/uniform/stats.txt

printf "\n\n"
echo "============================"
echo "    distribution tests"
echo "============================"
bash /opt/osp-xhist/scripts/run_gem5_distribution.sh

printf "\n\n"
echo "============================"
echo "        cache sweep"
echo "============================"
bash /opt/osp-xhist/scripts/run_gem5_cache_sweep.sh

printf "\n\n"
echo "============================"
echo "      xhpack microtest"
echo "============================"
bash /opt/osp-xhist/scripts/run_qemu_xhpack.sh


