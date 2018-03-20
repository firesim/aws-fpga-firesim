# This contains the CL specific constraints for synthesis at the CL level

#get_cells firesim_top/top/SimpleNICWidget_0/incomingPCISdat/BRAMQueue/fq/ram*

set_property RAM_STYLE ULTRA [get_cells firesim_top/top/SimpleNICWidget_0/incomingPCISdat/BRAMQueue/fq/ram_reg]
set_property RAM_STYLE ULTRA [get_cells firesim_top/top/SimpleNICWidget_0/outgoingPCISdat/BRAMQueue/fq/ram_reg]
