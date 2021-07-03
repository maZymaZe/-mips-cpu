`include "mycpu/defs.svh"

module divider_multicycle_from_single (
    input logic clk, resetn, valid, sig,
    input i32 _a, _b,
    output logic done,
    output i64 _c // c = {a % b, a / b}
);
    i32 a,b;
    i64 c;

    always_comb begin
        a=_a;
        b=_b;
        if(sig) begin
            if(_a[31]) begin
                a = (~_a) + 32'd1 ;
            end else begin
                a = _a;
            end
            if(_b[31]) begin
                b = (~_b) + 32'd1 ;
            end else begin
                b = _b;
            end
        end
    end

    always_comb begin
        if(sig) begin
            if(_a[31]) begin
                if(_b[31]) begin
                    _c[63:32] = (~c[63:32]) + 32'd1;
                    _c[31:0]  = c[31:0];
                end else begin
                    _c[63:32] = (~c[63:32]) + 32'd1;
                    _c[31:0]  = (~c[31:0])  + 32'd1;
                end
            end else begin
                if(_b[31]) begin
                    _c[63:32] = c[63:32];
                    _c[31:0]  = (~c[31:0])  + 32'd1;
                end else begin
                    _c=c;
                end
            end
        end else begin
            _c = c;
        end
    end

    enum i1 { INIT = 1'b0, DOING = 1'b1 } state, state_nxt;
    i35 count, count_nxt;
    localparam i35 DIV_DELAY = {2'b0, 1'b1, 32'b0};
    always_ff @(posedge clk) begin
        if (~resetn) begin
            {state, count} <= '0;
        end else begin
            {state, count} <= {state_nxt, count_nxt};
        end
    end
    assign done = (state_nxt == INIT);
    always_comb begin
        {state_nxt, count_nxt} = {state, count}; // default
        unique case(state)
            INIT: begin
                if (valid) begin
                    state_nxt = DOING;
                    count_nxt = DIV_DELAY;
                end
            end
            DOING: begin
                count_nxt = {1'b0, count_nxt[34:1]};
                if (count_nxt == '0) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    i64 p, p_nxt;
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {32'b0, a};
            end
            DOING: begin
                p_nxt = {p_nxt[62:0], 1'b0};
                if (p_nxt[63:32] >= b) begin
                    p_nxt[63:32] -= b;
                    p_nxt[0] = 1'b1;
                end
            end
        endcase
    end
    always_ff @(posedge clk) begin
        if (~resetn) begin
            p <= '0;
        end else begin
            p <= p_nxt;
        end
    end
    assign c = p;
endmodule
