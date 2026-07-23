# UART testbench helpers (Icarus + GTKWave)
#
# From UART_RTL/tb/:
#   make all    - run every TB
#   make tops   - just the top-level ones (tx/rx/config/loopback)
#   make units  - just the unit TBs
#
# Examples: make baud, make rx_fsm, make tx_byte, ...

IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

RTL_DIR  = ../uart
SV_FLAGS = -g2012

# all RTL (some unit TBs only need a subset but this is simple)
RTL_SRCS = $(RTL_DIR)/baud_generator.sv \
           $(RTL_DIR)/uart_tx_fsm.sv \
           $(RTL_DIR)/uart_tx_shift_reg.sv \
           $(RTL_DIR)/uart_tx_byte.sv \
           $(RTL_DIR)/uart_tx_top.sv \
           $(RTL_DIR)/uart_rx_sync.sv \
           $(RTL_DIR)/uart_rx_fsm.sv \
           $(RTL_DIR)/uart_rx_shift_reg.sv \
           $(RTL_DIR)/uart_rx_byte.sv \
           $(RTL_DIR)/uart_rx_top.sv \
           $(RTL_DIR)/uart_rx_config.sv

.PHONY: all tops units clean \
        tx rx config loopback \
        baud rx_sync rx_shift tx_shift rx_fsm tx_fsm rx_byte tx_byte

all: units tops

tops: tx rx config loopback

units: baud rx_sync rx_shift tx_shift tx_fsm rx_fsm tx_byte rx_byte

# ----- top level -----
tx: sim_tx
	$(VVP) sim_tx
rx: sim_rx
	$(VVP) sim_rx
config: sim_config
	$(VVP) sim_config
loopback: sim_loop
	$(VVP) sim_loop

sim_tx: tb_uart_tx.sv $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_tx $(RTL_SRCS) tb_uart_tx.sv
sim_rx: tb_uart_rx.sv $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_rx $(RTL_SRCS) tb_uart_rx.sv
sim_config: tb_uart_rx_config.sv $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_config $(RTL_SRCS) tb_uart_rx_config.sv
sim_loop: tb_uart_loopback.sv $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_loop $(RTL_SRCS) tb_uart_loopback.sv

# ----- unit -----
baud: sim_baud
	$(VVP) sim_baud
rx_sync: sim_rx_sync
	$(VVP) sim_rx_sync
rx_shift: sim_rx_shift
	$(VVP) sim_rx_shift
tx_shift: sim_tx_shift
	$(VVP) sim_tx_shift
tx_fsm: sim_tx_fsm
	$(VVP) sim_tx_fsm
rx_fsm: sim_rx_fsm
	$(VVP) sim_rx_fsm
tx_byte: sim_tx_byte
	$(VVP) sim_tx_byte
rx_byte: sim_rx_byte
	$(VVP) sim_rx_byte

sim_baud: tb_baud_generator.sv $(RTL_DIR)/baud_generator.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_baud $(RTL_DIR)/baud_generator.sv tb_baud_generator.sv

sim_rx_sync: tb_uart_rx_sync.sv $(RTL_DIR)/uart_rx_sync.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_rx_sync $(RTL_DIR)/uart_rx_sync.sv tb_uart_rx_sync.sv

sim_rx_shift: tb_uart_rx_shift_reg.sv $(RTL_DIR)/uart_rx_shift_reg.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_rx_shift $(RTL_DIR)/uart_rx_shift_reg.sv tb_uart_rx_shift_reg.sv

sim_tx_shift: tb_uart_tx_shift_reg.sv $(RTL_DIR)/uart_tx_shift_reg.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_tx_shift $(RTL_DIR)/uart_tx_shift_reg.sv tb_uart_tx_shift_reg.sv

sim_tx_fsm: tb_uart_tx_fsm.sv $(RTL_DIR)/uart_tx_fsm.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_tx_fsm $(RTL_DIR)/uart_tx_fsm.sv tb_uart_tx_fsm.sv

sim_rx_fsm: tb_uart_rx_fsm.sv $(RTL_DIR)/uart_rx_fsm.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_rx_fsm $(RTL_DIR)/uart_rx_fsm.sv tb_uart_rx_fsm.sv

sim_tx_byte: tb_uart_tx_byte.sv $(RTL_DIR)/baud_generator.sv $(RTL_DIR)/uart_tx_fsm.sv \
             $(RTL_DIR)/uart_tx_shift_reg.sv $(RTL_DIR)/uart_tx_byte.sv
	$(IVERILOG) $(SV_FLAGS) -o sim_tx_byte \
	  $(RTL_DIR)/baud_generator.sv $(RTL_DIR)/uart_tx_fsm.sv \
	  $(RTL_DIR)/uart_tx_shift_reg.sv $(RTL_DIR)/uart_tx_byte.sv \
	  tb_uart_tx_byte.sv

sim_rx_byte: tb_uart_rx_byte.sv $(RTL_SRCS)
	$(IVERILOG) $(SV_FLAGS) -o sim_rx_byte $(RTL_SRCS) tb_uart_rx_byte.sv

clean:
	rm -f sim_tx sim_rx sim_config sim_loop \
	      sim_baud sim_rx_sync sim_rx_shift sim_tx_shift \
	      sim_tx_fsm sim_rx_fsm sim_tx_byte sim_rx_byte \
	      *.vcd
