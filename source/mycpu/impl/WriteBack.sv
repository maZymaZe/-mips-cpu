`include "mycpu/defs.svh"
module WriteBack (
    input  plr_w r_W,
    output regid_t wr_reg,
    output word_t wr_word,   
    input  dbus_resp_t dresp,
    output logic WvEok,
    output logic WvMok,
    output word_t WvalM,
    output logic write_enable
);
    
    always_comb begin
        WvEok='0;
        WvMok='0;
        WvalM='0;
        wr_reg=regid_t'(0);
        wr_word='0;
        write_enable='0;
        unique case (r_W.opcode)
            OP_LUI,OP_ADDIU,OP_SLTI,OP_SLTIU,OP_ANDI,OP_ORI, OP_JAL, OP_XORI:begin
                write_enable=1;
                wr_reg=r_W.dstE;
                wr_word=r_W.valE;
            end
            OP_RTYPE:begin
                if(r_W.funct!=FN_JR)begin
                    write_enable=1;
                    wr_reg=r_W.dstE;
                    wr_word=r_W.valE;
                end
            end
            OP_LW:begin
                
                WvalM=dresp.data;
                
                write_enable=1;
                wr_reg=r_W.dstM;
                wr_word=WvalM;
            end
            default: begin
            end
        endcase
        unique case (r_W.opcode)
            OP_RTYPE,OP_LUI,OP_SLTI,OP_SLTIU,
            OP_ADDIU,OP_ANDI,OP_ORI, OP_XORI,OP_JAL:begin
                WvEok=1'b1;
            end
            OP_LW: begin
                WvMok=1'b1;
            end
            default: begin
            end
        endcase

    end
    logic _unused_ok = &{1'b0,r_W,dresp};
endmodule