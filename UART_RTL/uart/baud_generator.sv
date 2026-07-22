// baud_generator.sv
// just counts clocks and pulses baud_tick once per bit period
// sync_reset is so RX can realign when it sees a start bit

module baud_generator #(
    parameter int CLOCK_FREQ = 66_000_000, // board clk
    parameter int BAUD_RATE  = 115_200,
    localparam int CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE
) (
    input  logic clk,
    input  logic n_rst,
    input  logic sync_reset,
    output logic baud_tick
);

    // width big enough for the counter
    logic [$clog2(CLKS_PER_BIT + 1)-1:0] baud_counter;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            baud_counter <= '0;
            baud_tick <= 1'b0;
        end else if (sync_reset) begin
            // restart the count from 0
            baud_counter <= '0;
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_counter <= '0;
                baud_tick <= 1'b1; // one cycle pulse
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
