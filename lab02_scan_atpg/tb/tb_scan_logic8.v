`timescale 1ns / 1ps
module tb_scan_logic8;
    reg clk;
    reg rst_n;
    reg scan_en;
    reg scan_in;
    reg [1:0] fault_mode;
    wire scan_out;
    wire [7:0] scan_state;
    reg [7:0] serial_result;
    reg [7:0] observed_capture;
    reg [7:0] golden_capture;
    integer cases;
    integer i;

    scan_logic8 dut (
        .clk(clk), .rst_n(rst_n), .scan_en(scan_en),
        .scan_in(scan_in), .fault_mode(fault_mode),
        .scan_out(scan_out), .scan_state(scan_state)
    );

    initial clk=0;
    always #5 clk = ~clk;

    // Software-style independent reference model (does not use DUT nets).
    function [7:0] model;
        input [7:0] q;
        input [1:0] mode;
        reg mid;
        begin
            mid = q[0] & q[1];
            if (mode == 2'b01) mid = 1'b0;
            if (mode == 2'b10) mid = 1'b1;
            model[0] = (mid ^ q[2]) & q[3];
            model[1] = q[1] ^ q[3];
            model[2] = q[2] | q[4];
            model[3] = q[3] & ~q[5];
            model[4] = q[4] ^ q[6];
            model[5] = q[5] | q[7];
            model[6] = q[6] ^ q[0];
            model[7] = q[7] & q[1];
        end
    endfunction

    task tick;
        input en;
        input si;
        input [1:0] fm;
        begin
            @(negedge clk);
            scan_en = en;
            scan_in = si;
            fault_mode = fm;
            @(posedge clk);
            #1;
        end
    endtask

    // Eight MSB-first bits end up in q[7:0] as an ordinary byte.
    task load_pattern;
        input [7:0] p;
        integer k;
        begin
            for (k=7;k>=0;k=k-1) tick(1'b1, p[k], 2'b00);
            if (scan_state !== p) begin
                $display("FAIL: scan loading: expected=%h actual=%h",p,scan_state);
                $finish;
            end
        end
    endtask

    // Observe serial scan_out BEFORE each rising shift clock.
    task read_scan;
        output [7:0] data;
        integer k;
        begin
            data=8'h00;
            for (k=7;k>=0;k=k-1) begin
                @(negedge clk);
                scan_en = 1'b1;
                scan_in = 1'b0;
                fault_mode = 2'b00;
                #1;
                data[k] = scan_out;
                @(posedge clk);
                #1;
            end
        end
    endtask

    task run_case;
        input [7:0] pattern;
        input [1:0] mode;
        input should_detect;
        begin
            load_pattern(pattern);
            golden_capture = model(pattern, 2'b00);
            tick(1'b0, 1'b0, mode); // one functional capture clock
            observed_capture = model(pattern, mode);
            if (scan_state !== observed_capture) begin
                $display("FAIL: capture mismatch pattern=%h fault=%b",pattern,mode);
                $finish;
            end
            read_scan(serial_result);
            if (serial_result !== observed_capture) begin
                $display("FAIL: scan read mismatch: got=%h expected=%h",serial_result,observed_capture);
                $finish;
            end
            if ((serial_result != golden_capture) !== should_detect) begin
                $display("FAIL: fault detection expectation pattern=%h mode=%b",pattern,mode);
                $finish;
            end
            cases = cases+1;
            $display("PASS case %0d: pattern=%h fault_mode=%b golden=%h actual=%h detected=%b",
                     cases,pattern,mode,golden_capture,serial_result,should_detect);
        end
    endtask

    initial begin
        rst_n=0; scan_en=0; scan_in=0; fault_mode=0;
        cases=0; serial_result=0; observed_capture=0; golden_capture=0;
        #2;
        if (scan_state !== 8'h00) begin
            $display("FAIL: async reset"); $finish;
        end
        @(negedge clk); rst_n=1;

        run_case(8'h0B, 2'b00, 1'b0); // good circuit
        run_case(8'h0B, 2'b01, 1'b1); // stuck at 0: detectable
        run_case(8'h08, 2'b10, 1'b1); // stuck at 1: detectable
        run_case(8'h08, 2'b01, 1'b0); // stuck at 0: masked
        run_case(8'h0B, 2'b10, 1'b0); // stuck at 1: masked

        $display("ALL LAB02 TESTS PASSED (%0d cases)",cases);
        $finish;
    end
endmodule
