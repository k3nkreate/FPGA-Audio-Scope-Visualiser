// =================================================================
// SignalSource_tb — Self-Verifying Testbench
// Author: Kennedy Chukwuma — 202002729
// Module: ELEC5566M Mini-Project — Audio Scope Visualiser
//
// Tests the SignalSource DDS waveform generator module.
// All tests are self-checking: each prints PASS or FAIL.
// Final summary prints total PASS/FAIL count.
//
// DDS Architecture Reminder (for understanding test values):
//   phase_acc  = 24-bit accumulator, increments by freq_word each cycle
//   lut_addr   = phase_acc[23:16] — top 8 bits only (0-255)
//   freq_word  = 16-bit tuning word (max 65535)
//
//   To advance lut_addr by 1: phase_acc must increase by 2^16 = 65536
//   With freq_word = 1024: lut_addr advances by 1 every 64 cycles
//     because 64 * 1024 = 65536 = 2^16
//   This gives predictable, exact expected values for sawtooth.
//
// Test cases:
//   TC1: After reset, sawtooth output = 0 (phase_acc starts at 0)
//   TC2: Square wave at address 0 = 0xFF (first half = high)
//   TC3: Triangle wave at address 0 = 0 (triangle starts at 0)
//   TC4: Sawtooth frequency — verify lut_addr advances correctly
//        freq_word=1024 → lut_addr increments by 1 every 64 cycles
//        Check 5 steps: after 64, 128, 192, 256, 320 cycles
//   TC5: Mid-operation reset returns output to 0
//   TC6: Wave select switching — output changes on wave_sel change
// =================================================================

