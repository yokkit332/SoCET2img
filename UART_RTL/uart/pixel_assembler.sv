// pixel_assembler.sv
// [NOT USED] Legacy module for single-wire RX (3 sequential bytes -> pixel_in[23:0]).
// Current design uses three parallel uart_rx_byte instances (R/G/B wires) instead.
// Byte order was: byte 0 = R [23:16], byte 1 = G [15:8], byte 2 = B [7:0].

module pixel_assembler (
    input  logic        clk,         // System clock
    input  logic        n_rst,       // Active-low asynchronous reset
    input  logic [7:0]  rx_data,     // Received byte from uart_rx_shift_reg
    input  logic        rx_valid,    // Pulse when rx_data holds a new byte
    output logic [23:0] pixel_in,    // Assembled RGB888 pixel
    output logic        pixel_valid  // One-cycle pulse when pixel_in is valid
);

    // Tracks which byte of the current pixel is being received (0, 1, or 2)
    logic [1:0] byte_index;

    // Holds partial pixel data while bytes 0 and 1 are being collected
    logic [23:0] pixel_buffer;

    // -------------------------------------------------------------------------
    // Byte index register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset byte_index
        end else begin
            // TODO: Advance byte_index on rx_valid; wrap 2 -> 0
        end
    end

    // -------------------------------------------------------------------------
    // Pixel buffer register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset pixel_buffer
        end else begin
            // TODO: On rx_valid, store rx_data into the correct byte position
            //       based on byte_index (R, then G, then B)
        end
    end

    // -------------------------------------------------------------------------
    // Output logic
    // -------------------------------------------------------------------------
    always_comb begin
        // TODO: Drive pixel_in from pixel_buffer (or registered output)
        // TODO: Assert pixel_valid for one cycle when byte_index == 2 and rx_valid
    end

endmodule
