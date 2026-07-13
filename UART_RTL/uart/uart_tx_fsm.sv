// uart_tx_fsm.sv
// UART transmitter finite-state machine.
// Bit timing uses baud_tick from baud_generator.

module uart_tx_fsm (
    input  logic       clk,
    input  logic       n_rst,
    input  logic       tx_valid,
    input  logic       baud_tick,
    output logic       load,
    output logic       shift_en,
    output logic       tx_ready,
    output logic [1:0] tx_state,
    output logic       baud_resync
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } tx_state_t;

    tx_state_t state;
    tx_state_t next_state;

    logic [3:0] bit_count;

    assign tx_state = state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            bit_count <= 4'd0;
        else if (state == DATA && shift_en)
            bit_count <= bit_count + 4'd1;
        else if (state == START && next_state == DATA)
            bit_count <= 4'd0;
    end

    always_comb begin
        next_state      = state;
        load            = 1'b0;
        shift_en        = 1'b0;
        tx_ready        = 1'b0;
        baud_resync     = 1'b0;

        case (state)
            IDLE: begin
                tx_ready = 1'b1;
                if (tx_valid) begin
                    next_state  = START;
                    baud_resync = 1'b1;
                end
            end

            START: begin
                if (baud_tick) begin
                    next_state = DATA;
                    load       = 1'b1;
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
                if (baud_tick)
                    next_state = IDLE;
            end
        endcase
    end

endmodule
