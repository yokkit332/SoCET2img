// uart_tx_fsm.sv
// TX FSM - IDLE/START/DATA/STOP
// uses baud_tick to know when to move to the next bit

module uart_tx_fsm (
    input  logic clk,
    input  logic n_rst,
    input  logic tx_valid,   // start a new byte
    input  logic baud_tick,
    output logic load,       // load shift reg
    output logic shift_en,
    output logic tx_ready,   // high when we can take another byte
    output logic [1:0] tx_state,
    output logic baud_resync
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
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

    // count how many data bits we've shifted out
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            bit_count <= 4'd0;
        else if (state == DATA && shift_en)
            bit_count <= bit_count + 4'd1;
        else if (state == START && next_state == DATA)
            bit_count <= 4'd0;
    end

    always_comb begin
        next_state = state;
        load = 1'b0;
        shift_en = 1'b0;
        tx_ready = 1'b0;
        baud_resync = 1'b0;

        case (state)
            IDLE: begin
                tx_ready = 1'b1;
                if (tx_valid) begin
                    next_state = START;
                    baud_resync = 1'b1; // align baud counter to this frame
                end
            end

            START: begin
                // after start bit time, load data and go
                if (baud_tick) begin
                    next_state = DATA;
                    load = 1'b1;
                end
            end

            DATA: begin
                if (baud_tick) begin
                    shift_en = 1'b1;
                    if (bit_count == 4'd7)
                        next_state = STOP; // sent all 8
                end
            end

            STOP: begin
                if (baud_tick)
                    next_state = IDLE;
            end
        endcase
    end

endmodule
