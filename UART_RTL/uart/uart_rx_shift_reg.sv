// uart_rx_shift_reg.sv
// Serial-to-parallel converter for UART reception.
// Samples serial_rx on each enabled baud_tick and shifts one bit into an
// 8-bit holding register (LSB first, UART convention).

module uart_rx_shift_reg (
    input  logic       clk,       // System clock
    input  logic       n_rst,     // Active-low asynchronous reset
    input  logic       serial_rx, // Incoming serial line from host
    input  logic       baud_tick, // Bit-period timing pulse from baud_generator
    input  logic       shift_en,  // FSM enable: shift one bit when asserted with baud_tick
    output logic [7:0] rx_data    // Assembled byte (valid when FSM asserts rx_valid)
);

    // 8-bit shift register; LSB received first
    logic [7:0] shift_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset shift_reg
        end else begin
            // TODO: When shift_en and baud_tick are both asserted, shift in serial_rx
            //       Hint: new_byte = {serial_rx, shift_reg[7:1]} for LSB-first reception
        end
    end

    // Combinational output of the shift register
    always_comb begin
        // TODO: Drive rx_data from shift_reg (or assign directly if appropriate)
    end

endmodule
