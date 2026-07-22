// uart_rx_sync.sv
// 2 flop sync for the async RX pin so we dont feed metastability into the FSM

module uart_rx_sync (
    input  logic clk,
    input  logic n_rst,           // async active low reset
    input  logic serial_rx_async, // raw pin from outside
    output logic serial_rx_sync
);

    logic sync_ff0; // first flop

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            sync_ff0 <= 1'b1;       // idle high for UART
            serial_rx_sync <= 1'b1;
        end else begin
            // classic 2FF chain
            sync_ff0 <= serial_rx_async;
            serial_rx_sync <= sync_ff0;
        end
    end

endmodule
