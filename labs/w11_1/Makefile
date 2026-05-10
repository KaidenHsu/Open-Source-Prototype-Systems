TOP=tb_week11
RTL=rtl/two_core_cache_system.sv rtl/tb_week11.sv
VERILATOR_FLAGS=-sv --timing --binary  --top-module $(TOP) -Wno-fatal -Wno-DECLFILENAME -Wno-BLKSEQ
TRACE_DEFAULT=traces/coherence_directed.trace

.PHONY: clean build-baseline run-baseline run-case-b run-case-c run-case-d run-all trace-check generate-traces gem5-producer-consumer gem5-check

clean:
	rm -rf obj_dir

build-baseline:
	verilator $(VERILATOR_FLAGS) -GLAB_VARIANT=0 $(RTL)

run-baseline:
	./obj_dir/V$(TOP) +TRACE=$(TRACE_DEFAULT) | tee logs/baseline.log

run-case-b:
	verilator $(VERILATOR_FLAGS) -GLAB_VARIANT=1 $(RTL)
	./obj_dir/V$(TOP) +TRACE=traces/coherence_directed.trace | tee logs/case_b.log

run-case-c:
	verilator $(VERILATOR_FLAGS) -GLAB_VARIANT=2 $(RTL)
	./obj_dir/V$(TOP) +TRACE=traces/address_alias.trace | tee logs/case_c.log

run-case-d:
	verilator $(VERILATOR_FLAGS) -GLAB_VARIANT=3 $(RTL)
	./obj_dir/V$(TOP) +TRACE=traces/simultaneous_race.trace | tee logs/case_d.log

run-raw-trace:
	verilator $(VERILATOR_FLAGS) -GLAB_VARIANT=0 $(RTL)
	./obj_dir/V$(TOP) +TRACE=traces/raw.trace | tee logs/raw_trace.log

run-all: run-baseline run-case-b run-case-c run-case-d run-raw_trace

trace-check:
	@echo "Checking all .trace files in traces/"
	@rc=0; \
	for f in traces/*.trace; do \
		if [ -f "$$f" ]; then \
			echo "  checking $$f"; \
			python3 scripts/check_trace.py "$$f" || rc=$$?; \
		fi; \
	done; \
	exit $$rc

generate-traces:
	python3 scripts/make_traces.py

gem5-producer-consumer:
	bash gem5/run_producer_consumer.sh

gem5-check: gem5-producer-consumer
