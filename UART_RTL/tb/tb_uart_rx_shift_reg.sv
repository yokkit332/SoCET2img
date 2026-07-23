// tb_uart_rx_shift_reg.sv
// unit TB - shift in 8 bits LSB first and check the assembled byte

`timescale 1ns / 1ps

module tb_uart_rx_shift_reg;

    localparam real CLK_PERIOD_NS = 10.0;

    logic clk, n_rst;
    logic serial_rx;
    logic baud_tick; // unused by DUT but on the port
    logic shift_en;
    logic [7:0] rx_data;
    int error_count;

    uart_rx_shift_reg dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx),
        .baud_tick(baud_tick),
        .shift_en(shift_en),
        .rx_data(rx_data)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rx_shift_reg.vcd");
        $dumpvars(0, tb_uart_rx_shift_reg);
    end

    // pulse shift_en one cycle with the bit on serial_rx
    task automatic shift_bit(input logic b);
        serial_rx = b;
        @(posedge clk);
        shift_en = 1;
        @(posedge clk);
        shift_en = 0;
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        serial_rx = 1;
        baud_tick = 0;
        shift_en = 0;

        $display("=== tb_uart_rx_shift_reg: start ===");

        repeat (3) @(posedge clk);
        n_rst = 1;
        @(posedge clk);

        if (rx_data !== 8'h00) begin
            $error("after reset expected 00 got %02h", rx_data);
            error_count++;
        end else
            $display("PASS: reset clears reg");

        // shift in 0xA5 = 1010_0101 LSB first -> 1,0,1,0,0,1,0,1
        shift_bit(1);
        shift_bit(0);
        shift_bit(1);
        shift_bit(0);
        shift_bit(0);
        shift_bit(1);
        shift_bit(0);
        shift_bit(1);

        if (rx_data !== 8'hA5) begin
            $error("expected A5 got %02h", rx_data);
            error_count++;
        end else
            $display("PASS: assembled A5");

        // another byte: 0x3C
        shift_bit(0);
        shift_bit(0);
        shift_bit(1);
        shift_bit(1);
        shift_bit(1);
        shift_bit(1);
        shift_bit(0);
        shift_bit(0);

        if (rx_data !== 8'h3C) begin
            $error("expected 3C got %02h", rx_data);
            error_count++;
        end else
            $display("PASS: assembled 3C");

        if (error_count == 0)
            $display("=== tb_uart_rx_shift_reg: PASS ===");
        else
            $fatal(1, "=== tb_uart_rx_shift_reg: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
