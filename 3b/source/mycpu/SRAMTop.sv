`include "common.svh"
`include "sramx.svh"

module SRAMTop(
    input logic clk, resetn,

    output logic        inst_sram_en,
    output logic [3 :0] inst_sram_wen,
    output logic [31:0] inst_sram_addr,
    output logic [31:0] inst_sram_wdata,
    input  logic [31:0] inst_sram_rdata,
    output logic        data_sram_en,
    output logic [3 :0] data_sram_wen,
    output logic [31:0] data_sram_addr,
    output logic [31:0] data_sram_wdata,
    input  logic [31:0] data_sram_rdata,

    input i6 ext_int
);
    ibus_req_t   ireq;
    ibus_resp_t  iresp;
    dbus_req_t   dreq;
    dbus_resp_t  dresp;
    sramx_req_t  isreq,  dsreq;
    sramx_resp_t isresp, dsresp;

    MyCore core(.*);
    IBusToSRAMx icvt(.*);
    DBusToSRAMx dcvt(.*);

    /**
     * TODO (optional) add address translations for isreq.addr & dsreq.addr :)
     */

    typedef logic [31:0] paddr_t;
    typedef logic [31:0] vaddr_t;

    paddr_t paddr; // physical address
    vaddr_t vaddr; // virtual address

    assign inst_sram_addr[27:0] =isreq.addr[27:0];
    always_comb begin
        unique case (isreq.addr[31:28])
            4'h8: inst_sram_addr[31:28] = 4'b0; // kseg0
            4'h9: inst_sram_addr[31:28] = 4'b1; // kseg0
            4'ha: inst_sram_addr[31:28] = 4'b0; // kseg1
            4'hb: inst_sram_addr[31:28] = 4'b1; // kseg1
            default: inst_sram_addr[31:28] = isreq.addr[31:28]; // useg, ksseg, kseg3
        endcase
    end



    assign inst_sram_en    = isreq.en;
    assign inst_sram_wen   = isreq.wen;

    assign inst_sram_wdata = isreq.wdata;
    assign isresp.rdata    = inst_sram_rdata;

    assign data_sram_addr[27:0] =dsreq.addr[27:0];
    always_comb begin
        unique case (dsreq.addr[31:28])
            4'h8: data_sram_addr[31:28] = 4'b0; // kseg0
            4'h9: data_sram_addr[31:28] = 4'b1; // kseg0
            4'ha: data_sram_addr[31:28] = 4'b0; // kseg1
            4'hb: data_sram_addr[31:28] = 4'b1; // kseg1
            default: data_sram_addr[31:28] =dsreq.addr[31:28]; // useg, ksseg, kseg3
        endcase
    end



    assign data_sram_en    = dsreq.en;
    assign data_sram_wen   = dsreq.wen;
    assign data_sram_wdata = dsreq.wdata;
    assign dsresp.rdata    = data_sram_rdata;

    `UNUSED_OK({ext_int});
endmodule
