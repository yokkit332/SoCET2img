module uart_stream_decoder #(
    parameter int NUM_PIXELS = 4800
) (
    input  logic       clk,
    input  logic       n_rst,

    input  logic [7:0] rx_data,
    input  logic       rx_ready,
    output logic       rx_ack,

    output logic [2:0] mode,
    output logic [4:0] threshold,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue,
    output logic       pixel_valid,
    input  logic       pixel_ready,

    output logic       frame_start,
    output logic       frame_done
);

    localparam logic [7:0] CMD_MODE      = 8'hA0;
    localparam logic [7:0] CMD_THRESHOLD = 8'hA1;
    localparam logic [7:0] CMD_FRAME     = 8'hA2;

    typedef enum logic [2:0] {
        WAIT_COMMAND,
        READ_MODE,
        READ_THRESHOLD,
        READ_RED,
        READ_GREEN,
        READ_BLUE,
        HOLD_PIXEL
    } state_t;

    state_t state, next_state;

    logic [2:0] mode_r, mode_next;
    logic [4:0] threshold_r, threshold_next;
    logic [7:0] red_r, green_r, blue_r;
    logic [7:0] red_next, green_next, blue_next;

    logic [$clog2(NUM_PIXELS+1)-1:0] pixel_count, pixel_count_next;

    logic frame_start_next;
    logic frame_done_next;
    logic rx_ack_c;
    logic take_byte;

    assign mode      = mode_r;
    assign threshold = threshold_r;
    assign red       = red_r;
    assign green     = green_r;
    assign blue      = blue_r;
    assign pixel_valid = (state == HOLD_PIXEL);
    assign rx_ack      = rx_ack_c;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= WAIT_COMMAND;
        else
            state <= next_state;
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            mode_r       <= '0;
            threshold_r  <= '0;
            red_r        <= '0;
            green_r      <= '0;
            blue_r       <= '0;
            pixel_count  <= '0;
            frame_start  <= 1'b0;
            frame_done   <= 1'b0;
        end else begin
            mode_r       <= mode_next;
            threshold_r  <= threshold_next;
            red_r        <= red_next;
            green_r      <= green_next;
            blue_r       <= blue_next;
            pixel_count  <= pixel_count_next;
            frame_start  <= frame_start_next;
            frame_done   <= frame_done_next;
        end
    end

    always_comb begin
        next_state        = state;
        mode_next         = mode_r;
        threshold_next    = threshold_r;
        red_next          = red_r;
        green_next        = green_r;
        blue_next         = blue_r;
        pixel_count_next  = pixel_count;
        frame_start_next  = 1'b0;
        frame_done_next   = 1'b0;
        rx_ack_c          = 1'b0;
        take_byte         = 1'b0;

        case (state)
            WAIT_COMMAND,
            READ_MODE,
            READ_THRESHOLD,
            READ_RED,
            READ_GREEN,
            READ_BLUE: take_byte = rx_ready;
            default:   take_byte = 1'b0;
        endcase

        if (take_byte)
            rx_ack_c = 1'b1;

        case (state)
            WAIT_COMMAND: begin
                if (take_byte) begin
                    if (rx_data == CMD_MODE)
                        next_state = READ_MODE;
                    else if (rx_data == CMD_THRESHOLD)
                        next_state = READ_THRESHOLD;
                    else if (rx_data == CMD_FRAME) begin
                        pixel_count_next = '0;
                        frame_start_next = 1'b1;
                        next_state = READ_RED;
                    end
                end
            end

            READ_MODE: begin
                if (take_byte) begin
                    mode_next  = rx_data[2:0];
                    next_state = WAIT_COMMAND;
                end
            end

            READ_THRESHOLD: begin
                if (take_byte) begin
                    threshold_next = rx_data[4:0];
                    next_state     = WAIT_COMMAND;
                end
            end

            READ_RED: begin
                if (take_byte) begin
                    red_next   = rx_data;
                    next_state = READ_GREEN;
                end
            end

            READ_GREEN: begin
                if (take_byte) begin
                    green_next = rx_data;
                    next_state = READ_BLUE;
                end
            end

            READ_BLUE: begin
                if (take_byte) begin
                    blue_next  = rx_data;
                    next_state = HOLD_PIXEL;
                end
            end

            HOLD_PIXEL: begin
                if (pixel_ready) begin
                    if (pixel_count == NUM_PIXELS - 1) begin
                        pixel_count_next = '0;
                        frame_done_next  = 1'b1;
                        next_state       = WAIT_COMMAND;
                    end else begin
                        pixel_count_next = pixel_count + 1'b1;
                        next_state       = READ_RED;
                    end
                end
            end

            default: next_state = WAIT_COMMAND;
        endcase
    end

endmodule
