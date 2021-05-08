`include "mycpu/defs.svh"
module Alu(
    input word_t alu_in1,
    input word_t alu_in2,
    input shamt_t alushamt,
    input funct_t  alufunct,
    output word_t aluout,
    output word_t hi_data,
    output word_t lo_data,
    output logic hi_write,
    output logic lo_write
);
    i64 ans;
    always_comb begin
        ans='0;
        aluout='0;
        hi_data='0;
        lo_data='0;
        hi_write='0;
        lo_write='0;
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
            FN_MULTU:begin
                ans={32'b0,alu_in1}*{32'b0,alu_in2};
                hi_write=1'b1;
                lo_write=1'b1;
                hi_data=ans[63:32];
                lo_data=ans[31:0];
            end
            FN_MULT: begin
                ans = signed'({{32{alu_in1[31]}}, alu_in1}) * signed'({{32{alu_in2[31]}}, alu_in2});
                hi_data = ans[63:32];
                lo_data = ans[31:0];
                hi_write=1'b1;
                lo_write=1'b1;
            end
            FN_DIVU: begin
                ans = '0;
                /* verilator lint_off WIDTH */
                lo_data = {1'b0, alu_in1} / {1'b0, alu_in2};
                hi_data = {1'b0, alu_in1} % {1'b0, alu_in2};
                /* verilator lint_off WIDTH */
                hi_write=1'b1;
                lo_write=1'b1;
            end
            FN_DIV: begin
                ans = '0;
                lo_data = signed'(alu_in1) / signed'(alu_in2);
                hi_data = signed'(alu_in1) % signed'(alu_in2);
                hi_write=1'b1;
                lo_write=1'b1;
            end
            FN_MFHI,FN_MFLO: begin
                aluout=alu_in2;
            end
            FN_MTHI: begin
                hi_write=1'b1;
                hi_data=alu_in1;
            end
            FN_MTLO:begin
                lo_write=1'b1;
                lo_data=alu_in1;
            end
            default:begin
                aluout = 0;
            end
        endcase
    end
endmodule