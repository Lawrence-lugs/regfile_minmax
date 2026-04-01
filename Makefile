SHELL := /bin/bash

PYTHON ?= python
SWEEP  ?= all

FLOW_DEPS := flow/run_sweep.py flow/parse_reports.py flow/synth.tcl
FLOW_DEPS += $(wildcard flow/abc_files/*)
RTL_DEPS  := $(wildcard rtl/*.sv)
SYNTH_DEPS := $(FLOW_DEPS) $(RTL_DEPS)

PLOT_DEPS := flow/generate_plots.py results/summary.csv
PLOT_FILES := results/port_sweep.png results/port_scaling_fit.png results/bitwidth_sweep.png \
	results/regcount_sweep.png results/banking_sweep.png results/area_heatmap.png

.PHONY: help sweep sweep-all sweep-port sweep-bitwidth sweep-regcount sweep-banking \
	plot smoke clean

help:
	@echo "Regfile synthesis flow"
	@echo ""
	@echo "Targets:"
	@echo "  make sweep              # Build selected results target (SWEEP=all|port|bitwidth|regcount|banking)"
	@echo "  make sweep-all          # Build all synthesis result folders"
	@echo "  make sweep-port         # Build results/port"
	@echo "  make sweep-bitwidth     # Build results/bitwidth"
	@echo "  make sweep-regcount     # Build results/regcount"
	@echo "  make sweep-banking      # Build results/banking"
	@echo "  make plot               # Build results/*.png from results/summary.csv"
	@echo "  make smoke              # Run one smoke synthesis"
	@echo "  make clean              # Remove generated plots and summary CSV"

sweep: sweep-$(SWEEP)

sweep-all: results/port results/bitwidth results/regcount results/banking

sweep-port: results/port

sweep-bitwidth: results/bitwidth

sweep-regcount: results/regcount

sweep-banking: results/banking

results/port: $(SYNTH_DEPS)
	$(PYTHON) flow/run_sweep.py --sweep port --force
	@mkdir -p $@
	@touch $@

results/bitwidth: $(SYNTH_DEPS)
	$(PYTHON) flow/run_sweep.py --sweep bitwidth --force
	@mkdir -p $@
	@touch $@

results/regcount: $(SYNTH_DEPS)
	$(PYTHON) flow/run_sweep.py --sweep regcount --force
	@mkdir -p $@
	@touch $@

results/banking: $(SYNTH_DEPS)
	$(PYTHON) flow/run_sweep.py --sweep banking --force
	@mkdir -p $@
	@touch $@

results/summary.csv: results/port results/bitwidth results/regcount results/banking
	@echo "summary.csv updated by sweep targets"

$(PLOT_FILES): $(PLOT_DEPS)
	$(PYTHON) flow/generate_plots.py

plot: $(PLOT_FILES)

smoke:
	bash flow/smoke_test.sh

clean:
	rm -f results/summary.csv
	rm -f results/*.png