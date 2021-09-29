# This contains the CL specific constraints for synthesis at the CL level

set_property RAM_STYLE ULTRA [get_cells -hierarchical -regexp firesim_top.*PCISdat/fq/ram_reg.*]
