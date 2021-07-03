`include "mycpu/defs.svh"
module WriteBack (
    input logic clk,
    input  plr_w r_W,
    output regid_t wr_reg,
    output word_t wr_word,   
    input  dbus_resp_t dresp,
    output logic WvEok,
    output logic WvMok,
    output word_t WvalM,
    output logic write_enable,
    input logic StorebufferEn,
    input word_t StorebufferData,
    input addr_t StorebufferAddr 
);
    word_t tword;
    always_ff @(posedge clk)begin
        if(r_W.opcode==OP_LW&&r_W.valE==StorebufferAddr&&StorebufferEn)begin
            tword <=StorebufferData;
        end else begin
            tword<=dresp.data;
        end
    end

    always_comb begin
        WvEok='0;
        WvMok='0;
        WvalM='0;
        wr_reg=regid_t'(0);
        wr_word='0;
        write_enable='0;
        unique case (r_W.opcode)
            OP_LUI,OP_ADDIU,OP_ADDI,OP_SLTI,OP_SLTIU,OP_ANDI,OP_ORI, OP_JAL, OP_XORI:begin
                write_enable=1;
                wr_reg=r_W.dstE;
                wr_word=r_W.valE;
            end
            OP_BTYPE:begin
                if(r_W.btype==BR_BGEZAL||r_W.btype==BR_BLTZAL)begin
                    write_enable=1;
                    wr_reg=r_W.dstE;
                    wr_word=r_W.valE;
                end
            end
            OP_COP0:begin
                if(i5'(r_W.shamt)==i5'(CFN_MF))begin
                    write_enable=1;
                    wr_reg=r_W.dstE;
                    wr_word=r_W.valE;
                end
            end
            OP_RTYPE:begin
                if(r_W.funct!=FN_JR&&r_W.funct!=FN_DIVU&&r_W.funct!=FN_DIV
                &&r_W.funct!=FN_MULTU&&r_W.funct!=FN_MULT
                &&r_W.funct!=FN_MTLO&&r_W.funct!=FN_MTHI
                &&r_W.funct!=FN_BREAK&&r_W.funct!=FN_SYSCALL)begin
                    write_enable=1;
                    wr_reg=r_W.dstE;
                    wr_word=r_W.valE;
                end
            end
            OP_LW:begin

                //WvalM=dresp.data;
                if(r_W.opcode==OP_LW&&r_W.valE==StorebufferAddr&&StorebufferEn)begin
                    WvalM = StorebufferData;
                end else begin
                    WvalM = dresp.data;
                end

                write_enable=1;
                wr_reg=r_W.dstM;
                wr_word=tword;
            end
            OP_LB:begin
                unique case (r_W.valE[1:0])
                    2'b00:begin
                        WvalM={{24{dresp.data[7]}},dresp.data[7:0]};
                        wr_word={{24{tword[7]}},tword[7:0]};
                    end
                    2'b01:begin
                        WvalM={{24{dresp.data[15]}},dresp.data[15:8]};
                        wr_word={{24{tword[15]}},tword[15:8]};
                    end
                    2'b10:begin
                        WvalM={{24{dresp.data[23]}},dresp.data[23:16]};
                        wr_word={{24{tword[23]}},tword[23:16]};
                    end
                    2'b11:begin
                        WvalM={{24{dresp.data[31]}},dresp.data[31:24]};
                        wr_word={{24{tword[31]}},tword[31:24]};
                    end
                endcase    
                write_enable=1;
                wr_reg=r_W.dstM;
                
            end
            OP_LBU:begin
                unique case (r_W.valE[1:0])
                    2'b00:begin
                        WvalM={24'b0,dresp.data[7:0]};
                        wr_word={24'b0,tword[7:0]};
                    end
                    2'b01:begin
                        WvalM={24'b0,dresp.data[15:8]};
                        wr_word={24'b0,tword[15:8]};
                    end
                    2'b10:begin
                        WvalM={24'b0,dresp.data[23:16]};
                        wr_word={24'b0,tword[23:16]};
                    end
                    2'b11:begin
                        WvalM={24'b0,dresp.data[31:24]};
                        wr_word={24'b0,tword[31:24]};
                    end
                endcase    
                write_enable=1;
                wr_reg=r_W.dstM;
            end
            OP_LH:begin
                unique case (r_W.valE[1])
                    1'b0:begin
                        WvalM={{16{dresp.data[15]}},dresp.data[15:0]};
                        wr_word={{16{tword[15]}},tword[15:0]};
                    end
                    1'b1:begin
                        WvalM={{16{dresp.data[31]}},dresp.data[31:16]};
                        wr_word={{16{tword[31]}},tword[31:16]};
                    end
                endcase    
                write_enable=1;
                wr_reg=r_W.dstM;
            end
            OP_LHU:begin
               unique case (r_W.valE[1])
                    1'b0:begin
                        WvalM={16'b0,dresp.data[15:0]};
                        wr_word={16'b0,tword[15:0]};
                    end
                    1'b1:begin
                        WvalM={16'b0,dresp.data[31:16]};
                        wr_word={16'b0,tword[31:16]};
                    end
                endcase   
                write_enable=1;
                wr_reg=r_W.dstM;
            end
            default: begin
            end
        endcase
        unique case (r_W.opcode)
            OP_RTYPE,OP_LUI,OP_SLTI,OP_SLTIU,
            OP_ADDIU,OP_ADDI,OP_ANDI,OP_ORI, OP_XORI,OP_JAL:begin
                if(r_W.opcode == OP_RTYPE&&(r_W.funct==FN_JR||r_W.funct==FN_MULTU
                ||r_W.funct==FN_MULT||r_W.funct==FN_DIVU||r_W.funct==FN_DIV
                ||r_W.funct==FN_MTLO||r_W.funct==FN_MTHI
                ||r_W.funct==FN_SYSCALL||r_W.funct==FN_BREAK))begin
                    WvEok=1'b0;
                end else begin
                    WvEok=1'b1;
                end
            end
            OP_BTYPE:begin
                if(r_W.btype==BR_BGEZAL||r_W.btype==BR_BLTZAL)begin
                    WvEok=1'b1;
                end
            end
            OP_COP0:begin
                if(i5'(r_W.shamt)==i5'(CFN_MF))begin
                    WvEok=1'b1;
                end
            end
            OP_LW: begin
                WvMok=1'b1;
            end
            default: begin
            end
        endcase
        if(wr_reg==regid_t'(0))begin
            write_enable='0;
        end
        if(r_W.ExcCode!=0)begin
            write_enable='0;
            WvMok='0;
            WvEok='0;
        end
    end
    logic _unused_ok = &{1'b0,r_W,dresp};
endmodule