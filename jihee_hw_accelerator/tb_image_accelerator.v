`timescale 1ns / 1ps

module tb_image_accelerator;

    reg        clk;
    reg        rst_n;
    reg  [7:0] pixel_in;
    reg        pixel_in_valid;
    reg  [1:0] mode;
    reg  [4:0] threshold;
    wire [7:0] pixel_out;
    wire       pixel_out_valid;

    image_accelerator dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .pixel_in        (pixel_in),
        .pixel_in_valid  (pixel_in_valid),
        .mode            (mode),
        .threshold       (threshold),
        .pixel_out       (pixel_out),
        .pixel_out_valid (pixel_out_valid)
    );

    initial clk = 0;
    always #7.5 clk = ~clk;

    initial begin
        rst_n = 0; pixel_in = 0; pixel_in_valid = 0;
        mode = 0; threshold = 0;
        #30; rst_n = 1; #15;

        $display("=== Test 1: Pass-through ===");
        mode = 2'b00; threshold = 5'd0;
        pixel_in = 8'd100; pixel_in_valid = 1; #15;
        $display("IN:%0d OUT:%0d EXP:100 %s", pixel_in, pixel_out, (pixel_out==100)?"PASS":"FAIL");
        pixel_in = 8'd200; #15;
        $display("IN:%0d OUT:%0d EXP:200 %s", pixel_in, pixel_out, (pixel_out==200)?"PASS":"FAIL");
        pixel_in_valid = 0; #15;

        $display("=== Test 2: Inverter ===");
        mode = 2'b01;
        pixel_in = 8'd0;   pixel_in_valid = 1; #15;
        $display("IN:%0d OUT:%0d EXP:255 %s", pixel_in, pixel_out, (pixel_out==255)?"PASS":"FAIL");
        pixel_in = 8'd255; #15;
        $display("IN:%0d OUT:%0d EXP:0 %s", pixel_in, pixel_out, (pixel_out==0)?"PASS":"FAIL");
        pixel_in = 8'd100; #15;
        $display("IN:%0d OUT:%0d EXP:155 %s", pixel_in, pixel_out, (pixel_out==155)?"PASS":"FAIL");
        pixel_in_valid = 0; #15;

        $display("=== Test 3: Brighten (threshold=31) ===");
        mode = 2'b10; threshold = 5'd31;
        pixel_in = 8'd100; pixel_in_valid = 1; #15;
        $display("IN:%0d OUT:%0d EXP:131 %s", pixel_in, pixel_out, (pixel_out==131)?"PASS":"FAIL");
        pixel_in = 8'd240; #15;
        $display("IN:%0d OUT:%0d EXP:255 %s", pixel_in, pixel_out, (pixel_out==255)?"PASS":"FAIL");
        pixel_in_valid = 0; #15;

        $display("=== Test 4: Darken (threshold=31) ===");
        mode = 2'b11; threshold = 5'd31;
        pixel_in = 8'd100; pixel_in_valid = 1; #15;
        $display("IN:%0d OUT:%0d EXP:69 %s", pixel_in, pixel_out, (pixel_out==69)?"PASS":"FAIL");
        pixel_in = 8'd20; #15;
        $display("IN:%0d OUT:%0d EXP:0 %s", pixel_in, pixel_out, (pixel_out==0)?"PASS":"FAIL");
        pixel_in_valid = 0; #15;

        $display("=== All tests done ===");
        $finish;
    end

endmodule
