// uart_rx_config.sv
// UART receiver for mode/threshold configuration bytes.

module uart_rx_config #(
    parameter int CLOCK_FREQ = 12_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       serial_rx_config,
    input  logic       config_ack,
    output logic [7:0] config_byte,
    output logic       config_ready
);

    uart_rx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_rx_config (
        .clk          (clk),
        .n_rst        (n_rst),
        .serial_rx    (serial_rx_config),
        .output_ready (config_ack),
        .px_out       (config_byte),
        .px_ready     (config_ready)
    );

endmodule
