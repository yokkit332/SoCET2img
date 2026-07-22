// uart_rx_config.sv
// tiny wrapper around uart_rx_byte for the config UART
// host sends mode then threshold over this line

module uart_rx_config #(
    parameter int CLOCK_FREQ = 66_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic clk,
    input  logic n_rst,
    input  logic serial_rx_config,
    input  logic config_ack,       // pulse when we've read the byte
    output logic [7:0] config_byte,
    output logic config_ready
);

    // always uses its own baud gen (not shared)
    uart_rx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .USE_SHARED_BAUD(1'b0)
    ) u_rx_config (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx_config),
        .baud_tick_shared(1'b0),
        .output_ready(config_ack),
        .px_out(config_byte),
        .px_ready(config_ready)
    );

endmodule
