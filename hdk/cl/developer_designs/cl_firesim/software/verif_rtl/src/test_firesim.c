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
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>

// Vivado does not support svGetScopeFromName
#ifdef INCLUDE_DPI_CALLS
#ifndef VIVADO_SIM
#include "svdpi.h"
#endif
#endif

#include "sh_dpi_tasks.h"

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

    /* setup pipes */
    char * driver_to_xsim = "/tmp/driver_to_xsim";
    char * xsim_to_driver = "/tmp/xsim_to_driver";
    mkfifo(xsim_to_driver, 0666);
    log_printf("opening driver_to_xsim\n");
    int driver_to_xsim_fd = open(driver_to_xsim, O_RDONLY);
    log_printf("opening xsim_to_driver\n"); 
    int xsim_to_driver_fd = open(xsim_to_driver, O_WRONLY);

    // TODO remove this probably:
    sv_pause(2); // warm up 2us

    char buf[8];
    while(1) {
        int readbytes = read(driver_to_xsim_fd, buf, 8);
        if (readbytes != 8) {
            if (readbytes != 0) {
                log_printf("only read %d bytes\n", readbytes);
                exit(1);
            }
            continue;
        }
        uint64_t cmd = *((uint64_t*)buf);
        if (cmd >> 63) {
            //write
            uint32_t addr = (cmd >> 32) & 0x7FFFFFFF;
            uint32_t data = cmd & 0xFFFFFFFF;
            cl_poke(addr, data);
        } else {
            // read
            uint32_t addr = cmd & 0xFFFFFFFF;
            uint32_t dat;
            cl_peek(addr, &dat);
            uint64_t ret = dat;
            write(xsim_to_driver_fd, (char*)&ret, 8);
        }
    }
    *exit_code = 0;
}
