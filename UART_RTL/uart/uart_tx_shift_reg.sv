// uart_tx_shift_reg.sv
// Parallel-to-serial converter for UART transmission.

module uart_tx_shift_reg (
    input  logic       clk,
    input  logic       n_rst,
    input  logic [7:0] tx_data,
    input  logic       load,
    input  logic       baud_tick,
    input  logic       shift_en,
    output logic       serial_tx
);

    logic [7:0] shift_reg;
    logic       serial_tx_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            shift_reg     <= 8'h00;
            serial_tx_reg <= 1'b1;
        end else if (load) begin
            shift_reg <= tx_data;
        end else if (shift_en && baud_tick) begin
            serial_tx_reg <= shift_reg[0];
            shift_reg     <= shift_reg >> 1;
        end
    end

    assign serial_tx = serial_tx_reg;

endmodule
