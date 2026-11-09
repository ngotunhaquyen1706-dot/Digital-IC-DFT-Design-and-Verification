`timescale 1ns / 1ps
module tb_jtag_tap_demo;
    reg tck, trst_n, tms, tdi;
    wire tdo;
    wire [3:0] state, instruction;
    reg [7:0] shifted_out;
    integer k;
    jtag_tap_demo dut (
        .tck(tck), .trst_n(trst_n), .tms(tms), .tdi(tdi),
        .tdo(tdo), .state(state), .instruction(instruction)
    );
    initial tck=0;
    always #5 tck=~tck;

    task step;
        input tms_value;
        input tdi_value;
        input [3:0] expected_state;
        begin
            @(negedge tck);
            tms=tms_value; tdi=tdi_value;
            @(posedge tck); #1;
            if (state !== expected_state) begin
                $display("FAIL TAP: expected state=%0d actual=%0d", expected_state, state);
                $finish;
            end
        end
    endtask

    initial begin
        trst_n=0; tms=1; tdi=0; shifted_out=0;
        #2;
        if (state !== 4'd0) begin $display("FAIL TAP reset"); $finish; end
        @(negedge tck); trst_n=1;
        step(0,0,1);  // IDLE
        // BYPASS is the active instruction after reset.
        step(1,0,2);  // SELECT_DR
        step(0,0,3);  // CAPTURE_DR
        step(0,0,4);  // SHIFT_DR
        step(0,1,4);  // shift in 1 bit via BYPASS
        if (tdo !== 1'b1) begin
            $display("FAIL BYPASS: expected TDO=1"); $finish;
        end
        step(1,0,5);  // EXIT1_DR
        step(0,0,6);  // PAUSE_DR
        step(1,0,7);  // EXIT2_DR
        step(0,0,4);  // SHIFT_DR
        step(1,0,5);  // EXIT1_DR
        step(1,0,8);  // UPDATE_DR
        step(0,0,1);  // IDLE
        $display("PASS: BYPASS and DR pause path");

        step(1,0,2);  // SELECT_DR
        step(1,0,9);  // SELECT_IR
        step(0,0,10); // CAPTURE_IR
        step(0,0,11); // SHIFT_IR
        // Shift 4-bit instruction 0001, LSB first: 1,0,0,0.
        step(0,1,11);
        step(0,0,11);
        step(0,0,11);
        step(1,0,12); // final shift and EXIT1_IR
        step(1,0,15); // UPDATE_IR
        step(0,0,1);  // IDLE; instruction updated on previous edge
        if (instruction !== 4'b0001) begin
            $display("FAIL IR: expected 0001 actual=%b", instruction);
            $finish;
        end
        $display("PASS: 16-state TAP route + instruction loading");

        step(1,0,2);  // SEL_DR
        step(0,0,3);  // CAP_DR
        step(0,0,4);  // SHIFT_DR; captured A5 at preceding edge
        // Read LSB first, before each shift clock edge.
        for (k=0;k<8;k=k+1) begin
            @(negedge tck);
            tms=(k==7); tdi=0;
            #1; shifted_out[k]=tdo;
            @(posedge tck); #1;
        end
        if (shifted_out !== 8'hA5 || state !== 4'd5) begin
            $display("FAIL DR: expected A5 actual=%h state=%0d", shifted_out,state);
            $finish;
        end
        step(1,0,8);  // UPDATE_DR
        step(0,0,1);  // IDLE
        $display("PASS: DR shifted out = %h", shifted_out);
        $display("ALL LAB03 TESTS PASSED");
        $finish;
    end
endmodule
