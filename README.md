# Nexys4 Memory Game — ECE 4250 Final Project

**Chloe Imhoff, Michael Bolek, & Taqwa Siddiqui — University of Missouri-Columbia**

This is our ECE 4250 final project, a Simon-style memory game implemented in VHDL on the Nexys4 FPGA board. The board shows a sequence of LEDs one at a time, and the player has to repeat it back using the slide switches. Each round adds one more step to the sequence, and the game runs for 10 rounds total.

---

## Files

| File | Description |
|------|-------------|
| `top_level.vhd` | Top-level wrapper that connects everything together |
| `memory_game_fsm.vhd` | The main FSM — handles all game logic and state transitions |
| `lfsr_rng.vhd` | 8-bit LFSR used to randomly generate the sequence |
| `sequence_memory.vhd` | Stores the current sequence and tracks its length |
| `seven_seg_controller.vhd` | Drives the 7-segment display (round number, PASS/FAIL/WIN) |
| `switch_input.vhd` | Reads and debounces player input from the slide switches |
| `clock_divider.vhd` | Generates 1 Hz and 500 ms timing pulses from the 100 MHz clock |
| `nexys4_memory_game.xdc` | Constraint file for pin assignments (borrowed from Lab 4) |

---

## How to Play

1. Press the **start button** to begin.
2. Watch the **LEDs** they flash one at a time showing the sequence.
3. Flip the **slide switches** one at a time to repeat the sequence back. Each switch lines up directly with the LED above it. Hold a switch for 0.5 seconds to register your input.
4. The **7-segment display** shows your current round number. After each round it'll flash **PASS**, **FAIL**, or **WIN** depending on how you did.
5. Hit **reset** at any time to start over.

A few things to know:
- Only flip **one switch at a time** multiple switches at once counts as an invalid input.
- The sequence starts at 4 steps and grows by 1 each round, capping at 8 steps in round 5.
- LED flash speed starts at 1 second and gets faster each round, down to 0.3 seconds by round 8.
- Finishing all 10 rounds makes all the LEDs flash with a WIN message.

---

## How It Works

The core of the project is `memory_game_fsm.vhd`, which drives everything. When you hit start, it seeds the LFSR and builds an initial 4-step sequence, then cycles through displaying it on the LEDs and waiting for your input. If you get a round right it flashes PASS and adds another step; if you're wrong it goes to a FAIL state and waits for a reset.

The LFSR (`lfsr_rng.vhd`) runs continuously on every clock edge so the sequence is different each game. The switch input handler (`switch_input.vhd`) was one of the trickier parts — we went through a few iterations figuring out how to make it feel natural to use. We settled on a 3-state debounce FSM that waits for a switch to be stable for half a second before registering it, then waits for the player to release it before accepting the next input.

The 7-segment display multiplexes all 8 digits using a refresh counter, and shows either the round number during gameplay or a PASS/FAIL/WIN message at the end of each round.

---

## Tools & Hardware

- **Board:** Digilent Nexys4 DDR (Artix-7)
- **Tool:** Xilinx Vivado
- **Language:** VHDL
