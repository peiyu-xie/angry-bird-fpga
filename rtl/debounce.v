`timescale 1ns / 1ps

module debounce(
input button,clk,
output out
);
reg [23:0]counter;
assign out = counter[23]&counter[22]&button;//fpga23,22;tb0
always@(posedge clk)begin
    if(!button) counter<=0;
    else counter<=(counter[23]==1 && counter[22]==1)?0:counter+1;//fpga23,22;tb0
end
endmodule

