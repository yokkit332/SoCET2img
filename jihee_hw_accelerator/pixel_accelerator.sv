`timescale 1ns / 1ps

module pixel_accelerator (
  
    input logic [7:0] r_in,
    input logic [7:0] g_in,
    input logic [7:0] b_in,
    
    input logic [2:0] mode_locked,
    input logic [4:0] threshold_locked,

    output logic [7:0] r_out,
    output logic [7:0] g_out,
    output logic [7:0] b_out


);

    localparam MODE_PASSTHROUGH = 3'b000;
    localparam MODE_INVERTER    = 3'b001;
    localparam MODE_BRIGHTEN    = 3'b010;
    localparam MODE_DARKEN      = 3'b011;
    localparam MODE_GRAYSCALE   = 3'b100;


  	logic [8:0] r_brighten, g_brighten, b_brighten;
    logic [8:0] r_darken, g_darken, b_darken;

    logic [9:0] gray;
    assign gray = ({2'b0, r_in} >> 2) + ({2'b0, r_in} >> 4) + 
                  ({2'b0, g_in} >> 1) + ({2'b0, g_in} >> 4) +
                  ({2'b0, b_in} >> 4); 


//    assign brighten_result = {2'b00, pixel_in} + {5'b0, threshold};
    assign r_brighten = {1'b0, r_in} + {4'b0, threshold_locked};
    assign g_brighten = {1'b0, g_in} + {4'b0, threshold_locked};
    assign b_brighten = {1'b0, b_in} + {4'b0, threshold_locked};


//    assign darken_result   = {2'b00, pixel_in} - {5'b0, threshold};
    assign r_darken = {1'b0, r_in} - {4'b0, threshold_locked};
    assign g_darken = {1'b0, g_in} - {4'b0, threshold_locked};
    assign b_darken = {1'b0, b_in} - {4'b0, threshold_locked};
    


    always_comb begin
        case (mode_locked)
            MODE_PASSTHROUGH: begin
                r_out = r_in;
                g_out = g_in;
                b_out = b_in;
            end

            MODE_INVERTER: begin
                r_out = 8'd255 - r_in;
                g_out = 8'd255 - g_in;
                b_out = 8'd255 - b_in;
            end

            MODE_BRIGHTEN: begin
                r_out = (r_brighten > 9'd255) ? 8'd255 : r_brighten[7:0];
                g_out = (g_brighten > 9'd255) ? 8'd255 : g_brighten[7:0];
                b_out = (b_brighten > 9'd255) ? 8'd255 : b_brighten[7:0];
            end

            MODE_DARKEN: begin
                r_out = (r_darken[8]) ? 8'd0 : r_darken[7:0];
                g_out = (g_darken[8]) ? 8'd0 : g_darken[7:0];
                b_out = (b_darken[8]) ? 8'd0 : b_darken[7:0];

            end

            MODE_GRAYSCALE: begin
                r_out = gray[7:0];
                g_out = gray[7:0];
                b_out = gray[7:0];
            end

            default: begin
                r_out = r_in;
                g_out = g_in;
                b_out = b_in;
            end
        endcase
    end

endmodule
