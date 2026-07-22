# Interview Flashcards (Drill Sheet)

Print or quiz yourself. Cover the answer column.

## Architecture (30s / 60s)

**Q:** One-sentence project summary?  
**A:** Streaming 80×60 RGB UART image transformer with config UART, combinational accelerator, parallel R/G/B TX — VGA not implemented.

**Q:** External pins?  
**A:** `clk`, `n_rst`, `rx_r/g/b`, `rx_config`, `tx_r/g/b`.

**Q:** What does `output_ready` do today?  
**A:** AND of RGB ready in STREAM; acks all RX and launches all TX (does not check `tx_ready`).

## Numbers

**Q:** Bits per UART byte (8N1)?  
**A:** 10.

**Q:** Pixels/s at 115200 with 3 wires?  
**A:** 11520.

**Q:** Frames/s for 4800 pixels?  
**A:** ~2.4.

**Q:** CLKS_PER_BIT at 66 MHz / 115200?  
**A:** 572; ~+0.16% baud error.

**Q:** Brighten 250+10?  
**A:** Saturate to 255 (9-bit detect).

**Q:** Gray weights implemented?  
**A:** ~0.3125/0.5625/0.0625 (sum 0.9375).

## FSMs

**Q:** TX states?  
**A:** IDLE, START, DATA, STOP.

**Q:** RX states?  
**A:** IDLE, START, DATA, STOP, WAIT_READY.

**Q:** Controller states?  
**A:** INPUT_MODE, INPUT_THRESHOLD, STREAM.

**Q:** When is `tx_ready` high?  
**A:** Only in IDLE (per channel); top ANDs all three.

**Q:** When is `r_ready` high?  
**A:** WAIT_READY after good STOP until `output_ready`.

## Limitations → Fix

| Issue | Fix |
|-------|-----|
| Lost pixel if TX busy | Gate ack with `tx_ready` / FIFO |
| Frame count rollover | Increment+roll only on `output_ready` |
| Late TX load | Latch data on accept |
| Async sample early | First sample at 1.5 bit times |
| Config self-ack | Controller drives ack |
| No top TB / VGA | Add integration TB; VGA = future |

## Design-review one-liners

**G late?** Wait on AND of ready; no timeout.  
**Bad STOP?** That channel stays not-ready; silent drop.  
**False start?** Mid-START high → IDLE.  
**Why 2 flops?** Metastability on async RX.  
**Why 3 UARTs?** Throughput vs pins/duplication.  
**Why combo accelerator?** Zero latency vs timing risk.
