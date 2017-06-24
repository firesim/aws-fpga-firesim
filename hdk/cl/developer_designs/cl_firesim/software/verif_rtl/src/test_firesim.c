// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Vivado does not support svGetScopeFromName
#ifdef INCLUDE_DPI_CALLS
#ifndef VIVADO_SIM
#include "svdpi.h"
#endif
#endif

#include "sh_dpi_tasks.h"

#define HELLO_WORLD_REG_ADDR UINT64_C(0x00)

#define RESET_REG UINT64_C(0x0)
#define SOMETHING_REG UINT64_C(0x20)

void test_main(uint32_t *exit_code) {

// Vivado does not support svGetScopeFromName
#ifdef INCLUDE_DPI_CALLS
#ifndef VIVADO_SIM
  svScope scope;
#endif
#endif

  uint32_t rdata;

// Vivado does not support svGetScopeFromName
#ifdef INCLUDE_DPI_CALLS
#ifndef VIVADO_SIM
  scope = svGetScopeFromName("tb");
  svSetScope(scope);
#endif
#endif

  log_printf("HELLO! THIS IS SAGAR\n");

  // TODO: not clear: how does time/cycles factor in here?
  // ideally it works just like real software interfacing with the FPGA?
  log_printf("writing somethingreg 1\n");
  cl_poke(SOMETHING_REG, 0x1);


  rdata = 0;
  while (rdata == 0) {
      cl_peek(0x28, &rdata);
      log_printf("from 0x28 got: 0x%x\n", rdata);
  }




  log_printf("writing reset a\n");
  cl_poke(RESET_REG, 0xA);
  log_printf("writing reset 0\n");
  cl_poke(RESET_REG, 0x0);

  //cl_peek(BOOTROM_TESTREG, &rdata);

//  log_printf("Reading 0x%x from address 0x%x", rdata, BOOTROM_TESTREG);

//  if (rdata == 0xEFBEADDE) {
//    log_printf("Test PASSED");
//  } else {
//    log_printf("Test FAILED");
//  }

  *exit_code = 0;
}
