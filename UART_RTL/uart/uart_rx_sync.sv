// uart_rx_sync.sv
// 2-flop synchronizer for asynchronous serial_rx input.
// Metastability protection: external serial line is not clock-aligned to clk.

module uart_rx_sync (
    input  logic clk,              // System clock
    input  logic n_rst,            // Active-low asynchronous reset
    input  logic serial_rx_async,  // Raw UART RX pin (asynchronous)
    output logic serial_rx_sync    // Synchronized serial line for FSM/shift reg
);

    logic sync_ff0;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            sync_ff0        <= 1'b1;
            serial_rx_sync  <= 1'b1;
        end else begin
            sync_ff0       <= serial_rx_async;
            serial_rx_sync <= sync_ff0;
        end
    end

endmodule
