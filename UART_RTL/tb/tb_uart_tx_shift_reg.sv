// tb_uart_tx_shift_reg.sv
// unit TB - load a byte then shift it out LSB first

`timescale 1ns / 1ps

module tb_uart_tx_shift_reg;

    localparam real CLK_PERIOD_NS = 10.0;

    logic clk, n_rst;
    logic [7:0] tx_data;
    logic load, baud_tick, shift_en;
    logic [7:0] shift_out;
    int error_count;

    uart_tx_shift_reg dut (
        .clk(clk),
        .n_rst(n_rst),
        .tx_data(tx_data),
        .load(load),
        .baud_tick(baud_tick),
        .shift_en(shift_en),
        .shift_out(shift_out)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_tx_shift_reg.vcd");
        $dumpvars(0, tb_uart_tx_shift_reg);
    end

    task automatic do_load(input logic [7:0] d);
        tx_data = d;
        @(posedge clk);
        load = 1;
        @(posedge clk);
        load = 0;
    endtask

    task automatic do_shift();
        @(posedge clk);
        shift_en = 1;
        @(posedge clk);
        shift_en = 0;
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        tx_data = 0;
        load = 0;
        baud_tick = 0;
        shift_en = 0;

        $display("=== tb_uart_tx_shift_reg: start ===");

        repeat (3) @(posedge clk);
        n_rst = 1;
        @(posedge clk);

        // load 0x96 = 1001_0110, LSB is 0
        do_load(8'h96);
        if (shift_out !== 8'h96) begin
            $error("after load expected 96 got %02h", shift_out);
            error_count++;
        end else if (shift_out[0] !== 1'b0) begin
            $error("LSB should be 0");
            error_count++;
        end else
            $display("PASS: loaded 96, LSB=0");

        // shift once -> was 10010110 >> 1 = 01001011, LSB now 1
        do_shift();
        if (shift_out !== 8'h4B) begin
            $error("after 1 shift expected 4B got %02h", shift_out);
            error_count++;
        end else
            $display("PASS: after shift LSB=%b reg=%02h", shift_out[0], shift_out);

        // shift again -> 00100101 = 0x25
        do_shift();
        if (shift_out !== 8'h25) begin
            $error("after 2 shifts expected 25 got %02h", shift_out);
            error_count++;
        end else
            $display("PASS: after 2 shifts got 25");

        if (error_count == 0)
            $display("=== tb_uart_tx_shift_reg: PASS ===");
        else
            $fatal(1, "=== tb_uart_tx_shift_reg: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
