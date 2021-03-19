`include "mycpu/defs.svh"
module Execute (
    input  plr_e r_E,
    output plr_m r_e,
    output logic evEok
);
    word_t alu_in1;
    word_t alu_in2;
    shamt_t  alushamt;
    funct_t  alufunct;
    always_comb begin
        evEok='0;
        r_e.dstE=r_E.dstE;
        r_e.dstM=r_E.dstM;
        r_e.valA=r_E.valA;
        r_e.stat=r_E.stat;
        r_e.opcode=r_E.opcode;
        r_e.funct=r_E.funct;
        r_e.pc= r_E.pc;

        alu_in1='0;
        alu_in2='0;
        alufunct=funct_t'('0);
        alushamt='0;
        evEok='0;
        unique case (r_E.opcode)
            OP_LUI:begin//pass without changing
                alu_in1=r_E.valC;
                alu_in2=0;
                alufunct=FN_ADDU;
                evEok=1'b1;                
            end
            OP_RTYPE:begin
                alu_in1=r_E.valA;
                alu_in2=r_E.valB;
                alufunct=r_E.funct;
                alushamt=r_E.shamt;
                if(r_E.funct!=FN_JR)begin
                    evEok=1'b1;
                end else begin
                    evEok=1'b0;
                end
            end
            OP_ADDIU,OP_ANDI,OP_ORI, OP_XORI:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=r_E.funct;
                evEok=1'b1;
            end
            OP_LW,OP_SW:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=FN_ADDU;
                evEok=1'b0;
            end
            OP_SLTIU,OP_SLTI:begin
                alu_in1=r_E.valB;
                alu_in2=r_E.valC;
                alufunct=r_E.funct;
                evEok=1'b1;
            end
            OP_JAL:begin
                alu_in1=r_E.valA;
                alu_in2=8;
                alufunct=FN_ADDU;
                evEok=1'b1;
            end
            default: begin
            end
        endcase
        //TODO:
    end
    Alu aalluu(.aluout(r_e.valE),.*);
    logic _unused_ok = &{1'b0,r_E};
endmodule

