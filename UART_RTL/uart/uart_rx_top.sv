// uart_rx_top.sv
// Top-level UART receiver for the STARS image-processing project.
// Instantiates baud_generator, uart_rx_fsm, uart_rx_shift_reg, and
// pixel_assembler. Receives serial bytes and outputs 24-bit RGB888 pixels.

module uart_rx_top #(
    parameter int CLOCK_FREQ = 12_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic        clk,         // System clock (12 MHz on iCE40-HX8K)
    input  logic        n_rst,       // Active-low asynchronous reset
    input  logic        serial_rx,   // UART RX pin from host
    output logic [23:0] pixel_in,    // Assembled RGB888 pixel
    output logic        pixel_valid  // Pulse when pixel_in holds a new pixel
);

    // -------------------------------------------------------------------------
    // Internal interconnect signals
    // -------------------------------------------------------------------------
    logic       baud_tick;  // Bit-period timing pulse
    logic       shift_en;   // FSM -> shift register enable
    logic       rx_valid;   // FSM -> pixel_assembler byte-ready strobe
    logic [7:0] rx_data;    // Shift register -> pixel_assembler byte data

    // -------------------------------------------------------------------------
    // baud_generator: produces baud_tick at configured baud rate
    // -------------------------------------------------------------------------
    baud_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk      (clk),
        .n_rst    (n_rst),
        .baud_tick(baud_tick)
    );

    // -------------------------------------------------------------------------
    // uart_rx_fsm: controls reception framing and shifting
    // -------------------------------------------------------------------------
    uart_rx_fsm u_rx_fsm (
        .clk      (clk),
        .n_rst    (n_rst),
        .serial_rx(serial_rx),
        .baud_tick(baud_tick),
        .shift_en (shift_en),
        .rx_valid (rx_valid)
    );

    // -------------------------------------------------------------------------
    // uart_rx_shift_reg: assembles serial bits into bytes
    // -------------------------------------------------------------------------
    uart_rx_shift_reg u_rx_shift (
        .clk      (clk),
        .n_rst    (n_rst),
        .serial_rx(serial_rx),
        .baud_tick(baud_tick),
        .shift_en (shift_en),
        .rx_data  (rx_data)
    );

    // -------------------------------------------------------------------------
    // pixel_assembler: groups 3 bytes (R, G, B) into one RGB888 pixel
    // -------------------------------------------------------------------------
    pixel_assembler u_pixel_asm (
        .clk        (clk),
        .n_rst      (n_rst),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .pixel_in   (pixel_in),
        .pixel_valid(pixel_valid)
    );

endmodule
