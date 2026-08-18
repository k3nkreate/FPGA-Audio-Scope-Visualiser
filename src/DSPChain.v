/*
 * DSPChain — Signal Routing and Effect Selection
 * Author: Kennedy Chukwuma
 * ELEC5566M Mini-Project: Audio Scope Visualiser
 * Instantiates all three effects and selects output via mux
 */
module DSPChain #(
    parameter DATA_WIDTH  = 8,
    parameter ECHO_DEPTH  = 64,
    parameter FIR_TAPS    = 5
)(
    input                         clock,
    input                         reset,
    input  [DATA_WIDTH-1:0]       sample_in,
    input  [1:0]                  target_module,
    input  [1:0]                  delay_sel,     
    input  [DATA_WIDTH-1:0]       threshold,
    input                         filter_sel,    

    output [DATA_WIDTH-1:0]       original_out,
    output [DATA_WIDTH-1:0]       echo_out,
    output [DATA_WIDTH-1:0]       dist_out,
    output [DATA_WIDTH-1:0]       fir_out,
    output reg [DATA_WIDTH-1:0]   selected_out
);
    
     // Pass original through unchanged
    assign original_out = sample_in;

    // ─── Instantiate all three effects ───────────────────
    EchoEngine #(
    .DATA_WIDTH(DATA_WIDTH),
    .BUFFER_DEPTH(ECHO_DEPTH)
) u_echo (
    .clk           (clock),
    .rst           (reset),
    .sample_valid  (1'b1),        // always processing for now
    .sample_in     (sample_in),
    .delay_sel     (delay_sel),
    .sample_out    (echo_out)
);

    DistortionEngine #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dist (
        .sample_in (sample_in ),
        .threshold (threshold ),
        .dist_out  (dist_out  )
    );

    FirFilterParam u_fir (
    .clock     (clock),
    .reset     (reset),
    .filter    (filter_sel),   // FIXED
    .sampleIn  (sample_in),
    .sampleOut (fir_out)
);
    
     // ─── Output multiplexer ───────────────────────────────
    always @* begin
        selected_out = sample_in;       // default: pass-through
        case (target_module)    
            2'b00: selected_out = sample_in;  // original
            2'b01: selected_out = echo_out;   // echo
            2'b10: selected_out = dist_out;   // distortion
            2'b11: selected_out = fir_out; 
        endcase
    end

endmodule
