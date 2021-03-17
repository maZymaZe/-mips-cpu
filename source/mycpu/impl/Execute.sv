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
        r_e='0;
        evEok='0;
        r_e.dstE=r_E.dstE;
        r_e.dstM=r_E.dstM;
        r_e.valA=r_E.valA;
        r_e.stat=r_E.stat;
        r_e.opcode=r_E.opcode;
        r_e.funct=r_E.funct;
        r_e.pc= r_E.pc;

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
                evEok=1'b1;
            end
            OP_ADDIU:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=FN_ADDU;
                evEok=1'b1;
            end
            OP_ANDI:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=FN_AND;
                evEok=1'b1;
            end
            OP_ORI:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=FN_OR;
                evEok=1'b1;
            end
            OP_XORI:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=FN_XOR;
                evEok=1'b1;
            end
            OP_LW,OP_SW:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=FN_ADDU;
                evEok=1'b0;
            end
            OP_SLTIU:begin
                alu_in1=r_E.valB;
                alu_in2=r_E.valC;
                alufunct=FN_SLTU;
                evEok=1'b1;
            end
            OP_SLTI:begin
                alu_in1=r_E.valB;
                alu_in2=r_E.valC;
                alufunct=FN_SLT;
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

