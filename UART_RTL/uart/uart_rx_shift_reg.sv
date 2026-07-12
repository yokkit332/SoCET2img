// uart_rx_shift_reg.sv
// Serial-to-parallel converter for UART reception.
// Samples serial_rx on each enabled baud_tick and shifts one bit into an
// 8-bit holding register (LSB first, UART convention).

module uart_rx_shift_reg (
    input  logic       clk,       // System clock
    input  logic       n_rst,     // Active-low asynchronous reset
    input  logic       serial_rx, // Synchronized incoming serial line
    input  logic       baud_tick, // Bit-period timing pulse from baud_generator
    input  logic       shift_en,  // FSM enable: shift one bit when asserted with baud_tick
    output logic [7:0] rx_data    // Assembled byte (stable when FSM asserts rx_valid)
);

    logic [7:0] shift_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            shift_reg <= 8'h00;
        end else if (shift_en && baud_tick) begin
            shift_reg <= {serial_rx, shift_reg[7:1]};
        end
    end

    assign rx_data = shift_reg;

endmodule
