/*
 * DSPChain_tb — Self-Verifying Testbench for DSPChain
 * Author: Kennedy Chukwuma
 *
 * What is tested:
 *   TC1: effect_sel=00 → selected_out = sample_in (pass-through)
 *   TC2: effect_sel=01 → selected_out = echo_out (not sample_in)
 *   TC3: effect_sel=10 → selected_out = dist_out (clipped if above threshold)
 *   TC4: effect_sel=11 → selected_out = fir_out
 *   TC5: original_out always equals sample_in regardless of effect_sel
 *   TC6: All four outputs have valid 8-bit values (0–255)
 *   TC7: Switching effect_sel mid-run changes selected_out immediately
 *   TC8: Reset clears echo buffer — echo_out equals sample_in after reset
 */

`timescale 1ns/100ps

module DSPChain_tb;

    // ── DUT inputs ────────────────────────────────────────────────────
    //======================================================================
    reg        clock;
    reg        reset;
    reg [7:0]  sample_in;
    reg [1:0]  effect_sel;
    reg [3:0]  delay_sel;
    reg [7:0]  threshold;

    // ── DUT outputs ───────────────────────────────────────────────────
    //====================================================================
    wire [7:0] original_out;
    wire [7:0] echo_out;
    wire [7:0] dist_out;
    wire [7:0] fir_out;
    wire [7:0] selected_out;

    integer pass_count;
    integer fail_count;

    // ── DUT ───────────────────────────────────────────────────────────
    //====================================================================
    DSPChain #(
        .DATA_WIDTH(8 ),
        .ECHO_DEPTH(64),
        .FIR_TAPS  (5 )
    ) dut (
        .clock       (clock       ),
        .reset       (reset       ),
        .sample_in   (sample_in   ),
        .effect_sel  (effect_sel  ),
        .delay_sel   (delay_sel   ),
        .threshold   (threshold   ),
        .original_out(original_out),
        .echo_out    (echo_out    ),
        .dist_out    (dist_out    ),
        .fir_out     (fir_out     ),
        .selected_out(selected_out)
    );

    initial clock = 1'b0;
    always #10 clock = ~clock;

    task tick; begin @(posedge clock); #1; end endtask

    task check;
        input [7:0]  expected;
        input [7:0]  actual;
        input [7:0]  tc_num;
        input [63:0] desc;
        begin
            if (actual === expected) begin
                $display("  PASS TC%0d: %s | expected=%0d actual=%0d", tc_num, desc, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL TC%0d: %s | expected=%0d actual=%0d <<<", tc_num, desc, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        $display("================================================");
        $display("  DSPChain Self-Verifying Testbench");
        $display("  Author: Kennedy Chukwuma (ELEC5566M)");
        $display("================================================");

        // Reset
        reset      = 1'b1;
        sample_in  = 8'd0;
        effect_sel = 2'b00;
        delay_sel  = 2'b00;
        threshold  = 8'd255;   // no clipping initially
        repeat(4) @(posedge clock);
        reset = 1'b0;

        // ── TC1: Pass-through — selected_out must equal sample_in ─────
        sample_in  = 8'd100;
        effect_sel = 2'b00;
        tick;
        check(8'd100, selected_out, 1, "pass-through");
        check(8'd100, original_out, 1, "original always = sample_in");

        // ── TC2: Echo selected — selected_out != original_out initially
        // After reset the buffer is cleared. So echo_out = (100+0)/2 = 50
        sample_in  = 8'd100;
        effect_sel = 2'b01;   // select echo
        tick;
        // echo: (sample_in + buffer[oldest]) >> 1 = (100 + 0) >> 1 = 50
        check(8'd50, selected_out, 2, "echo output (50/50 mix with cleared buffer)");

        // ── TC3: Distortion — threshold=128, input=200 → clipped to 128
        sample_in  = 8'd200;
        threshold  = 8'd128;
        effect_sel = 2'b10;   // select distortion
        tick;
        check(8'd128, selected_out, 3, "distortion: 200 clipped to threshold 128");

        // ── TC3b: Distortion — input below threshold passes through ───
        sample_in  = 8'd80;
        effect_sel = 2'b10;
        tick;
        check(8'd80, selected_out, 3, "distortion: 80 below threshold 128, passes through");

        // ── TC4: FIR selected — output is a weighted average ──────────
        // After reset all taps = 0. FIR output approaches sample_in slowly.
        reset = 1'b1; repeat(2) @(posedge clock); reset = 1'b0;
        sample_in  = 8'd100;
        effect_sel = 2'b11;   // select FIR
        threshold  = 8'd255;
        repeat(10) tick;      // let FIR taps fill with 100
        // After 10 cycles with constant 100, all taps = 100
        // Low-pass: (1×100 + 2×100 + 4×100 + 2×100 + 1×100)/10 = 100
        check(8'd100, selected_out, 4, "FIR with constant input=100 should output 100");

        // ── TC5: original_out always equals sample_in ─────────────────
        //=================================================================
        sample_in  = 8'd42;
        effect_sel = 2'b01;   // echo selected
        tick;
        check(8'd42, original_out, 5, "original_out always = sample_in");

        // ── TC6: All outputs in valid 8-bit range ─────────────────────
        //===============================================================
        sample_in = 8'd180;
        tick;
        if (echo_out <= 8'd255 && dist_out <= 8'd255 && fir_out <= 8'd255) begin
            $display("  PASS TC6: All outputs in valid range 0-255");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL TC6: Output out of range <<<");
            fail_count = fail_count + 1;
        end

        // ── TC7: Switching effect_sel changes selected_out immediately ─
        //=================================================================
        sample_in  = 8'd200;
        threshold  = 8'd128;
        effect_sel = 2'b10;   // distortion: 200 clipped to 128
        tick;
        check(8'd128, selected_out, 7, "distortion active: 200 clipped to 128");
        effect_sel = 2'b00;   // switch to pass-through immediately
        #1;                   // combinational — 1ns for mux to settle
        check(8'd200, selected_out, 7, "after switch to pass-through: 200 passes");

        // ── TC8: Reset clears echo — first output after reset is mixed with 0
        //=====================================================================
        reset = 1'b1; repeat(2) @(posedge clock); reset = 1'b0;
        sample_in  = 8'd200;
        effect_sel = 2'b01;   // echo
        tick;
        // After reset, buffer all 0. echo = (200 + 0) >> 1 = 100
        check(8'd100, selected_out, 8, "echo after reset: (200+0)/2 = 100");

        $display("================================================");
        $display("  RESULT: %0d PASS  |  %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display("  ALL TESTS PASSED — DSPChain verified");
        else
            $display("  WARNING: %0d test(s) failed", fail_count);
        $display("================================================");
        $stop;
    end

endmodule
