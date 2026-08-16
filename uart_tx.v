`timescale 1ns / 1ps


module uart_controller (
    input        clk,
    input        reset,
    input        tx_start,
    input  [7:0] tx_data,
    input        rx,
    output [7:0] rx_data,
    output       rx_done,
    output       tx_busy,
    output       tx_done,
    output       tx
);

    wire w_baud_tick_x16;




    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .i_baud_tick(w_baud_tick_x16),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .tx(tx)
    );
    baud_tick_x16 U_BAUD_TICK_X16 (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(w_baud_tick_x16)
    );
    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
endmodule

module baud_tick (
    input clk,
    input reset,
    output reg o_baud_tick
);
    parameter count_max = 10417;
    reg [$clog2(count_max)-1:0] count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            o_baud_tick <= 1'b0;
        end else begin
            count <= count + 1;
            if (count == count_max - 1) begin
                count <= 0;
                o_baud_tick <= 1'b1;
            end else begin
                o_baud_tick <= 1'b0;
            end
        end
    end
endmodule


// module uart_tx (
//    input clk,
//    input reset,
//    input [7:0] tx_data,
//    input tx_start,
//    input i_baud_tick,
//    output tx
// );
//    localparam [3:0] idle = 4'h0, start = 4'h1;
//    localparam [3:0] bit0 = 4'h2, bit1 = 4'h3;
//    localparam [3:0] bit2 = 4'h4, bit3 = 4'h5;
//    localparam [3:0] bit4 = 4'h6, bit5 = 4'h7;
//    localparam [3:0] bit6 = 4'h8, bit7 = 4'h9;
//    localparam [3:0] stop = 4'ha;
//    reg [3:0] c_state, n_state;
//    reg tx_reg, tx_next;

// assign tx = tx_reg;
// //state register
//   always @(posedge clk, posedge reset) begin
//     if(reset) begin
//         c_state <= idle;
//         tx_reg <= 1'b1;
//   end else begin
//     c_state <= n_state;
//     tx_reg <= tx_next;
//   end
//   end


//   //next, output cl
//   always @(*) begin
//     n_state = c_state;
//     tx_next = tx_reg;
//     case(c_state)
//       idle: begin
//         // output
//         tx_next = 1'b1;
//         //condition of next transtition
//         if(tx_start) begin
//             n_state = start;
//         end
//       end
//       start: begin
//         tx_next = 1'b0;
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit0;
//         end
//       end
//       bit0: begin
//         tx_next = tx_data[0];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit1;
//         end
//       end
//       bit1: begin
//         tx_next = tx_data[1];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit2;
//         end
//       end
//       bit2: begin
//         tx_next = tx_data[2];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit3;
//         end
//       end
//       bit3: begin
//         tx_next = tx_data[3];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit4;
//         end
//       end
//       bit4: begin
//         tx_next = tx_data[4];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit5;
//         end
//       end
//        bit5: begin
//         tx_next = tx_data[5];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit6;
//         end
//       end
//        bit6: begin
//         tx_next = tx_data[6];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = bit7;
//         end
//       end
//       bit7: begin
//         tx_next = tx_data[7];
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = stop;
//         end
//       end

//        stop: begin
//         tx_next = 1'b1;
//         // output
//         //condition of next transtition
//         if(i_baud_tick) begin
//             n_state = idle;
//         end
//       end


//     endcase
//   end
// endmodule


module uart_tx (
    input        clk,
    input        reset,
    input  [7:0] tx_data,
    input        tx_start,
    input        i_baud_tick,
    output       tx,
    output       tx_done,
    output       tx_busy
);
    localparam [2:0] idle = 0, start = 1, data = 2, stop = 3;

    reg [2:0] c_state, n_state;
    reg [3:0] tick_count_reg, tick_count_next;
    reg [2:0] bit_cnt, bit_cnt_next;
    reg tx_reg, tx_next;
    reg [7:0] data_reg, data_next;
    reg tx_busy_reg, tx_busy_next;
    reg tx_done_reg, tx_done_next;
    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= idle;
            tick_count_reg <= 0;
            bit_cnt <= 0;
            tx_reg <= 1'b1;
            data_reg <= 8'h00;
            tx_busy_reg <= 1'b0;
            tx_done_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            tick_count_reg <= tick_count_next;
            bit_cnt <= bit_cnt_next;
            tx_reg <= tx_next;
            data_reg <= data_next;
            tx_busy_reg <= tx_busy_next;
            tx_done_reg <= tx_done_next;
        end
    end

    // next, output cl
    always @(*) begin
        n_state         = c_state;
        tick_count_next = tick_count_reg;
        bit_cnt_next    = bit_cnt;
        tx_next         = tx_reg;
        data_next       = data_reg;
        tx_busy_next    = tx_busy_reg;
        tx_done_next    = tx_done_reg;

        case (c_state)
            idle: begin
                tick_count_next = 0;
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                tx_done_next = 1'b0;
                if (tx_start) begin
                    data_next = tx_data;
                    tx_busy_next = 1'b1;
                    n_state = start;
                end

            end


            start: begin
                tx_next = 1'b0;
                bit_cnt_next = 3'd0;
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        n_state         = data;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            data: begin
                tx_next = data_reg[0];
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin

                        data_next = {1'b0, data_reg[7:1]};
                        tick_count_next = 0;
                        if (bit_cnt == 7) n_state = stop;
                        else begin
                            n_state = data;
                            bit_cnt_next = bit_cnt + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            stop: begin
                tx_next = 1'b1;
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tx_busy_next = 1'b0;
                        tx_done_next = 1'b1;
                        n_state = idle;
                    end else tick_count_next = tick_count_reg + 1;
                end
            end
        endcase
    end
endmodule

// module uart_tx (
//     input        clk,
//     input        reset,
//     input  [7:0] tx_data,
//     input        tx_start,
//     input        i_baud_tick,
//     output       tx,
//     output       tx_done,
//     output       tx_busy
// );
//     localparam [2:0] idle = 0, wait_tick = 1, start = 2, data = 3, stop = 4;

//     reg [2:0] c_state, n_state;
//     reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
//     reg [2:0] bit_cnt, bit_cnt_next;
//     reg tx_reg, tx_next;
//     reg [7:0] data_reg, data_next;
//     reg tx_busy_reg, tx_busy_next;
//     reg tx_done_reg, tx_done_next;

//     assign tx = tx_reg;
//     assign tx_busy = tx_busy_reg;
//     assign tx_done = tx_done_reg;

//     // state register
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             c_state <= idle;
//             b_tick_cnt_reg <= 0;
//             bit_cnt <= 0;
//             tx_reg <= 1'b1;
//             data_reg <= 8'h00;
//             tx_busy_reg <= 1'b0;
//             tx_done_reg <= 1'b0;
//         end else begin
//             c_state <= n_state;
//             b_tick_cnt_reg <= b_tick_cnt_next;
//             bit_cnt <= bit_cnt_next;
//             tx_reg <= tx_next;
//             data_reg <= data_next;
//             tx_busy_reg <= tx_busy_next;
//             tx_done_reg <= tx_done_next;
//         end
//     end

//     // next, output cl
//     always @(*) begin
//         n_state      = c_state;
//         b_tick_cnt_next = b_tick_cnt_reg;
//         bit_cnt_next = bit_cnt;
//         tx_next      = tx_reg;
//         data_next    = data_reg;
//         tx_busy_next = tx_busy_reg;
//         tx_done_next = tx_done_reg;

//         case (c_state)
//             idle: begin
//                 tx_next = 1'b1;
//                 tx_busy_next = 1'b0;
//                 tx_done_next = 1'b0;
//                 if (tx_start) begin
//                     data_next = tx_data;
//                     tx_busy_next = 1'b1;
//                     n_state = wait_tick;
//                 end

//             end


//             start: begin

//                 if (i_baud_tick) begin
//                     if(b_tick_cnt_reg == 15) begin
//                     n_state      = data;
//                     bit_cnt_next = 0;
//                     end
//                 end
//             end

//             data: begin
//                 tx_next = data_reg[bit_cnt];
//                 if (i_baud_tick) begin
//                     if (bit_cnt == 3'd7) begin
//                         n_state = stop;
//                     end else begin
//                         bit_cnt_next = bit_cnt + 1;
//                     end
//                 end
//             end

//             stop: begin
//                 tx_next = 1'b1;
//                 if (i_baud_tick) begin
//                     tx_busy_next = 1'b0;
//                     tx_done_next = 1'b1;
//                     n_state = idle;
//                 end
//             end
//         endcase
//     end
// endmodule


module uart_rx (
    input clk,
    input reset,
    input i_baud_tick,
    input rx,
    output [7:0] rx_data,
    output rx_done
);
    // state
    localparam [1:0] idle = 0, start = 1, data = 2, stop = 3;
    reg [1:0] c_state, n_state;
    reg [3:0] tick_count_reg, tick_count_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [7:0] data_reg, data_next;
    //reg rx_done_reg;
    reg rx_done_reg, rx_done_next;

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;

    //state sl
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= idle;
            tick_count_reg <= 0;
            bit_count_reg <= 0;
            data_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            c_state <= n_state;
            tick_count_reg <= tick_count_next;
            bit_count_reg <= bit_count_next;
            data_reg <= data_next;
            rx_done_reg <= rx_done_next;

        end
    end

    //next
    always @(*) begin
        n_state = c_state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        data_next = data_reg;
        rx_done_next = rx_done_reg;
        case (c_state)
            idle: begin
                rx_done_next   = 0;
                bit_count_next = 0;
                if (i_baud_tick) begin
                    if (!rx) begin
                        if (tick_count_reg == 7) begin
                            n_state = start;
                            tick_count_next = 0;
                        end else begin
                            tick_count_next = tick_count_reg + 1;
                        end
                    end else begin
                        //data_next = 0;
                        tick_count_next = 0;
                    end
                end
            end

            start: begin
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        n_state = data;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            data: begin
                //tx_next = data_reg[bit_cnt]; //pipo, bit indexing
                //sipo

                if (i_baud_tick) begin
                    if (tick_count_reg == 0) begin
                        data_next = {rx, data_reg[7:1]};
                        //data_next = data_reg[bit_count_reg];
                    end
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            n_state = stop;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            stop: begin
                if (i_baud_tick) begin
                    // if   = 7) begin
                    //     //for cl output
                        rx_done_next = 1;
                        n_state = idle;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            // stop: begin
//     if (i_baud_tick) begin
//         if (tick_count_reg == 15) begin
//             tick_count_next = 0;
//             rx_done_next = 1;
//             n_state = idle;
//         end else begin
//             tick_count_next = tick_count_reg + 1;
//         end
//     end
// end
            
        endcase
    end

endmodule


module baud_tick_x16 (
    input clk,
    input reset,
    output reg o_baud_tick
);
    parameter count_max = 100_000_000 / (9600 * 16);
    reg [$clog2(count_max)-1:0] count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            o_baud_tick <= 1'b0;
        end else begin
            count <= count + 1;
            if (count == count_max - 1) begin
                count <= 0;
                o_baud_tick <= 1'b1;
            end else begin
                o_baud_tick <= 1'b0;
            end
        end
    end
endmodule
