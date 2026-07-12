// uart_rx_byte.sv
// Single-byte UART receive path for one color (or config) channel.
// Each instance has its own baud_generator so three RX wires stay independent.

module uart_rx_byte #(
    parameter int CLOCK_FREQ = 12_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       serial_rx,
    input  logic       output_ready,
    output logic [7:0] px_out,
    output logic       px_ready
);

    logic serial_rx_sync;
    logic shift_en;
    logic baud_tick;
    logic baud_sync_reset;

    baud_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk         (clk),
        .n_rst       (n_rst),
        .sync_reset  (baud_sync_reset),
        .baud_tick   (baud_tick)
    );

    uart_rx_sync u_sync (
        .clk             (clk),
        .n_rst           (n_rst),
        .serial_rx_async (serial_rx),
        .serial_rx_sync  (serial_rx_sync)
    );

    uart_rx_fsm #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_fsm (
        .clk             (clk),
        .n_rst           (n_rst),
        .serial_rx       (serial_rx_sync),
        .baud_tick       (baud_tick),
        .output_ready    (output_ready),
        .shift_en        (shift_en),
        .px_ready        (px_ready),
        .baud_sync_reset (baud_sync_reset)
    );

    uart_rx_shift_reg u_shift (
        .clk       (clk),
        .n_rst     (n_rst),
        .serial_rx (serial_rx_sync),
        .baud_tick (baud_tick),
        .shift_en  (shift_en),
        .rx_data   (px_out)
    );

endmodule
