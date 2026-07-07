`timescale 1ns / 1ps
module tb_pixel_accelerator;

    reg  [7:0] r_in, g_in, b_in;
    reg  [2:0] mode_locked;
    reg  [4:0] threshold_locked;
    wire [7:0] r_out, g_out, b_out;

    pixel_accelerator dut (
        .r_in             (r_in),
        .g_in             (g_in),
        .b_in             (b_in),
        .mode_locked      (mode_locked),
        .threshold_locked (threshold_locked),
        .r_out            (r_out),
        .g_out            (g_out),
        .b_out            (b_out)
    );

    initial begin
        // ------------------------------------------------
        // Test 1: Pass-through (mode 000)
        // ------------------------------------------------
        $display("=== Test 1: Pass-through ===");
        mode_locked = 3'b000; threshold_locked = 5'd0;
        r_in = 8'd100; g_in = 8'd150; b_in = 8'd200; #10;
        $display("R IN:%0d OUT:%0d EXP:100 %s", r_in, r_out, (r_out==100)?"PASS":"FAIL");
        $display("G IN:%0d OUT:%0d EXP:150 %s", g_in, g_out, (g_out==150)?"PASS":"FAIL");
        $display("B IN:%0d OUT:%0d EXP:200 %s", b_in, b_out, (b_out==200)?"PASS":"FAIL");

        // ------------------------------------------------
        // Test 2: Inverter (mode 001)
        // ------------------------------------------------
        $display("=== Test 2: Inverter ===");
        mode_locked = 3'b001; threshold_locked = 5'd0;
        r_in = 8'd0; g_in = 8'd128; b_in = 8'd255; #10;
        $display("R IN:%0d OUT:%0d EXP:255 %s", r_in, r_out, (r_out==255)?"PASS":"FAIL");
        $display("G IN:%0d OUT:%0d EXP:127 %s", g_in, g_out, (g_out==127)?"PASS":"FAIL");
        $display("B IN:%0d OUT:%0d EXP:0   %s", b_in, b_out, (b_out==0)?"PASS":"FAIL");

        // ------------------------------------------------
        // Test 3: Brighten (mode 010, threshold=30)
        // ------------------------------------------------
        $display("=== Test 3: Brighten (threshold=30) ===");
        mode_locked = 3'b010; threshold_locked = 5'd30;
        r_in = 8'd100; g_in = 8'd200; b_in = 8'd240; #10;
        $display("R IN:%0d OUT:%0d EXP:130 %s", r_in, r_out, (r_out==130)?"PASS":"FAIL");
        $display("G IN:%0d OUT:%0d EXP:230 %s", g_in, g_out, (g_out==230)?"PASS":"FAIL");
        $display("B IN:%0d OUT:%0d EXP:255 %s", b_in, b_out, (b_out==255)?"PASS":"FAIL");

        // ------------------------------------------------
        // Test 4: Darken (mode 011, threshold=30)
        // ------------------------------------------------
        $display("=== Test 4: Darken (threshold=30) ===");
        mode_locked = 3'b011; threshold_locked = 5'd30;
        r_in = 8'd100; g_in = 8'd20; b_in = 8'd200; #10;
        $display("R IN:%0d OUT:%0d EXP:70  %s", r_in, r_out, (r_out==70)?"PASS":"FAIL");
        $display("G IN:%0d OUT:%0d EXP:0   %s", g_in, g_out, (g_out==0)?"PASS":"FAIL");
        $display("B IN:%0d OUT:%0d EXP:170 %s", b_in, b_out, (b_out==170)?"PASS":"FAIL");

        // ------------------------------------------------
        // Test 5: Grayscale (mode 100)
        // Gray ≈ 0.299*R + 0.587*G + 0.114*B
        // R=100, G=150, B=200 → approx gray = 141
        // ------------------------------------------------
        $display("=== Test 5: Grayscale ===");
        mode_locked = 3'b100; threshold_locked = 5'd0;
        r_in = 8'd100; g_in = 8'd150; b_in = 8'd200; #10;
        $display("R IN:%0d OUT:%0d (R=G=B expected) %s", r_in, r_out, (r_out==g_out && g_out==b_out)?"PASS":"FAIL");
        $display("Gray value: %0d", r_out);

        // Pure red → gray
        r_in = 8'd255; g_in = 8'd0; b_in = 8'd0; #10;
        $display("Pure RED: R=%0d G=%0d B=%0d Gray=%0d %s", r_in, g_in, b_in, r_out, (r_out==g_out && g_out==b_out)?"PASS":"FAIL");

        // Pure green → gray
        r_in = 8'd0; g_in = 8'd255; b_in = 8'd0; #10;
        $display("Pure GREEN: R=%0d G=%0d B=%0d Gray=%0d %s", r_in, g_in, b_in, r_out, (r_out==g_out && g_out==b_out)?"PASS":"FAIL");

        // Pure blue → gray
        r_in = 8'd0; g_in = 8'd0; b_in = 8'd255; #10;
        $display("Pure BLUE: R=%0d G=%0d B=%0d Gray=%0d %s", r_in, g_in, b_in, r_out, (r_out==g_out && g_out==b_out)?"PASS":"FAIL");

        $display("=== All tests done ===");
        $finish;
    end

endmodule
