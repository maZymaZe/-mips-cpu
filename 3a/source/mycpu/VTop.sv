`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq;
    ibus_resp_t iresp;
    dbus_req_t  dreq;
    dbus_resp_t dresp;
    cbus_req_t  icreq,  dcreq;
    cbus_resp_t icresp, dcresp;

    MyCore core(.*);
    /*
    IBusToCBus ucicvt(.*);
    DBusToCBus ucdcvt(.*);
    */
    ICache icvt(.*);
    DCache dcvt(.*);
    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    cbus_req_t oreqv;
    logic uncached;
    always_comb begin
        if(oreqv.addr>=32'ha0000000&&oreqv.addr<32'hc0000000)begin
            uncached=1;
        end else begin
            uncached=0;
        end
        oreq=oreqv;
        oreq.addr[31:29]='0;
        
    end


    CBusArbiter #(.NUM_INPUTS(4))mux(
        .ireqs({icreq, dcreq,,}),
        .iresps({icresp, dcresp,,}),
        .oreq(oreqv),
        .*
    );
    /**
     * TODO (optional) add address translation for oreq.addr :)
     */

    `UNUSED_OK({ext_int});
endmodule
