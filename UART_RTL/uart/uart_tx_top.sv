// uart_tx_top.sv
// Top-level UART transmitter for the STARS image-processing project.
// Instantiates baud_generator, pixel_serializer, uart_tx_fsm, and
// uart_tx_shift_reg. Accepts 24-bit RGB888 pixels and transmits serial bytes.

module uart_tx_top #(
    parameter int CLOCK_FREQ = 12_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic        clk,          // System clock (12 MHz on iCE40-HX8K)
    input  logic        n_rst,        // Active-low asynchronous reset
    input  logic [23:0] pixel_out,    // RGB888 pixel to transmit
    input  logic        pixel_valid,  // Pulse when pixel_out holds a new pixel
    output logic        serial_tx    // UART TX pin to host
);

    // -------------------------------------------------------------------------
    // Internal interconnect signals
    // -------------------------------------------------------------------------
    logic       baud_tick;  // Bit-period timing pulse
    logic       load;       // FSM -> shift register load strobe
    logic       shift_en;   // FSM -> shift register enable
    logic       tx_valid;   // pixel_serializer -> FSM byte-ready strobe
    logic       tx_ready;   // FSM -> indicates ready for next byte
    logic [7:0] tx_data; 
    logic       shift_tx;   // bit from shift register to serial_tx
    logic [1:0] tx_state;   // state of the FSM

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
    // pixel_serializer: splits RGB888 pixel into R, G, B bytes
    // -------------------------------------------------------------------------
    pixel_serializer u_pixel_ser (
        .clk         (clk),
        .n_rst       (n_rst),
        .pixel_out   (pixel_out),
        .pixel_valid (pixel_valid),
        .tx_ready    (tx_ready),
        .tx_data     (tx_data),
        .tx_valid    (tx_valid)
    );

    // -------------------------------------------------------------------------
    // uart_tx_fsm: controls transmission framing and shifting
    // -------------------------------------------------------------------------
    uart_tx_fsm u_tx_fsm (
        .clk      (clk),
        .n_rst    (n_rst),
        .tx_valid (tx_valid),
        .baud_tick(baud_tick),
        .load     (load),
        .shift_en (shift_en),
        .tx_ready (tx_ready),
        .tx_state(tx_state)
    );

    // -------------------------------------------------------------------------
    // uart_tx_shift_reg: shifts bytes out serially
    // -------------------------------------------------------------------------
    uart_tx_shift_reg u_tx_shift (
        .clk      (clk),
        .n_rst    (n_rst),
        .tx_data  (tx_data),
        .load     (load),
        .baud_tick(baud_tick),
        .shift_en (shift_en),
        .serial_tx(shift_tx),
    );

    always_comb begin
        case (tx_state)
            2'b01: begin
                serial_tx = 1'b0;
            end
            2'b10: begin
                serial_tx = shift_tx;
            end
            default: begin
                serial_tx = 1'b1;
            end
        endcase
    end

endmodule
