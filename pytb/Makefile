CWD=$(shell pwd)
export COCOTB_REDUCED_LOG_FMT = 1
#export COCOTB_SCHEDULER_DEBUG = 1
#export COCOTB_LOG_LEVEL = DEBUG
#export COVERAGE=1
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
ifeq ($(TOPLEVEL_LANG),verilog)
	VERILOG_SOURCES = $(CWD)/../rtl/simple_dpram_sclk.v \
                          $(CWD)/../rtl/fifo.v \
                          $(CWD)/../rtl/fifo_fwft_adapter.v \
                          $(CWD)/../rtl/fifo_fwft.v \
                          $(CWD)/../rtl/switch.sv \
                          $(CWD)/rtl_top.sv
else
    $(error "A valid value verilog was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG)")
endif
MODULE := tests
TOPLEVEL = packet_router
GHDL_ARGS := --ieee=synopsys
ifeq ($(SIM), verilator)
	COMPILE_ARGS += --timing
	EXTRA_ARGS += --coverage --trace --trace-structs
endif
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 100ps
include $(shell cocotb-config --makefiles)/Makefile.sim
include ../.cleanall.mk
