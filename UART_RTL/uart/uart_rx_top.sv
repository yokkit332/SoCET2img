// uart_rx_top.sv
// Top-level RGB UART receiver — matches system block diagram.

module uart_rx_top #(
    parameter int CLOCK_FREQ      = 66_000_000,
    parameter int BAUD_RATE       = 115_200,
    parameter bit USE_SHARED_BAUD = 1'b0
) (
    input  logic        clk,
    input  logic        n_rst,
    input  logic        serial_rx_r,
    input  logic        serial_rx_g,
    input  logic        serial_rx_b,
    input  logic        baud_tick_shared,
    input  logic        output_ready,
    output logic [7:0]  r_px,
    output logic        r_ready,
    output logic [7:0]  g_px,
    output logic        g_ready,
    output logic [7:0]  b_px,
    output logic        b_ready
);

    uart_rx_byte #(
        .CLOCK_FREQ      (CLOCK_FREQ),
        .BAUD_RATE       (BAUD_RATE),
        .USE_SHARED_BAUD (USE_SHARED_BAUD)
    ) u_rx_r (
        .clk              (clk),
        .n_rst            (n_rst),
        .serial_rx        (serial_rx_r),
        .baud_tick_shared (baud_tick_shared),
        .output_ready     (output_ready),
        .px_out           (r_px),
        .px_ready         (r_ready)
    );

    uart_rx_byte #(
        .CLOCK_FREQ      (CLOCK_FREQ),
        .BAUD_RATE       (BAUD_RATE),
        .USE_SHARED_BAUD (USE_SHARED_BAUD)
    ) u_rx_g (
        .clk              (clk),
        .n_rst            (n_rst),
        .serial_rx        (serial_rx_g),
        .baud_tick_shared (baud_tick_shared),
        .output_ready     (output_ready),
        .px_out           (g_px),
        .px_ready         (g_ready)
    );

    uart_rx_byte #(
        .CLOCK_FREQ      (CLOCK_FREQ),
        .BAUD_RATE       (BAUD_RATE),
        .USE_SHARED_BAUD (USE_SHARED_BAUD)
    ) u_rx_b (
        .clk              (clk),
        .n_rst            (n_rst),
        .serial_rx        (serial_rx_b),
        .baud_tick_shared (baud_tick_shared),
        .output_ready     (output_ready),
        .px_out           (b_px),
        .px_ready         (b_ready)
    );

endmodule
