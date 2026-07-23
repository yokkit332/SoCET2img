// tb_baud_generator.sv
// unit TB - make sure baud_tick pulses every CLKS_PER_BIT clocks
// and sync_reset restarts the counter

`timescale 1ns / 1ps

module tb_baud_generator;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE; // 8
    localparam real CLK_PERIOD_NS = 1000.0; // 1 MHz

    logic clk, n_rst, sync_reset, baud_tick;
    int error_count;
    int tick_count;
    int gap;

    baud_generator #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .sync_reset(sync_reset),
        .baud_tick(baud_tick)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_baud_generator.vcd");
        $dumpvars(0, tb_baud_generator);
    end

    initial begin
        error_count = 0;
        tick_count = 0;
        n_rst = 0;
        sync_reset = 0;

        $display("=== tb_baud_generator: start ===");

        repeat (5) @(posedge clk);
        n_rst = 1;

        // wait for a few ticks and measure spacing
        gap = 0;
        while (tick_count < 3) begin
            @(posedge clk);
            gap++;
            if (baud_tick) begin
                if (gap != CLKS_PER_BIT) begin
                    $error("tick gap was %0d expected %0d", gap, CLKS_PER_BIT);
                    error_count++;
                end else
                    $display("PASS: tick #%0d after %0d clocks", tick_count, gap);
                tick_count++;
                gap = 0;
            end
        end

        // sync_reset should kill the count and restart
        @(posedge clk);
        sync_reset = 1;
        @(posedge clk);
        sync_reset = 0;
        if (baud_tick) begin
            $error("baud_tick high during sync_reset cycle");
            error_count++;
        end

        gap = 0;
        begin : wait_tick
            for (int k = 0; k < CLKS_PER_BIT + 5; k++) begin
                @(posedge clk);
                gap++;
                if (baud_tick)
                    disable wait_tick;
            end
        end
        if (!baud_tick) begin
            $error("no tick after sync_reset");
            error_count++;
        end else if (gap == CLKS_PER_BIT)
            $display("PASS: first tick %0d clocks after sync_reset", gap);
        else begin
            $error("after sync_reset gap=%0d expected %0d", gap, CLKS_PER_BIT);
            error_count++;
        end

        if (error_count == 0)
            $display("=== tb_baud_generator: PASS ===");
        else
            $fatal(1, "=== tb_baud_generator: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
