// baud_generator.sv
// Generates a one-cycle baud_tick pulse every CLKS_PER_BIT clock cycles.
// sync_reset realigns the counter (used by RX on start-bit detection).

module baud_generator #(
    parameter int CLOCK_FREQ = 66_000_000,  // iCE40-HX8K board clock (Hz)
    parameter int BAUD_RATE  = 115_200,
    localparam int CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE
) (
    input  logic clk,
    input  logic n_rst,
    input  logic sync_reset,  // High to reset counter phase (RX start-bit align)
    output logic baud_tick
);

    logic [$clog2(CLKS_PER_BIT + 1)-1:0] baud_counter;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            baud_counter <= '0;
            baud_tick    <= 1'b0;
        end else if (sync_reset) begin
            baud_counter <= '0;
            baud_tick    <= 1'b0;
        end else begin
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_counter <= '0;
                baud_tick    <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick    <= 1'b0;
            end
        end
    end

endmodule
