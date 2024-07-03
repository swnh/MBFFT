module controller #(
            PNT = 16,
            N = $clog2(PNT) // STAGE
)(
            input               clk,
            input               rstn,
            
            input               in_vld,
            input               out_rdy,
            output wire         in_rdy,
            output wire         out_vld,
            
            output wire         sel_input,
            output wire         sel_res,
            output wire         sel_mem,
            
            output wire         we_AMEM,
            output wire         we_BMEM,
            output wire         we_OMEM,

            output wire [N-1:0] addr_AMEM,
            output wire [N-1:0] addr_BMEM,
            output wire [N-1:0] addr_OMEM,
            output wire [9:0]   addr_CROM,
            
            output wire         en_REG_A,
            output reg          en_REG_B,
            output reg          en_REG_C
);

wire [$clog2(N):0]     last_n;
wire [$clog2(PNT/2):0] last_b;
wire [$clog2(PNT/2):0] last_k;
assign last_n = N;
assign last_b = PNT/(1 << cnt_n) - 1;
assign last_k = (1 << (cnt_n-1)) - 1; 
assign last_i = 1;

// Counter
reg [N:0] cnt;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cnt <= 0;
    end else begin
        if (state == IDLE) begin
            cnt <= (cnt == PNT-1) ? 0 : cnt+1;
        end else if (state == RUN || state == BUBL) begin
            cnt <= (cnt == PNT-1 + 3) ? 0 : cnt+1; // Pipeline depth: 3
        end else cnt <= cnt;
    end
end

reg [$clog2(8192):0]  cnt_s;
reg [$clog2(8192):0]  tmp_cnt_s;
reg [$clog2(N):0]     cnt_n;
reg [$clog2(N):0]     tmp_cnt_n;
reg [$clog2(PNT/2):0] cnt_b;
reg [$clog2(PNT/2):0] cnt_k;
reg                   cnt_i;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cnt_s <= 0; // SET
    tmp_cnt_s <= 0;
    end
    else begin
        if (cnt_n == last_n && cnt_b == last_b && cnt_k == last_k && cnt_i == last_i)
            tmp_cnt_s = cnt_s + 1;
        else if (cnt == PNT+2 && state == BUBL)
            cnt_s <= tmp_cnt_s;
    end
end
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cnt_n <= 0; // STAGE
    tmp_cnt_n <= 0;
        cnt_b <= 0; // BU
        cnt_k <= 0; // INDEX
        cnt_i <= 0; // 0,1
    end else if (state == RUN) begin
            if (cnt_b == last_b && cnt_k == last_k && cnt_i == last_i) begin
                tmp_cnt_n <= (cnt_n == last_n) ? 1 : cnt_n+1;
                cnt_b <= 0;
                cnt_k <= 0;
                cnt_i <= 0;
            end else if (cnt_k == last_k && cnt_i == last_i) begin
                cnt_b <= (cnt_b == last_b) ? 0 : cnt_b+1;
                cnt_k <= 0;
                cnt_i <= 0;
            end else if (cnt_i == last_i) begin
                cnt_k <= (cnt_k == last_k) ? 0 : cnt_k+1;
                cnt_i <= 0;
            end else cnt_i <= (cnt_i == last_i) ? 0 : cnt_i+1;
    end else if (state == IDLE) begin
            if (cnt == PNT-1) cnt_n <= cnt_n + 1;
    end else if (cnt == PNT+2 && state == BUBL) begin
            cnt_n <= tmp_cnt_n;
            cnt_b <= 0;
            cnt_k <= 0;
            cnt_i <= 0;
    end else begin
        cnt_n <= cnt_n;
        cnt_b <= cnt_b;
        cnt_k <= cnt_k;
        cnt_i <= cnt_i;
    end
end

// FSM
localparam BUBL = 2'b00;
localparam IDLE = 2'b10;
localparam RUN  = 2'b11;

reg [1:0] state;
reg [1:0] next;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state  <= IDLE;
    end else begin
        state <= next;
    end
end

always @(*) begin
    case(state)
        IDLE: begin
            if (cnt == PNT-1) next <= RUN; 
            else next <= IDLE;
        end
        RUN : begin
            if (cnt_b == last_b && cnt_k == last_k && cnt_i == last_i)
                next <= BUBL;
            else next <= RUN;
        end
        BUBL: begin
            if (cnt_n == 0 && cnt == PNT+2) next <= RUN;
            if (cnt == PNT+2) next <= RUN;
            else next <= BUBL;
        end
        default: next <= IDLE;
    endcase
