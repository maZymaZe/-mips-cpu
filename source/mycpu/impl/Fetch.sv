`include "mycpu/defs.svh"
module Fetch (
    output ibus_req_t  ireq,
    input addr_t PG_PC
);
    always_comb begin
        ireq.valid=1'b1;
        ireq.addr=PG_PC; 
    end
endmodule