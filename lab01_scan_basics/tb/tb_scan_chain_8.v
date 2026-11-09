`timescale 1ns / 1ps

module tb_scan_chain_8;
    reg        clk;
    reg        rst_n;
    reg        scan_en;
    reg        scan_in;
    reg  [7:0] functional_data;
    wire       scan_out;
    wire [7:0] scan_state;

    reg  [7:0] expected;
    reg  [7:0] observed;
    integer    checks;

    scan_chain_8 dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .scan_en         (scan_en),
        .scan_in         (scan_in),
        .functional_data (functional_data),
        .scan_out        (scan_out),
        .scan_state      (scan_state)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;  // 10 ns clock period

    task check_state;
        input [8*40-1:0] scenario;
        begin
            if ((scan_state !== expected) || (scan_out !== expected[7])) begin
                $display("FAIL: %0s at %0t ns", scenario, $time);
                $display("  expected=%b, state=%b, scan_out=%b",
                         expected, scan_state, scan_out);
                $finish;
            end
            checks = checks + 1;
        end
    endtask

    // One clock of functional capture (scan_en=0) or serial shift (scan_en=1).
    // Drive inputs at falling edge; check results after the rising edge.
    task cycle;
        input       en;
        input       si;
        input [7:0] fd;
        begin
            @(negedge clk);
            scan_en        = en;
            scan_in        = si;
            functional_data = fd;
            @(posedge clk);
            if (en)
                expected = {expected[6:0], si};
            else
                expected = fd;
            #1;
            check_state("clock cycle");
        end
    endtask

    // Inject byte MSB-first. After 8 cycles, scan_state equals data_in.
    task shift_in_byte;
        input [7:0] data_in;
        integer bit_index;
        begin
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1)
                cycle(1'b1, data_in[bit_index], 8'h00);
        end
    endtask

    // Shift out a byte MSB-first while shifting in zeros.
    task shift_out_byte;
        output [7:0] data_out;
        integer bit_index;
        begin
            data_out = 8'h00;
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1) begin
                @(negedge clk);
                scan_en         = 1'b1;
                scan_in         = 1'b0;
                functional_data = 8'h00;
                // Observe serial output BEFORE the next rising edge.
                data_out[bit_index] = scan_out;
                @(posedge clk);
                expected = {expected[6:0], 1'b0};
                #1;
                check_state("shift-out cycle");
            end
        end
    endtask

    initial begin
        rst_n          = 1'b0;
        scan_en        = 1'b0;
        scan_in        = 1'b0;
        functional_data = 8'h00;
        expected       = 8'h00;
        observed       = 8'h00;
        checks         = 0;

        // TEST 1: Reset clears all flip-flops.
        #2;
        check_state("initial reset");
        $display("PASS: initial reset");
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // TEST 2: Parallel functional capture.
        cycle(1'b0, 1'b0, 8'h3C);
        $display("PASS: parallel capture (3C)");

        // TEST 3: Shift out captured data.
        shift_out_byte(observed);
        if (observed !== 8'h3C) begin
            $display("FAIL: expected serial 3C, observed %h", observed);
            $finish;
        end
        $display("PASS: serial shift-out (3C)");

        // TEST 4: Shift in A5, then read it out.
        shift_in_byte(8'hA5);
        if (scan_state !== 8'hA5) begin
            $display("FAIL: expected scan_state A5, observed %h", scan_state);
            $finish;
        end
        $display("PASS: serial shift-in (A5)");
        shift_out_byte(observed);
        if (observed !== 8'hA5) begin
            $display("FAIL: expected serial A5, observed %h", observed);
            $finish;
        end
        $display("PASS: serial shift-out (A5)");

        // TEST 5: Capture overrides previous chain contents.
        cycle(1'b0, 1'b1, 8'hF0);
        $display("PASS: capture-mode priority (F0)");

        // TEST 6: Assert asynchronous reset between clock edges.
        @(negedge clk);
        rst_n = 1'b0;
        expected = 8'h00;
        #1;
        check_state("asynchronous reset");
        $display("PASS: asynchronous reset");

        $display("ALL TESTS PASSED (%0d state checks)", checks);
        $finish;
    end
endmodule
