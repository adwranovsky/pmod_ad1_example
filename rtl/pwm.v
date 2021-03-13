`default_nettype none
module pwm #(
    parameter WIDTH = 12
) (
    input wire clk_i,
    input wire [WIDTH-1:0] compare_i,
    output wire pwm_o
);
    reg [WIDTH-1:0] counter;
    initial counter = 0;
    always @(posedge clk_i)
        counter <= counter + 1;
    assign pwm_o = counter < compare_i;
endmodule
`default_nettype wire
