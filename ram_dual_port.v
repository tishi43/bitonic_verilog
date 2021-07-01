//--------------------------------------------------------------------------------------------------
// Copyright (C) 2021 tianqishi
// All rights reserved
// Design    : bitstream_p
// Author(s) : tianqishi
// Email     : tishi1@126.com
// Phone & wx: 15221864205
//-------------------------------------------------------------------------------------------------

module ram_d
(
clk,
aen,
ben
we,
addra,
addrb,
dia,
doa,
dob
);

parameter addr_bits = 8;
parameter data_bits = 16;
input     clk;
input     aen;
input     ben;
input     we;
input     [addr_bits-1:0]  addra;
input     [addr_bits-1:0]  addrb;
input     [data_bits-1:0]  dia;
output    [data_bits-1:0]  doa;
output    [data_bits-1:0]  dob;

wire      clk;
wire      aen;
wire      ben;
wire      we;
wire      [addr_bits-1:0]  addra;
wire      [addr_bits-1:0]  addrb;
wire      [data_bits-1:0]  dia;
reg       [data_bits-1:0]  doa;
reg       [data_bits-1:0]  dob;

(* ram_style = "block" *)
reg       [data_bits-1:0]  ram[0:(1 << addr_bits) -1];



initial  begin
    readmemh("data.bin",ram);
end


//read
always @ ( posedge clk )
begin
    if (ben)
        dob <= ram[addrb];
end 

always @ ( posedge clk )
begin
    if (aen)
        doa <= ram[addra];
end 

//write
always @ (posedge clk)
begin
    if (we && aen)
        ram[addra] <= dia;
end

endmodule
