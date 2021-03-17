`ifndef __MYCPU_STAT_SVH__
`define __MYCPU_STAT_SVH__

`include "common.svh"

typedef enum i2 {
    AOK = 2'b00,
    ADR = 2'b01,
    HLT = 2'b10,
    INS = 2'b11
} stat_t ;


`endif