`timescale 1ns/100ps

module SignalSource_tb;

    // ── DUT signals ───────────────────────────────────────────────
	 //================================================================
    reg        clock;
    reg        reset;
    reg  [1:0] wave_sel;
    reg [15:0] freq_word;
    wire [7:0] sample_out;

    // ── Test tracking ─────────────────────────────────────────────
	 //===============================================================
    integer pass_count;
    integer fail_count;
    integer i;
    reg [7:0] prev_sample;

    initial pass_count = 0;
    initial fail_count = 0;

    // ── DUT instantiation ─────────────────────────────────────────
	 //===============================================================
    SignalSource #(
        .PHASE_WIDTH (24),
        .LUT_DEPTH   (256),
        .SAMPLE_WIDTH(8)
    ) dut (
        .clock     (clock     ),
        .reset     (reset     ),
        .wave_sel  (wave_sel  ),
        .freq_word (freq_word ),
        .sample_out(sample_out)
    );

    // ── Clock: 50MHz = 20ns period ────────────────────────────────
	 //===============================================================
    initial clock = 1'b0;
    always #10 clock = ~clock;

    // ── Helper task: check and report ────────────────────────────
	 //==============================================================
    task check;
        input [7:0]  actual;
        input [7:0]  expected;
        input [63:0] test_num;
        input [127:0] description;
        begin
            if (actual === expected) begin
                $display("PASS TC%0d: %s | got=%0d expected=%0d",
                         test_num, description, actual, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL TC%0d: %s | got=%0d expected=%0d",
                         test_num, description, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Main stimulus ─────────────────────────────────────────────
	 //===============================================================
    initial begin
        $display("=========================================");
        $display("  SignalSource Testbench — Kennedy 202002729");
        $display("=========================================");

        // Initialise all inputs
        reset     = 1'b1;
        wave_sel  = 2'b11;   // sawtooth for most tests
        freq_word = 16'd0;

        // Hold reset for 2 clock cycles
        repeat(2) @(posedge clock);
        reset = 1'b0;
        @(posedge clock); #1;

        // =============================================================
        // TC1: After reset — sawtooth output must be 0
        // phase_acc resets to 0 → lut_addr = 0 → saw_lut[0] = 0
        // =============================================================
        $display("--- TC1: Reset state ---");
        wave_sel  = 2'b11;   // sawtooth
        freq_word = 16'd0;   // freeze accumulator
        @(posedge clock); #1;
        check(sample_out, 8'd0, 1, "Reset: sawtooth LUT[0]=0");

        // =============================================================
        // TC2: Square wave — address 0 must be 0xFF (first half = 255)
        // =============================================================
        $display("--- TC2: Square wave at address 0 ---");
        wave_sel  = 2'b01;   // square
        freq_word = 16'd0;   // stay at address 0
        @(posedge clock); #1;
        check(sample_out, 8'hFF, 2, "Square wave LUT[0]=0xFF");

        // =============================================================
        // TC3: Triangle wave — address 0 must be 0
        // tri_lut[0] = (0 << 1) & 0xFF = 0
        // =============================================================
        $display("--- TC3: Triangle wave at address 0 ---");
        wave_sel  = 2'b10;   // triangle
        freq_word = 16'd0;   // stay at address 0
        @(posedge clock); #1;
        check(sample_out, 8'd0, 3, "Triangle wave LUT[0]=0");

        // =============================================================
        // TC4: Sawtooth frequency advancement
        //
        // freq_word = 1024 (fits comfortably in 16 bits)
        // phase_acc increases by 1024 every cycle.
        // lut_addr = phase_acc[23:16] advances by 1 every 64 cycles
        // because: 64 * 1024 = 65536 = 2^16 (one full step of top 8 bits)
        //
        // After reset: lut_addr = 0, sample_out = 0 (sawtooth)
        // After  64 cycles: lut_addr = 1, sample_out = 1
        // After 128 cycles: lut_addr = 2, sample_out = 2
        // After 192 cycles: lut_addr = 3, sample_out = 3
        // After 256 cycles: lut_addr = 4, sample_out = 4
        // After 320 cycles: lut_addr = 5, sample_out = 5
        // =============================================================
        $display("--- TC4: Sawtooth frequency advancement (freq_word=1024) ---");
        $display("    DDS maths: 64 cycles * 1024 = 65536 = 2^16 → lut_addr+1");

        // Fresh reset so phase_acc starts clean
        reset = 1'b1;
        @(posedge clock);
        reset = 1'b0;

        wave_sel  = 2'b11;      // sawtooth: sample_out = lut_addr exactly
        freq_word = 16'd1024;   // advances lut_addr by 1 every 64 cycles

        // Check 5 steps — run 64 cycles per step, verify expected value
        for (i = 1; i <= 5; i = i + 1) begin
            // Run exactly 64 cycles to advance lut_addr by 1
            repeat(64) @(posedge clock);
            #1;
            check(sample_out, i[7:0], 4,
                  "Sawtooth step: sample_out == step number");
        end

        // =============================================================
        // TC5: Mid-operation reset
        // Let accumulator advance several steps, then assert reset.
        // After reset, sample_out must return to 0 immediately.
        // =============================================================
        $display("--- TC5: Mid-operation reset ---");
        wave_sel  = 2'b11;    // sawtooth
        freq_word = 16'd1024;

        // Advance accumulator well past zero
        repeat(200) @(posedge clock);

        // Confirm it has advanced (sample should be non-zero)
        #1;
        if (sample_out != 8'd0)
            $display("INFO TC5: accumulator advanced to %0d before reset (expected)", sample_out);

        // Assert reset for one cycle
        reset = 1'b1;
        @(posedge clock);
        reset = 1'b0;
        @(posedge clock); #1;

        check(sample_out, 8'd0, 5, "Mid-op reset returns sample_out to 0");

        // =============================================================
        // TC6: Wave select switching
        // With accumulator frozen at 0, switching wave_sel should
        // produce different outputs:
        //   sawtooth  [0] = 0
        //   square    [0] = 255 (0xFF)
        //   triangle  [0] = 0
        //   sine      [0] = 128 (midpoint — x if MIF not loaded)
        // =============================================================
        $display("--- TC6: Wave select switching at address 0 ---");
        reset     = 1'b1;
        freq_word = 16'd0;   // freeze at address 0
        @(posedge clock);
        reset = 1'b0;
        @(posedge clock); #1;

        wave_sel = 2'b11; @(posedge clock); #1;
        check(sample_out, 8'd0,   6, "wave_sel=11 sawtooth  LUT[0]=0");

        wave_sel = 2'b01; @(posedge clock); #1;
        check(sample_out, 8'hFF,  6, "wave_sel=01 square    LUT[0]=0xFF");

        wave_sel = 2'b10; @(posedge clock); #1;
        check(sample_out, 8'd0,   6, "wave_sel=10 triangle  LUT[0]=0");

        // Sine: only check if not unknown (MIF may not be loaded in ModelSim)
        wave_sel = 2'b00; @(posedge clock); #1;
        if (^sample_out === 1'bx) begin
            $display("INFO TC6: wave_sel=00 sine LUT[0]=x (sine_lut.mif not loaded in simulator)");
            $display("          This is expected in simulation. Synthesis uses the MIF file.");
        end else begin
            check(sample_out, 8'd128, 6, "wave_sel=00 sine LUT[0]=128 (midpoint)");
        end

        // =============================================================
        // Final summary
        // =============================================================
        $display("=========================================");
        $display("  RESULTS: %0d PASS   %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  WARNING: %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $stop;
    end

endmodule
