`include "common.svh"
`include "mycpu/defs.svh"

module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp,

    input i6 ext_int
);
    plr_d r_D;
    plr_e r_d;
    
    plr_m r_e;
    plr_e r_E;

    plr_w r_m;
    plr_m r_M;

    plr_w r_W;

    logic ErrorI;
    assign ErrorI = (r_M.ExcCode!=0);
 
    logic ErrorO;
    word_t cp0wdata;
    logic cp0is_write;
    word_t cp0rdata;
    cprid_t cprrid,cpwrid;
    ecode_t ecode;
    assign ecode=ecode_t'(r_M.ExcCode);
    addr_t error_addr;
    assign error_addr =r_M.erraddr;
    addr_t error_pc;
    assign error_pc =r_M.pc;
    logic is_eret;
    assign is_eret = (r_M.opcode==OP_COP0&&i6'(r_M.funct)==i6'(COFN_ERET));
    logic minssl;
    assign minssl =r_M.inssl;
    addr_t pubepc;
    cp0reg cprg(.ra1(cprrid),.wa2(cpwrid),.write_enable(cp0is_write),.wd2(cp0wdata),.rd1(cp0rdata),.*);

    /**
     * TODO (Lab1) your code here :)
     */
    

    addr_t PG_PC;
    addr_t veri_pc/* verilator public_flat_rd */;
    assign veri_pc=r_W.pc;

    logic evEok;
    logic MvEok;
    logic WvMok;
    logic WvEok;

    word_t WvalM;
    word_t rvalA,rvalB;
    regid_t wr_reg/* verilator public_flat_rd */;
    logic write_enable/* verilator public_flat_rd */;
    word_t wr_word/* verilator public_flat_rd */;

    regid_t dsrcA;
    regid_t dsrcB;

    logic dsaok;
    logic dsbok;

    logic i_data_ok,d_data_ok;
    //TODO: check
    assign i_data_ok=iresp.data_ok;
    assign d_data_ok=(~dreq.valid)|dresp.data_ok;

    logic SolveLW;
    assign SolveLW =((r_E.opcode==OP_LW||r_E.opcode==OP_LB||r_E.opcode==OP_LH||r_E.opcode==OP_LBU||r_E.opcode==OP_LHU)&&
    ((r_E.dstM==dsrcA&&dsaok)||(r_E.dstM==dsrcB&&dsbok)))||
        ((r_M.opcode==OP_LW||r_M.opcode==OP_LB||r_M.opcode==OP_LH||r_M.opcode==OP_LBU||r_M.opcode==OP_LHU)
        &&((r_M.dstM==dsrcA&&dsaok)||(r_M.dstM==dsrcB&&dsbok)))||
        ((r_W.opcode==OP_LW||r_W.opcode==OP_LB||r_W.opcode==OP_LH||r_W.opcode==OP_LBU||r_W.opcode==OP_LHU)
        &&((r_W.dstM==dsrcA&&dsaok)||(r_W.dstM==dsrcB&&dsbok)));

    logic branchstall1,branchstall2;
    assign branchstall1 =((r_d.opcode==OP_BNE||r_d.opcode==OP_BEQ||
    r_d.opcode==OP_BTYPE||r_d.opcode==OP_BLEZ||r_d.opcode==OP_BGTZ)
    &&r_d.valC!=0)||(r_d.opcode==OP_J||r_d.opcode==OP_JAL);
    assign branchstall2 = (r_d.opcode==OP_RTYPE&&(r_d.funct==FN_JR||r_d.funct==FN_JALR));
    logic fd_stall,e_stall,m_stall,e_bubble,w_bubble;

    logic branchstall1sp,branchstall2sp;
    logic isjmpsp;
    assign branchstall1sp =((r_d.opcode==OP_BNE||r_d.opcode==OP_BEQ||
    r_d.opcode==OP_BTYPE||r_d.opcode==OP_BLEZ||r_d.opcode==OP_BGTZ)
    )||(r_d.opcode==OP_J||r_d.opcode==OP_JAL);
    assign branchstall2sp = (r_d.opcode==OP_RTYPE&&(r_d.funct==FN_JR||r_d.funct==FN_JALR));

    logic hilo_delay;
    assign hilo_delay =(r_E.opcode==OP_RTYPE&&(r_E.funct==FN_DIV||r_E.funct==FN_DIVU||r_E.funct==FN_MULT||r_E.funct==FN_MULTU||r_E.funct==FN_MTLO||r_E.funct==FN_MTHI)
    &&(r_D.opcode==OP_RTYPE&&(r_D.funct==FN_MFLO||r_D.funct==FN_MTHI)));

    assign fd_stall = ~i_data_ok | ~d_data_ok | SolveLW | hilo_delay;
   
    assign e_stall = ~d_data_ok;
    assign m_stall = ~d_data_ok;

    assign e_bubble = SolveLW | ~i_data_ok|hilo_delay;
    assign w_bubble = ~d_data_ok;

    addr_t nxt;
    logic isjmp;

    i32 hi,lo;
    i1 hi_write,lo_write;
    i32 hi_data,lo_data;

    logic ERRPROCESS;
    logic ERETPROCESS;
   
    always_ff @(posedge clk)
    if (~resetn) begin
        // AHA!
        PG_PC<=32'hbfc0_0000;
        r_E<='0;
        r_M<='0;
        r_W<='0;
        isjmp<='0;
        isjmpsp<='0;
        nxt<='0;
        ERRPROCESS<='0;
        ERETPROCESS<='0;
    end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
        
        
        if(~fd_stall)begin
            if(ERRPROCESS)begin
                PG_PC<=32'hbfc00380;
                ERRPROCESS<='0;
                isjmp<='0;
            end else if(ERETPROCESS)begin
                PG_PC<=pubepc;
                ERETPROCESS<='0;
                isjmp<='0;
            end else if (~isjmp)begin
                PG_PC<=PG_PC+4;
            end else begin
                PG_PC<=nxt;
                isjmp<=0;
            end
            if(r_d.pc!='0)begin
                isjmpsp<='0;
            end
            if(branchstall1&&(~ERETPROCESS)&&(~ERRPROCESS))begin
                nxt<=r_d.valC; 
                isjmp<=1;
            end else if(branchstall2&&(~ERETPROCESS)&&(~ERRPROCESS)) begin
                nxt<=r_d.valA;
                isjmp<=1;
            end 
            if(branchstall1sp&&(~ERETPROCESS)&&(~ERRPROCESS))begin                
                isjmpsp<=1;
            end else if(branchstall2sp&&(~ERETPROCESS)&&(~ERRPROCESS)) begin
                isjmpsp<=1;
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

        if(ERRPROCESS||ERETPROCESS)begin
            r_E<='0;
            isjmp<='0;
        end
        if(ErrorO||ErrorI)begin
            ERRPROCESS<=1'b1;
            isjmp<='0;
            r_E<='0;
            r_M<='0;
            r_W<='0;
        end
        if(is_eret)begin
            ERETPROCESS<=1'b1;
            isjmp<='0;
            r_E<='0;
            r_M<='0;
            r_W<='0;
        end


    end
    regfile rgfl(.clk(clk),.ra1(dsrcA),.ra2(dsrcB),.wa3(wr_reg),.write_enable(write_enable),
    .wd3(wr_word),.rd1(rvalA),.rd2(rvalB));
    hilo hl(.*);
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
