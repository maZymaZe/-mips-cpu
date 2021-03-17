`include "mycpu/defs.svh"
module Decode (
    input  plr_d r_D,
    output plr_e r_d,
    input word_t rvalA,
    input word_t rvalB,
    input logic evEok,
    input logic MvEok,
    input logic WvMok,
    input logic WvEok,
    input word_t evalE,
    input word_t MvalE,
    input word_t WvalM,
    input word_t WvalE,
    input regid_t edstE,
    input regid_t MdstE,
    input regid_t WdstM,
    input regid_t WdstE,
    output regid_t dsrcA,
    output regid_t dsrcB
);
    logic dsaok;
    logic dsbok;
    always_comb begin
        dsbok='0;
        dsaok='0;
        unique case (r_D.opcode)
            OP_LUI:begin
                r_d.dstE=r_D.rB;
            end
            OP_RTYPE:begin
                r_d.dstE=r_D.rC;
                dsrcA=r_D.rA;
                dsrcB=r_D.rB;
                dsaok=1'b1;
                dsbok=1'b1;
            end
            OP_ADDIU,OP_SLTI,OP_SLTIU,OP_ANDI,OP_ORI,OP_XORI: begin
                r_d.dstE=r_D.rB;
                dsrcB=r_D.rA;
                dsbok=1'b1;
            end
            OP_BEQ,OP_BNE:begin
                dsrcA=r_D.rA;
                dsrcB=r_D.rB;
                dsaok=1'b1;
                dsbok=1'b1;

            end
            OP_LW: begin
                dsrcB=r_D.rA;
                r_d.dstM=r_D.rB;
                dsbok=1'b1;
            end
            OP_SW: begin
                dsrcA=r_D.rB;
                dsrcB=r_D.rA;
                dsaok=1'b1;
                dsbok=1'b1;
            end
            OP_JAL:begin
                r_d.dstE=RA;
            end
            default: begin
            end
        endcase
    
        r_d.opcode=r_D.opcode;
        r_d.funct=r_D.funct;
        r_d.stat=r_D.stat;
        r_d.shamt= r_D.shamt;
        r_d.pc= r_D.pc;
        
    end

    always_comb begin

        if(dsbok==1'b1)begin
            priority if(dsrcB==edstE&&evEok==1'b1)begin
                r_d.valB=evalE;                
            end else if(dsrcB==MdstE&&MvEok==1'b1)begin
                r_d.valB=MvalE;            
            end else if(dsrcB==WdstM&&WvMok==1'b1)begin
                r_d.valB=WvalM;            
            end else if(dsrcB==WdstE&&WvEok==1'b1)begin
                r_d.valB=WvalE;            
            end else begin
                r_d.valB=rvalB;
            end
        end else begin
            r_d.valB=rvalB;
        end



        unique case (r_D.opcode)
            
            OP_SLTI: begin
                r_d.funct=FN_SLT;
            end
            OP_SLTIU: begin
                r_d.funct=FN_SLTU;
            end
            default: begin
            
            end
        endcase

        if(r_D.opcode==OP_JAL)begin
            r_d.valA=r_D.valP;
        end else if(dsaok==1'b1)begin
            priority if(dsrcA==edstE&&evEok==1'b1)begin
                r_d.valA=evalE;                
            end else if(dsrcA==MdstE&&MvEok==1'b1)begin
                r_d.valA=MvalE;            
            end else if(dsrcA==WdstM&&WvMok==1'b1)begin
                r_d.valA=WvalM;            
            end else if(dsrcA==WdstE&&WvEok==1'b1)begin
                r_d.valA=WvalE;            
            end else begin
                r_d.valA=rvalA;
            end
        end else begin            
            r_d.valA=rvalA;
        end
        r_d.valC=r_D.valC;
        unique case (r_D.opcode)
            OP_BEQ:begin
                if(rvalA==rvalB)begin
                    r_d.valC=r_D.valC+r_D.valP+4;
                end else begin
                    r_d='0;
                end
            end
            OP_BNE:begin
                if(rvalA!=rvalB)begin
                    r_d.valC=r_D.valC+r_D.valP+4;
                end else begin
                    r_d='0;
                end
            end
            default: begin
            end
        endcase

    end
    logic _unused_ok = &{1'b0,r_D};
endmodule
