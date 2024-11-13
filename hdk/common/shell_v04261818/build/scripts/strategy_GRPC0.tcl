source $HDK_SHELL_DIR/build/scripts/params.tcl
source $HDK_SHELL_DIR/build/scripts/uram_options.tcl

# Most options are removed and driven by the directive defaults
# See UG901 "Vivado Preconfigured Stategies"  (Table 1-2, pp43, v2021.2)
# Leave retiming in because one can dream.
set synth_options "$synth_uram_option -retiming"
# these seem to be fine
# these needed to avoid segfault (one of these different causes segfault?)
append synth_options " -fsm_extraction off"
append synth_options " -resource_sharing auto"
append synth_options " -no_lc"
append synth_options " -shreg_min_size 5"

set synth_directive "AreaOptimized_high"

# Everything after this point is identical to the Timing strategy and should be
# explored for future area savings.

#Set psip to 1 to enable Physical Synthesis in Placer
set psip 0

set link 1

set opt 1
set opt_options    ""
set opt_directive  "Explore"
set opt_preHookTcl  "$HDK_SHELL_DIR/build/scripts/check_uram.tcl"
set opt_postHookTcl "$HDK_SHELL_DIR/build/scripts/apply_debug_constraints.tcl"

set place 1
set place_options    ""
set place_directive  "ExtraNetDelay_high"
set place_preHookTcl ""
set place_postHookTcl ""

set phys_opt 1
set phys_options     ""
set phys_directive   "AggressiveExplore"
set phys_preHookTcl  ""
set phys_postHookTcl ""

set route 1
set route_options    "-tns_cleanup"
set route_directive  "Explore"
set route_preHookTcl ""
set route_postHookTcl ""

set route_phys_opt 1
set post_phys_options     ""
set post_phys_directive   "AggressiveExplore"
set post_phys_preHookTcl  ""
set post_phys_postHookTcl ""

