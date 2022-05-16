# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

# A baseline resource-minimizing strategy originally based off the TIMING strategy.

source $HDK_SHELL_DIR/build/scripts/params.tcl
source $HDK_SHELL_DIR/build/scripts/uram_options.tcl

# Most options are removed and driven by the directive defaults
# See UG901 "Vivado Preconfigured Stategies"  (Table 1-2, pp43, v2021.2)
# Leave retiming in because one can dream.
set synth_options "$synth_uram_option -retiming"
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
set phys_directive   ""
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

