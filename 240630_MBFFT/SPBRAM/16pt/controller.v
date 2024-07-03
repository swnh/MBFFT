/******************************************************************************
Copyright (c) 2022 SoC Design Laboratory, Konkuk University, South Korea
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met: redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer;
redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution;
neither the name of the copyright holders nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUPRE_G, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUPRE_G, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUPRE_G NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Uyong Lee (uyonglee@konkuk.ac.kr)

Revision History
2022.11.17: Started by Uyong Lee
*******************************************************************************/
module controller
	#(parameter N = 4) // 16pt
(
        input 		    clk, nrst, in_vld, out_rdy,
        output wire 	in_rdy, out_vld,
	    output wire	    sel_input,
	    output wire 	sel_res,
        output wire 	sel_mem,
        output wire 	we_AMEM, we_BMEM, we_OMEM,
        output wire 	[N-1:0] addr_AMEM,
        output wire 	[N-1:0] addr_BMEM,
        output wire 	[N-1:0] addr_OMEM,
        output wire 	[N-1:0] addr_CROM, // 4 bits (0 ~ 15)
        output wire 	en_REG_A,
	    output reg	    en_REG_B, en_REG_C
);

reg [N:0] cnt, cnt_in, cnt_out; // 2^5 = 32
reg [N/2:0] cstate, nstate;
reg [N/2:0] cstate_in, cstate_out, nstate_in, nstate_out; // 3 bits

// FSM
localparam
	STALL   = 3'b000, // 0
	STAGE_1 = 3'b001, // 1
	STAGE_2 = 3'b010, // 2
	STAGE_3 = 3'b011, // 3
	STAGE_4 = 3'b100, // 4
	PRE_IN  = 3'b101, // 5
	IDLE    = 3'b110, // 6
	RUN     = 3'b111, // 7
	LCNT	= 2**N + 2; // Pipeline depth = 3, (2**N + 2) + 1 cycle


always @(posedge clk)
begin
    if(!nrst) begin
       cstate     <= IDLE;
	   cstate_in  <= PRE_IN; // 1 cycle
       cstate_out <= IDLE;
    end

    else begin
       cstate     <= nstate;
	   cstate_in  <= nstate_in;
       cstate_out <= nstate_out;
    end
end

always @(*)
begin
	case(cstate_in)
		PRE_IN:
		begin
			if(in_vld)
			begin
				nstate_in <= RUN;
			end
			else
			begin
				nstate_in <= PRE_IN; 
			end
		end
		RUN:
		begin
			if(cnt_in == LCNT - 3) // Pipeline depth = 3
			begin
				nstate_in <= IDLE;
			end
			else
			begin
				nstate_in <= RUN;
			end
		end
		IDLE:
		begin
			if(cstate == STAGE_4 && cnt == 2) // 3 cycles 이후에 
			begin
				nstate_in <= RUN;
			end
			else
			begin
				nstate_in <= IDLE;
			end
		end
		default: nstate_in <= RUN;
	endcase

	case(cstate)
		IDLE:
		begin
			if(nstate_in == IDLE) 
				nstate <= STAGE_1;
			else 
				nstate <= IDLE;
		end

		STAGE_1:
		begin
			if(cnt == LCNT) // 18; 19 cycles
				nstate <= STAGE_2;
			else 
				nstate <= STAGE_1;
		end

		STAGE_2:
		begin
			if(cnt == LCNT) 
				nstate <= STAGE_3;
			else 
				nstate <= STAGE_2;
		end

		STAGE_3:
		begin
			if(cnt == LCNT) 
				nstate <= STAGE_4;
			else 
				nstate <= STAGE_3;
		end

		STAGE_4:
		begin
			if(cnt == LCNT)
				nstate <= STAGE_1;
			else
				nstate <= STAGE_4;
		end
		
		default: nstate <= IDLE;
	endcase

	case(cstate_out)
		IDLE:
		begin
			if(cstate == STAGE_4 && cnt == LCNT) 
				nstate_out <= RUN;
			else
				nstate_out <= IDLE;
		end

		RUN:
		begin
			if(cnt_out == LCNT - 2)
				nstate_out <= IDLE;
			else
				nstate_out <= RUN;
		end

		default: nstate_out <= IDLE;
	endcase
end

// Counter
// cnt
always @(posedge clk)
begin
	if(!nrst) cnt <= 0;
	else
	begin
		if(cstate == IDLE) 	 cnt <= 0;
		else if(cnt == LCNT) cnt <= 0;
		else				 cnt <= cnt + 1;
	end
end

// cnt_in
always @(posedge clk)
begin
	if(!nrst) cnt_in <= 0;
	else
	begin
		if(cstate_in == PRE_IN || cstate_in == IDLE) //  nstate_in --> cstate_in
		begin
			cnt_in <= 0;
		end
		else if(cstate_in == RUN)
		begin
			cnt_in <= cnt_in + 1;
		end
		else cnt_in <= cnt_in;
	end
end

always @(posedge clk)
begin
	if(!nrst) cnt_out <= 0;
	else
	begin
		if(cstate_out == IDLE)
		begin
			cnt_out <= 0;
		end
		else if(cnt_out == LCNT - 2)
		begin
			cnt_out <= 0;
		end
		else if(cstate_out == RUN)
		begin
			cnt_out <= cnt_out + 1;
		end
		else cnt_out <= cnt_out;
	end
end

// REG_A
assign en_REG_A = cnt[0]; // 1 for odd count

