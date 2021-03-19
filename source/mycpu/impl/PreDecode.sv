`include "mycpu/defs.svh"
module PreDecode (
    output  plr_d r_D,
    input  ibus_resp_t iresp,
    input addr_t PR_PC
);
    
    always_comb begin
        r_D='0;
    
        r_D.opcode=opcode_t'(iresp.data[31:26]);
        r_D.valP=PR_PC;
        r_D.pc=PR_PC;
        
        unique case (r_D.opcode)
            OP_RTYPE:begin
                r_D.rA=regid_t'(iresp.data[25:21]);
                r_D.rB=regid_t'(iresp.data[20:16]);
                r_D.rC=regid_t'(iresp.data[15:11]);
                r_D.shamt=iresp.data[10:6];
                r_D.funct=funct_t'(iresp.data[5:0]);
            end
            OP_LUI:begin
                r_D.rB=regid_t'(iresp.data[20:16]);
                r_D.valC={iresp.data[15:0],16'b0};
            end
            OP_ADDIU,OP_LW,OP_SLTI,OP_SLTIU,OP_SW:begin
                r_D.rA=regid_t'(iresp.data[25:21]);
                r_D.rB=regid_t'(iresp.data[20:16]);
                r_D.valC={{16{iresp.data[15]}},iresp.data[15:0]};
            end
            OP_ANDI,OP_ORI,OP_XORI:begin
                r_D.rA=regid_t'(iresp.data[25:21]);
                r_D.rB=regid_t'(iresp.data[20:16]);
                r_D.valC={{16{0}},iresp.data[15:0]};
            end
            OP_BEQ, OP_BNE:begin
                r_D.rA=regid_t'(iresp.data[25:21]);
                r_D.rB=regid_t'(iresp.data[20:16]);
                r_D.valC={{14{iresp.data[15]}},iresp.data[15:0],2'b00};
            end
            OP_J, OP_JAL: begin
                r_D.valC={PR_PC[31:28],iresp.data[25:0],2'b00};
            end
            default: begin
            end
        endcase
        
    end
    logic _unused_ok = &{1'b0,iresp};
endmodule
