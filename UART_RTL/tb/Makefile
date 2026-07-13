# UART testbench simulation helpers (Icarus Verilog + GTKWave)
#
# Usage (from UART_RTL/tb/):
#   make tx       -> run TX testbench, open waveform
#   make rx       -> run RX testbench
#   make loopback -> run TX->RX loopback testbench
#
# Requirements: iverilog, vvp, gtkwave (optional target)

IVERILOG  = iverilog
VVP       = vvp
GTKWAVE   = gtkwave

RTL_DIR   = ../uart
SV_FLAGS  = -g2012

RTL_SRCS  = $(RTL_DIR)/baud_generator.sv \
            $(RTL_DIR)/uart_tx_fsm.sv \
            $(RTL_DIR)/uart_tx_shift_reg.sv \
            $(RTL_DIR)/uart_tx_byte.sv \
            $(RTL_DIR)/uart_tx_top.sv \
            $(RTL_DIR)/uart_rx_sync.sv \
            $(RTL_DIR)/uart_rx_fsm.sv \
            $(RTL_DIR)/uart_rx_shift_reg.sv \
            $(RTL_DIR)/uart_rx_byte.sv \
            $(RTL_DIR)/uart_rx_top.sv

TX_TB     = tb_uart_tx.sv
RX_TB     = tb_uart_rx.sv
LOOP_TB   = tb_uart_loopback.sv

.PHONY: all tx rx loopback clean wave_tx wave_rx wave_loop

all: tx

tx: sim_tx
	$(VVP) sim_tx

rx: sim_rx
	$(VVP) sim_rx

loopback: sim_loop
	$(VVP) sim_loop

sim_tx: $(TX_TB) $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_tx $(RTL_SRCS) $(TX_TB)

sim_rx: $(RX_TB) $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_rx $(RTL_SRCS) $(RX_TB)

sim_loop: $(LOOP_TB) $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_loop $(RTL_SRCS) $(LOOP_TB)

wave_tx: tx
	$(GTKWAVE) tb_uart_tx.vcd

wave_rx: rx
	$(GTKWAVE) tb_uart_rx.vcd

wave_loop: loopback
	$(GTKWAVE) tb_uart_loopback.vcd

clean:
	rm -f sim_tx sim_rx sim_loop *.vcd
