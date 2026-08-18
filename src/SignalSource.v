/*
 * SignalSource — DDS Waveform Generator
 * Author: Kennedy Chukwuma
 * ELEC5566M Mini-Project: Audio Scope Visualiser
 * Generates sine/square/triangle/sawtooth waveforms
 * using Direct Digital Synthesis and a look-up table
 */
 
 
 /*==================================================
  * Ports:
  *   clock      - in  - 50MHz system clock (20ns period)
  *   reset      - in  - asynchronous reset, active HIGH
  *   wave_sel   - in  - 00=sine 01=square 10=triangle 11=sawtooth
  *   freq_word  - in  - phase increment per clock cycle (tuning word)
  *   sample_out - out - 8-bit current amplitude (0=minimum 255=maximum)
  *
  * Parameters:
  *   PHASE_WIDTH  - accumulator width in bits (default 24) - controls freq resolution
  *   LUT_DEPTH    - number of waveform samples (default 256)
  *   SAMPLE_WIDTH - amplitude resolution in bits (default 8)
  */
  //===========================================================
  
  
module SignalSource #(
    parameter PHASE_WIDTH  = 24,   // 2^24 = 16,777,216 phase steps
    parameter LUT_DEPTH    = 256,  // 2^8  = 256 LUT entries
    parameter SAMPLE_WIDTH = 8     // 0 to 255 amplitude range
)(
    input                          clock,
    input                          reset,
    input  [1:0]                   wave_sel,
    input  [15:0]                  freq_word,
    output reg [SAMPLE_WIDTH-1:0]  sample_out
);

    // ── Phase accumulator ─────────────────────────────────────────
    // 24 flip-flops counting 0 to 16,777,215 then wrapping to 0
    // Adds freq_word every 20ns (every 50MHz clock cycle)
    reg [PHASE_WIDTH-1:0] phase_acc;

    always @(posedge clock or posedge reset) begin
        if (reset)
            phase_acc <= 0;                    // start from beginning of waveform
        else
            phase_acc <= phase_acc + freq_word; // advance by tuning word
    end                                         // auto-wraps at 2^24

    // ── LUT address extraction ─────────────────────────────────────
    // Only top 8 bits used — bottom 16 bits are "fractional phase"
    // providing fine frequency control
    localparam ADDR_MSB = PHASE_WIDTH - 1;                 // = 23
    localparam ADDR_LSB = PHASE_WIDTH - SAMPLE_WIDTH;      // = 16
    wire [SAMPLE_WIDTH-1:0] lut_addr = phase_acc[ADDR_MSB : ADDR_LSB];

    // ── Waveform look-up tables ────────────────────────────────────
    // Four separate ROMs, one per waveform type
    // Sawtooth and square computed by formula; sine loaded from MIF

    (* ram_init_file = "sine_lut.mif" *)
    reg [SAMPLE_WIDTH-1:0] sine_lut   [0:LUT_DEPTH-1];

    reg [SAMPLE_WIDTH-1:0] square_lut [0:LUT_DEPTH-1];
    reg [SAMPLE_WIDTH-1:0] tri_lut    [0:LUT_DEPTH-1];
    reg [SAMPLE_WIDTH-1:0] saw_lut    [0:LUT_DEPTH-1];

    integer k;
    initial begin
        for (k = 0; k < LUT_DEPTH; k = k + 1) begin
            saw_lut[k]    = k[SAMPLE_WIDTH-1:0];           // 0,1,2,...,255
            square_lut[k] = (k < LUT_DEPTH/2) ? {SAMPLE_WIDTH{1'b1}} : 0; // 255 or 0
            tri_lut[k]    = (k < LUT_DEPTH/2)             // rise then fall
                            ? (k << 1)                    // 0→254 rising
                            : ((LUT_DEPTH-1-k) << 1);     // 254→0 falling
        end
    end

    // ── Output multiplexer ─────────────────────────────────────────
    // Combinational: output = LUT[address] based on wave_sel
    // Default prevents latch inference
    always @* begin
        sample_out = {SAMPLE_WIDTH{1'b0}};   // default = 0 (prevents latch)
        case (wave_sel)
            2'b00: sample_out = sine_lut[lut_addr];
            2'b01: sample_out = square_lut[lut_addr];
            2'b10: sample_out = tri_lut[lut_addr];
            2'b11: sample_out = saw_lut[lut_addr];
        endcase
    end

endmodule
