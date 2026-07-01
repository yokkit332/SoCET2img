`timescale 1ns / 1ps

module image_accelerator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] pixel_in,
    input  wire       pixel_in_valid,
    input  wire [1:0] mode,
    input  wire [4:0] threshold,
    output reg  [7:0] pixel_out,
    output reg        pixel_out_valid
);

    localparam MODE_PASSTHROUGH = 2'b00;
    localparam MODE_INVERTER    = 2'b01;
    localparam MODE_BRIGHTEN    = 2'b10;
    localparam MODE_DARKEN      = 2'b11;

    wire [8:0] brighten_result;
    wire [8:0] darken_result;

    assign brighten_result = {1'b0, pixel_in} + {4'b0, threshold};
    assign darken_result   = {1'b0, pixel_in} - {4'b0, threshold};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out       <= 8'd0;
            pixel_out_valid <= 1'b0;
        end
        else begin
            pixel_out_valid <= pixel_in_valid;
            if (pixel_in_valid) begin
                case (mode)
                    MODE_PASSTHROUGH: pixel_out <= pixel_in;
                    MODE_INVERTER:    pixel_out <= 8'd255 - pixel_in;
                    MODE_BRIGHTEN:    pixel_out <= (brighten_result > 9'd255) ? 8'd255 : brighten_result[7:0];
                    MODE_DARKEN:      pixel_out <= (darken_result[8]) ? 8'd0 : darken_result[7:0];
                    default:          pixel_out <= pixel_in;
                endcase
            end
        end
    end

endmodule
