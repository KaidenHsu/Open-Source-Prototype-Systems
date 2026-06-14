IMAGE ?= amansinhaatnycu/osp:week13-power
WORKLOAD ?= workloads/array_sum.c

.PHONY: docker check smoke build gem5 mcpat summarize full clean

docker:
	docker run --rm -it -v "$$(pwd)":/work -w /work $(IMAGE) bash

check:
	bash scripts/00_check_tools.sh

smoke:
	bash scripts/06_mcpat_smoke_test.sh

build:
	bash scripts/01_build_workloads.sh $(WORKLOAD)

gem5: build
	bash scripts/02_run_gem5_sweep.sh build/$$(basename $(WORKLOAD) .c).riscv

mcpat:
	bash scripts/04_run_mcpat_sweep.sh

summarize:
	python3 scripts/05_summarize_results.py results

full: check smoke build gem5 mcpat summarize

clean:
	rm -rf build results/*
