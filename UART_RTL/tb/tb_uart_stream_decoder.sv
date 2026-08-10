// tb_uart_stream_decoder.sv
// Self-checking TB for uart_stream_decoder (no UART PHY, just byte interface)

`timescale 1ns / 1ps

module tb_uart_stream_decoder;

    localparam int NUM_PIXELS = 2; // keep the TB short
    localparam real CLK_PERIOD_NS = 10.0;

    logic       clk;
    logic       n_rst;
    logic [7:0] rx_data;
    logic       rx_ready;
    logic       rx_ack;
    logic [2:0] mode;
    logic [4:0] threshold;
    logic [7:0] red, green, blue;
    logic       pixel_valid;
    logic       pixel_ready;
    logic       frame_start;
    logic       frame_done;

    int error_count;
    int ack_seen;

    uart_stream_decoder #(
        .NUM_PIXELS(NUM_PIXELS)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_ack(rx_ack),
        .mode(mode),
        .threshold(threshold),
        .red(red),
        .green(green),
        .blue(blue),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .frame_start(frame_start),
        .frame_done(frame_done)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_stream_decoder.vcd");
        $dumpvars(0, tb_uart_stream_decoder);
    end

    // count ack pulses in background while sending
    always @(posedge clk) begin
        if (rx_ack)
            ack_seen++;
    end

    // present one byte the way uart_rx_byte does: hold until ack
    task automatic send_byte(input logic [7:0] b);
        @(negedge clk);
        rx_data  = b;
        rx_ready = 1'b1;
        // wait until decoder consumes it
        while (!rx_ack) @(posedge clk);
        @(negedge clk);
        rx_ready = 1'b0;
        @(posedge clk);
    endtask

    task automatic expect_eq_byte(input string tag, input logic [7:0] got, input logic [7:0] exp);
        if (got !== exp) begin
            $error("%s: got %02h expected %02h", tag, got, exp);
            error_count++;
        end else
            $display("PASS: %s = %02h", tag, got);
    endtask

    initial begin
        error_count = 0;
        ack_seen    = 0;
        n_rst       = 0;
        rx_data     = 0;
        rx_ready    = 0;
        pixel_ready = 0;

        $display("=== tb_uart_stream_decoder: start ===");

        repeat (4) @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        repeat (2) @(posedge clk);

        // A0 + mode 3
        send_byte(8'hA0);
        send_byte(8'h03);
        if (mode !== 3'h3) begin
            $error("mode got %0d expected 3", mode);
            error_count++;
        end else
            $display("PASS: mode = 3");

        // A1 + threshold 17
        send_byte(8'hA1);
        send_byte(8'h11); // 17
        if (threshold !== 5'd17) begin
            $error("threshold got %0d expected 17", threshold);
            error_count++;
        end else
            $display("PASS: threshold = 17");

        // A2 -> frame_start
        begin
            logic saw_start;
            saw_start = 1'b0;
            fork
                begin : watch_start
                    forever begin
                        @(posedge clk);
                        if (frame_start)
                            saw_start = 1'b1;
                    end
                end
                begin
                    send_byte(8'hA2);
                    repeat (4) @(posedge clk);
                    disable watch_start;
                end
            join
            if (!saw_start) begin
                $error("frame_start not seen on A2");
                error_count++;
            end else
                $display("PASS: frame_start pulsed");
        end

        // pixel 12 34 56
        send_byte(8'h12);
        send_byte(8'h34);
        send_byte(8'h56);

        if (!pixel_valid) begin
            $error("pixel_valid not high after RGB");
            error_count++;
        end
        expect_eq_byte("red",   red,   8'h12);
        expect_eq_byte("green", green, 8'h34);
        expect_eq_byte("blue",  blue,  8'h56);

        // hold pixel_ready low: RGB must stay stable
        pixel_ready = 0;
        repeat (10) @(posedge clk);
        if (!pixel_valid || red !== 8'h12 || green !== 8'h34 || blue !== 8'h56) begin
            $error("RGB/valid not held while pixel_ready low");
            error_count++;
        end else
            $display("PASS: RGB held while waiting");

        // accept pixel 0
        @(negedge clk);
        pixel_ready = 1;
        @(posedge clk);
        @(negedge clk);
        pixel_ready = 0;
        @(posedge clk);

        if (pixel_valid) begin
            $error("pixel_valid should clear after accept");
            error_count++;
        end else
            $display("PASS: pixel accepted");

        // after frame start, A0/A1/A2 are just colors
        send_byte(8'hA0);
        send_byte(8'hA1);
        send_byte(8'hA2);

        if (!pixel_valid) begin
            $error("pixel_valid missing for A0/A1/A2 color pixel");
            error_count++;
        end
        expect_eq_byte("red(A0)",   red,   8'hA0);
        expect_eq_byte("green(A1)", green, 8'hA1);
        expect_eq_byte("blue(A2)",  blue,  8'hA2);

        // accept last pixel -> frame_done (NUM_PIXELS=2)
        begin
            logic saw_done;
            saw_done = 1'b0;
            fork
                begin : watch_done
                    forever begin
                        @(posedge clk);
                        if (frame_done)
                            saw_done = 1'b1;
                    end
                end
                begin
                    @(negedge clk);
                    pixel_ready = 1'b1;
                    @(posedge clk);
                    @(negedge clk);
                    pixel_ready = 1'b0;
                    repeat (4) @(posedge clk);
                    disable watch_done;
                end
            join
            if (!saw_done) begin
                $error("frame_done not seen after final pixel");
                error_count++;
            end else
                $display("PASS: frame_done pulsed");
        end

        if (ack_seen < 10) begin
            $error("expected multiple rx_ack pulses, got %0d", ack_seen);
            error_count++;
        end else
            $display("PASS: rx_ack seen (%0d pulses)", ack_seen);

        if (error_count == 0)
            $display("=== tb_uart_stream_decoder: PASS ===");
        else
            $fatal(1, "=== tb_uart_stream_decoder: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