end

assign en_REG_A = (state == RUN) ? cnt[0] : 0;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        en_REG_B <= 0;
        en_REG_C <= 0;
    end else if (state == RUN || state == BUBL) begin
        en_REG_B <= en_REG_A;
        en_REG_C <= en_REG_B;
    end else begin
        en_REG_B <= en_REG_B;
        en_REG_C <= en_REG_C;
    end
end

reg  [1:0] mode_reg;
wire [1:0] mode;
always @(posedge clk or negedge rstn) begin
    if (!rstn) mode_reg <= 0;
    else if (state == RUN) mode_reg <= mode;
    else mode_reg <= mode_reg;
end
assign mode = (state == IDLE) ? 2'b11
            : (state == RUN && cnt_n % 2 == 1) ? 2'b10 // RD(A), WR(B)
            : (state == RUN && cnt_n % 2 == 0) ? 2'b01 // RD(B), WR(A)
            : (state == BUBL) ? mode_reg : 0;

assign we_AMEM = (mode == 2'b11 || (cnt>2 && mode == 2'b01)) ? 1'b1 : 1'b0;
assign we_BMEM = ((cnt>2) && mode == 2'b10) ? 1'b1 : 1'b0;
assign we_OMEM = (cnt>2 && mode == 2'b01) ? 1'b1 : 1'b0;

assign sel_input = in_rdy;
assign sel_mem   = (mode == 2'b10) ? 1'b0 // RD AMEM
                 : (mode == 2'b01) ? 1'b1 // RD BMEM
                 : 'b0;
assign sel_res = en_REG_C;

wire [N:0] cntd;
assign cntd = (cnt>0) ? cnt-1 : 'b0; // 1 cycle delayed counter
assign in_rdy  = (cnt_n == 0 || (cnt>2 && cnt_n == last_n)) ? 1'b1 : 1'b0;
assign out_vld = (!cnt_s) ? 1'b0 : (cnt>0 && cnt_n == 1 && cntd<PNT) ? 1'b1 : 1'b0; // set 2 부터

// DIT input
function [N-1:0] bit_reverse;
        input [N-1:0] in;
        integer i;
        begin
            for (i=0; i<N; i=i+1) begin
                bit_reverse[i] = in[N-1-i];
            end
        end
endfunction

reg  [N-1:0] tmp1_addr_d, tmp2_addr_d, addr_d; // delayed by pipeline depth: 3
wire [N-1:0] addr;
wire [N-1:0] cnt_scaled = cnt[N-1:0];
assign addr   = (state == IDLE) ? bit_reverse(cnt_scaled)
              : (1 << cnt_n)*cnt_b + cnt_k + cnt_i*(1 << (cnt_n-1));
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        tmp1_addr_d <= 0;
        tmp2_addr_d <= 0;
             addr_d <= 0;
    end else begin
        tmp1_addr_d <= addr;
        tmp2_addr_d <= tmp1_addr_d;
             addr_d <= tmp2_addr_d;
    end
end
wire [N-1:0] cnt_scaled_d;
assign cnt_scaled_d = (cnt>2) ? cnt-3 : 'b0;
assign addr_AMEM = (cnt_n == last_n) ? bit_reverse(cnt_scaled_d) // Next set input
                 : (mode == 2'b10 || mode == 2'b11) ? addr     // First set input or RD(A), WR(B)
                 : (mode == 2'b01) ? addr_d                    // RD(B), WR(A)
                 : 'b0;
assign addr_BMEM = (mode == 2'b01) ? addr 
                 : (mode == 2'b10) ? addr_d
                 : 'b0;
assign addr_OMEM = (cnt_n == last_n) ? addr_d 
                 :((mode == 2'b10 && cnt_n == 1) && cnt<PNT) ? cnt 
                 : 'b0;

reg  [9:0] tmp1_addr_CROM;
wire [9:0] tmp0_addr_CROM;
assign tmp0_addr_CROM = (1 << (N-cnt_n))*cnt_k; 
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        tmp1_addr_CROM <= 0;
        //tmp2_addr_CROM <= 0;
    end else begin
        tmp1_addr_CROM <= tmp0_addr_CROM;
        //tmp2_addr_CROM <= tmp1_addr_CROM;
    end
end
assign addr_CROM = tmp1_addr_CROM;
                 
endmodule