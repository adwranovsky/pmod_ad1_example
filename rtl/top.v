`default_nettype none
module pmod_ad1_top #(
    parameter CLK_FREQ = 100_000_000
) (
    input wire clk_i,
    input wire rst_i,

    // PMOD AD1 Interface
    output wire sclk_o,
    output wire cs_n_o,
    input wire [1:0] sdata_i,

    // PWM output
    output wire [1:0] pwm_o,

    // Enable input
    input wire enable_i
);
    // Bring asynchronous inputs into this clock domain
    reg rst_input, rst_input_metastable;
    reg enable, enable_metastable;
    always @(posedge clk_i) begin
        {rst_input, rst_input_metastable} <= {rst_input_metastable, rst_i};
        {enable, enable_metastable} <= {enable_metastable, enable_i};
    end

    // Assert reset for the first cycle after the bitstream is loaded, then mirror the rst_i input afterwards
    reg rst;
    initial rst = 1;
    always @(posedge clk_i)
        rst <= rst_input;

    // Read samples from the PMOD AD1 if the enable input is on
    wire [23:0] sample_data;
    wire sample_data_valid;
    ad7476a_interface #(
        .CLK_FREQ_HZ(CLK_FREQ),
        .SCLK_FREQ_HZ(20000000),
        .NUM_DEVICES(2)
    ) pmod_ad1 (
        .clk_i(clk_i),
        .rst_i(rst),
        .request_i(enable),
        .data_o(sample_data),
        .data_valid_o(sample_data_valid),
        .sclk_o(sclk_o),
        .cs_n_o(cs_n_o),
        .sdata_i(sdata_i)
    );

    // Save the last valid samples
    reg [11:0] sample1, sample2;
    always @(posedge clk_i) begin
        if (rst) begin
            sample1 <= 0;
            sample2 <= 0;
        end else if (sample_data_valid) begin
            sample1 <= sample_data[11:0];
            sample2 <= sample_data[23:12];
        end else begin
            sample1 <= sample1;
            sample2 <= sample2;
        end
    end

    // Output the last samples read as PWM signals
    pwm #(
        .WIDTH(12)
    ) sample1_pwm (
        .clk_i(clk_i),
        .compare_i(sample1),
        .pwm_o(pwm_o[0])
    );
    pwm #(
        .WIDTH(12)
    ) sample2_pwm (
        .clk_i(clk_i),
        .compare_i(sample2),
        .pwm_o(pwm_o[1])
    );
endmodule
`default_nettype wire
