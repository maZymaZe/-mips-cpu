`include "mycpu/defs.svh"
module Memory (
    input  plr_m r_M,
    output plr_w r_m,
    output dbus_req_t  dreq,
    output logic MvEok
);
    word_t m_addr;
    always_comb begin
        r_m='0;
        MvEok='0;
        dreq.valid=1'b0;
        m_addr='0;
        dreq.addr=m_addr;
        dreq.size=MSIZE4;
        dreq.strobe=4'b0000;
        dreq.data='0;
        unique case (r_M.opcode)
            OP_LW:begin
                m_addr=r_M.valE;
                dreq.valid=1'b1;
                dreq.addr=m_addr;
                dreq.size=MSIZE4;
                dreq.strobe=4'b0000;
            end
            OP_SW:begin
                m_addr=r_M.valE;
                dreq.valid=1'b1;
                dreq.addr=m_addr;
                dreq.size=MSIZE4;
                dreq.strobe=4'b1111;
                dreq.data=r_M.valA;
            end
            default: begin
            end
        endcase
        unique case (r_M.opcode)
            OP_RTYPE,OP_LUI,OP_SLTI,OP_SLTIU,
            OP_ADDIU,OP_ANDI,OP_ORI, OP_XORI,OP_JAL:begin
                MvEok=1'b1;
            end
            default: begin
            end
        endcase
        r_m.opcode=r_M.opcode;
        r_m.valE = r_M.valE;        
        r_m.dstE = r_M.dstE;
        r_m.dstM = r_M.dstM;
        r_m.funct = r_M.funct;
        r_m.pc = r_M.pc;
    end
    logic _unused_ok = &{1'b0,r_M};
endmodule