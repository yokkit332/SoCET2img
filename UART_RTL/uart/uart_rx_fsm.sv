// uart_rx_fsm.sv
// UART receiver FSM for one byte. Asserts px_ready in WAIT_READY until
// pixel_controller acknowledges via output_ready.
//
// Async mode: per-channel baud_generator with resync on start detect.
// Shared-baud mode: sample using a clock counter aligned to the local TX
// byte FSM (loopback / same-clock-domain links).

module uart_rx_fsm #(
    parameter int CLOCK_FREQ    = 66_000_000,
    parameter int BAUD_RATE     = 115_200,
    parameter bit SHARED_BAUD   = 1'b0,
    localparam int CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE,
    localparam int HALF_CLKS    = CLKS_PER_BIT / 2,
    localparam int SHARED_FIRST = CLKS_PER_BIT + HALF_CLKS
) (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       serial_rx,
    input  logic       baud_tick,
    input  logic       output_ready,
    output logic       shift_en,
    output logic       px_ready,
    output logic       baud_sync_reset
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP,
        WAIT_READY
    } rx_state_t;

    rx_state_t state;
    rx_state_t next_state;

    logic [3:0]  bit_count;
    logic [15:0] clk_counter;
    logic        shared_sample;

    assign shared_sample = (state == DATA)
                        && (clk_counter == SHARED_FIRST + bit_count * CLKS_PER_BIT)
                        && (bit_count < 4'd8);

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

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

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            clk_counter <= 16'd0;
        else if (state != START && next_state == START)
            clk_counter <= 16'd0;
        else if (state == START || state == DATA || state == STOP)
            clk_counter <= clk_counter + 16'd1;
    end

    always_comb begin
        next_state      = state;
        shift_en        = 1'b0;
        px_ready        = 1'b0;
        baud_sync_reset = 1'b0;

        case (state)
            IDLE: begin
                if (serial_rx == 1'b0) begin
                    next_state = START;
                    if (!SHARED_BAUD)
                        baud_sync_reset = 1'b1;
                end
            end

            START: begin
                if (SHARED_BAUD) begin
                    if (clk_counter == HALF_CLKS && serial_rx == 1'b1)
                        next_state = IDLE;
                    else if (clk_counter == SHARED_FIRST - 1)
                        next_state = DATA;
                end else begin
                    if (clk_counter == HALF_CLKS && serial_rx == 1'b1)
                        next_state = IDLE;
                    else if (baud_tick) begin
                        shift_en   = 1'b1;
                        next_state = DATA;
                    end
                end
            end

            DATA: begin
                if (SHARED_BAUD) begin
                    if (shared_sample) begin
                        shift_en = 1'b1;
                        if (bit_count == 4'd7)
                            next_state = STOP;
                    end
                end else if (baud_tick) begin
                    shift_en = 1'b1;
                    if (bit_count == 4'd7)
                        next_state = STOP;
                end
            end

            STOP: begin
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
                px_ready = 1'b1;
                if (output_ready)
                    next_state = IDLE;
            end
        endcase
    end

endmodule
