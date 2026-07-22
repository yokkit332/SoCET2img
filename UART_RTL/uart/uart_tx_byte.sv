// uart_tx_byte.sv
// one TX channel (R or G or B)
// wires up the FSM + shift reg and muxes the serial line

module uart_tx_byte #(
    parameter int CLOCK_FREQ = 66_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic clk,
    input  logic n_rst,
    input  logic baud_tick,
    input  logic [7:0] px_in,
    input  logic output_ready,
    output logic serial_tx,
    output logic tx_ready,
    output logic baud_resync
);

    logic load;
    logic shift_en;
    logic tx_valid;
    logic [1:0] tx_state;
    logic [7:0] shift_out;

    // only fire when we're idle AND controller wants to send
    assign tx_valid = output_ready & tx_ready;

    uart_tx_fsm u_fsm (
        .clk(clk),
        .n_rst(n_rst),
        .tx_valid(tx_valid),
        .baud_tick(baud_tick),
        .load(load),
        .shift_en(shift_en),
        .tx_ready(tx_ready),
        .tx_state(tx_state),
        .baud_resync(baud_resync)
    );

    uart_tx_shift_reg u_shift (
        .clk(clk),
        .n_rst(n_rst),
        .tx_data(px_in),
        .load(load),
        .baud_tick(baud_tick),
        .shift_en(shift_en),
        .shift_out(shift_out)
    );

    // drive the wire based on what state we're in
    // START=01 drives 0, DATA=10 drives shift_out[0], else idle high
    always_comb begin
        if (load)
            serial_tx = px_in[0]; // first data bit shows up right at load
        else begin
            case (tx_state)
                2'b01:   serial_tx = 1'b0;         // start bit
                2'b10:   serial_tx = shift_out[0]; // data
                default: serial_tx = 1'b1;         // idle / stop
            endcase
        end
    end

endmodule
