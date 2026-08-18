# =============================================================================
# AudioScopePin_assignments.tcl
# DE1-SoC Pin Assignment Script — FPGA Audio Scope Visualiser
# Author: Kennedy - 202002729
# Module: ELEC5566M Mini-Project
#
# LCD pin locations taken directly from the provided class script:
#   set_LCD_pin_locs.tcl (Unit 3.2 lab resource)
#
# All other board pins (clock, buttons, switches, LEDs, 7-seg) from:
#   Terasic DE1-SoC User Manual, Rev 1.0, Tables 3-1 to 3-13.
#
# HOW TO RUN:
#   Tools --> Tcl Scripts --> select this file --> Run
#   Then verify: Assignments --> Pin Planner
# =============================================================================

package require ::quartus::project

# =============================================================================
# SECTION 1 — CLOCK
# =============================================================================
set_location_assignment PIN_AF14 -to CLOCK_50

# =============================================================================
# SECTION 2 — PUSH BUTTONS (active LOW)
# KEY[0] = effect mode cycle
# KEY[3] = system reset (inverted in AudioScopeTop to produce globalReset)
# =============================================================================
set_location_assignment PIN_AA14 -to "KEY[0]"
set_location_assignment PIN_AA15 -to "KEY[1]"
set_location_assignment PIN_W15  -to "KEY[2]"
set_location_assignment PIN_Y16  -to "KEY[3]"

# =============================================================================
# SECTION 3 — SLIDE SWITCHES (active HIGH)
# SW[1:0]  -> wave_sel    (waveform type)
# SW[3:0]  -> freq_word   (frequency tuning)
# SW[5:4]  -> threshold   (distortion clip level)
# SW[7:6]  -> delay_sel   (echo depth)
# SW[8]    -> filter_sel  (FIR: 0=low-pass, 1=high-pass)
# =============================================================================
set_location_assignment PIN_AB12 -to "SW[0]"
set_location_assignment PIN_AC12 -to "SW[1]"
set_location_assignment PIN_AF9  -to "SW[2]"
set_location_assignment PIN_AF10 -to "SW[3]"
set_location_assignment PIN_AD11 -to "SW[4]"
set_location_assignment PIN_AD12 -to "SW[5]"
set_location_assignment PIN_AE11 -to "SW[6]"
set_location_assignment PIN_AC9  -to "SW[7]"
set_location_assignment PIN_AD10 -to "SW[8]"
set_location_assignment PIN_AE12 -to "SW[9]"

# =============================================================================
# SECTION 4 — RED LEDs (active HIGH)
# LEDR[1:0] = effect_sel binary
# LEDR[4]   = filter_sel
# LEDR[9:5] = mirror of SW[9:5]
# =============================================================================
set_location_assignment PIN_V16  -to "LEDR[0]"
set_location_assignment PIN_W16  -to "LEDR[1]"
set_location_assignment PIN_V17  -to "LEDR[2]"
set_location_assignment PIN_V18  -to "LEDR[3]"
set_location_assignment PIN_W17  -to "LEDR[4]"
set_location_assignment PIN_W19  -to "LEDR[5]"
set_location_assignment PIN_Y19  -to "LEDR[6]"
set_location_assignment PIN_W20  -to "LEDR[7]"
set_location_assignment PIN_W21  -to "LEDR[8]"
set_location_assignment PIN_Y21  -to "LEDR[9]"

# =============================================================================
# SECTION 5 — SEVEN-SEGMENT DISPLAYS (active LOW)
# HEX0 = effect mode: 0 / E / d / F
# HEX1 = always 'A' (active indicator)
# HEX2-HEX3 = freq_word nibbles
# =============================================================================

# HEX0
set_location_assignment PIN_AE26 -to "HEX0[0]"
set_location_assignment PIN_AE27 -to "HEX0[1]"
set_location_assignment PIN_AE28 -to "HEX0[2]"
set_location_assignment PIN_AG27 -to "HEX0[3]"
set_location_assignment PIN_AF28 -to "HEX0[4]"
set_location_assignment PIN_AG28 -to "HEX0[5]"
set_location_assignment PIN_AH28 -to "HEX0[6]"

# HEX1
set_location_assignment PIN_AJ29 -to "HEX1[0]"
set_location_assignment PIN_AH29 -to "HEX1[1]"
set_location_assignment PIN_AH30 -to "HEX1[2]"
set_location_assignment PIN_AG30 -to "HEX1[3]"
set_location_assignment PIN_AF29 -to "HEX1[4]"
set_location_assignment PIN_AF30 -to "HEX1[5]"
set_location_assignment PIN_AD27 -to "HEX1[6]"

