`include "mycpu/defs.svh"
module Fetch (
    output ibus_req_t  ireq,
    input addr_t PG_PC
);
    always_comb begin
        if(PG_PC[1:0]!=0)begin
            ireq.valid=1'b1;
            ireq.addr=32'hbfc0_0000; 
        end else begin
            ireq.valid=1'b1;
            ireq.addr=PG_PC; 
        end
    end
endmodule