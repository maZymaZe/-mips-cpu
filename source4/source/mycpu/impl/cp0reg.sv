`include "mycpu/defs.svh"

module cp0reg(
    input logic clk,
    input logic resetn,
    input cprid_t ra1,
    input cprid_t wa2,
    input logic write_enable,
    input word_t wd2,
    output word_t rd1,
    input ecode_t ecode,
    input logic ErrorI ,
    input addr_t error_addr,
    output logic ErrorO, 
    input i6 ext_int,
    input logic is_eret,
    input logic minssl,  
    input addr_t error_pc,
    output addr_t pubepc
);
    
    i8 interrupt_info;
    assign interrupt_info=(regs[CP0_STATUS][15:8])&({ext_int[5:0],2'b00}|
    regs[CP0_CAUSE][15:8]|{timer_interrupt_r,7'b0});
    assign ErrorO=regs[CP0_STATUS][0]==1&&(regs[CP0_STATUS][1]==0)&&(interrupt_info!=0);



    word_t [31:0] regs, regs_nxt;

    assign pubepc=regs[CP0_EPC];

    logic [31:0] writable;
    assign writable = 32'b00000000_00000000_01111010_00000000;
    logic [31:0] readable;
    assign readable = 32'b00000000_00000000_01111011_00000000;
    logic [31:0] status_writable;
    assign status_writable = 32'b11111110_01111000_11111111_00010111;
    logic [31:0] cause_writable;
    assign cause_writable  = 32'b00001000_11000000_00000011_00000000;
    logic [31:0] status_readable;
    assign status_readable = 32'b11111111_01111111_11111111_00011111;
    logic [31:0] cause_readable;
    assign cause_readable  = 32'b11111100_11100000_11111111_01111100;
    // write: sequential logic


    logic ticker;
    logic cmpdirty;
    logic timer_interrupt_r;

    always_ff @(posedge clk) begin
        if(~resetn)begin
            regs[31:0]<='0;
            ticker<='0;
            cmpdirty<=0;
            timer_interrupt_r<='0;
        end else begin
            regs[31:0] <= regs_nxt[31:0];
            if(is_eret)begin
                regs[CP0_STATUS][1]<='0;
            end
            ticker<=(~ticker);
            if(wa2==CP0_COMPARE&&write_enable)begin
                cmpdirty<=1;
                timer_interrupt_r<=0;
            end
            if(cmpdirty&&regs[CP0_COMPARE]==regs[CP0_COUNT])begin
                timer_interrupt_r<=1;
            end
        end
    end

    
    always_comb begin
        for (int i = 0; i <= 31; i ++) begin
            regs_nxt[i[4:0]] = regs[i[4:0]];
        end
        if(ticker==1)begin
            regs_nxt[CP0_COUNT] = regs[CP0_COUNT]+1;
        end
        if (write_enable&& writable[wa2]) begin
            unique case (wa2)
                CP0_STATUS:begin
                    for(int j=0;j<=31;j++) begin
                        if(status_writable[j]) begin
                            regs_nxt[wa2][j]=wd2[j];
                        end else begin
                            regs_nxt[wa2][j] = regs[wa2][j];
                        end
                    end
                end
                CP0_CAUSE: begin
                    for(int j=0;j<=31;j++) begin
                        if(cause_writable[j]) begin
                            regs_nxt[wa2][j]=wd2[j];
                        end else begin
                            regs_nxt[wa2][j] = regs[wa2][j];
                        end
                    end
                end
                default: begin
                    regs_nxt[wa2] = wd2;
                end
            endcase
            
        end
        if(ErrorO)begin
            regs_nxt[CP0_CAUSE][6:2]='0;
        end if(ErrorI)begin
            regs_nxt[CP0_CAUSE][6:2]=ecode;
        end
        if(ErrorI&&(ecode==5'h4||ecode==5'h5))begin
            regs_nxt[CP0_BADVADDR][31:0]=error_addr[31:0];
        end
        if(ErrorI||ErrorO)begin
            if(regs[CP0_STATUS][1]==0)begin
                if(ErrorI)begin
                    if(minssl)begin
                        regs_nxt[CP0_EPC][31:0]=error_pc[31:0]-32'h4;                 
                        regs_nxt[CP0_CAUSE][31]=1'b1;                   
                    end else begin                  
                        regs_nxt[CP0_EPC][31:0]=error_pc[31:0];
                        regs_nxt[CP0_CAUSE][31]=1'b0;                   
                    end
                end else begin
                    if(minssl)begin
                        regs_nxt[CP0_EPC][31:0]=error_pc[31:0];                 
                        regs_nxt[CP0_CAUSE][31]=1'b1;                   
                    end else begin                  
                        regs_nxt[CP0_EPC][31:0]=error_pc[31:0]+4;
                        regs_nxt[CP0_CAUSE][31]=1'b0;                   
                    end
                end
            end else begin
            end  
            regs_nxt[CP0_STATUS][1]=1'b1;         
        end
    end
    


    // read: combinational logic
    always_comb begin
        rd1 = '0;
        if(readable[ra1])begin
            unique case (ra1)
                CP0_STATUS: begin
                    for(int j=0;j<=31;j++) begin
                        if(status_readable[j]) begin
                            rd1[j]=regs[ra1][j];
                        end else begin
                            rd1[j]=1'b0;
                        end
                    end
                end
                CP0_CAUSE: begin
                    for(int j=0;j<=31;j++) begin
                        if(cause_readable[j]) begin
                            rd1[j]=regs[ra1][j];
                        end else begin
                            rd1[j]=0;
                        end
                    end
                end
                default: begin
                    rd1=regs[ra1];
                end
            endcase
        end else begin
            rd1='0;
        end
    end
endmodule