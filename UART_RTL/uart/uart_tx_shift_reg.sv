// uart_tx_shift_reg.sv
// Parallel-to-serial converter for UART transmission.
// Loads one byte and shifts bits out serially on each enabled baud_tick
// (LSB first, UART convention).

module uart_tx_shift_reg (
    input  logic       clk,       // System clock
    input  logic       n_rst,     // Active-low asynchronous reset
    input  logic [7:0] tx_data,   // Byte to load for transmission
    input  logic       load,      // FSM strobe: load tx_data into shift register
    input  logic       baud_tick, // Bit-period timing pulse from baud_generator
    input  logic       shift_en,  // FSM enable: shift one bit when asserted with baud_tick
    output logic       serial_tx  // UART TX line to host (idle high)
);

    // 8-bit shift register; LSB transmitted first
    logic [7:0] shift_reg;

    // Registered serial output (idle high when not shifting)
    logic serial_tx_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset shift_reg and serial_tx_reg (idle = 1'b1)
            shift_reg <= 0;
            serial_tx_reg <= 1;
        end else begin
            // TODO: When load is asserted, load tx_data into shift_reg
            if (load == 1'b1) begin
                shift_reg <= tx_data;
            end else if (shift_en == 1'b1 && baud_tick == 1'b1) begin
                shift_reg <= shift_reg >> 1;
                serial_tx_reg <= shift_reg[0];
            end

        end
    end

    // Combinational output
    always_comb begin
        // TODO: Drive serial_tx from serial_tx_reg (or assign directly)
        serial_tx = serial_tx_reg;
    end

endmodule
