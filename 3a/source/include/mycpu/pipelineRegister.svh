`ifndef __MYCPU_PIPELINEREGISTER_SVH__
`define __MYCPU_PIPELINEREGISTER_SVH__

`include "defs.svh"

typedef struct packed {
    opcode_t opcode;
    word_t valP;
    word_t valC;
    regid_t rA;
    regid_t rB;
    regid_t rC;
    regid_t dstE;
    regid_t dstM;
    shamt_t  shamt;
    funct_t  funct;
    btype_t btype;
    long_imm_t instr_index;
    addr_t pc;
} plr_d;
typedef struct packed {
    opcode_t opcode;
    word_t valA;
    word_t valB;
    word_t valC;
    regid_t dstE;
    regid_t dstM;
    shamt_t  shamt;
    funct_t  funct;
    btype_t btype;
    addr_t pc;
} plr_e;
typedef struct packed {
    opcode_t opcode;
    word_t valA;
    word_t valE;
    regid_t dstE;
    regid_t dstM;
    funct_t  funct;
    btype_t btype;
    addr_t pc;
} plr_m;
typedef struct packed {
    opcode_t opcode;
    word_t valE;
    regid_t dstE;
    regid_t dstM;
    funct_t  funct;
    btype_t btype;
    addr_t pc;
} plr_w;
`endif
