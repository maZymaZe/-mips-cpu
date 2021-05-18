`include "mycpu/defs.svh"
module PreDecode (
    output  plr_d r_D,
    input  ibus_resp_t iresp,
    input addr_t PG_PC,
    input isjmpsp
);
    
    always_comb begin
        r_D='0;
        r_D.inssl=isjmpsp;
        if(iresp.data_ok)begin
            if(PG_PC[1:0]==2'b00)begin
                r_D.opcode=opcode_t'(iresp.data[31:26]);
                r_D.valP=PG_PC;
                r_D.pc=PG_PC;
                
                unique case (iresp.data[31:26])
                    OP_RTYPE:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.rC=regid_t'(iresp.data[15:11]);
                        r_D.shamt=iresp.data[10:6];
                        r_D.funct=funct_t'(iresp.data[5:0]);
                        unique case (iresp.data[5:0])
                            FN_ADDU,FN_OR,FN_SLT,FN_AND,FN_SLTU,FN_NOR,FN_XOR,
                            FN_SLLV,FN_SRAV,FN_SRLV,FN_ADD,FN_SUB,FN_SUBU:begin
                                if(iresp.data[10:6]!=0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                        
                                end else begin
                                end
                            end
                            FN_SLL,FN_SRA,FN_SRL: begin
                                if(iresp.data[25:21]!=R0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end else begin
                                end
                            end
                            FN_JR: begin
                                if(iresp.data[15:11]!=R0||iresp.data[20:16]!=R0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end else begin
                                end
                            end
                            FN_MULT, FN_MULTU,FN_DIVU,FN_DIV: begin
                                if(iresp.data[15:11]!=R0||iresp.data[10:6]!=0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end else begin
                                end
                            end
                            FN_JALR: begin
                                if(iresp.data[20:16]!=R0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end else begin
                                end
                            end
                            FN_MFHI,FN_MFLO: begin
                                if(iresp.data[20:16]!=R0||iresp.data[25:21]!=R0||iresp.data[10:6]!=0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end else begin
                                end
                            end
                            FN_MTHI, FN_MTLO: begin
                                if(iresp.data[20:16]!=R0||iresp.data[15:11]!=R0||iresp.data[10:6]!=0)begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end else begin
                                end
                            end
                            FN_BREAK: begin
                                r_D.ExcCode=5'h9;
                            end
                            FN_SYSCALL: begin
                                r_D.ExcCode=5'h8;    
                            end
                            default: begin
                                r_D='0;
                                r_D.pc=PG_PC;
                                r_D.ExcCode=5'ha;
                            end
                        endcase

                    end
                    OP_LUI:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.valC={iresp.data[15:0],16'b0};
                        if(iresp.data[25:21]!=R0)begin
                            r_D='0;
                            r_D.pc=PG_PC;
                            r_D.ExcCode=5'ha;    
                        end
                    end
                    OP_ADDIU,OP_ADDI,OP_LW,OP_LB,OP_LH,OP_LBU,OP_LHU,
                    OP_SLTI,OP_SLTIU,OP_SW,OP_SH,OP_SB:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.valC={{16{iresp.data[15]}},iresp.data[15:0]};
                    end
                    OP_ANDI,OP_ORI,OP_XORI:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.valC={{16{1'b0}},iresp.data[15:0]};
                    end
                    OP_BEQ, OP_BNE:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.valC={{14{iresp.data[15]}},iresp.data[15:0],2'b00};
                    end
                    OP_J, OP_JAL: begin
                        r_D.valC={PG_PC[31:28],iresp.data[25:0],2'b00};
                    end
                    OP_BGTZ, OP_BLEZ:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.valC={{14{iresp.data[15]}},iresp.data[15:0],2'b00};
                        if(iresp.data[20:16]!=R0)begin
                            r_D='0;
                            r_D.pc=PG_PC;
                            r_D.ExcCode=5'ha;
                        end else begin
                        end
                    end
                    OP_BTYPE:begin
                        r_D.rA=regid_t'(iresp.data[25:21]);
                        r_D.valC={{14{iresp.data[15]}},iresp.data[15:0],2'b00};
                        r_D.btype=btype_t'(iresp.data[20:16]);
                        unique case (iresp.data[20:16])
                            BR_BGEZAL,BR_BGEZ,BR_BLTZAL,BR_BLTZ:begin
                            end
                            default: begin
                                r_D='0;
                                r_D.pc=PG_PC;
                                r_D.ExcCode=5'ha;
                            end
                        endcase
                    end
                    OP_COP0: begin
                        r_D.shamt=(iresp.data[25:21]);
                        r_D.funct=funct_t'(iresp.data[5:0]);
                        r_D.rB=regid_t'(iresp.data[20:16]);
                        r_D.rC=regid_t'(iresp.data[15:11]);
                        if(iresp.data[31:0]==32'h42000018)begin
                        end else begin
                            unique case (iresp.data[25:21])
                                CFN_MF,CFN_MT:begin
                                    if(iresp.data[10:0]!=0)begin
                                        r_D='0;
                                        r_D.pc=PG_PC;
                                        r_D.ExcCode=5'ha;
                                    end
                                end
                                default: begin
                                    r_D='0;
                                    r_D.pc=PG_PC;
                                    r_D.ExcCode=5'ha;
                                end
                            endcase
                        end
                    end
                    default: begin
                        r_D='0;
                        r_D.pc=PG_PC;
                        r_D.ExcCode=5'ha;
                    end
                endcase
            end else begin
                r_D.ExcCode=5'h4;
                r_D.pc=PG_PC;
                r_D.erraddr=PG_PC;
            end
        end else begin
        end
        r_D.inssl=isjmpsp;
    end
    logic _unused_ok = &{1'b0,iresp};
endmodule
