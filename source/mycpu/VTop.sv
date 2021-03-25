`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "cbus_decl"

    ibus_req_t  ireq;
    ibus_resp_t iresp;
    dbus_req_t  dreq;
    dbus_resp_t dresp;
    cbus_req_t  icreq,  dcreq;
    cbus_resp_t icresp, dcresp;

    MyCore core(.*);
    IBusToCBus icvt(.*);
    DBusToCBus dcvt(.*);

    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    CBusArbiter mux(
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
        .*
    );

    /**
     * TODO (optional) add address translation for oreq.addr :)
     */
     /*
    typedef logic [31:0] paddr_t;
    typedef logic [31:0] vaddr_t;

    paddr_t paddr; // physical address
    vaddr_t vaddr; // virtual address

    assign inst_sram_addr[27:0] =oreq.addr[27:0];
    always_comb begin
        unique case (oreq.addr[31:28])
            4'h8: inst_sram_addr[31:28] = 4'b0; // kseg0
            4'h9: inst_sram_addr[31:28] = 4'b1; // kseg0
            4'ha: inst_sram_addr[31:28] = 4'b0; // kseg1
            4'hb: inst_sram_addr[31:28] = 4'b1; // kseg1
            default: inst_sram_addr[31:28] = oreq.addr[31:28]; // useg, ksseg, kseg3
        endcase
    end
    */
    logic _unused_ok = &{ext_int};
endmodule
