//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------



// used for storing intra4x4_pred_mode, ref_idx, mvp etc
// 
module ram
(
clk,
en,
we,
addr,
data_in,
data_out
);

parameter addr_bits = 8;
parameter data_bits = 16;
input     clk;
input     en;
input     we;
input     [addr_bits-1:0]  addr;
input     [data_bits-1:0]  data_in;
output    [data_bits-1:0]  data_out;

wire      clk;
wire      en;
wire      we;
wire      [addr_bits-1:0]  addr;
wire      [data_bits-1:0]  data_in;
reg       [data_bits-1:0]  data_out;

(* ram_style = "block" *)
reg       [data_bits-1:0]  ram[0:(1 << addr_bits) -1];


`ifdef RANDOM_INIT
integer  seed;
integer random_val;
integer i;
initial  begin
    seed                               = $get_initial_random_seed(); 
    random_val                         = $random(seed);
    for (i=0;i<(1 << addr_bits);i=i+1)
        ram[i] = random_val;
end
`endif


//read
always @ ( posedge clk )
begin
    if (en)
        data_out <= ram[addr];
end 

//write
always @ (posedge clk)
begin
    if (we && en)
        ram[addr] <= data_in;
end

endmodule
