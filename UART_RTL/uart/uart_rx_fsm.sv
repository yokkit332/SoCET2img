// uart_rx_fsm.sv
// RX state machine for one UART byte
// goes IDLE -> START -> DATA -> STOP -> WAIT_READY then back
//
// if SHARED_BAUD=0 we use the baud_tick from our own baud gen
// if SHARED_BAUD=1 we just count clocks (for loopback w/ TX)

module uart_rx_fsm #(
    parameter int CLOCK_FREQ  = 66_000_000,
    parameter int BAUD_RATE   = 115_200,
    parameter bit SHARED_BAUD = 1'b0,
    localparam int CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE,
    localparam int HALF_CLKS    = CLKS_PER_BIT / 2,
    // first data sample is 1.5 bit periods after start edge
    localparam int SHARED_FIRST = CLKS_PER_BIT + HALF_CLKS
) (
    input  logic clk,
    input  logic n_rst,
    input  logic serial_rx,
    input  logic baud_tick,
    input  logic output_ready, // ack from pixel_controller / host
    output logic shift_en,
    output logic px_ready,
    output logic baud_sync_reset
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP,
        WAIT_READY
    } rx_state_t;

    rx_state_t state, next_state;

    logic [3:0] bit_count;
    logic [15:0] clk_counter;
    logic shared_sample;

    // when to sample in shared-baud mode
    assign shared_sample = (state == DATA)
                        && (clk_counter == SHARED_FIRST + bit_count * CLKS_PER_BIT)
                        && (bit_count < 4'd8);

    // state reg
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // which data bit we're on
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            bit_count <= 4'd0;
        else if (state != START && next_state == START)
            bit_count <= 4'd0;
        else if (shift_en)
            bit_count <= bit_count + 4'd1;
        else if (SHARED_BAUD && state == START && next_state == DATA)
            bit_count <= 4'd0;
    end

    // free running counter while we're in a frame (shared baud path)
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            clk_counter <= 16'd0;
        else if (state != START && next_state == START)
            clk_counter <= 16'd0;
        else if (state == START || state == DATA || state == STOP)
            clk_counter <= clk_counter + 16'd1;
    end

    always_comb begin
        next_state = state;
        shift_en = 1'b0;
        px_ready = 1'b0;
        baud_sync_reset = 1'b0;

        case (state)
            IDLE: begin
                // look for falling edge = start bit
                if (serial_rx == 1'b0) begin
                    next_state = START;
                    if (!SHARED_BAUD)
                        baud_sync_reset = 1'b1; // kick baud gen
                end
            end

            START: begin
                if (SHARED_BAUD) begin
                    // check mid-start that it's still low (reject glitches)
                    if (clk_counter == HALF_CLKS && serial_rx == 1'b1)
                        next_state = IDLE;
                    else if (clk_counter == SHARED_FIRST - 1)
                        next_state = DATA;
                end else begin
                    if (clk_counter == HALF_CLKS && serial_rx == 1'b1)
                        next_state = IDLE; // false start
                    else if (baud_tick) begin
                        // sample first data bit on this tick
                        shift_en = 1'b1;
                        next_state = DATA;
                    end
                end
            end

            DATA: begin
                if (SHARED_BAUD) begin
                    if (shared_sample) begin
                        shift_en = 1'b1;
                        if (bit_count == 4'd7)
                            next_state = STOP; // just got bit 7
                    end
                end else if (baud_tick) begin
                    shift_en = 1'b1;
                    if (bit_count == 4'd7)
                        next_state = STOP;
                end
            end

            STOP: begin
                // stop bit should be high, otherwise framing error -> dump it
                if (SHARED_BAUD) begin
                    if (clk_counter >= SHARED_FIRST + 8 * CLKS_PER_BIT) begin
                        if (serial_rx == 1'b1)
                            next_state = WAIT_READY;
                        else
                            next_state = IDLE;
                    end
                end else if (baud_tick) begin
                    if (serial_rx == 1'b1)
                        next_state = WAIT_READY;
                    else
                        next_state = IDLE;
                end
            end

            WAIT_READY: begin
                // hold the byte until something acks us
                px_ready = 1'b1;
                if (output_ready)
                    next_state = IDLE;
            end
        endcase
    end

endmodule
