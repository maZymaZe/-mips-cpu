`include "common.svh"
`include "mycpu/defs.svh"

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
    plr_e r_d;
    
    plr_m r_e;
    plr_e r_E;

    plr_w r_m;
    plr_m r_M;

    plr_w r_W;

    addr_t PG_PC;

    logic evEok;
    logic MvEok;
    logic WvMok;
    logic WvEok;

    word_t WvalM;
    word_t rvalA,rvalB;
    regid_t wr_reg;
    logic write_enable;
    word_t wr_word;

    regid_t dsrcA;
    regid_t dsrcB;

    logic dsaok;
    logic dsbok;

    logic i_data_ok,d_data_ok;
    //TODO: check
    assign i_data_ok=iresp.data_ok;
    assign d_data_ok=(~dreq.valid)|dresp.data_ok;

    logic SolveLW;
    assign SolveLW =(r_E.opcode==OP_LW&&((r_E.dstM==dsrcA&&dsaok)||(r_E.dstM==dsrcB&&dsbok)))||
        (r_M.opcode==OP_LW&&((r_M.dstM==dsrcA&&dsaok)||(r_M.dstM==dsrcB&&dsbok)));

    logic branchstall1,branchstall2;
    assign branchstall1 =((r_d.opcode==OP_BNE||r_d.opcode==OP_BEQ)&&r_d.valC!=0)||
    (r_d.opcode==OP_J||r_d.opcode==OP_JAL);
    assign branchstall2 = (r_d.opcode==OP_RTYPE&&r_d.funct==FN_JR);
    logic fd_stall,e_stall,m_stall,e_bubble,w_bubble;

    assign fd_stall = ~i_data_ok | ~d_data_ok | SolveLW ;
   
    assign e_stall = ~d_data_ok;
    assign m_stall = ~d_data_ok;

    assign e_bubble = SolveLW | ~i_data_ok;
    assign w_bubble = ~d_data_ok;

    addr_t nxt;
    logic isjmp;

    always_ff @(posedge clk)
    if (~resetn) begin
        // AHA!
        PG_PC<=32'hbfc0_0000;
        r_E<='0;
        r_M<='0;
        r_W<='0;
        isjmp<='0;
        nxt<='0;
    end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.

        if(~fd_stall)begin
            if (~isjmp)begin
                PG_PC<=PG_PC+4;
            end else begin
                PG_PC<=nxt;
                isjmp<=0;
            end
            if(branchstall1)begin
                nxt<=r_d.valC; 
                isjmp<=1;
            end else if(branchstall2) begin
                nxt<=r_d.valA;
                isjmp<=1;
            end 
        end
        if(e_bubble)begin
            r_E<='0;
        end else if(~e_stall)begin
            r_E<=r_d;
        end
        if(~m_stall)begin
            r_M<=r_e;
        end
        if(w_bubble)begin
            r_W<='0;
        end else begin
            r_W<=r_m;
        end
    end
    regfile rgfl(.clk(clk),.ra1(dsrcA),.ra2(dsrcB),.wa3(wr_reg),.write_enable(write_enable),
    .wd3(wr_word),.rd1(rvalA),.rd2(rvalB));
    Fetch ftch(.PG_PC(PG_PC),.*);    
    PreDecode prdcd(.*);
    Decode dcd(.evalE(r_e.valE),.MvalE(r_M.valE),.WvalM(WvalM),
    .WvalE(r_W.valE),.edstE(r_e.dstE),.MdstE(r_M.dstE),.WdstM(r_W.dstM),.WdstE(r_W.dstE),.*);
    Execute xct(.*);
    Memory mmry(.*);
    WriteBack wrtbck(.*);
    // TODO:remove following lines when you start
    //assign ireq = '0;
    //assign dreq = '0;
    logic _unused_ok = &{1'b0,iresp, dresp,r_D,r_d,r_M,r_m,r_e,r_E,r_W};
endmodule
