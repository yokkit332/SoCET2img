// uart_rx_fsm.sv
// UART receiver FSM for one byte. Asserts px_ready in WAIT_READY until
// pixel_controller acknowledges via output_ready.

module uart_rx_fsm #(
    parameter int CLOCK_FREQ = 12_000_000,
    parameter int BAUD_RATE  = 115_200,
    localparam int CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE,
    localparam int HALF_CLKS    = CLKS_PER_BIT / 2
) (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       serial_rx,
    input  logic       baud_tick,
    input  logic       output_ready,
    output logic       shift_en,
    output logic       px_ready,
    output logic       baud_sync_reset  // Pulse when start bit detected (IDLE -> START)
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

    logic [3:0] bit_count;
    logic [$clog2(HALF_CLKS + 1)-1:0] half_counter;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            bit_count    <= 4'd0;
            half_counter <= '0;
        end else begin
            if (state == START && next_state == DATA)
                bit_count <= 4'd0;
            else if (state == DATA && baud_tick)
                bit_count <= bit_count + 4'd1;

            if (state != START && next_state == START)
                half_counter <= '0;
            else if (state == START)
                half_counter <= half_counter + 1'b1;
        end
    end

    always_comb begin
        next_state      = state;
        shift_en        = 1'b0;
        px_ready        = 1'b0;
        baud_sync_reset = 1'b0;

        case (state)
            IDLE: begin
                if (serial_rx == 1'b0) begin
                    next_state      = START;
                    baud_sync_reset = 1'b1;
                end
            end

            START: begin
                if (half_counter >= HALF_CLKS) begin
                    if (serial_rx == 1'b0)
                        next_state = DATA;
                    else
                        next_state = IDLE;
                end
            end

            DATA: begin
                if (baud_tick) begin
                    shift_en = 1'b1;
                    if (bit_count == 4'd7)
                        next_state = STOP;
                end
            end

            STOP: begin
                if (baud_tick) begin
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
