// baud_generator.sv
// Generates a one-cycle baud_tick pulse every CLKS_PER_BIT clock cycles.
// Used by both UART RX and TX paths to sample/shift serial data at the
// configured baud rate.

module baud_generator #(
    parameter int CLOCK_FREQ = 66_000_000,  // iCE40-HX8K board clock (Hz)
    parameter int BAUD_RATE  = 115_200,     // Target UART baud rate (Hz)
    localparam int CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE  // ~104 at 12 MHz / 115200
) (
    input  logic clk,       // System clock
    input  logic n_rst,     // Active-low asynchronous reset
    output logic baud_tick  // One-cycle pulse; asserted once per bit period
);

    // Internal counter; increments each clock cycle and wraps at CLKS_PER_BIT
    logic [$clog2(CLKS_PER_BIT + 1)-1:0] baud_counter;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset baud_counter and baud_tick
            baud_counter <= 0;
            baud_tick <= 0;
        end else begin
            // TODO: Increment baud_counter each cycle
            baud_counter <= baud_counter + 1;
            // TODO: Assert baud_tick for one cycle when counter reaches CLKS_PER_BIT - 1
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_tick <= 1;
            end else begin
                baud_tick <= 0;
            end

            //Reset the counter
            if (baud_counter == CLKS_PER_BIT - 1) begin
                baud_counter <= 0;
            end
            
        end
    end

endmodule
