`include "mycpu/defs.svh"
module Alu(
    input word_t alu_in1,
    input word_t alu_in2,
    input shamt_t alushamt,
    input funct_t  alufunct,
    output word_t aluout
);
    always_comb begin
        unique case (alufunct)
            FN_ADDU:begin
                aluout=alu_in1+alu_in2;
            end
            FN_OR:begin
                aluout=alu_in1|alu_in2;
            end
            FN_SLT:begin
                aluout=(signed'(alu_in1)<signed'(alu_in2))?1:0;
            end
            FN_SLL,FN_SLLV:begin
                aluout=alu_in2<<alushamt;
            end
            FN_SUBU:begin
                aluout=alu_in1-alu_in2;
            end
            FN_SLTU:begin
                aluout=(alu_in1<alu_in2)?1:0;
            end
            FN_AND:begin
                aluout=alu_in1&alu_in2;
            end
            FN_NOR:begin
                aluout=~(alu_in1|alu_in2);
            end
            FN_XOR:begin
                aluout=alu_in1^alu_in2;
            end
            FN_SRA,FN_SRAV:begin
                aluout = (signed'(alu_in2) >>> alushamt);
            end
            FN_SRL,FN_SRLV:begin
                aluout = (signed'(alu_in2) >> alushamt);
            end
            FN_JR:begin
                aluout = alu_in1;
            end
            FN_JALR:begin
                aluout = alu_in2+8;
            end
            default:begin
                aluout = 0;
            end
        endcase
    end
endmodule