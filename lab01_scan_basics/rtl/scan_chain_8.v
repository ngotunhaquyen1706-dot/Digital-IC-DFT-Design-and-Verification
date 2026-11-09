`timescale 1ns / 1ps

// Eight muxed-D scan flip-flops connected in a serial chain.
module scan_chain_8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       scan_en,
    input  wire       scan_in,
    input  wire [7:0] functional_data,
    output wire       scan_out,
    output wire [7:0] scan_state   // Debug visibility for this lab
);
    wire [8:0] scan_link;
    assign scan_link[0] = scan_in;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_SCAN_DFF
            scan_dff u_dff (
                .clk      (clk),
                .rst_n    (rst_n),
                .scan_en  (scan_en),
                .scan_in  (scan_link[i]),
                .func_in  (functional_data[i]),
                .q        (scan_link[i+1])
            );
        end
    endgenerate

    assign scan_state = scan_link[8:1];
    assign scan_out   = scan_link[8];
endmodule
