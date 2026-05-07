# Nexys4 Memory Game — VHDL Final Project

**ECE 4250 — University of Missouri - Columbia**  
**Authors:** Chloe Imhoff, Michael Bolek, & Taqwa Siddiqui  
**Date:** May 5, 2026

A hardware implementation of a Simon-style memory game on the **Digilent Nexys4 DDR** FPGA board. The player watches a sequence of LEDs light up one at a time, then must reproduce that sequence using the slide switches. Each successful round adds a new step to the sequence. The game runs for up to 10 rounds, with the 7-segment display showing the current round number and a PASS, FAIL, or WIN message.

---

## File Overview

| File | Entity | Description |
|------|--------|-------------|
| `top_level.vhd` | `top_level` | Top-level wrapper; connects all components to board I/O |
| `memory_game_fsm.vhd` | `memory_game_fsm` | Main FSM controlling all game flow and state transitions |
| `lfsr_rng.vhd` | `lfsr_rng` | 8-bit Linear Feedback Shift Register for random sequence generation |
| `sequence_memory.vhd` | `sequence_memory` | Stores the current LED sequence and tracks its length |
| `seven_seg_controller.vhd` | `seven_seg_controller` | Drives the 8-digit 7-segment display with round info and messages |
| `switch_input.vhd` | `switch_input` | Debounced switch input handler for player guesses |
| `clock_divider.vhd` | `clock_divider` | Generates 1 Hz and 500 ms timing pulses from the 100 MHz board clock |
| `nexys4_memory_game.xdc` | — | Constraint file (pin assignments for the Nexys4 DDR) |

---

## How to Play

1. Press the **start button** to begin a new game.
2. Watch the **LEDs** — they will light up one at a time to show the sequence.
3. After the sequence plays, **flip the slide switches** one at a time to reproduce it in order.
   - Each switch corresponds to the LED directly above it.
   - Flip one switch at a time; the input is registered after the switch is held for **0.5 seconds**.
4. The **7-segment display** shows the current round number.
   - A **PASS** message flashes if you got the round correct.
   - A **FAIL** message (and your score) appears if you make a mistake — game over.
   - A **WIN** message appears if you complete all 10 rounds successfully.
5. Press **reset** at any time to return to the idle state.

---

## Game Rules & Behavior

- The game has **10 rounds**. Each round, one more LED step is added to the sequence.
- The sequence **caps at 8 digits** starting in round 5.
- LED flash timing starts at **1 second ON** with a **0.5 second gap** between flashes.
- Flash time decrements by 0.1 seconds each round, capping at **0.3 seconds ON** from round 8 onward.
- Completing all 10 rounds causes **all LEDs to flash** alongside the WIN message.
- Only **one switch at a time** is accepted as valid input. Multiple switches held simultaneously will trigger an invalid input flag.

---

## FSM States (`memory_game_fsm.vhd`)

| State | Description |
|-------|-------------|
| `IDLE` | Waits for the start button (rising edge). |
| `LOAD_SEED_STATE` | Latches the current LFSR value as the seed for this game. |
| `CLEAR_SEQ` | Clears the sequence memory before building a new sequence. |
| `BUILD_START_SEQ` | Adds 4 random steps to the sequence to begin the game. |
| `ADD_NEXT_STEP` | Appends one new random step at the start of each subsequent round. |
| `PREP_DISPLAY` | Resets display and input indices before showing the sequence. |
| `DISPLAY_ON` | Lights the current LED in the sequence for 1 tick (1 Hz). |
| `DISPLAY_OFF` | Blanks LEDs for 0.5 seconds between flashes. Advances to next step or player input. |
| `WAIT_PLAYER` | Waits for a valid switch input from the player. |
| `CHECK_INPUT` | Compares the player's selected switch to the expected sequence value. |
| `ROUND_PASS_WAIT` | 2-tick delay before flashing the PASS message. |
| `ROUND_PASS_FLASH` | Flashes PASS message 5 times, then advances to the next round. |
| `FAIL_STATE` | Displays FAIL message and flashes all LEDs. Game halts until reset. |
| `WIN_STATE` | Displays WIN message and flashes all LEDs. Game halts until reset. |

---

## Component Details

### `top_level.vhd`
The top-level wrapper instantiates and port-maps all other components. It handles the final LED output logic — during FAIL or WIN states, all 8 LEDs flash in sync with `tick_500ms` instead of showing the FSM-driven pattern.

**Board I/O:**
| Port | Direction | Description |
|------|-----------|-------------|
| `clk` | in | 100 MHz board clock |
| `reset` | in | Active-high reset |
| `start_button` | in | Start / restart the game |
| `switches[7:0]` | in | 8 slide switches for player input |
| `led[7:0]` | out | 8 LEDs for sequence display |
| `seg[6:0]` | out | 7-segment cathode signals |
| `an[7:0]` | out | 7-segment digit enable (active low) |

---

### `lfsr_rng.vhd`
An 8-bit LFSR with feedback taps on bits 7, 5, 4, and 3. It runs continuously on every clock edge and is seeded at game start to produce a different sequence each play. If a zero seed is provided, it defaults to `0x01` to avoid the all-zero lock-up state. The lower 3 bits of the output (`rand_val[2:0]`) are used to select one of the 8 LEDs (values 0–7).

---

### `sequence_memory.vhd`
A simple 8-element integer array (values 0–7) with synchronous write and combinational read. Supports:
- `clear` — resets all entries and the length counter to 0.
- `add` — appends `value_in` at the current end of the sequence (up to length 8).
- `read_index` — selects which entry to present on `value_out`.

---

### `switch_input.vhd`
A 3-state FSM (`WAIT_PRESS → CHECK_STABLE → WAIT_RELEASE`) that debounces the slide switches. An input is only accepted as valid after the switch has been held stable for `STABLE_COUNT` clock cycles (default: 50,000,000 = 0.5 sec at 100 MHz). Only exactly one switch may be active at a time; multiple switches held simultaneously set `invalid_input = '1'`.

---

### `seven_seg_controller.vhd`
Multiplexes all 8 digits of the 7-segment display using a 16-bit refresh counter (upper 3 bits select the active digit). Display priority:
1. **PASS** — shows `PASS` on digits 7–4.
2. **FAIL** — shows `FAIL` on digits 7–4, score on digits 1–0.
3. **WIN** — shows `WIN` on digits 7–5, score on digits 1–0.
4. **Default** — shows current round number on digits 1–0.

---

### `clock_divider.vhd`
Counts up from the 100 MHz board clock to produce two single-cycle strobes:
- `tick_1hz` — pulses high for one clock cycle every 1 second (100,000,000 count).
- `tick_500ms` — pulses high for one clock cycle every 0.5 seconds (50,000,000 count).

---

## Tools & Target Hardware

- **Target Board:** Digilent Nexys4 DDR (Artix-7 FPGA)
- **EDA Tool:** Xilinx Vivado
- **Language:** VHDL (IEEE 1164 / Numeric Standard)
- **Constraint File:** `nexys4_memory_game.xdc` (adapted from Lab 4)

---

## Known Limitations

- The sequence length caps at 8 even though 10 rounds are played — rounds 5–10 replay the same 8-step sequence at decreasing flash speeds.
- There is no timeout on player input; the game waits indefinitely for a switch to be flipped.
- Pressing start mid-game does not restart until reset is asserted first.
