# Angry Bird — FPGA Hardware Game

A real-time, hardware-accelerated projectile game implemented entirely in Verilog on an
Artix-7 FPGA. No soft processor: game logic, collision detection, sprite rendering and
display timing are all synthesised RTL.

Final project for *Digital System Design and Implementation*, National Central University.

---

## Hardware

| | |
|---|---|
| Device | Xilinx Artix-7 **xc7a35t** |
| Toolchain | Vivado 2020.1 |
| Input clock | 100 MHz |
| Pixel clock | 25 MHz (MMCM, `dcm_25M`) |
| Display | VGA, 4-bit R/G/B (4096 colours) |
| Controls | PS/2 keyboard, 5 push-buttons, 2 slide switches |
| Status output | Dual 4-digit 7-segment displays, 16 LEDs |

Pin assignments are in [`constraints/constraint.xdc`](constraints/constraint.xdc).

## Display timing

The sync generator is written from scratch rather than using an IP core.

| Parameter | Horizontal | Vertical |
|---|---|---|
| Sync pulse end | 96 | 2 |
| Back porch end | 144 | 35 |
| Front porch start | 625 | 516 |
| Total | 640 | 525 |

The generator is clocked by the 25 MHz pixel clock produced by `dcm_25M`.

`dataValid` gates pixel output to the visible window, and `hDataCnt` / `vDataCnt` give
in-window pixel coordinates that the sprite logic uses for ROM address generation.

## Module overview

| Module | Lines | Role |
|---|---:|---|
| [`AngryBird.v`](rtl/AngryBird.v) | 670 | Top level: game FSM, trajectory and collision logic, sprite compositing, score/display drivers |
| [`SyncGeneration.v`](rtl/SyncGeneration.v) | 59 | VGA sync generator and visible-window pixel counters |
| [`KeyBoard.v`](rtl/KeyBoard.v) | 46 | PS/2 serial receiver and scancode decode |
| [`debounce.v`](rtl/debounce.v) | 14 | Push-button debouncer |
| [`LEDShine.v`](rtl/LEDShine.v) | 64 | LED status and animation driver |

## Sprite pipeline

Each sprite is a PNG converted to a `.coe` memory-initialisation file and loaded into a
Block Memory Generator ROM. `AngryBird.v` computes a read address per sprite from the
current pixel coordinate and composites the six ROM outputs into the 12-bit VGA bus with
priority-based overlap handling.

```
assets/sprites/*.png  ->  assets/coe/*.coe  ->  Block RAM ROM (ip/*_rom.xci)  ->  VGA
```

Six sprites: `Red`, `Chuck`, `Bomb`, `King_Pig`, `Minion_Pig`, `wood`.

## Repository layout

```
rtl/          Verilog sources
ip/           Vivado IP definitions (.xci) -- 7 sprite ROMs + the 25 MHz MMCM
assets/coe/   Memory-initialisation files consumed by the ROM IP
assets/sprites/  Source PNG artwork the .coe files were generated from
constraints/  Top-level pin constraints
```

Vivado build output (`*.cache/`, `*.runs/`, `*.sim/`, generated stubs and netlists) is
deliberately not tracked — it is regenerated from the `.xci` definitions on every build.

## Building

1. Create a new Vivado 2020.1 RTL project targeting `xc7a35t`.
2. Add `rtl/*.v` as design sources and `constraints/constraint.xdc` as a constraint file.
3. Add the IP in `ip/` (**Add Sources → Add existing IP**). Vivado regenerates the ROM
   and MMCM outputs; the `.coe` files in `assets/coe/` are referenced by the ROM IP, so
   keep the relative paths intact or re-point each ROM at its `.coe`.
4. Set `AngryBird` as the top module, then synthesise, implement and generate a bitstream.
5. Connect a VGA monitor and a PS/2 keyboard, and program the device.

## Authorship

All RTL in this repository was written by me — the top-level game FSM and
trajectory/collision logic in `AngryBird.v`, the VGA sync generator, the PS/2
receiver, the button debouncer and the LED driver, along with the sprite-ROM
address generation and compositing.

## Credits

- **Pei-yu Xie** — RTL design and implementation
- **Po-lin Chen** — project partner

Course project, National Central University — *Digital System Design and Implementation*.
