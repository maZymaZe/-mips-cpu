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
            OP_LW,OP_LB,OP_LH,OP_LBU,OP_LHU:begin
                m_addr={r_M.valE[31:2],2'b00};
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
            OP_SB:begin
                m_addr=r_M.valE;
                dreq.valid=1'b1;
                dreq.addr=m_addr;
                dreq.size=MSIZE4;
                unique case (m_addr[1:0])
                    2'b00:begin
                        dreq.strobe=4'b0001;
                        dreq.data={24'b0,r_M.valA[7:0]};
                    end
                    2'b01:begin
                        dreq.strobe=4'b0010;
                        dreq.data={16'b0,r_M.valA[7:0],8'b0};
                    end
                    2'b10:begin
                        dreq.strobe=4'b0100;
                        dreq.data={8'b0,r_M.valA[7:0],16'b0};
                    end
                    2'b11:begin
                        dreq.strobe=4'b1000;
                        dreq.data={r_M.valA[7:0],24'b0};
                    end
                endcase
            end
            OP_SH:begin
                m_addr=r_M.valE;
                dreq.valid=1'b1;
                dreq.addr=m_addr;
                dreq.size=MSIZE4;
                unique case (m_addr[1])
                    1'b0:begin
                        dreq.strobe=4'b0011;
                        dreq.data={16'b0,r_M.valA[15:0]};
                    end
                    1'b1:begin
                        dreq.strobe=4'b1100;
                        dreq.data={r_M.valA[15:0],16'b0};
                    end
                endcase
            end
            default: begin
            end
        endcase
        unique case (r_M.opcode)
            OP_RTYPE,OP_LUI,OP_SLTI,OP_SLTIU,
            OP_ADDIU,OP_ANDI,OP_ORI, OP_XORI,OP_JAL:begin
                if(r_M.opcode == OP_RTYPE&&(r_M.funct==FN_JR||r_M.funct==FN_MULTU
                ||r_M.funct==FN_MULT||r_M.funct==FN_DIVU||r_M.funct==FN_DIV
                ||r_M.funct==FN_MTLO||r_M.funct==FN_MTHI))begin
                    MvEok=1'b0;
                end else begin
                    MvEok=1'b1;
                end
            end
            OP_BTYPE:begin
                if(r_M.btype==BR_BLTZAL||r_M.btype==BR_BGEZAL)begin
                    MvEok=1'b1;
                end
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
        r_m.btype = r_M.btype;
    end
    logic _unused_ok = &{1'b0,r_M};
endmodule