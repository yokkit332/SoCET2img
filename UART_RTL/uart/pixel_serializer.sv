// pixel_serializer.sv
// Splits one 24-bit RGB888 pixel into three UART bytes for transmission.
// Byte order: R [23:16], then G [15:8], then B [7:0].

module pixel_serializer (
    input  logic        clk,          // System clock
    input  logic        n_rst,        // Active-low asynchronous reset
    input  logic [23:0] pixel_out,    // RGB888 pixel to transmit
    input  logic        pixel_valid, 
    input  logic        tx_ready,     // Pulse when tx_data is ready to be transmitted
    output logic [7:0]  tx_data,      // Current byte to transmit
    output logic        tx_valid      // Pulse when tx_data holds a new byte
);

    // Tracks which byte of the current pixel is being sent (0 = R, 1 = G, 2 = B)
    logic [1:0] byte_index;

    // Holds the pixel being serialized across three byte cycles
    logic [23:0] pixel_hold;

    // -------------------------------------------------------------------------
    // Byte index register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset byte_index
            byte_index <= 2'b00;
        end else begin
            // TODO: On pixel_valid, reset byte_index to 0
            if (pixel_valid)
                byte_index <= 2'b00;
            else if (tx_valid && tx_ready)
                byte_index <= byte_index + 1;
            else
                byte_index <= byte_index;
            // TODO: On tx_valid (byte sent), increment byte_index; wrap after byte 2
        end
    end

    // -------------------------------------------------------------------------
    // Pixel hold register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset pixel_hold
            pixel_hold <= 24'h000000;
        end else begin
            // TODO: Latch pixel_out into pixel_hold when pixel_valid is asserted
            if (pixel_valid)
                pixel_hold <= pixel_out;
            else
                pixel_hold <= pixel_hold;
        end
    end

    // -------------------------------------------------------------------------
    // Output logic
    // -------------------------------------------------------------------------
    always_comb begin
        // TODO: Select tx_data byte from pixel_hold based on byte_index
        // TODO: Assert tx_valid when a new byte is ready to send
        if (byte_index == 2'b00)
            tx_data = pixel_hold[23:16];
        else if (byte_index == 2'b01)
            tx_data = pixel_hold[15:8];
        else if (byte_index == 2'b10)
            tx_data = pixel_hold[7:0];
        else
            tx_data = 8'h00;
        if (byte_index == 2'b01 || byte_index == 2'b10 || byte_index == 2'b00)
            tx_valid = 1'b1;
        else
            tx_valid = 1'b0;
    end
endmodule
