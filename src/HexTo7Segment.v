/*
 * HexTo7Segment — Hexadecimal to 7-Segment Display Encoder
 * Source: ELEC5566M Unit 1.2 Lab Task 1 (reused IP)
 * Author: Kennedy Chukwuma (original from lab)
 * Module: ELEC5566M Mini-Project — Audio Scope Visualiser
 *
 * Description:
 *   Converts a 4-bit hexadecimal digit (0x0–0xF) into the 7-bit
 *   active-LOW segment encoding for the DE1-SoC HEX displays.
 *   Active-LOW means: 0 turns a segment ON, 1 turns it OFF.
 *
 *   Segment mapping (standard):
 *       _
 *      |_|   Segments: a(bit0) b(bit1) c(bit2) d(bit3)
 *      |_|             e(bit4) f(bit5) g(bit6)
 *
 * Ports:
 *   hexIn - in  - 4-bit hex digit (0–15)
 *   seg   - out - 7-bit active-LOW segment pattern
 *
 * Citation: Reused from Unit 1.2 Lab Task 1 — HexTo7Segment.v
 */

module HexTo7Segment (
    input  [3:0] hexIn,   // 4-bit input digit (0x0 to 0xF)
    output reg [6:0] seg  // 7-segment output, active LOW
);

    // ── Segment encoding table ───────────────────────────────────────
    // Each 7-bit value encodes which segments are OFF (1) and ON (0).
    // Bit order: {g, f, e, d, c, b, a}
    always @* begin
        seg = 7'h7F;  // default: all segments OFF (prevents latch)
        case (hexIn)
            4'h0: seg = 7'b1000000;  // 0: a,b,c,d,e,f on — g off
            4'h1: seg = 7'b1111001;  // 1: b,c on
            4'h2: seg = 7'b0100100;  // 2: a,b,d,e,g on
            4'h3: seg = 7'b0110000;  // 3: a,b,c,d,g on
            4'h4: seg = 7'b0011001;  // 4: b,c,f,g on
            4'h5: seg = 7'b0010010;  // 5: a,c,d,f,g on
            4'h6: seg = 7'b0000010;  // 6: a,c,d,e,f,g on
            4'h7: seg = 7'b1111000;  // 7: a,b,c on
            4'h8: seg = 7'b0000000;  // 8: all on
            4'h9: seg = 7'b0010000;  // 9: a,b,c,d,f,g on
            4'hA: seg = 7'b0001000;  // A: a,b,c,e,f,g on
            4'hB: seg = 7'b0000011;  // b: c,d,e,f,g on
            4'hC: seg = 7'b1000110;  // C: a,d,e,f on
            4'hD: seg = 7'b0100001;  // d: b,c,d,e,g on
            4'hE: seg = 7'b0000110;  // E: a,d,e,f,g on
            4'hF: seg = 7'b0001110;  // F: a,e,f,g on
            default: seg = 7'b1111111; // all OFF
        endcase
    end

endmodule