// REG_B, REG_C
always @(posedge clk) 
begin
	if(!nrst) 
    begin
		en_REG_B <= 0;
		en_REG_C <= 0;
	end
    else if(cstate != IDLE)
    begin
		en_REG_B <= en_REG_A; 	// Delayed 1 cycle from en_REG_A
		en_REG_C <= en_REG_B; 	// Delayed 1 cycle from en_REG_B
	end
	else 
    begin
		en_REG_B <= en_REG_B;
		en_REG_C <= en_REG_C;
	end 
end

// Memory Write Enable
assign we_AMEM 	= (cstate_in == RUN || (cstate == STAGE_2 && cnt > 2)) ? 0 : 1;
assign we_BMEM 	= ((cstate == STAGE_1 && cnt > 2) || (cstate == STAGE_3 && cnt > 2)) ? 0 : 1;
assign we_OMEM 	= (cstate_in == RUN && cstate == STAGE_4) ? 0 : 1;

// Handshake Signals
assign out_vld   = (cstate_out == RUN && cnt_out) ? 1 : 0;
assign in_rdy    = (cstate_in  == RUN) ? 1 : 0;

// MUX Signals
assign sel_input = in_rdy;
assign sel_res 	 = en_REG_C;  
assign sel_mem   = (cstate == STAGE_2 || cstate == STAGE_4) ? 1 : 0;

// Address
wire [N:0] cnt_dly; // Delayed counter
assign cnt_dly = (cnt > 2) ? (cnt - 3) : 0; // Count starts when cnt == 3

// 1. AMEM Address(IDLE: Bit-reversed; 0123, S1: No Change, S2: 0 <-> 1, S3: 3021, S4: Bit-reversed)
wire [N-1:0] tmp0_addr_AMEM, tmp1_addr_AMEM, tmp2_addr_AMEM, tmp3_addr_AMEM, tmp4_addr_AMEM;

assign tmp4_addr_AMEM = (!we_AMEM && cstate == STAGE_4) ? (cnt > 2  ? {cnt_dly[0], cnt_dly[1], cnt_dly[2], cnt_dly[3]} : 0) : 0;
assign tmp3_addr_AMEM = ( we_AMEM && cstate == STAGE_3) ? (cnt < 16 ? {cnt[3], cnt[0], cnt[2], cnt[1]} : 0)				    : tmp4_addr_AMEM;
assign tmp2_addr_AMEM = (!we_AMEM && cstate == STAGE_2) ? (cnt > 2  ? {cnt_dly[3], cnt_dly[2], cnt_dly[0], cnt_dly[1]} : 0) : tmp3_addr_AMEM;
assign tmp1_addr_AMEM = ( we_AMEM && cstate == STAGE_1) ? (cnt < 16 ? {cnt[3], cnt[2], cnt[1], cnt[0]} : 0) 				: tmp2_addr_AMEM;
assign tmp0_addr_AMEM = (!we_AMEM && cstate == IDLE   ) ? 			  {cnt_in[0], cnt_in[1], cnt_in[2], cnt_in[3]}		    : tmp1_addr_AMEM;
assign addr_AMEM = tmp0_addr_AMEM;

// 2. BMEM Address(S1: No Change, S2 : 3201, S3 : 3021, S4 : 0321)
wire [N-1:0] tmp1_addr_BMEM, tmp2_addr_BMEM, tmp3_addr_BMEM, tmp4_addr_BMEM;

assign tmp4_addr_BMEM = ( we_BMEM && cstate == STAGE_4) ? (cnt < 16 ? {cnt[0], cnt[3], cnt[2], cnt[1]} : 0) 				: 0;
assign tmp3_addr_BMEM = (!we_BMEM && cstate == STAGE_3) ? (cnt > 2  ? {cnt_dly[3], cnt_dly[0], cnt_dly[2], cnt_dly[1]} : 0) : tmp4_addr_BMEM;
assign tmp2_addr_BMEM = ( we_BMEM && cstate == STAGE_2) ? (cnt < 16 ? {cnt[3], cnt[2], cnt[0], cnt[1]} : 0) 			  	: tmp3_addr_BMEM;
assign tmp1_addr_BMEM = (!we_BMEM && cstate == STAGE_1) ? (cnt > 2  ? {cnt_dly[3], cnt_dly[2], cnt_dly[1], cnt_dly[0]} : 0) : tmp2_addr_BMEM;
assign addr_BMEM = tmp1_addr_BMEM;

// 3. OMEM Address 
assign addr_OMEM = we_OMEM ? (cnt < 16 ? cnt_out[3:0] : 0) : {cnt_dly[0], cnt_dly[3], cnt_dly[2], cnt_dly[1]};

// 4. CROM Address
wire [N:0] cnt_CROM; // Delayed counter
assign cnt_CROM = (cnt > 0) ? (cnt - 1) : 0; // Count starts when cnt == 1

wire [N-1:0] tmp1_addr_CROM, tmp2_addr_CROM, tmp3_addr_CROM, tmp4_addr_CROM;

assign tmp4_addr_CROM = (cstate == STAGE_4) ? (  cnt_CROM[1] + 2*cnt_CROM[2] + 4*cnt_CROM[3]) : 0;				// 0,1,2,3,4,5,6,7
assign tmp3_addr_CROM = (cstate == STAGE_3) ? (2*cnt_CROM[1] + 4*cnt_CROM[2]				) : tmp4_addr_CROM; // 0,2,4,6
assign tmp2_addr_CROM = (cstate == STAGE_2) ? (4*cnt_CROM[1] 							    ) : tmp3_addr_CROM; // 0,4,0,4
assign tmp1_addr_CROM = (cstate == STAGE_1) ? (0								       	    ) : tmp2_addr_CROM;
assign addr_CROM = (cnt > 0 && cnt < 17) ? tmp1_addr_CROM : 0;	
		
endmodule