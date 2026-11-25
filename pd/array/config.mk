export DESIGN_NAME      = array_top
export DESIGN_NICKNAME  = array
export PLATFORM         = nangate45

export VERILOG_FILES    = $(sort $(wildcard $(WORK_HOME)/designs/src/array/*.sv))
export SDC_FILE         = $(WORK_HOME)/designs/nangate45/array/constraint.sdc

export CORE_UTILIZATION = 40
