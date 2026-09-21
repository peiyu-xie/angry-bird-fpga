`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module LEDShine(clk_LED,rst,LED,state);

input clk_LED;
input rst;
output reg [15:0]LED;
input [2:0]state;
reg tag;
reg tag_1;
reg [3:0]count;
reg clk1Hz;
parameter   start=0,set1=1,set2=2,play1=3,play2=4,success=5,fail=6;
always@(posedge clk_LED or  negedge rst)begin
    clk1Hz<=~clk1Hz;
    if(!rst)begin
        LED<=16'b0;
        tag<=1;
        count<=0;
        tag_1<=1;
    end    
    else begin
        if(state==success & clk1Hz)begin
            if(tag)begin
                LED<=16'b1100110000110011;
            end    
            else begin
                if(LED[0]==1)
                    LED<=16'b0011001111001100;
                else
                    LED<=16'b1100110000110011;       
            end
        tag<=0;
        end
        else if(state==fail)begin
          if(tag_1)begin
            count<=count+1;
            case(count)
            0: LED<=16'b0;
            1: LED<=16'b1000000110000001;
            2: LED<=16'b0100001001000010;
            3: LED<=16'b0010010000100100;
            4: LED<=16'b0001100000011000;
            5: LED<=16'b0010010000100100;
            6: LED<=16'b0100001001000010;
            7: LED<=16'b1000000110000001;
            8: LED<=16'b0;
            default: LED<=16'b0;
            endcase
            if(count==9)
                tag_1<=0;
            else
                tag_1<=tag_1; 
          end  
          else  
            LED<=16'b0;
        end
        else LED<=LED;
    end    
end

endmodule


