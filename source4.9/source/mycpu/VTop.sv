`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq , uireq , iireq;
    ibus_resp_t iresp , uiresp , iiresp;
    dbus_req_t  dreq , ddreq , udreq;
    dbus_resp_t dresp , udresp , ddresp;
    cbus_req_t  icreq,  dcreq, uicreq , udcreq , iicreq , ddcreq;
    cbus_resp_t iicresp , ddcresp , udcresp , uicresp , cdcresp , cicresp;

    MyCore core(.iresp(iiresp),.dresp(ddresp),.*);
    
    IBusToCBus ucicvt(.ireq(uireq),.iresp(uiresp),.icreq(uicreq),.icresp(uicresp),.*);
    DBusToCBus ucdcvt(.dreq(udreq),.dresp(udresp),.dcreq(udcreq),.dcresp(udcresp),.*);
    
    ICache icvt(.ireq(iireq),.iresp(iresp),.icreq(icreq),.icresp(cicresp),.*);
    DCache dcvt(.dreq(ddreq),.dresp(dresp),.dcreq(dcreq),.dcresp(cdcresp),.*);
    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    cbus_req_t oreqv;
    //logic uncached;
    always_comb begin
        if(ireq.addr>=32'ha0000000&&ireq.addr<32'hc0000000)begin
            iireq=0;
            uireq=ireq;
            iicreq=uicreq; 
            iiresp=uiresp;
            uicresp=iicresp;
            cicresp=0;
        end else begin
            iireq=ireq;
            uireq=0;
            iicreq=icreq; 
            iiresp=iresp;
            uicresp=0;
            cicresp=iicresp;
        end
        if(dreq.addr>=32'ha0000000&&dreq.addr<32'hc0000000)begin
            udreq=dreq;
            ddreq=0;
            ddcreq=udcreq;
            ddresp=udresp;  
            udcresp=ddcresp;
            cdcresp=0;
        end else begin
            udreq=0;
            ddreq=dreq;
            ddcreq=dcreq;   
            ddresp=dresp;
            udcresp=0;
            cdcresp=ddcresp;
        end 
        oreq=oreqv;
        oreq.addr[31:29]='0;        
    end


    //#(.NUM_INPUTS(4))
    CBusArbiter mux(
        .ireqs({iicreq, ddcreq}),
        .iresps({iicresp, ddcresp}),
        .oreq(oreqv),
        .*
    );
    /*CBusArbiter mux(
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
        .oreq(oreqv),
        .*
    );*/

    /**
     * TODO (optional) add address translation for oreq.addr :)
     */

    `UNUSED_OK({ext_int});
endmodule
