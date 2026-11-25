export DESIGN_NAME      = pe
export DESIGN_NICKNAME  = pe
export PLATFORM         = nangate45

export VERILOG_FILES    = $(sort $(wildcard $(WORK_HOME)/designs/src/pe/*.sv))
export SDC_FILE         = $(WORK_HOME)/designs/nangate45/pe/constraint.sdc

export CORE_UTILIZATION = 40
