# ============================================================
# Week 15 Two-Hour RTL Exercise
# Shared Accelerator Arbiter Lab
#
# Main commands:
#   make env-check
#   make sim POLICY=fixed
#   make sim POLICY=rr CHECK_FAIR=1
#   make check
#   make compare
#   make yosys POLICY=rr
#   make wave POLICY=rr CHECK_FAIR=1 TRACE=1
#   make clean
# ============================================================

SHELL := /bin/bash

# -----------------------------
# Tool configuration
# -----------------------------
VERILATOR ?= verilator
YOSYS     ?= yosys
PYTHON    ?= python3

# -----------------------------
# Project files
# -----------------------------
TOP     := tb_shared_accel_arbiter
RTL_DIR := rtl
TB_DIR  := tb

RTL_SRCS := $(RTL_DIR)/shared_accel_arbiter.sv \
            $(RTL_DIR)/shared_accel_lane.sv \
            $(RTL_DIR)/shared_accel_top.sv
TB_SRCS  := $(TB_DIR)/tb_shared_accel_arbiter.sv
SV_SRCS  := $(RTL_SRCS) $(TB_SRCS)

BUILD_DIR  := build
LOG_DIR    := logs
RESULT_DIR := results
REPORT_DIR := yosys_reports
WAVE_DIR   := waves

# -----------------------------
# Simulation parameters
# -----------------------------
POLICY ?= fixed
N0 ?= 32
N1 ?= 32
LANE_LATENCY ?= 4
AGE_LIMIT ?= 8
MAX_CYCLES ?= 1000
CHECK_FAIR ?= 0
FAIR_MAX_WAIT ?= 32
TRACE ?= 0

# -----------------------------
# Policy mapping
# -----------------------------
ifeq ($(POLICY),fixed)
POLICY_ID := 0
else ifeq ($(POLICY),rr)
POLICY_ID := 1
else ifeq ($(POLICY),aging)
POLICY_ID := 2
else
$(error Unsupported POLICY='$(POLICY)'. Use POLICY=fixed, POLICY=rr, or POLICY=aging)
endif

TRACE_FLAG := $(if $(filter 1,$(TRACE)),--trace,)
SIM_BIN := obj_dir/V$(TOP)
SIM_LOG := $(LOG_DIR)/$(POLICY)_sim.log
CSV_OUT := $(RESULT_DIR)/$(POLICY)_metrics.csv

.PHONY: help dirs env-check build sim sim-fixed sim-rr fixed rr check compare wave waves yosys synth clean

help:
	@echo ""
	@echo "Week 15 Shared Accelerator Arbiter Exercise"
	@echo ""
	@echo "Common commands:"
	@echo "  make env-check"
	@echo "  make sim POLICY=fixed"
	@echo "  make sim POLICY=rr CHECK_FAIR=1"
	@echo "  make check"
	@echo "  make compare"
	@echo "  make yosys POLICY=rr"
	@echo "  make wave POLICY=rr CHECK_FAIR=1 TRACE=1"
	@echo "  make clean"
	@echo ""
	@echo "Useful parameters:"
	@echo "  POLICY=fixed|rr|aging"
	@echo "  CHECK_FAIR=0|1"
	@echo "  FAIR_MAX_WAIT=32"
	@echo "  N0=32 N1=32"
	@echo "  LANE_LATENCY=4"
	@echo "  TRACE=0|1"
	@echo ""

dirs:
	@mkdir -p $(BUILD_DIR) $(LOG_DIR) $(RESULT_DIR) $(REPORT_DIR) $(WAVE_DIR) obj_dir

env-check: dirs
	bash docker/verify_env.sh

build: dirs
	$(VERILATOR) -sv --binary --timing -Wall -Wno-fatal $(TRACE_FLAG) \
		--top-module $(TOP) \
		-GARB_POLICY=$(POLICY_ID) \
		-GLANE_LATENCY=$(LANE_LATENCY) \
		-GAGE_LIMIT=$(AGE_LIMIT) \
		$(SV_SRCS)

