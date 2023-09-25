CWD=$(shell pwd)
export COCOTB_REDUCED_LOG_FMT = 1
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
ifeq ($(TOPLEVEL_LANG),verilog)
	VERILOG_SOURCES = $(CWD)/rtl/simple_dpram_sclk.v \
					  $(CWD)/rtl/fifo.v \
                      $(CWD)/rtl/fifo_fwft_adapter.v \
                      $(CWD)/rtl/fifo_fwft.v \
                      $(CWD)/rtl/switch.sv
else
    $(error "A valid value verilog was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG)")
endif
MODULE := tests
TOPLEVEL = switch
GHDL_ARGS := --ieee=synopsys
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 100ps
include $(shell cocotb-config --makefiles)/Makefile.sim
include ../cleanall.mk