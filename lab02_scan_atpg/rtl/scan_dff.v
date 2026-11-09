`timescale 1ns / 1ps

// A simple muxed-D scan flip-flop, active-low asynchronous reset.
module scan_dff (
    input  wire clk,
    input  wire rst_n,
    input  wire scan_en,
    input  wire scan_in,
    input  wire func_in,
    output reg  q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else if (scan_en)
            q <= scan_in;   // Shift mode
        else
            q <= func_in;   // Functional capture mode
    end
endmodule
