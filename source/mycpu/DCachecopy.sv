`include "common.svh"
`include "mycpu/defs.svh"
module DCache  #(
    parameter int OFFSET_BITS = 4,
    parameter int INDEX_BITS = 2,
    localparam int TAG_BITS = 30 - OFFSET_BITS - INDEX_BITS
) (
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  dcreq,
    input  cbus_resp_t dcresp
);
    /**
     * TODO (Lab3) your code here :)
     */
    typedef i24 tag_t;
    typedef i2 index_t;
    typedef i4 offset_t;
    typedef i2 position_t;  // cache set 内部的下标

    typedef struct packed {
        tag_t tag;
        logic valid;  // cache line 是否有效？
        logic dirty;  // cache line 是否被写入了？
    } meta_t;
    typedef meta_t [3:0] meta_set_t;

    typedef enum i3 {
        IDLE,
        WRT_BCK,
        FETCH,
        READY,
        FLUSH,
        JUDGE,
        FIN,
        SJUDGE
    } state_t /* verilator public */;
     // registers
    state_t    state /* verilator public_flat_rd */;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.

    //tag_t tag;
    //index_t index;
    //offset_t addr_offset;
    offset_t offset;
    //assign {tag, index, addr_offset} = dreq.addr[31:2];
    //assign {tag, index} = dreq.addr[31:6];

    tag_t rtag;
    index_t rindex;
    offset_t raddr_offset;
    assign {rtag, rindex, raddr_offset} = req.addr[31:2];

    logic  [15:0]ram_en;
    strobe_t ram_strobe;
    word_t   ram_wdata;
    word_t [15:0]ram_rdata;   
    // 存储单元（寄存器）
    genvar gvr_i;
    generate
        for(gvr_i = 0; gvr_i <16;gvr_i++)begin:ram_gen
            LUTRAM ram_inst(
                .clk(clk), .en(ram_en[gvr_i]),
                .addr(offset),
                .strobe(ram_strobe),
                .wdata(ram_wdata),
                .rdata(ram_rdata[gvr_i])
            );
        end
    endgenerate
    meta_set_t [3:0]meta;
    // 解析地址

    // 访问元数据
    meta_set_t foo;
    assign foo = meta[rindex];

    // 搜索 cache line
    position_t position;
    logic inCache;
    always_comb begin
        position = 2'b00;  // 防止出现锁存器
        inCache=0;
        if (foo[0].tag == rtag&&foo[0].valid==1)begin
            position = 2'b00;
            inCache=1;
        end else if (foo[1].tag == rtag&&foo[1].valid==1)begin
            position = 2'b01;
            inCache=1;
        end else if (foo[2].tag == rtag&&foo[2].valid==1)begin
            position = 2'b10;
            inCache=1;
        end else if (foo[3].tag == rtag&&foo[3].valid==1)begin
            position = 2'b11;
            inCache=1;
        end else begin           
            inCache=0;
        end
    end

    // 访问 cache line
    //assign dreq.data = bar[offset[3:2]];  // 2 字节对齐
   /* always_comb begin
        ram_gen[{index,position}].addr=addr_offset;
    end*/

    i2 [3:0]nxt_wr;

    always_comb begin
        ram_en='0;
        ram_strobe='0;
        ram_wdata ='0;
        unique case (state)
        FETCH: begin
            ram_en[{rindex,nxt_wr[rindex]}] = 1;
            ram_strobe = 4'b1111;
            ram_wdata  = dcresp.data;
        end

        WRT_BCK:begin
            ram_en[{rindex,nxt_wr[rindex]}] = 1;
            ram_strobe = 4'b1111;
            ram_wdata  = ram_rdata[{rindex,nxt_wr[rindex]}];
        end
        FLUSH:begin
            ram_en[{rindex,position}] = 1;
            ram_wdata = req.data;
            ram_strobe= req.strobe;
        end
        default: begin
           ram_en='0;
           ram_strobe='0;
           ram_wdata ='0;
        end
        endcase
    end
    

    
     // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = (state == READY&&(~(|req.strobe)))||(state ==FIN);
    assign dresp.data    = ram_rdata[{rindex,position}];

    // CBus driver
    assign dcreq.valid    = state == FETCH ||state==WRT_BCK||(
        (meta[rindex][nxt_wr[rindex]].valid&&
        meta[rindex][nxt_wr[rindex]].dirty)&&
        (~inCache)&&state==SJUDGE
    );
    assign dcreq.is_write = state ==WRT_BCK||(
        (meta[rindex][nxt_wr[rindex]].valid&&
        meta[rindex][nxt_wr[rindex]].dirty)&&
        (~inCache)&&state==SJUDGE
    );
    assign dcreq.size     = MSIZE4;
    assign dcreq.addr     = (state==FETCH)?{req.addr[31:6],6'b0}:
    ({meta[rindex][nxt_wr[rindex]].tag,rindex,6'b0});
    //TODO:fix
    assign dcreq.strobe   = ram_strobe;
    assign dcreq.data     = (ram_rdata[{rindex,nxt_wr[rindex]}]);

    assign dcreq.len      = MLEN16;


    
    always_ff @(posedge clk)begin
        if (resetn) begin
            unique case (state)
                IDLE: begin
                    if (dreq.valid) begin
                            req    <= dreq;
                            state  <= JUDGE;
                            offset <= 0;
                        
                    end                
                end
                JUDGE: begin
                    if(inCache)begin
                        offset <= raddr_offset;
                        state<=READY;
                    end else begin
                        if(nxt_wr[rindex]==2'b11)begin
                            nxt_wr[rindex]<=0;
                        end else begin
                            nxt_wr[rindex]<=nxt_wr[rindex]+1;
                        end
                        state  <= SJUDGE;
                        
                    end
                end
                SJUDGE: begin
                    if(
                        (meta[rindex][nxt_wr[rindex]].valid&&
                        meta[rindex][nxt_wr[rindex]].dirty)&&
                        (~inCache)
                    )begin
                            state  <= WRT_BCK;
                    end else begin
                            state <= FETCH;
                    end
                end
                WRT_BCK:begin
                    if(dcresp.last)begin
                        state<=FETCH;
                        offset <=0;
                        meta[rindex][nxt_wr[rindex]].dirty<=0;
                        meta[rindex][nxt_wr[rindex]].valid<=0;
                    end else begin
                        state<=WRT_BCK;
                        if(dcresp.ready)begin
                            offset<=offset + 1;
                        end
                        meta[rindex][nxt_wr[rindex]].valid<=0;                    
                    end 
                end
                FETCH: begin
                    if (dcresp.ready) begin
                        if(dcresp.last) begin
                            state<=READY;
                            offset <= raddr_offset;
                            meta[rindex][nxt_wr[rindex]].valid<=1;
                            meta[rindex][nxt_wr[rindex]].tag<=rtag;
                        end else begin
                            state  <= FETCH;
                            offset <= offset + 1;    
                        end
                    end            
                end
                READY: begin
                    if(|req.strobe) begin
                        state  <= FLUSH;
                        //offset <= 0;
                        offset <= raddr_offset;
                    end else begin
                        state <= IDLE;
                        offset <=0;
                    end
                end
                FLUSH: begin
                    state  <= FIN;
                    meta[rindex][position].dirty<=1;
                    /*if (dcresp.last) begin
                        meta[index][nxt_wr[index]].dirty<=1;
                        state  <= IDLE;
                    end else begin
                        state <= FLUSH;
                        offset <= offset + 1;
                    end*/
                end
                FIN: begin
                    state  <= IDLE;
                end
                default: begin
                end
            endcase
        end else begin
            state <= IDLE;
            nxt_wr<='0;
            {req, offset} <= '0;
            meta<='0;
        end
    end

    // remove following lines when you start
    //assign {dresp, dcreq} = '0;
    `UNUSED_OK({clk, resetn, dreq, dcresp,req});
endmodule
