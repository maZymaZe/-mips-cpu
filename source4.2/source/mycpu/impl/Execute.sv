`include "mycpu/defs.svh"
module Execute (
    input logic clk,resetn,
    input  plr_e r_E,
    output plr_m r_e,
    output logic evEok,
    output word_t hi_data,
    output word_t lo_data,
    output logic hi_write,
    output logic lo_write,
    output word_t cp0wdata,
    output cprid_t cpwrid,
    output logic cp0is_write,
    output logic mul_div_stall
);
    word_t alu_in1;
    word_t alu_in2;
    shamt_t  alushamt;
    funct_t  alufunct;
    i5 Excupdate;
    addr_t erraddrupdate;
    always_comb begin
        cp0wdata='0;
        cpwrid=cprid_t'(0);
        cp0is_write='0;
        evEok='0;
        r_e.dstE=r_E.dstE;
        r_e.dstM=r_E.dstM;
        r_e.valA=r_E.valA;
        r_e.opcode=r_E.opcode;
        r_e.funct=r_E.funct;
        r_e.pc= r_E.pc;
        r_e.btype= r_E.btype;
        r_e.ExcCode= r_E.ExcCode;
        r_e.shamt= r_E.shamt;
        r_e.erraddr= r_E.erraddr;
        r_e.inssl= r_E.inssl;
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
                if(r_E.funct==FN_SLLV||r_E.funct==FN_SRLV||r_E.funct==FN_SRAV)begin                    
                    alushamt=r_E.valA[4:0];
                end else begin
                    alushamt=r_E.shamt;
                end               
                alufunct=r_E.funct;
                if(r_E.funct!=FN_JR&&r_E.funct!=FN_DIVU
                &&r_E.funct!=FN_DIV&&r_E.funct!=FN_MULTU&&r_E.funct!=FN_MULT
                &&r_E.funct!=FN_MTLO&&r_E.funct!=FN_MTHI
                &&r_E.funct!=FN_SYSCALL&&r_E.funct!=FN_BREAK
                )begin
                    evEok=1'b1;
                end else begin
                    evEok=1'b0;
                end
            end
            OP_ADDIU,OP_ANDI,OP_ORI, OP_XORI,OP_ADDI:begin
                alu_in1=r_E.valC;
                alu_in2=r_E.valB;
                alufunct=r_E.funct;
                evEok=1'b1;
            end
            OP_LW,OP_SW,OP_LH, OP_LHU, OP_LB, OP_LBU,OP_SH, OP_SB:begin
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
            OP_BTYPE:begin
                if(r_E.btype==BR_BGEZAL||r_E.btype==BR_BLTZAL)begin
                    alu_in1=r_E.valB;
                    alu_in2=8;
                    alufunct=FN_ADDU;
                    evEok=1'b1;
                end
            end
            OP_COP0: begin
                if(i6'(r_E.funct)==i6'(COFN_ERET))begin
                    alu_in1=r_E.valA;
                    alu_in2=0;
                    alufunct=FN_ADDU;
                    evEok=1'b0;
                end else if(i5'(r_E.shamt)==i5'(CFN_MF))begin
                    alu_in1=r_E.valA;
                    alu_in2=0;
                    alufunct=FN_ADDU;
                    evEok=1'b1;
                end else begin    
                    alu_in1='0;
                    alu_in2=r_E.valB;
                    alufunct=FN_ADDU;
                    evEok=1'b0;
                end
            end
            default: begin
            end
        endcase
        if(r_E.ExcCode==0)begin
            r_e.ExcCode=Excupdate;
            r_e.erraddr=erraddrupdate;
        end
        if(r_E.opcode==OP_COP0&&i5'(r_E.shamt)==i5'(CFN_MT))begin
            cp0is_write=1'b1;
            cpwrid=cprid_t'(r_E.dstE);
            cp0wdata=r_E.valB;
        end
    end
    Alu aalluu(.aluout(r_e.valE),.opcode(r_E.opcode),.*);
    logic _unused_ok = &{1'b0,r_E};
endmodule

