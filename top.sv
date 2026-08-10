module top #(
    parameter int CLOCK_FREQ = 66_000_000,
    parameter int BAUD_RATE  = 115_200,
    parameter int NUM_PIXELS = 4800
) (
    input  logic clk,
    input  logic n_rst,

    input  logic serial_rx,
    output logic serial_tx
);

    logic [7:0] rx_data;
    logic       rx_ready;
    logic       rx_ack;

    logic [2:0] mode;
    logic [4:0] threshold;
    logic [7:0] red_in, green_in, blue_in;
    logic       pixel_valid;
    logic       pixel_ready;
    logic       frame_start;
    logic       frame_done;

    logic [7:0] red_out, green_out, blue_out;

    uart_rx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE),
        .USE_SHARED_BAUD(1'b0)
    ) u_rx (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx),
        .baud_tick_shared(1'b0),
        .output_ready(rx_ack),
        .px_out(rx_data),
        .px_ready(rx_ready)
    );

    uart_stream_decoder #(
        .NUM_PIXELS(NUM_PIXELS)
    ) u_decoder (
        .clk(clk),
        .n_rst(n_rst),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_ack(rx_ack),
        .mode(mode),
        .threshold(threshold),
        .red(red_in),
        .green(green_in),
        .blue(blue_in),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .frame_start(frame_start),
        .frame_done(frame_done)
    );

    pixel_accelerator u_accel (
        .r_in(red_in),
        .g_in(green_in),
        .b_in(blue_in),
        .mode_locked(mode),
        .threshold_locked(threshold),
        .r_out(red_out),
        .g_out(green_out),
        .b_out(blue_out)
    );

    uart_rgb_serializer #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_serializer (
        .clk(clk),
        .n_rst(n_rst),
        .red_in(red_out),
        .green_in(green_out),
        .blue_in(blue_out),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .serial_tx(serial_tx),
        .busy(),
        .pixel_done()
    );

endmodule