# ------------------------------------------------------------
# Run one simulation.
# Classroom behavior:
# - Functional failures and timeouts remain fatal.
# - Fairness failure is printed in the log but does not abort simulation.
# - Use "make check" when you want strict pass/fail grading.
# ------------------------------------------------------------
sim: build
	@echo ""
	@echo "Running simulation: POLICY=$(POLICY) POLICY_ID=$(POLICY_ID) CHECK_FAIR=$(CHECK_FAIR) FAIR_MAX_WAIT=$(FAIR_MAX_WAIT) N0=$(N0) N1=$(N1)"
	@set -o pipefail; \
	$(SIM_BIN) \
		+N0=$(N0) \
		+N1=$(N1) \
		+MAX_CYCLES=$(MAX_CYCLES) \
		+CHECK_FAIR=$(CHECK_FAIR) \
		+FAIR_MAX_WAIT=$(FAIR_MAX_WAIT) \
		+TRACE=$(TRACE) \
		| tee $(SIM_LOG); \
	sim_status=$$?; \
	if [ -f "$(SIM_LOG)" ]; then \
		$(PYTHON) scripts/parse_sim_log.py $(SIM_LOG) $(CSV_OUT); \
	fi; \
	if [ $$sim_status -ne 0 ]; then \
		echo ""; \
		echo "ERROR: Simulator exited with status $$sim_status."; \
		echo "       Functional correctness failures and timeouts are intentionally fatal."; \
		exit $$sim_status; \
	fi
	@echo "Simulation log: $(SIM_LOG)"
	@echo "Metrics CSV:    $(CSV_OUT)"

sim-fixed fixed:
	@$(MAKE) --no-print-directory sim POLICY=fixed CHECK_FAIR=0

sim-rr rr:
	@$(MAKE) --no-print-directory sim POLICY=rr CHECK_FAIR=1

# Strict check: this should fail on the unmodified student starter and pass on the instructor solution.
check: dirs
	@echo ""
	@echo "Checking logs..."
	@if grep -q "FAIL correctness" $(LOG_DIR)/fixed_sim.log; then \
		echo "FAIL: Fixed-priority simulation failed correctness."; exit 1; \
	fi
	@if grep -q "FAIL correctness" $(LOG_DIR)/rr_sim.log; then \
		echo "FAIL: Round-robin simulation failed correctness."; exit 1; \
	fi
	@if grep -q "FAIL fairness" $(LOG_DIR)/rr_sim.log; then \
		echo "FAIL: Round-robin policy is still unfair."; \
		echo "Hint: Implement the ARB_POLICY == 1 branch in rtl/shared_accel_arbiter.sv."; \
		exit 1; \
	fi
	@if ! grep -q "PASS fairness" $(LOG_DIR)/rr_sim.log; then \
		echo "FAIL: Round-robin simulation did not report PASS fairness."; exit 1; \
	fi
	@echo "PASS: Correctness and fairness checks passed."

compare: dirs
	@$(PYTHON) scripts/compare_metrics.py $(RESULT_DIR)/fixed_metrics.csv $(RESULT_DIR)/rr_metrics.csv

wave waves:
	@$(MAKE) --no-print-directory sim POLICY=$(POLICY) CHECK_FAIR=$(CHECK_FAIR) TRACE=1
	@if [ -f $(WAVE_DIR)/shared_accel_arbiter.vcd ]; then \
		echo "Waveform written to $(WAVE_DIR)/shared_accel_arbiter.vcd"; \
	else \
		echo "No waveform found. Check TRACE=1 and testbench dumpfile settings."; \
	fi

yosys synth: dirs
	$(YOSYS) -p "read_verilog -sv $(RTL_SRCS); chparam -set ARB_POLICY $(POLICY_ID) shared_accel_top; chparam -set LANE_LATENCY $(LANE_LATENCY) shared_accel_top; chparam -set AGE_LIMIT $(AGE_LIMIT) shared_accel_top; synth -top shared_accel_top; stat" \
		> $(REPORT_DIR)/$(POLICY)_area.txt
	@echo "Yosys report: $(REPORT_DIR)/$(POLICY)_area.txt"

clean:
	rm -rf obj_dir waves
