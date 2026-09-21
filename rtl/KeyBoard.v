`timescale 1ns / 1ps

module KeyBoard(
input rst,
input ps2_data,
input clk_ps2,
output reg [7:0]PS2_DATA_value
);
reg [3:0]data_counter;
reg [7:0]data_temp;
always@(negedge clk_ps2 or negedge rst)begin
    if(!rst)begin
        data_counter<=0;
        data_temp<=8'b0;
        PS2_DATA_value[7:0]<=8'b0;
    end
    else begin
        if(ps2_data==0 && data_counter==0)begin
            data_counter<=data_counter+1;
        end
        else if(data_counter<=9 &&data_counter>0)begin
            case(data_counter)
            1:data_temp[0]<=ps2_data;
            2:data_temp[1]<=ps2_data;
            3:data_temp[2]<=ps2_data;
            4:data_temp[3]<=ps2_data;
            5:data_temp[4]<=ps2_data;
            6:data_temp[5]<=ps2_data;
            7:data_temp[6]<=ps2_data;
            8:data_temp[7]<=ps2_data;
            9:PS2_DATA_value[7:0]<=data_temp[7:0];
            default:data_temp<=8'b0;
            endcase
            data_counter<=data_counter+1;
        end
        else begin
            if(data_temp==8'hF0)//break code
                data_counter<=0;
            else begin
                data_counter<=0;
            end 
            data_temp[7:0]<=8'b0;   
        end
    end
end
endmodule
