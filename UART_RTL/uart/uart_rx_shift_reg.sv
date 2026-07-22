// uart_rx_shift_reg.sv
// shifts in one bit at a time (LSB first) when the FSM says so

module uart_rx_shift_reg (
    input  logic clk,
    input  logic n_rst,
    input  logic serial_rx,
    input  logic baud_tick, // not really used here but kept around
    input  logic shift_en,
    output logic [7:0] rx_data
);

    logic [7:0] shift_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            shift_reg <= 8'h00;
        else if (shift_en)
            // new bit comes in on the left, old LSB falls off
            shift_reg <= {serial_rx, shift_reg[7:1]};
    end

    assign rx_data = shift_reg;

endmodule
