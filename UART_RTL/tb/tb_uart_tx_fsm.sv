// tb_uart_tx_fsm.sv
// unit TB for TX FSM - walk through IDLE/START/DATA/STOP with fake baud ticks

`timescale 1ns / 1ps

module tb_uart_tx_fsm;

    localparam real CLK_PERIOD_NS = 10.0;

    logic clk, n_rst;
    logic tx_valid, baud_tick;
    logic load, shift_en, tx_ready, baud_resync;
    logic [1:0] tx_state;
    int error_count;

    uart_tx_fsm dut (
        .clk(clk),
        .n_rst(n_rst),
        .tx_valid(tx_valid),
        .baud_tick(baud_tick),
        .load(load),
        .shift_en(shift_en),
        .tx_ready(tx_ready),
        .tx_state(tx_state),
        .baud_resync(baud_resync)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_tx_fsm.vcd");
        $dumpvars(0, tb_uart_tx_fsm);
    end

    // drive on negedge so posedge sees stable inputs
    task automatic pulse_baud();
        @(negedge clk);
        baud_tick = 1;
        @(negedge clk);
        baud_tick = 0;
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        tx_valid = 0;
        baud_tick = 0;

        $display("=== tb_uart_tx_fsm: start ===");

        repeat (3) @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        repeat (2) @(posedge clk);

        if (!tx_ready || tx_state !== 2'b00) begin
            $error("should be IDLE/ready after reset");
            error_count++;
        end else
            $display("PASS: idle after reset");

        // kick off a byte
        @(negedge clk);
        tx_valid = 1;
        @(posedge clk); // leave IDLE
        @(negedge clk);
        tx_valid = 0;

        if (tx_state !== 2'b01) begin
            $error("expected START got %b", tx_state);
            error_count++;
        end else
            $display("PASS: entered START");

        // baud tick -> DATA
        pulse_baud();
        @(posedge clk);
        if (tx_state !== 2'b10) begin
            $error("expected DATA got %b", tx_state);
            error_count++;
        end else
            $display("PASS: entered DATA");

        // 8 data ticks -> STOP
        for (int i = 0; i < 8; i++)
            pulse_baud();
        @(posedge clk);

        if (tx_state !== 2'b11) begin
            $error("expected STOP after 8 data ticks, got %b", tx_state);
            error_count++;
        end else
            $display("PASS: entered STOP after data");

        pulse_baud();
        @(posedge clk);
        if (tx_state !== 2'b00 || !tx_ready) begin
            $error("expected back to IDLE");
            error_count++;
        end else
            $display("PASS: back to IDLE");

        if (error_count == 0)
            $display("=== tb_uart_tx_fsm: PASS ===");
        else
            $fatal(1, "=== tb_uart_tx_fsm: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
