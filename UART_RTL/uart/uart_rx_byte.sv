// uart_rx_byte.sv
// Single-byte UART receive path for one color (or config) channel.
// Each instance has its own baud_generator by default so three async RX wires
// stay independent. Set USE_SHARED_BAUD when sampling a locally generated TX
// line (loopback / same-clock-domain) to share the transmitter baud tick.

module uart_rx_byte #(
    parameter int CLOCK_FREQ     = 66_000_000,
    parameter int BAUD_RATE      = 115_200,
    parameter bit USE_SHARED_BAUD = 1'b0
) (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       serial_rx,
    input  logic       baud_tick_shared,
    input  logic       output_ready,
    output logic [7:0] px_out,
    output logic       px_ready
);

    logic serial_rx_sync;
    logic serial_rx_sync_raw;
    logic shift_en;
    logic baud_tick;
    logic baud_tick_local;
    logic baud_sync_reset;
    logic fsm_baud_sync_reset;

    generate
        if (!USE_SHARED_BAUD) begin : gen_local_baud
            baud_generator #(
                .CLOCK_FREQ(CLOCK_FREQ),
                .BAUD_RATE (BAUD_RATE)
            ) u_baud_gen (
                .clk         (clk),
                .n_rst       (n_rst),
                .sync_reset  (baud_sync_reset),
                .baud_tick   (baud_tick_local)
            );
        end
    endgenerate

    assign baud_tick       = USE_SHARED_BAUD ? baud_tick_shared : baud_tick_local;
    assign baud_sync_reset = USE_SHARED_BAUD ? 1'b0 : fsm_baud_sync_reset;

    uart_rx_sync u_sync (
        .clk             (clk),
        .n_rst           (n_rst),
        .serial_rx_async (serial_rx),
        .serial_rx_sync  (serial_rx_sync_raw)
    );

    assign serial_rx_sync = USE_SHARED_BAUD ? serial_rx : serial_rx_sync_raw;

    uart_rx_fsm #(
        .CLOCK_FREQ  (CLOCK_FREQ),
        .BAUD_RATE   (BAUD_RATE),
        .SHARED_BAUD (USE_SHARED_BAUD)
    ) u_fsm (
        .clk             (clk),
        .n_rst           (n_rst),
        .serial_rx       (serial_rx_sync),
        .baud_tick       (baud_tick),
        .output_ready    (output_ready),
        .shift_en        (shift_en),
        .px_ready        (px_ready),
        .baud_sync_reset (fsm_baud_sync_reset)
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
