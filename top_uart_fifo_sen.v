
module top_dht11 (
    input        clk,
    input        rst,
    input        btn_start,   
    inout        dht11_io,    
    output [3:0] fnd_com,
    output [7:0] fnd_data
);
 
    wire        w_start;      
    wire        w_done;
    wire        w_valid;
    wire [15:0] w_h;          
    wire [15:0] w_t;       

    reg [7:0] humidity_int_reg;
    reg [7:0] temp_int_reg;
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            humidity_int_reg <= 0;
            temp_int_reg     <= 0;
        end else if (w_done && w_valid) begin
            humidity_int_reg <= w_h[15:8];
            temp_int_reg     <= w_t[15:8];
        end
    end
 
    Btn_debouncer U_BTN_DEBOUNCER (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_start),
        .o_btn(w_start)
    );
 
    t_h_controller U_DHT11 (
        .clk     (clk),
        .reset   (rst),
        .start   (w_start),
        .dht11_io(dht11_io),
        .done    (w_done),
        .valid   (w_valid),
        .h       (w_h),
        .t       (w_t)
    );
 

    Fnd_controller U_FND_CONTROLLER (
        .clk     (clk),
        .rst     (rst),
        .sw      (1'b0),
        .msec    (humidity_int_reg),   
        .sec     (temp_int_reg),        
        .min     (6'd0),
        .hour    (5'd0),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );
    endmodule
 
module tick_us (
    input clk,
    input reset,
    output reg tick_us
);

    parameter count_max = 100;
    reg [$clog2(count_max)-1:0] count_cnt;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_cnt <= 0;
            tick_us   <= 1'b0;
        end else if (count_cnt == count_max - 1) begin
            count_cnt <= 0;
            tick_us   <= 1'b1;
        end else begin
            count_cnt <= count_cnt + 1;
            tick_us   <= 1'b0;
        end
    end
endmodule

module t_h_controller (
    input clk,
    input reset,
    input start,
    inout dht11_io,
    output reg done,
    output reg valid,
    output reg [15:0] h,
    output reg [15:0] t
);

    wire w_tick_us;
    tick_us U_TICK_US (
        .clk(clk),
        .reset(reset),
        .tick_us(w_tick_us)
    );

    localparam idle = 0;
    localparam start_low = 1;
    localparam start_high = 2;
    localparam sync_low = 3;
    localparam sync_high = 4;
    localparam sync_end = 5;
    localparam data_low = 6;
    localparam data_high = 7;
    localparam s_stop = 8;
    localparam s_done = 9;

    reg [3:0] n_state, c_state;
    reg [31:0] cnt_reg, cnt_next;
    reg [5:0] bit_idx_reg, bit_idx_next;
    reg [6:0] high_cnt_reg, high_cnt_next;
    reg [39:0] shift_reg, shift_next;
    reg dht_oe_reg, dht_oe_next;
    reg dht_out_reg, dht_out_next;
    reg done_next;
    reg valid_next;
    reg [15:0] h_next;
    reg [15:0] t_next;
    reg data_sync1, data_sync2;
always @(posedge clk, posedge reset) begin
    if (reset) begin
        data_sync1 <= 1'b1;
        data_sync2 <= 1'b1;
    end else begin
        data_sync1 <= dht11_io;
        data_sync2 <= data_sync1;
    end
end
wire dht_in = data_sync2;   

    assign dht11_io = dht_oe_reg ? dht_out_reg : 1'bz;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= idle;
            cnt_reg <= 0;
            bit_idx_reg <= 0;
            shift_reg <= 0;
            high_cnt_reg <= 0;
            dht_oe_reg <= 1'b0;
            dht_out_reg <= 1'b1;
            done <= 1'b0;
            valid <= 1'b0;
            h <= 0;
            t <= 0;
        end else begin
            c_state <= n_state;
            cnt_reg <= cnt_next;
            bit_idx_reg <= bit_idx_next;
            shift_reg <= shift_next;
            high_cnt_reg <= high_cnt_next;
            dht_oe_reg <= dht_oe_next;
            dht_out_reg <= dht_out_next;
            done <= done_next;
            valid <= valid_next;
            h <= h_next;
            t <= t_next;
        end
    end




    always @(*) begin
        n_state = c_state;
        cnt_next = cnt_reg;
        bit_idx_next = bit_idx_reg;
        shift_next = shift_reg;
        high_cnt_next = high_cnt_reg;
        dht_oe_next = dht_oe_reg;
        dht_out_next = dht_out_reg;
        done_next = 1'b0;
        valid_next = valid;
        h_next = h;
        t_next = t;
        case (c_state)
            idle: begin
                dht_oe_next = 1'b0;
                dht_out_next = 1'b1;
                cnt_next = 0;
                bit_idx_next = 0;
                if (start) begin
                    dht_oe_next = 1'b1;
                    dht_out_next = 1'b0;
                    n_state = start_low;
                end
            end
            start_low: begin
                if (w_tick_us) begin
                    if (cnt_reg == 20000) begin
                        cnt_next = 0;
                        dht_out_next = 1'b1;
                        n_state = start_high;
                    end else begin
                        cnt_next = cnt_reg + 1;
                    end
                end
            end
            start_high: begin
                if (w_tick_us) begin
                    if (cnt_reg == 30) begin
                        cnt_next = 0;
                        dht_oe_next = 1'b0;
                        n_state = sync_low;
                    end else begin
                        cnt_next = cnt_reg + 1;
                    end
                end
            end
            sync_low: begin
                if (dht_in == 1'b0) begin
                    cnt_next = 0;
                    n_state  = sync_high;
                end else begin
                    if (w_tick_us) begin
                        if (cnt_reg == 100) begin
                            n_state = s_stop;
                        end else begin
                            cnt_next = cnt_reg + 1;
                        end
                    end
                end
            end
            sync_high: begin
                if (dht_in == 1'b1) begin
                    cnt_next = 0;
                    n_state  = sync_end;
                end else begin
                    if (w_tick_us) begin
                        if (cnt_reg == 100) begin
                            n_state = s_stop;
                        end else begin
                            cnt_next = cnt_reg + 1;
                        end
                    end

                end
            end
            sync_end: begin
                if (dht_in == 1'b0) begin
                    cnt_next      = 0;
                    high_cnt_next = 0;
                    bit_idx_next  = 0;
                    n_state       = data_low;
                end else if (w_tick_us) begin
                    if (cnt_reg == 100) n_state = s_stop;
                    else cnt_next = cnt_reg + 1;
                end
            end
            data_low: begin
                if (dht_in == 1'b1) begin
                    cnt_next = 0;
                    high_cnt_next = 0;
                    n_state = data_high;
                end else begin
                    if (w_tick_us) begin
                        if (cnt_reg == 100) begin
                            n_state = s_stop;
                        end else begin
                            cnt_next = cnt_reg + 1;
                        end
                    end
                end
            end
            data_high: begin
                if (dht_in == 1'b0) begin
                    shift_next = {shift_reg[38:0], (high_cnt_reg > 45)};
                    bit_idx_next = bit_idx_reg + 1;
                    cnt_next = 0;
                    if (bit_idx_reg + 1 == 40) begin
                        n_state = s_done;
                    end else begin
                        n_state = data_low;
                    end
                end else begin
                    if (w_tick_us) begin
                        if (high_cnt_reg == 100) begin
                            n_state = s_stop;
                        end else begin
                            high_cnt_next = high_cnt_reg + 1;
                        end
                    end
                end
            end
            s_stop: begin
                valid_next = 1'b0;
                done_next = 1'b1;
                n_state = idle;
            end
            s_done: begin
                if((shift_reg[39:32] + shift_reg[31:24] + shift_reg[23:16] + shift_reg[15:8])== shift_reg[7:0]) begin
                    h_next = {shift_reg[39:32], shift_reg[31:24]};
                    t_next = {shift_reg[23:16], shift_reg[15:8]};
                    valid_next = 1'b1;
                end else begin
                    valid_next = 1'b0;
                end
                done_next = 1'b1;
                n_state   = idle;
            end
        endcase
    end
endmodule




