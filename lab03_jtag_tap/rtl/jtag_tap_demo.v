`timescale 1ns / 1ps
// Teaching example: all 16 TAP state transitions, a 4-bit IR,
// a demo 8-bit DR (captured fixed data A5), and a 1-bit BYPASS register.
// Does NOT implement a complete IEEE 1149.1-compliant boundary-scan device:
// no boundary scan cells, BSDL, EXTEST, IDCODE, or production TDO timing.
module jtag_tap_demo (
    input wire tck, input wire trst_n,
    input wire tms, input wire tdi,
    output wire tdo, output reg [3:0] state,
    output reg [3:0] instruction
);
    localparam TLR=4'd0, IDLE=4'd1, SEL_DR=4'd2, CAP_DR=4'd3;
    localparam SH_DR=4'd4, E1_DR=4'd5, PA_DR=4'd6, E2_DR=4'd7;
    localparam UP_DR=4'd8, SEL_IR=4'd9, CAP_IR=4'd10, SH_IR=4'd11;
    localparam E1_IR=4'd12, PA_IR=4'd13, E2_IR=4'd14, UP_IR=4'd15;
    reg [3:0] next_state;
    reg [3:0] ir_shift;
    reg [7:0] dr_shift;
    reg bypass_shift;
    // Demo instruction 0001 selects the 8-bit DR; anything else bypasses.
    wire dr_selected = instruction == 4'b0001;

    always @(*) begin
        case(state)
            TLR:    next_state = tms ? TLR    : IDLE;
            IDLE:   next_state = tms ? SEL_DR : IDLE;
            SEL_DR: next_state = tms ? SEL_IR : CAP_DR;
            CAP_DR: next_state = tms ? E1_DR  : SH_DR;
            SH_DR:  next_state = tms ? E1_DR  : SH_DR;
            E1_DR:  next_state = tms ? UP_DR  : PA_DR;
            PA_DR:  next_state = tms ? E2_DR  : PA_DR;
            E2_DR:  next_state = tms ? UP_DR  : SH_DR;
            UP_DR:  next_state = tms ? SEL_DR : IDLE;
            SEL_IR: next_state = tms ? TLR    : CAP_IR;
            CAP_IR: next_state = tms ? E1_IR  : SH_IR;
            SH_IR:  next_state = tms ? E1_IR  : SH_IR;
            E1_IR:  next_state = tms ? UP_IR  : PA_IR;
            PA_IR:  next_state = tms ? E2_IR  : PA_IR;
            E2_IR:  next_state = tms ? UP_IR  : SH_IR;
            UP_IR:  next_state = tms ? SEL_DR : IDLE;
            default:next_state = TLR;
        endcase
    end

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            state <= TLR;
            ir_shift <= 4'b0001;
            instruction <= 4'b1111; // default BYPASS
            dr_shift <= 8'h00;
            bypass_shift <= 1'b0;
        end else begin
            state <= next_state;
            case(state) // operations use OLD state at current TCK rising edge
                CAP_IR: ir_shift <= 4'b0001;
                SH_IR:  ir_shift <= {tdi, ir_shift[3:1]};
                UP_IR:  instruction <= ir_shift;
                CAP_DR: begin
                    dr_shift <= 8'hA5; // illustrative device register
                    bypass_shift <= 1'b0;
                end
                SH_DR: begin
                    if (dr_selected) dr_shift <= {tdi, dr_shift[7:1]};
                    else bypass_shift <= tdi;
                end
                default: ;
            endcase
        end
    end

    // Simplified combinational TDO for an easy RTL lab.
    // A real compliant TAP requires more detailed timing treatment.
    assign tdo = (state == SH_IR) ? ir_shift[0] :
                 (state == SH_DR) ? (dr_selected ? dr_shift[0] : bypass_shift) : 1'b0;
endmodule
