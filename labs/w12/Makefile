RISCV_CC ?= riscv64-linux-gnu-gcc
CFLAGS   ?= -O2 -static -march=rv64gc -mabi=lp64d
MODE ?= uniform

ifeq ($(MODE),uniform)
MODE_DEFINE :=
else ifeq ($(MODE),hot-bin-clustered)
MODE_DEFINE := -DMODE_HOT_BIN_CLUSTERED
else ifeq ($(MODE),out-of-range-heavy)
MODE_DEFINE := -DMODE_OUT_OF_RANGE_HEAVY
else ifeq ($(MODE),adversarial-stride)
MODE_DEFINE := -DMODE_ADVERSARIAL_STRIDE
else
$(error unsupported MODE '$(MODE)')
endif

BUILD_DIR := build
BASELINE_BIN := $(BUILD_DIR)/hist_baseline.$(MODE).riscv
XHIST_BIN := $(BUILD_DIR)/hist_xhist.$(MODE).riscv

all: baseline xhist

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

baseline: $(BASELINE_BIN)

$(BASELINE_BIN): src/hist_baseline.c | $(BUILD_DIR)
	$(RISCV_CC) $(CFLAGS) $(MODE_DEFINE) -o $@ $<

xhist: $(XHIST_BIN)

$(XHIST_BIN): src/hist_xhist.c | $(BUILD_DIR)
	$(RISCV_CC) $(CFLAGS) $(MODE_DEFINE) -o $@ $<

clean:
	rm -rf $(BUILD_DIR) results
