`timescale 1ns/1ps
module top_tb;
    logic clk, n_rst;
    logic tb_r_ready, tb_g_ready, tb_b_ready;
    logic tb_config_ready;
    logic [7:0] tb_config_byte;
    logic [2:0] tb_mode_locked;
    logic [4:0]  tb_threshold_locked;
    logic tb_output_ready;

    // assume 66 Mhz clock
    always #10 clk = ~clk;


    pixel_controller DUT(
        .clk(clk), .n_rst(n_rst),
        .r_ready(tb_r_ready), .g_ready(tb_g_ready), .b_ready(tb_b_ready),
        .config_ready(tb_config_ready),
        .config_byte(tb_config_byte),
        .mode_locked(tb_mode_locked), .threshold_locked(tb_threshold_locked),
        .output_ready(tb_output_ready)
    );


    task reset();
    begin
        $display("\nRESETTING VALUES...\n");
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        n_rst = 1;
    end
    endtask

    // task for just driving config signals, called by set_mode and set_threshold
    task send_config(input logic [7:0] config_byte);
    begin
        @(posedge clk);
        #1;
        tb_config_ready = 1;
        tb_config_byte = config_byte;
        @(posedge clk);
        #1;
        tb_config_ready = 0;
        @(posedge clk);

    end
    endtask
    task set_mode(input logic [2:0] mode_byte);
    begin
        $display("\n===SETTING MODE===");
        send_config({4'b0, mode_byte});

        // check mode was latched correctly
        if (tb_mode_locked !== mode_byte[2:0]) begin
            $error("FAILED TO SET MODE: expected mode_locked=%0d, got %0d", mode_byte[2:0], tb_mode_locked);
        end
        else begin
            $display("SUCCESSFULLY SET MODE: mode_locked correctly latched to %0d", tb_mode_locked);
        end

    end
    endtask

    task set_threshold(input logic [4:0] threshold_byte);
    begin
        
        $display("\n===SETTING THRESHOLD===");
        send_config({2'b0, threshold_byte});
        if(tb_threshold_locked !== threshold_byte[4:0]) begin
            $error("FAILED TO SET THRESHOLD: expected mode_locked=%0d, got %0d", threshold_byte[4:0], tb_threshold_locked);
        
        end else begin
            $display("SUCCESSFULLY SET THRESHOLD: threshold_locked correctly latched to %0d", tb_threshold_locked);
        end 
    end
    endtask

    task test_output_ready();
    begin
        $display("\n\n===TEST OUTPUT READY BEHAVIOR===");
        @(posedge clk);

        // assert all readys
        tb_r_ready = 1;
        tb_g_ready = 1;
        tb_b_ready = 1;
        @(posedge clk);
        if(tb_output_ready !== 1)
            $error("FAILED! OUTPUT_READY SHOULD BE 1");
        else
            $display("SUCCESS! OUTPUT_READY IS 1 WHEN ALL 3 READY SIGNALS ARE 1");
        
        // drop one of the ready signals low
        tb_r_ready = 0;
        @(posedge clk);
        if(tb_output_ready !== 1'b0)
            $error("FAILED: output_ready should drop when r_ready goes low");
        else
            $display("PASSED: output_ready goes low when r_ready goes low");
        
        tb_r_ready = 0;
        tb_g_ready = 0;
        tb_b_ready = 0;
        $display("===OUTPUT_READY TEST COMPLETE===");
    end
    endtask

    // task that mimics uart sending a pixel
    task send_pixel();
    begin
        tb_r_ready = 1;
        tb_g_ready = 1;
        tb_b_ready = 1;
        @(posedge clk);
        tb_r_ready = 0;
        tb_g_ready = 0;
        tb_b_ready = 0;
        repeat(3) @(posedge clk);
    end
    endtask
    task test_rollover();
    begin
        $display("\n\n===TEST STREAMING PIXELS AND ROLLOVER===");
        set_mode(3'd2);
        set_threshold(5'd5);

        // send first 2399 pixels to the controller
        repeat(2399) begin
            send_pixel();
        end    

        $display("\n===ACTUALLY TESTING STREAMING AND ROLLOVERS NOW===");
        // test that we are still in stream mode
        tb_r_ready = 1;
        tb_g_ready = 1;
        tb_b_ready = 1;
        @(posedge clk);
        if(tb_output_ready === 1'b1) begin
            $display("SUCCESS: STILL IN STREAM MODE AFTER 2400 PIXELS");
        end
        else begin
            $error("FAILED: SHOULD BE IN STREAM MODE AFTER 2400 PIXELS");
        end
        tb_r_ready = 0;
        tb_g_ready = 0;
        tb_b_ready = 0;

        // send last 2400 pixels to controller to test rollover
        repeat(2400) begin
            send_pixel();
        end

        // now verify return to INPUT_MODE by checking output_ready when all individual readys are high 
        tb_r_ready = 1; tb_g_ready = 1; tb_b_ready = 1;
        @(posedge clk);
        if (tb_output_ready !== 1'b0)
            $error("FAILED: should be in INPUT_MODE after 4800 pixels");
        else
            $display("PASSED: correctly returned to INPUT_MODE after 4800 pixels");
        tb_r_ready = 0; tb_g_ready = 0; tb_b_ready = 0;

    end
    endtask

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, pixel_controller_tb);
        clk = 0;
        n_rst = 1;  // inactive (active low)
        tb_r_ready = 0;
        tb_g_ready = 0;
        tb_b_ready = 0;
        tb_config_ready = 0;
        tb_config_byte = '0;

        reset();

        // test mode and threshold
        set_mode(3'b001);
        set_threshold(7'd16);

        // test output_ready in STREAM
        test_output_ready();

        // test rollover
        reset();
        test_rollover();

    end
endmodule