#Previous wrong pins for HEX1
#set_location_assignment PIN_AD26 -to "HEX1[0]"
#set_location_assignment PIN_AD27 -to "HEX1[1]"
#set_location_assignment PIN_AB27 -to "HEX1[2]"
#set_location_assignment PIN_AB28 -to "HEX1[3]"
#set_location_assignment PIN_AB25 -to "HEX1[4]"
#set_location_assignment PIN_AA26 -to "HEX1[5]"
#set_location_assignment PIN_AA25 -to "HEX1[6]"

# HEX2
set_location_assignment PIN_AB23 -to "HEX2[0]"
set_location_assignment PIN_AE29 -to "HEX2[1]"
set_location_assignment PIN_AD29 -to "HEX2[2]"
set_location_assignment PIN_AC28 -to "HEX2[3]"
set_location_assignment PIN_AD30 -to "HEX2[4]"
set_location_assignment PIN_AC29 -to "HEX2[5]"
set_location_assignment PIN_AC30 -to "HEX2[6]"

# HEX3
set_location_assignment PIN_AC25  -to "HEX3[0]"
set_location_assignment PIN_AC27 -to "HEX3[1]"
set_location_assignment PIN_AD25 -to "HEX3[2]"
set_location_assignment PIN_AF15 -to "HEX3[3]"
set_location_assignment PIN_AG13 -to "HEX3[4]"
set_location_assignment PIN_AH14 -to "HEX3[5]"
set_location_assignment PIN_AF11 -to "HEX3[6]"

# =============================================================================
# SECTION 6 — LT24 LCD (via GPIO0 connector)
#
# Pin numbers taken DIRECTLY from the provided class script:
#   set_LCD_pin_locs.tcl (Unit 3.2 lab resource, do not change these)
#
# Port names on the LEFT match AudioScopeTop.v output port names.
# These map onto the LT24Display IP core signals via LT24Driver.v.
#
# LT24Display port  --> LT24Driver port --> AudioScopeTop port
# LT24Data[15:0]    --> LT24_D          --> LT24_D[15:0]
# LT24Reset_n       --> LT24_NRESET     --> LT24_NRESET
# LT24RS            --> LT24_DCX        --> LT24_DCX
# LT24CS_n          --> LT24_CSX        --> LT24_CSX
# LT24Rd_n          --> LT24_RDX        --> LT24_RDX
# LT24Wr_n          --> LT24_WRX        --> LT24_WRX
# LT24LCDOn         --> LT24_LCD_ON     --> LT24_LCD_ON
# =============================================================================

# 16-bit parallel data bus to ILI9341
set_location_assignment PIN_AJ17 -to "LT24_D[0]"
set_location_assignment PIN_AJ19 -to "LT24_D[1]"
set_location_assignment PIN_AK19 -to "LT24_D[2]"
set_location_assignment PIN_AK18 -to "LT24_D[3]"
set_location_assignment PIN_AE16 -to "LT24_D[4]"
set_location_assignment PIN_AF16 -to "LT24_D[5]"
set_location_assignment PIN_AG17 -to "LT24_D[6]"
set_location_assignment PIN_AA18 -to "LT24_D[7]"
set_location_assignment PIN_AA19 -to "LT24_D[8]"
set_location_assignment PIN_AE17 -to "LT24_D[9]"
set_location_assignment PIN_AC20 -to "LT24_D[10]"
set_location_assignment PIN_AH19 -to "LT24_D[11]"
set_location_assignment PIN_AJ20 -to "LT24_D[12]"
set_location_assignment PIN_AH20 -to "LT24_D[13]"
set_location_assignment PIN_AK21 -to "LT24_D[14]"
set_location_assignment PIN_AD19 -to "LT24_D[15]"

# LCD control signals (from class script)
#LT24_RDX require 3.3-v; not 2.5 latched by the fitter
set_location_assignment PIN_AG20 -to LT24_NRESET
set_location_assignment PIN_AG16 -to LT24_DCX
set_location_assignment PIN_AD20 -to LT24_CSX
set_location_assignment PIN_AH18 -to LT24_RDX
#set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LT24_RDX
set_location_assignment PIN_AH17 -to LT24_WRX
set_location_assignment PIN_AJ21 -to LT24_LCD_ON

# =============================================================================
# COMMIT ALL ASSIGNMENTS TO THE .QSF FILE
# =============================================================================
export_assignments

puts ""
puts "=============================================="
puts " pin_assignments.tcl completed successfully"
puts " LCD pins from: set_LCD_pin_locs.tcl (class)"
puts " Board pins from: DE1-SoC User Manual"
puts " Verify in: Assignments --> Pin Planner"
puts "=============================================="
puts ""
