# This contains the CL specific constraints for synthesis at the CL level

# Add F1 specific constraints here -- constraints common to different FPGA host
# platforms should be generated during Golden Gate compilation to ensure
# portability.  See XDCAnnotation + WriteXDCFile pass for more information.

# map L2 banks to URAMs
set_property RAM_STYLE ULTRA [get_cells -hierarchical -regexp firesim_top.*cc_banks_.*_reg.*]
