`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/10 15:21:24
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo #(parameter width = 2)(
    input clk,
    input reset,
    input push,
    input pop,
    input [7:0] wdata,
    output [7:0] rdata,
    output full,
    output empty
);
  wire [width-1:0] w_wptr, w_rptr;

 register_file #(.width(2))
 U_REG_FILE (
    .clk(clk),
    .waddr(w_wptr),
    .raddr(w_rptr),
    .wdata(wdata),
    .we(~full & push),
    .rdata(rdata)
 );

 fifo_control_unit #(
    .width(2)
) U_CON_UNIT(
    .clk(clk),
    .reset(reset),
    .push(push),
    .pop(pop),
    .wptr(w_wptr),
    .rptr(w_rptr),
    .full(full),
    .empty(empty)
);
endmodule

module register_file #(
    parameter width = 2
) (
    input clk,
    input [width-1:0] waddr,
    input [width-1:0] raddr,
    input [7:0] wdata,
    input we,
    output [7:0] rdata
);

    parameter depth = 2 ** width;
    reg [7:0] register_file[0:depth-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    //rdata:cl output
    assign rdata = register_file[raddr];
endmodule

module fifo_control_unit #(
    parameter width = 2
) (
    input clk,
    input reset,
    input push,
    input pop,
    output [width-1:0] wptr,
    output [width-1:0] rptr,
    output full,
    output empty
);
    reg [width-1:0] wptr_reg, wptr_next;
    reg [width-1:0] rptr_reg, rptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    assign wptr = wptr_reg;
    assign rptr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;
    always @(posedge clk) begin
        if (reset) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    //next cl
    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            2'b00: begin
                //init
            end
            2'b01: begin
                //pop only
               if (!empty) begin
        rptr_next = rptr_reg + 1;
        full_next = 1'b0;
                if (wptr_reg == rptr_next) empty_next = 1'b1;
               end
            end
            2'b10: begin
                //pugh only
                if (!full) begin
        wptr_next  = wptr_reg + 1;
        empty_next = 1'b0;
                
                if (wptr_next == rptr_reg) full_next = 1'b1;
            end
            end
            2'b11: begin
                //push pop
                if (full) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
endmodule
