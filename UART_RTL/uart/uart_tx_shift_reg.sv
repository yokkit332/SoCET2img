// uart_tx_shift_reg.sv
// Parallel-to-serial converter for UART transmission.

module uart_tx_shift_reg (
    input  logic       clk,
    input  logic       n_rst,
    input  logic [7:0] tx_data,
    input  logic       load,
    input  logic       baud_tick,  // unused; kept for interface compatibility
    input  logic       shift_en,
    output logic [7:0] shift_out
);

    logic [7:0] shift_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            shift_reg <= 8'h00;
        else if (load)
            shift_reg <= tx_data;
        else if (shift_en)
            shift_reg <= shift_reg >> 1;
    end

    assign shift_out = shift_reg;

endmodule
