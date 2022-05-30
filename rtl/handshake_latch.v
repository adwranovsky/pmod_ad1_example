`default_nettype none
module handshake_latch #(
    parameter WIDTH = 24,
    parameter RESET_VALUE = 24'h0
) (
    input  wire clk_i,
    input  wire rst_i,

    output wire ready_o,
    input  wire valid_i,
    input  wire [WIDTH-1:0] data_i,

    output reg  [WIDTH-1:0] latched_data_o
);

    assign ready_o = !rst_i;
    initial latched_data_o = RESET_VALUE;
    always @(posedge clk_i)
        if (rst_i)
            latched_data_o <= RESET_VALUE;
        else if (valid_i)
            latched_data_o <= data_i;
        else
            latched_data_o <= latched_data_o;
endmodule
`default_nettype wire
