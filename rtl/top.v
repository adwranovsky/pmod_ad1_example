/* ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright 2022 Alex Wranovsky
 *
 * This work is licensed under the CERN-OHL-P v2, a permissive license for hardware. You may find the full license text
 * here if you have not received it with this source code distribution:
 *
 * https://ohwr.org/cern_ohl_p_v2.txt
 *
 * ---------------------------------------------------------------------------------------------------------------------
 *
 *
 * `pmod_ad1_top` - An example project using the PMOD AD1 from Digilent.
 *
 * Parameters:
 *  `CLK_FREQ_HZ` - The input clock frequency
 *
 * Ports:
 *  `clk_i` - The system clock input
 *  `rst_i` - An active high asynchronous reset
 *
 *  `pwm_o` - PWM output to the board LEDs. The PWM duty cycle matches the last sample read.
 *  `enable_i` - An enable input. May be asynchronous
 *
 *  `sclk_o` - The output clock for the SPI interface, with a frequency no greater than `SCLK_FREQ_HZ`.
 *  `cs_n_o` - The chip select signal of the SPI interface
 *  `sdata_i` - The SPI data input from the SPI device
 *
 * Description:
 *  An example design showing off the PMOD AD1 board from Digilent. Accompanying constraints files are meant to be used
 *  with the Arty A7 35t board, also from Digilent.
 */

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

    // LEDs
    output wire [3:0] led_o,

    // Reset indicator
    output wire rst_o
);
    // Bring asynchronous inputs into this clock domain
    reg rst_input, rst_input_metastable;
    always @(posedge clk_i) begin
        {rst_input, rst_input_metastable} <= {rst_input_metastable, rst_i};
    end

    // Assert reset for the first cycle after the bitstream is loaded, then mirror the rst_i input afterwards
    reg rst;
    initial rst = 1;
    always @(posedge clk_i)
        rst <= rst_input;

    // Continously samples from the PMOD AD1
    wire [31:0] sample_data;
    wire sample_data_valid, sample_data_ready;
    quick_spi #(
        .CLK_FREQ_HZ(CLK_FREQ),
        .SCLK_FREQ_HZ(20000000),
        .MAX_DATA_LENGTH(16),
        .NUM_DEVICES(2),
        .CS_TO_SCLK_TIME(10e-9),
        .QUIET_TIME(86e-9)
    ) pmod_ad1 (
        .clk_i(clk_i),
        .rst_i(rst),

        // FPGA interface
        .wrdata_ready_o(),
        .wrdata_valid_i(1'b1),
        .wrdata_len_i(5'd16),
        .wrdata_i(32'h0),

        .rddata_ready_i(sample_data_ready),
        .rddata_valid_o(sample_data_valid),
        .rddata_mask_o(),
        .rddata_o(sample_data),

        // SPI interface
        .sclk_o(sclk_o),
        .cs_n_o(cs_n_o),
        .sdata_o(),
        .sdata_i(sdata_i)
    );


    // Save the last valid samples
    wire [11:0] sample1, sample2;
    handshake_latch #(
        .WIDTH(24),
        .RESET_VALUE(0)
    ) save_samples (
        .clk_i(clk_i),
        .rst_i(rst),
        .ready_o(sample_data_ready),
        .valid_i(sample_data_valid),
        // The upper 3 bits from the converter are always 0 and the lowest bit is tri-stated, so ignore them
        .data_i({sample_data[17 +: 12], sample_data[1 +: 12]}),
        .latched_data_o({sample2,sample1})
    );

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

    // Make the LEDs match the top 4 bits of the last value of sample1
    assign led_o = sample1[11:8];
    // Assign the reset indicator light to rst
    assign rst_o = rst;

endmodule
`default_nettype wire
