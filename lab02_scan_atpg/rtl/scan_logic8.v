`timescale 1ns / 1ps
// Educational scan-based sequential logic DUT.
// Internal register bank models eight muxed-D scan flip-flops.
// fault_mode is a simulation/teaching fault-injection control:
// 00 = good, 01 = internal node stuck-at-0, 10 = stuck-at-1.
// This port and mux must NOT be mistaken for industrial DFT insertion.
module scan_logic8 (
    input wire clk,
    input wire rst_n,
    input wire scan_en,
    input wire scan_in,
    input wire [1:0] fault_mode,
    output wire scan_out,
    output wire [7:0] scan_state
);
    wire [8:0] link;
    wire a_and_b;
    wire fault_node;
    wire [7:0] functional_next;
    assign link[0] = scan_in;
    assign scan_state = link[8:1];
    assign scan_out = link[8];

    // This is the precise location of the emulated stuck-at fault.
    assign a_and_b = scan_state[0] & scan_state[1];
    assign fault_node = (fault_mode == 2'b01) ? 1'b0 :
                        (fault_mode == 2'b10) ? 1'b1 : a_and_b;

    // Fault must be ACTIVATED and PROPAGATED to become observable.
    // The AND with q[3] makes some patterns mask the fault.
    assign functional_next[0] = (fault_node ^ scan_state[2]) & scan_state[3];
    assign functional_next[1] = scan_state[1] ^ scan_state[3];
    assign functional_next[2] = scan_state[2] | scan_state[4];
    assign functional_next[3] = scan_state[3] & ~scan_state[5];
    assign functional_next[4] = scan_state[4] ^ scan_state[6];
    assign functional_next[5] = scan_state[5] | scan_state[7];
    assign functional_next[6] = scan_state[6] ^ scan_state[0];
    assign functional_next[7] = scan_state[7] & scan_state[1];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : FF
            scan_dff u_ff (
                .clk(clk), .rst_n(rst_n), .scan_en(scan_en),
                .scan_in(link[i]), .func_in(functional_next[i]),
                .q(link[i+1])
            );
        end
    endgenerate
endmodule
