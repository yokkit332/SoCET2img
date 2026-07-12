// uart_tx_top.sv
// Top-level RGB UART transmitter — matches system block diagram.
// Three parallel byte transmitters (R, G, B). Takes processed pixels from
// Pixel Processor; output_ready from pixel_controller triggers all three.

module uart_tx_top #(
    parameter int CLOCK_FREQ = 12_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [7:0]  r_out,         // From Pixel Processor
    input  logic [7:0]  g_out,
    input  logic [7:0]  b_out,
    input  logic        output_ready,  // From pixel_controller
    output logic        serial_tx_r,
    output logic        serial_tx_g,
    output logic        serial_tx_b,
    output logic        tx_ready        // High when all three TX paths are idle
);

    logic baud_tick;
    logic tx_ready_r;
    logic tx_ready_g;
    logic tx_ready_b;

    assign tx_ready = tx_ready_r & tx_ready_g & tx_ready_b;

    baud_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk         (clk),
        .n_rst       (n_rst),
        .sync_reset  (1'b0),
        .baud_tick   (baud_tick)
    );

    uart_tx_byte u_tx_r (
        .clk          (clk),
        .n_rst        (n_rst),
        .baud_tick    (baud_tick),
        .px_in        (r_out),
        .output_ready (output_ready),
        .serial_tx    (serial_tx_r),
        .tx_ready     (tx_ready_r)
    );

    uart_tx_byte u_tx_g (
        .clk          (clk),
        .n_rst        (n_rst),
        .baud_tick    (baud_tick),
        .px_in        (g_out),
        .output_ready (output_ready),
        .serial_tx    (serial_tx_g),
        .tx_ready     (tx_ready_g)
    );

    uart_tx_byte u_tx_b (
        .clk          (clk),
        .n_rst        (n_rst),
        .baud_tick    (baud_tick),
        .px_in        (b_out),
        .output_ready (output_ready),
        .serial_tx    (serial_tx_b),
        .tx_ready     (tx_ready_b)
    );

endmodule
