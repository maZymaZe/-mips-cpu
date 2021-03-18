`include "common.svh"
`include "mycpu/defs.svh"
`include "mycpu/impl.svh"

module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp
);
    /**
     * TODO (Lab1) your code here :)
     */
    plr_d r_D;
    plr_d r_D_S;
    plr_d r_D_t;
    plr_e r_d;
    
    plr_m r_e;
    plr_e r_E;

    plr_w r_m;
    plr_m r_M;

    plr_w r_W;

    addr_t PG_PC;
    //addr_t PD_PC=32'hbfc0_0000;
    addr_t PR_PC;
    addr_t PG_PC_t;

    logic evEok;
    logic MvEok;
    logic WvMok;
    logic WvEok;

    word_t WvalM;
    word_t rvalA,rvalB;
    regid_t wr_reg;
    logic write_enable;
    word_t wr_word;
    logic SolveLW;

    regid_t dsrcA;
    regid_t dsrcB;

    always_ff @(posedge clk)
    if (~resetn) begin
        // AHA!
        PG_PC<=32'hbfc0_0000;
        PR_PC<=32'hbfc0_0000;
    end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
        

         // TODO:REGUPDATE
        if(SolveLW==1)begin
            //PG_PC<=PG_PC;
            r_E<='0;
        end else begin

            if(r_E.opcode==OP_BNE||r_E.opcode==OP_BEQ)begin
                PG_PC<=r_E.valC;          
            end else if(r_E.opcode==OP_J||r_E.opcode==OP_JAL)begin
                PG_PC<=r_E.valC;
            end else if(r_E.opcode==OP_RTYPE&&r_E.funct==FN_JR)begin
                PG_PC<=r_E.valC;
            end else begin
                PG_PC<=PG_PC+4;
            end
            r_E<=r_d;
        end
        r_M<=r_e;
        r_W<=r_m;

        if(r_E.opcode==OP_LW&&(r_E.dstM==dsrcA||r_E.dstM==dsrcB))begin
            SolveLW<=1; 
            //r_D_S<=r_D_S;     
            PR_PC<=PR_PC;      
        end else begin
            SolveLW<=0;
            r_D_S<=r_D;
            PR_PC<=PG_PC;
        end
    end
    always_comb begin 
        if(SolveLW==1'b1)begin
            r_D_t=r_D_S;
            PG_PC_t=PR_PC;
        end else begin
            r_D_t=r_D;
            PG_PC_t=PG_PC;
        end 

        if(PG_PC==PR_PC)begin
            r_D_t='0;
        end
        //TODO:FORWARD
        // TODO: control logic
    end

    regfile rgfl(.clk(clk),.ra1(dsrcA),.ra2(dsrcB),.wa3(wr_reg),.write_enable(write_enable),
    .wd3(wr_word),.rd1(rvalA),.rd2(rvalB));
    Fetch ftch(.PG_PC(PG_PC_t),.*);    
    PreDecode prdcd(.*);
    Decode dcd(.r_D(r_D_t),.evalE(r_e.valE),.MvalE(r_M.valE),.WvalM(WvalM),
    .WvalE(r_W.valE),.edstE(r_e.dstE),.MdstE(r_M.dstE),.WdstM(r_W.dstM),.WdstE(r_W.dstE),.*);
    Execute xct(.*);
    Memory mmry(.*);
    WriteBack wrtbck(.*);
    // TODO:remove following lines when you start
    //assign ireq = '0;
    //assign dreq = '0;
    logic _unused_ok = &{1'b0,iresp, dresp,r_D,r_d,r_M,r_m,r_e,r_E,r_W};
endmodule
