module uart_rgb_serializer #(
    parameter int CLOCK_FREQ = 66_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic       clk,
    input  logic       n_rst,

    input  logic [7:0] red_in,
    input  logic [7:0] green_in,
    input  logic [7:0] blue_in,
    input  logic       pixel_valid,
    output logic       pixel_ready,

    output logic       serial_tx,
    output logic       busy,
    output logic       pixel_done
);

    typedef enum logic [3:0] {
        IDLE,
        START_R,
        WAIT_R_BUSY,
        WAIT_R_DONE,
        START_G,
        WAIT_G_BUSY,
        WAIT_G_DONE,
        START_B,
        WAIT_B_BUSY,
        WAIT_B_DONE
    } state_t;

    state_t state, next_state;

    logic [7:0] red_hold, green_hold, blue_hold;
    logic [7:0] red_hold_next, green_hold_next, blue_hold_next;
    logic [7:0] tx_byte;

    logic baud_tick;
    logic baud_resync;
    logic tx_ready;
    logic output_ready;
    logic pixel_ready_c;
    logic pixel_done_c;
    logic busy_c;

    assign pixel_ready = pixel_ready_c;
    assign pixel_done  = pixel_done_c;
    assign busy        = busy_c;

    baud_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud (
        .clk(clk),
        .n_rst(n_rst),
        .sync_reset(baud_resync),
        .baud_tick(baud_tick)
    );

    uart_tx_byte #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_tx (
        .clk(clk),
        .n_rst(n_rst),
        .baud_tick(baud_tick),
        .px_in(tx_byte),
        .output_ready(output_ready),
        .serial_tx(serial_tx),
        .tx_ready(tx_ready),
        .baud_resync(baud_resync)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            red_hold   <= '0;
            green_hold <= '0;
            blue_hold  <= '0;
        end else begin
            red_hold   <= red_hold_next;
            green_hold <= green_hold_next;
            blue_hold  <= blue_hold_next;
        end
    end

    always_comb begin
        case (state)
            START_R, WAIT_R_BUSY, WAIT_R_DONE: tx_byte = red_hold;
            START_G, WAIT_G_BUSY, WAIT_G_DONE: tx_byte = green_hold;
            START_B, WAIT_B_BUSY, WAIT_B_DONE: tx_byte = blue_hold;
            default:                           tx_byte = red_hold;
        endcase
    end

    always_comb begin
        next_state      = state;
        red_hold_next   = red_hold;
        green_hold_next = green_hold;
        blue_hold_next  = blue_hold;
        output_ready    = 1'b0;
        pixel_ready_c   = 1'b0;
        pixel_done_c    = 1'b0;
        busy_c          = 1'b1;

        case (state)
            IDLE: begin
                busy_c = 1'b0;
                if (pixel_valid) begin
                    red_hold_next   = red_in;
                    green_hold_next = green_in;
                    blue_hold_next  = blue_in;
                    pixel_ready_c   = 1'b1;
                    next_state      = START_R;
                end
            end

            START_R: begin
                if (tx_ready) begin
                    output_ready = 1'b1;
                    next_state   = WAIT_R_BUSY;
                end
            end

            WAIT_R_BUSY: begin
                if (!tx_ready)
                    next_state = WAIT_R_DONE;
            end

            WAIT_R_DONE: begin
                if (tx_ready)
                    next_state = START_G;
            end

            START_G: begin
                if (tx_ready) begin
                    output_ready = 1'b1;
                    next_state   = WAIT_G_BUSY;
                end
            end

            WAIT_G_BUSY: begin
                if (!tx_ready)
                    next_state = WAIT_G_DONE;
            end

            WAIT_G_DONE: begin
                if (tx_ready)
                    next_state = START_B;
            end

            START_B: begin
                if (tx_ready) begin
                    output_ready = 1'b1;
                    next_state   = WAIT_B_BUSY;
                end
            end

            WAIT_B_BUSY: begin
                if (!tx_ready)
                    next_state = WAIT_B_DONE;
            end

            WAIT_B_DONE: begin
                if (tx_ready) begin
                    pixel_done_c = 1'b1;
                    next_state   = IDLE;
                end
            end

            default: begin
                busy_c     = 1'b0;
                next_state = IDLE;
            end
        endcase
    end

endmodule
