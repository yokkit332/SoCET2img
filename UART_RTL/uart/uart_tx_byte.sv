// uart_tx_byte.sv
// Single-byte UART transmit path for one color channel.

module uart_tx_byte (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       baud_tick,
    input  logic [7:0] px_in,
    input  logic       output_ready,
    output logic       serial_tx,
    output logic       tx_ready       // High when idle and ready for a new byte
);

    logic       load;
    logic       shift_en;
    logic       tx_valid;
    logic       shift_tx;
    logic [1:0] tx_state;
    logic [7:0] px_hold;

    assign tx_valid = output_ready & tx_ready;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            px_hold <= 8'h00;
        else if (load)
            px_hold <= px_in;
    end

    uart_tx_fsm u_fsm (
        .clk       (clk),
        .n_rst     (n_rst),
        .tx_valid  (tx_valid),
        .baud_tick (baud_tick),
        .load      (load),
        .shift_en  (shift_en),
        .tx_ready  (tx_ready),
        .tx_state  (tx_state)
    );

    uart_tx_shift_reg u_shift (
        .clk       (clk),
        .n_rst     (n_rst),
        .tx_data   (px_hold),
        .load      (load),
        .baud_tick (baud_tick),
        .shift_en  (shift_en),
        .serial_tx (shift_tx)
    );

    always_comb begin
        case (tx_state)
            2'b01:   serial_tx = 1'b0;
            2'b10:   serial_tx = shift_tx;
            default: serial_tx = 1'b1;
        endcase
    end

endmodule
