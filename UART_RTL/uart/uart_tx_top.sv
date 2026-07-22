// uart_tx_top.sv
// top TX - shared baud gen + 3 parallel byte transmitters for R/G/B
// output_ready from pixel_controller kicks off all three at once

module uart_tx_top #(
    parameter int CLOCK_FREQ = 66_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic clk,
    input  logic n_rst,
    input  logic [7:0] r_out, // from pixel processor
    input  logic [7:0] g_out,
    input  logic [7:0] b_out,
    input  logic output_ready,
    output logic serial_tx_r,
    output logic serial_tx_g,
    output logic serial_tx_b,
    output logic tx_ready,  // all 3 idle
    output logic baud_tick
);

    logic tx_ready_r, tx_ready_g, tx_ready_b;
    logic tx_baud_resync;

    // ready only when every channel is free
    assign tx_ready = tx_ready_r & tx_ready_g & tx_ready_b;

    baud_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_gen (
        .clk(clk),
        .n_rst(n_rst),
        .sync_reset(tx_baud_resync),
        .baud_tick(baud_tick)
    );

    // only R drives baud_resync, G/B just follow the same tick
    uart_tx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx_r (
        .clk(clk),
        .n_rst(n_rst),
        .baud_tick(baud_tick),
        .px_in(r_out),
        .output_ready(output_ready),
        .serial_tx(serial_tx_r),
        .tx_ready(tx_ready_r),
        .baud_resync(tx_baud_resync)
    );

    uart_tx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx_g (
        .clk(clk),
        .n_rst(n_rst),
        .baud_tick(baud_tick),
        .px_in(g_out),
        .output_ready(output_ready),
        .serial_tx(serial_tx_g),
        .tx_ready(tx_ready_g),
        .baud_resync() // unused
    );

    uart_tx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx_b (
        .clk(clk),
        .n_rst(n_rst),
        .baud_tick(baud_tick),
        .px_in(b_out),
        .output_ready(output_ready),
        .serial_tx(serial_tx_b),
        .tx_ready(tx_ready_b),
        .baud_resync()
    );

endmodule
