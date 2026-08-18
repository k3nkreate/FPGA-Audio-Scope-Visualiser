# AudioScopeTop.sdc — Timing Constraints File
# Author: Kennedy - 202002729
# Module: ELEC5566M Mini-Project — Audio Scope Visualiser
#
# Purpose:
#   Tells Quartus TimeQuest Timing Analyser the operating frequency
#   of the system clock so it can verify timing closure.
#   Without this file, Quartus cannot guarantee that all flip-flop
#   setup and hold times are met at 50MHz.
#
# How to use:
#   1. In Quartus: Assignments → Settings → TimeQuest Timing Analyser
#   2. Add this file under "SDC Files"
#   3. Run Fitter then TimeQuest to verify timing

# ── Primary 50MHz clock constraint ──────────────────────────────────
# create_clock: defines a clock signal at a specific pin
# -period 20.000: one clock cycle = 20 nanoseconds = 50MHz
# [get_ports CLOCK_50]: applied to the CLOCK_50 port of AudioScopeTop
create_clock -name "CLOCK_50" -period 20.000ns [get_ports {CLOCK_50}]

# ── Input delay constraints ──────────────────────────────────────────
# These tell the timing analyser how long inputs take to settle
# after the clock edge. Values based on DE1-SoC board trace lengths.
set_input_delay -clock "CLOCK_50" -max 3.0 [get_ports {SW[*]}]
set_input_delay -clock "CLOCK_50" -max 3.0 [get_ports {KEY[*]}]
set_input_delay -clock "CLOCK_50" -min 0.5 [get_ports {SW[*]}]
set_input_delay -clock "CLOCK_50" -min 0.5 [get_ports {KEY[*]}]

# ── Output delay constraints ─────────────────────────────────────────
# Tell TimeQuest when outputs must be stable before the next clock edge.
set_output_delay -clock "CLOCK_50" -max 3.0 [get_ports {LEDR[*]}]
set_output_delay -clock "CLOCK_50" -max 3.0 [get_ports {HEX0[*]}]
set_output_delay -clock "CLOCK_50" -max 3.0 [get_ports {HEX1[*]}]
set_output_delay -clock "CLOCK_50" -max 3.0 [get_ports {HEX2[*]}]
set_output_delay -clock "CLOCK_50" -max 3.0 [get_ports {HEX3[*]}]

# ── Derived clock for LT24 SPI ───────────────────────────────────────
# The LT24 IP core divides CLOCK_50 by 2 for SPI clock.
# This tells TimeQuest about the derived clock relationship.
create_generated_clock -name "SPI_CLK" \
    -source [get_ports {CLOCK_50}]     \
    -divide_by 2                       \
    [get_registers {u_lt24_driver|lt24_ip|*}]
