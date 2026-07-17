module top(
    input logic clk,
    input logic n_rst,

    input logic rx_r,
    input logic rx_g,
    input logic rx_b,
    input logic rx_config,

    output logic tx_r,
    output logic tx_g,
    output logic tx_b
);
    // internal signals
    logic r_ready, g_ready, b_ready, config_ready, output_ready;
    logic [7:0] config_byte, r_in, b_in, g_in, r_out, g_out, b_out;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;

    // uart rx rgb instantiations
    uart_rx_top rgb_rx (
        .clk(clk), .n_rst(n_rst),
        .serial_rx_r(rx_r), .serial_rx_g(rx_g), .serial_rx_b(rx_b),
        .baud_tick_shared(1'b0), .output_ready(output_ready),
        .r_px(r_in), .r_ready(r_ready), 
        .g_px(g_in), .g_ready(g_ready), 
        .b_px(b_in), .b_ready(b_ready)
    );

    // uart rx config instantiation
    uart_rx_config uart_config(
        .clk(clk), .n_rst(n_rst),
        .serial_rx_config(rx_config), .config_ack(config_ready),
        .config_byte(config_byte), .config_ready(config_ready)
    );

    
    // uart tx rgb instantiation
    uart_tx_top rgb_tx(
        .clk(clk), .n_rst(n_rst),
        .r_out(r_out), .g_out(g_out), .b_out(b_out),
        .output_ready(output_ready),
        .serial_tx_r(tx_r), .serial_tx_g(tx_g), .serial_tx_b(tx_b),
        .tx_ready(), .baud_tick()
    );
    

    // control instantiation
    pixel_controller control (
        .clk(clk), .n_rst(n_rst),
        .r_ready(r_ready), .g_ready(g_ready), .b_ready(b_ready), 
        .config_ready(config_ready), .config_byte(config_byte),
        .mode_locked(mode_locked), .threshold_locked(threshold_locked),
        .output_ready(output_ready)
    );

    // pixel accelerator instantiation
    pixel_accelerator accelerator(
        .r_in(r_in), .g_in(g_in), .b_in(b_in),
        .mode_locked(mode_locked), .threshold_locked(threshold_locked),
        .r_out(r_out), .g_out(g_out), .b_out(b_out)
    );

endmodule
