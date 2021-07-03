`include "mycpu/defs.svh"
module Alu(
    input logic clk,resetn,
    input word_t alu_in1,
    input word_t alu_in2,
    input shamt_t alushamt,
    input funct_t  alufunct,
    output word_t aluout,
    output word_t hi_data,
    output word_t lo_data,
    output logic hi_write,
    output logic lo_write,
    output i5 Excupdate,
    output addr_t erraddrupdate,
    input opcode_t opcode,
    output logic mul_div_stall
);
    logic sig,is_mul,is_div;
    logic mul_done,div_done;
    word_t div_hi_data;
    word_t div_lo_data;
    word_t mul_hi_data;
    word_t mul_lo_data;

    multiplier_multicycle_dsp multiplier(
        .valid(is_mul),
        ._a(alu_in1), ._b(alu_in2),
        .done(mul_done),
        ._c({mul_hi_data,mul_lo_data}),
        .*
    );
    divider_multicycle_from_single divider(
        .valid(is_div),
        ._a(alu_in1), ._b(alu_in2),
        .done(div_done),
        ._c({div_hi_data,div_lo_data}), // c = {a % b, a / b}
        .*
    );

    always_comb begin
        mul_div_stall = '0;
        if(alufunct == FN_MULTU || alufunct == FN_MULT) begin
            mul_div_stall = ~mul_done;
        end
        if(alufunct == FN_DIV || alufunct == FN_DIVU) begin
            mul_div_stall = ~div_done;
        end
    end

    always_comb begin
        aluout='0;
        hi_data='0;
        lo_data='0;
        hi_write='0;
        lo_write='0;
        Excupdate='0;
        erraddrupdate='0;
        sig='0;
        is_mul='0;
        is_div='0;
        unique case (alufunct)
            FN_ADD:begin
                aluout=(signed'(alu_in1)+signed'(alu_in2));
                if(alu_in1[31]==alu_in2[31]&&alu_in1[31]!=aluout[31])begin
                    Excupdate=5'hc;
                end
            end
            FN_SUB:begin
                aluout=(signed'(alu_in1)-signed'(alu_in2));
                if(aluout[31]==alu_in2[31]&&alu_in1[31]!=aluout[31])begin
                    Excupdate=5'hc;
                end
            end    
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
                is_mul = '1;
                sig = '0;
                hi_write=1'b1;
                lo_write=1'b1;
                hi_data = mul_hi_data;
                lo_data = mul_lo_data;
            end
            FN_MULT: begin
                is_mul = '1;
                sig = '1;
                hi_write=1'b1;
                lo_write=1'b1;
                hi_data = mul_hi_data;
                lo_data = mul_lo_data;
            end
            FN_DIVU: begin
                is_div = '1;
                sig = '0;
                hi_write=1'b1;
                lo_write=1'b1;
                hi_data = div_hi_data;
                lo_data = div_lo_data;
            end
            FN_DIV: begin
                is_div = '1;
                sig = '1;
                hi_write=1'b1;
                lo_write=1'b1;
                hi_data = div_hi_data;
                lo_data = div_lo_data;
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
        unique case (opcode)
            OP_LW:begin
                if(aluout[1:0]!=0)begin
                    Excupdate=5'h4;
                    erraddrupdate=aluout;
                end
            end
            OP_LH, OP_LHU:begin
                if(aluout[0]!=0)begin
                    Excupdate=5'h4;
                    erraddrupdate=aluout;
                end
            end
            OP_SW:begin
                if(aluout[1:0]!=0)begin
                    Excupdate=5'h5;
                    erraddrupdate=aluout;
                end
            end
            OP_SH:begin
                if(aluout[0]!=0)begin
                    Excupdate=5'h5;
                    erraddrupdate=aluout;
                end
            end
            default: begin
            end
        endcase
    end
endmodule