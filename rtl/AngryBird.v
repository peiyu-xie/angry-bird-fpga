`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module AngryBird(
    input clk,
    input rst,
    input level,
    input shoot_direction,
    input [1:0]switch34,
    input [4:0]button,
    input ps2_data,
    input clk_ps2,
    
    output hsync,vsync,
    output [3:0]vga_r, vga_g, vga_b,
    output reg[6:0]segment,
    output reg[3:0]enable,
    output reg[6:0]left_segment,
    output reg[3:0]left_enable,
    output reg[15:0]LED
    
    );
    wire valid;
    wire[9:0] h_cnt,v_cnt;
    wire pclk;
    reg[11:0]vga_data;
    assign {vga_r,vga_g,vga_b} = vga_data;
    
    reg add_height,sub_height,shoot;
    reg[2:0] peak;//飛行高度
    reg[3:0]down;
    reg [2:0]direction;
    parameter level1=0,level2=1,horizontal=6,vertical=7;
    reg[2:0] segmentvalue;
    
    wire[11:0] Red_dout,Chuck_dout,Bomb_dout,KingPig_dout,MinionPig_dout,Wood_dout;
    reg [11:0] Red_addr,Chuck_addr,Bomb_addr,KingPig_addr,MinionPig_addr,Wood_addr;
    wire [1:0]MinionPig_area;
    wire KingPig_area;
    wire shoot_area;
    reg[4:0][8:0]birdx;
    reg[4:0][8:0]birdy;
    reg[2:0]bird_order; 
    wire[4:0] bird_area;
    reg[4:0][1:0]bird_type;
    parameter Red=0,Chuck=1,Bomb=2,none=3;
    
    wire [6:0]Wood_area;
    reg  [6:0][8:0]Woodx;
    reg  [6:0][8:0]Woody;   
    
    reg[8:0]KingPigx,KingPigy;
    reg[1:0][8:0]MinionPigx;
    reg[1:0][8:0]MinionPigy;    
    
    reg [2:0]state;
    parameter   start=0,set1=1,set2=2,play1=3,play2=4,success=5,fail=6;
    reg win,lose,stop;
    
    reg[1:0] Red_remain,Chuck_remain,Bomb_remain,MinionPig_remain,KingPig_remain;
    wire [7:0] PS2_DATA_value;
    reg[27:0] counter;

    debounce S3(.button(button[3]),.clk(clk),.out(sub_height));
    debounce S1(.button(button[1]),.clk(clk),.out(shoot));
    debounce S0(.button(button[0]),.clk(clk),.out(add_height));
    KeyBoard k0(rst,ps2_data,clk_ps2,PS2_DATA_value);
    SyncGeneration u0 (
		.pclk(pclk), 
		.reset(rst), 
		.hSync(hsync), 
		.vSync(vsync), 
		.dataValid(valid), 
		.hDataCnt(h_cnt), 
		.vDataCnt(v_cnt)
		);
    LEDShine l0(.clk_LED(counter[24]),.rst(rst),.LED(LED),.state(state));
    dcm_25M u1(.clk_in1(clk),.clk_out1(pclk),.reset(!rst));
       
    Red_rom r0(.clka(pclk) , .addra(Red_addr) , .douta(Red_dout));
    Chuck_rom r1(.clka(pclk) , .addra(Chuck_addr) , .douta(Chuck_dout));
    Bomb_rom r2(.clka(pclk) , .addra(Bomb_addr) , .douta(Bomb_dout));
    King_Pig_rom r3(.clka(pclk) , .addra(KingPig_addr) , .douta(KingPig_dout));
    Minion_Pig_rom r4(.clka(pclk) , .addra(MinionPig_addr) , .douta(MinionPig_dout));
    Wood_rom r5(.clka(pclk) , .addra(Wood_addr) , .douta(Wood_dout));
    always@(posedge clk or negedge rst)begin//low frequency
        if(!rst) counter<=0;
        else counter<=counter+1;
   end

    //state
    always@(posedge clk or negedge rst)begin
        if(!rst)    state<=start;
        else begin
            case(state)
            start:  state<=(level==level1)?set1:set2;
            set1: begin
                if(level==level2)   state<=start;
                else if (shoot & bird_type[bird_order]!=none)state<=play1;
                else if(win) state<=success;
                else if(lose)   state<=fail;
                else state<=state;
            end
            set2:  begin
                if(level==level1)   state<=start;
                else if (shoot & bird_type[bird_order]!=none)state<=play2;
                else if(win) state<=success;
                else if(lose)   state<=fail;
                else state<=state;
            end
            play1:begin
                if(stop) state<=set1;
                else state<=state;
            end
            play2:begin
                if(stop) state<=set2;
                else state<=state;
            end
            default:    state<=state;
            endcase
        end
    end
    //order
    always@(posedge clk or negedge rst)begin
        if(!rst)  bird_order<=0;
        else begin
        case(state)
        start : bird_order<=0;
        play1:   bird_order<=(stop)?bird_order+1:bird_order;
        play2:   bird_order<=(stop)?bird_order+1:bird_order;
        default:    bird_order<=bird_order;
        endcase
        end
    end
    
    //remain
    reg first_enter_set2;
    always@(posedge clk or negedge rst)begin
        if(!rst)begin
            Red_remain<=0;Chuck_remain<=0;Bomb_remain<=0;MinionPig_remain<=0;KingPig_remain<=0;
            first_enter_set2<=1;
        end
        else begin
            case(state)
            start :begin
                if(level==level1)begin
                    Red_remain<=1;Chuck_remain<=1;Bomb_remain<=0;
                end
                else begin
                    Red_remain<=(switch34==3)?2:switch34;Chuck_remain<=(switch34==3)?2:switch34;Bomb_remain<=1;
                end
            end
            set1: begin
                if(shoot & bird_type[bird_order]==Red) Red_remain<=Red_remain-1;
                else if(shoot & bird_type[bird_order]==Chuck) Chuck_remain<=Chuck_remain-1;
                else if(shoot & bird_type[bird_order]==Bomb) Bomb_remain<=Bomb_remain-1;
                else begin
                    Red_remain<=Red_remain;Chuck_remain<=Chuck_remain;Bomb_remain<=Bomb_remain;
                end
            end
            set2: begin
                if(first_enter_set2)begin
                    Red_remain<=switch34;
                    Chuck_remain<=switch34;
                    if(shoot)begin
                        first_enter_set2<=0;
                        if(shoot & bird_type[bird_order]==Red) Red_remain<=Red_remain-1;
                        else if(shoot & bird_type[bird_order]==Chuck) Chuck_remain<=Chuck_remain-1;
                        else if(shoot & bird_type[bird_order]==Bomb) Bomb_remain<=Bomb_remain-1;
                        else begin
                            Red_remain<=Red_remain;Chuck_remain<=Chuck_remain;Bomb_remain<=Bomb_remain;
                        end
                    end
                    else first_enter_set2<=first_enter_set2;
                end
                else begin
                    if(shoot)begin
                        if(shoot & bird_type[bird_order]==Red) Red_remain<=Red_remain-1;
                        else if(shoot & bird_type[bird_order]==Chuck) Chuck_remain<=Chuck_remain-1;
                        else if(shoot & bird_type[bird_order]==Bomb) Bomb_remain<=Bomb_remain-1;
                        else begin
                            Red_remain<=Red_remain;Chuck_remain<=Chuck_remain;Bomb_remain<=Bomb_remain;
                        end
                    end
                    else begin
                         Red_remain<=Red_remain;Chuck_remain<=Chuck_remain;Bomb_remain<=Bomb_remain;
                    end
                end
            end
            play1,play2:begin
                Red_remain<=Red_remain;Chuck_remain<=Chuck_remain;Bomb_remain<=Bomb_remain;
                MinionPig_remain<=MinionPig_remain;KingPig_remain<=KingPig_remain;
            end
            default:begin
                    Red_remain<=Red_remain;Chuck_remain<=Chuck_remain;Bomb_remain<=Bomb_remain;
                    MinionPig_remain<=MinionPig_remain;KingPig_remain<=KingPig_remain;
            end
            endcase
        end
    end
    //bird type 
    integer i;
    always@(posedge clk or negedge rst)begin
        if(!rst)  begin
            for(i=0;i<5;i=i+1)  bird_type[i]<=none;
        end
        else begin
            case(state)
            start: bird_type[bird_order]<=none;
            set1:begin
                if(Red_remain!=0 & switch34==2'b10) bird_type[bird_order]<=Red;
                else if(Chuck_remain!=0 & switch34==2'b01) bird_type[bird_order]<=Chuck;
                else    bird_type[bird_order]<=bird_type[bird_order]; 
            end
            set2:begin
                
                if(Red_remain!=0 & PS2_DATA_value==8'h2d) bird_type[bird_order]<=Red;
                else if(Chuck_remain!=0 & PS2_DATA_value==8'h35) bird_type[bird_order]<=Chuck;
                else if(Bomb_remain!=0 & PS2_DATA_value==8'h32) bird_type[bird_order]<=Bomb;
                else if(Red_remain!=0 &  bird_type[bird_order-1]==Red)  bird_type[bird_order]<=Red;
                else if(Chuck_remain!=0 & bird_type[bird_order-1]==Chuck) bird_type[bird_order]<=Chuck;
                else if(Bomb_remain!=0 & bird_type[bird_order-1]==Bomb) bird_type[bird_order]<=Bomb;
                else    bird_type[bird_order]<=bird_type[bird_order]; 
            end
            default:    bird_type[bird_order]<=bird_type[bird_order];
            endcase
        end  
    end
    //peak & direction
    always@(posedge clk or negedge rst)begin
        if(!rst) begin
            peak<=1;direction<=horizontal;
        end
        else begin
            case(state)
            start:begin
                peak<=1;
            end
            set1:begin
                direction<=horizontal;
                if(add_height & peak<5) peak<=peak+1;
                else if(sub_height & peak>1) peak<=peak-1;
                else peak<=peak;
            end
            set2:begin
                if(bird_type[bird_order]==Chuck)    direction<=(shoot_direction)?vertical:horizontal;
                if(add_height & peak<5) peak<=peak+1;
                else if(sub_height & peak>1) peak<=peak-1;
                else peak<=peak;
            end
            default:peak<=peak;
            endcase
        end
    end
    //add_sub
    reg add,sub;
    reg right,left;
    always@(button[4],button[2],counter[23],button[0],button[3])begin
        if(button[4])  add=1; 
        else if(button[2]) sub=1;
        else if(button[0]) right=1;
        else if(button[3]) left=1;
        else if(counter[24] & counter[23])begin
            add=0;sub=0;right=0;left=0;
        end
        else begin
            add=add;sub=sub;right=right;left=left;
        end      
    end
    //win and lose
    always@(posedge clk or negedge rst)begin
        if(!rst)begin
            win<=0;lose<=0;
        end
        else begin
        case(state)
        start,play1,play2:begin
            win<=0;lose<=0;
        end
        set1:begin
            if( Woodx[0]==490 & Woodx[1]==490 & Woodx[2]==490 & Woodx[3]==490 & Woodx[4]==490 & Woodx[5]==490 & Woodx[6]==490 )
                win<=1;
            else if(Red_remain==0  & Chuck_remain==0 & !( Woodx[0]==490 & Woodx[1]==490 & Woodx[2]==490 & Woodx[3]==490 & Woodx[4]==490 & Woodx[5]==490 & Woodx[6]==490 ))
                lose<=1;
            else begin
                win<=win;lose<=lose;
            end
        end
        set2:begin
            if(KingPigx==490 || (MinionPigx[0]==490 & MinionPigx[1]==490) )  win<=1;
            else if(Red_remain==0  & Chuck_remain==0 & Bomb_remain==0 & !(KingPigx==490 & MinionPigx[0]==490 & MinionPigx[1]==490)) lose<=1;
            else begin
                win<=win;lose<=lose;
            end
        end
        default:begin
            win<=win;lose<=lose;
        end
        endcase
        end
    end
    
    //stop
    always@(*)begin
        if(!rst)    stop=0;
        else begin
            case(state)
            start: stop=stop;
            set1,set2:stop=stop;
            play1,play2:begin
            
            if(birdx[bird_order]==420 || birdy[bird_order]==0
            || (birdx[bird_order]==MinionPigx[0] & birdy[bird_order]==MinionPigy[0]) 
            || (birdx[bird_order]==MinionPigx[1] & birdy[bird_order]==MinionPigy[1])
            || (birdx[bird_order]==KingPigx & birdy[bird_order]==KingPigy)  )  stop=1;
            else if((bird_type[bird_order]==Red || bird_type[bird_order]==Bomb) & ( birdx[bird_order]==420 || birdy[bird_order]==0  || (birdy[bird_order]==420 & birdx[bird_order]!=0) 
            || (birdx[bird_order]==Woodx[0] &birdy[bird_order]==Woody[0] )|| (birdx[bird_order]==Woodx[1] &birdy[bird_order]==Woody[1] ) 
            || (birdx[bird_order]==Woodx[2] &birdy[bird_order]==Woody[2] )|| (birdx[bird_order]==Woodx[3] &birdy[bird_order]==Woody[3] )
            || (birdx[bird_order]==Woodx[4] &birdy[bird_order]==Woody[4] )|| (birdx[bird_order]==Woodx[5] &birdy[bird_order]==Woody[5] )
            || (birdx[bird_order]==Woodx[6] &birdy[bird_order]==Woody[6] ) ) )
                stop=1;
            else stop=0;
            end
            default : stop=stop;
            endcase
        end
    end
            
    //bird position
    integer j;
    reg low_speed;
    always@(posedge counter[24] or negedge rst)begin
        if(!rst)begin 
            for(j=0;j<7;j=j+1)begin
                birdx[i]<=490;birdy[i]<=490;
                down<=0;
            end
            low_speed<=0;
        end
        else begin
            low_speed<=~low_speed;
            case(state)
            start:begin
                birdx[bird_order]<=490;birdy[bird_order]<=490;
            end
            set1:begin
                down<=peak*2;
                if(birdx[bird_order]==490 & birdy[bird_order]==490)begin
                    birdx[bird_order]<=0;birdy[bird_order]<=420;
                end
                else if(add & birdy[bird_order]>=360)   birdy[bird_order]<=birdy[bird_order]-60;
                else if(sub & birdy[bird_order]<=360)   birdy[bird_order]<=birdy[bird_order]+60;
                else begin
                    birdx[bird_order]<=birdx[bird_order];birdy[bird_order]<=birdy[bird_order];
                end
            end
            set2:begin
                down<=peak*2;
                if(birdx[bird_order]==490 & birdy[bird_order]==490)begin
                    birdx[bird_order]<=0;birdy[bird_order]<=420;
                end
                else if(add & birdy[bird_order]>=360 & birdx[bird_order]==0)   birdy[bird_order]<=birdy[bird_order]-60;
                else if(sub & birdy[bird_order]<=360 & birdx[bird_order]==0)   birdy[bird_order]<=birdy[bird_order]+60;
                else if (right & bird_type[bird_order]==Chuck & birdx[bird_order]<=60 & birdy[bird_order]==420) birdx[bird_order]<=birdx[bird_order]+60;
                else if (left & bird_type[bird_order]==Chuck & birdx[bird_order]>=60 & birdy[bird_order]==420) birdx[bird_order]<=birdx[bird_order]-60;
                else begin
                    birdx[bird_order]<=birdx[bird_order];birdy[bird_order]<=birdy[bird_order];
                end
            end
            play1,play2:begin
                down<=(down==0)?down:down-1;
                if(bird_type[bird_order]==Chuck)begin
                    if(direction==horizontal)
                        birdx[bird_order]<=(stop)?birdx[bird_order]:birdx[bird_order]+60;
                    else if (direction==vertical)
                        birdy[bird_order]<=(stop)?birdy[bird_order]:birdy[bird_order]-60;
                    else begin
                        birdx[bird_order]<=birdx[bird_order];birdy[bird_order]<=birdy[bird_order];
                    end
                end
                else if(bird_type[bird_order]==Red || bird_type[bird_order]==Bomb)begin
                    if(stop)begin
                         birdx[bird_order]<=birdx[bird_order];birdy[bird_order]<=birdy[bird_order];
                    end
                    else if(down==0)begin
                        birdx[bird_order]<=(low_speed)?birdx[bird_order]+60:birdx[bird_order];birdy[bird_order]<=(low_speed)?birdy[bird_order]+60:birdy[bird_order];
                    end
                    else begin
                        birdx[bird_order]<=(low_speed)?birdx[bird_order]+60:birdx[bird_order];birdy[bird_order]<=(low_speed)?birdy[bird_order]-60:birdy[bird_order];
                    end
                end
                else begin
                    birdx[bird_order]<=birdx[bird_order];birdy[bird_order]<=birdy[bird_order];
                end
            end
            default:begin
                birdx[bird_order]<=birdx[bird_order];birdy[bird_order]<=birdy[bird_order];
            end
            endcase
        end
    end
    //pig position
    always@(posedge clk or negedge rst)begin
        if(!rst)begin
            MinionPigx[0]<=0;MinionPigy[0]<=0;
            MinionPigx[1]<=0;MinionPigy[1]<=0;
            KingPigx<=0;KingPigy<=0;
        end
        else begin
            case(state)
            start:begin
                if(level == level2)begin
                    MinionPigx[0]<=300;MinionPigy[0]<=240;
                    MinionPigx[1]<=420;MinionPigy[1]<=420;
                    KingPigx<=0;KingPigy<=0;
                end
                else begin
                    MinionPigx[0]<=490;MinionPigy[0]<=490;
                    MinionPigx[1]<=490;MinionPigy[1]<=490;
                    KingPigx<=490;KingPigy<=490;
                end 
            end
            set1,set2,play1:begin
                if(bird_type[bird_order-1]==Bomb & (MinionPigx[0]>=birdx[bird_order-1]-60 & MinionPigx[0]<=birdx[bird_order-1]+60 & MinionPigy[0]>=birdy[bird_order-1]-60 & MinionPigy[0]<=birdy[bird_order-1]+60))begin
                        MinionPigx[0]<=490;MinionPigy[0]<=490;
                end
                else if(bird_type[bird_order-1]==Bomb & (MinionPigx[1]>=birdx[bird_order-1]-60 & MinionPigx[1]<=birdx[bird_order-1]+60 & MinionPigy[1]>=birdy[bird_order-1]-60 & MinionPigy[1]<=birdy[bird_order-1]+60))begin
                        MinionPigx[1]<=490;MinionPigy[1]<=490;
                end
                else if(bird_type[bird_order-1]==Bomb & (KingPigx>=birdx[bird_order-1]-60 & KingPigx<=birdx[bird_order-1]+60 & KingPigy>=birdy[bird_order-1]-60 & KingPigy<=birdy[bird_order-1]+60))begin
                        KingPigx<=490;KingPigy<=490;
                end
                else begin
                    MinionPigx[0]<=MinionPigx[0];MinionPigy[0]<=MinionPigy[0];
                    MinionPigx[1]<=MinionPigx[1];MinionPigy[1]<=MinionPigy[1];
                    KingPigx<=KingPigx;KingPigy<=KingPigy;
                end
            end
            play2:begin
                MinionPigx[0]<=(birdx[bird_order]==MinionPigx[0] & birdy[bird_order]==MinionPigy[0] )?490:MinionPigx[0];
                MinionPigy[0]<=(birdx[bird_order]==MinionPigx[0] & birdy[bird_order]==MinionPigy[0] )?490:MinionPigy[0];
                MinionPigx[1]<=(birdx[bird_order]==MinionPigx[1] & birdy[bird_order]==MinionPigy[1] )?490:MinionPigx[1];
                MinionPigy[1]<=(birdx[bird_order]==MinionPigx[1] & birdy[bird_order]==MinionPigy[1] )?490:MinionPigy[1];
                KingPigx<=(birdx[bird_order]==KingPigx & birdy[bird_order]==KingPigy)?490:KingPigx;
                KingPigy<=(birdx[bird_order]==KingPigx & birdy[bird_order]==KingPigy)?490:KingPigy;
            end 
            endcase
        end
    end
   integer l;
    //wood position
    always@(posedge clk or negedge rst)begin
        if(!rst)begin
            for(l=0;l<7;l=l+1)begin
                Woodx[l]<=490;Woody[l]<=490;
            end
        end
        else begin
            case(state)
            start:begin
                if(level==level1)begin
                    Woodx[0]<=300;Woody[0]<=360;
                    Woodx[1]<=180;Woody[1]<=420;
                    Woodx[2]<=240;Woody[2]<=420;
                    Woodx[3]<=300;Woody[3]<=420;
                    Woodx[4]<=360;Woody[4]<=420;
                    Woodx[5]<=420;Woody[5]<=420;
                end
                else begin
                    Woodx[0]<=360;Woody[0]<=300;
                    Woodx[1]<=420;Woody[1]<=300;
                    Woodx[2]<=300;Woody[2]<=360;
                    Woodx[3]<=360;Woody[3]<=360;
                    Woodx[4]<=420;Woody[4]<=360;
                    Woodx[5]<=300;Woody[5]<=420;
                    Woodx[6]<=360;Woody[6]<=420;
                end
            end
            set1,set2:begin
                for(l=0;l<7;l=l+1)begin
                    if(bird_type[bird_order-1]==Bomb & (Woodx[l]>=birdx[bird_order-1]-60 & Woodx[l]<=birdx[bird_order-1]+60 & Woody[l]>=birdy[bird_order-1]-60 & Woody[l]<=birdy[bird_order-1]+60))begin
                        Woodx[l]<=490;Woody[l]<=490;
                    end
                    else begin
                        Woodx[l]<=Woodx[l];Woody[l]<=Woody[l];
                    end
                end
            end
            play1,play2:begin
                for(l=0;l<7;l=l+1)begin
                    Woodx[l]<=(birdx[bird_order] ==Woodx[l] & birdy[bird_order] ==Woody[l] )?490:Woodx[l];
                    Woody[l]<=(birdx[bird_order] ==Woodx[l] & birdy[bird_order] ==Woody[l] )?490:Woody[l];
                end
            end
            default:begin
                Woodx[0]<=Woodx[0];Woody[0]<=Woody[0];
                Woodx[1]<=Woodx[1];Woody[1]<=Woody[1];
                Woodx[2]<=Woodx[2];Woody[2]<=Woody[2];
                Woodx[3]<=Woodx[3];Woody[3]<=Woody[3];
                Woodx[4]<=Woodx[4];Woody[4]<=Woody[4];
                Woodx[5]<=Woodx[5];Woody[5]<=Woody[5];
                Woodx[6]<=Woodx[6];Woody[6]<=Woody[6];
            end
            endcase
        end
    end
    
    //bird area
    genvar k;
    generate
    for(k=0;k<5;k=k+1)begin
        assign bird_area[k]=(v_cnt>=birdy[k] & v_cnt<=birdy[k]+59 & h_cnt>=birdx[k] & h_cnt<=birdx[k]+59)?1:0;
    end
    endgenerate
    
    //pig area
    assign MinionPig_area[0]=(v_cnt>=MinionPigy[0] & v_cnt<=MinionPigy[0]+59 & h_cnt>=MinionPigx[0] & h_cnt<=MinionPigx[0]+59)?1:0;
    assign MinionPig_area[1]=(v_cnt>=MinionPigy[1] & v_cnt<=MinionPigy[1]+59 & h_cnt>=MinionPigx[1] & h_cnt<=MinionPigx[1]+59)?1:0;
    assign KingPig_area=(v_cnt>=KingPigy & v_cnt<=KingPigy+59 & h_cnt>=KingPigx & h_cnt<=KingPigx+59)?1:0;
    //wood area
    genvar m;
    generate
    for(m=0;m<7;m=m+1)begin
        assign Wood_area[m]=(v_cnt>=Woody[m] & v_cnt<=Woody[m]+59 & h_cnt>=Woodx[m] & h_cnt<=Woodx[m]+59)?1:0;
    end
    endgenerate
    //vgs data
    always@(posedge pclk or negedge rst)begin
        if(!rst)    vga_data <= 12'd0;
        else if(valid)begin
            if(v_cnt<=3 || v_cnt>=477 || h_cnt<=3 || h_cnt>=477 )   vga_data <= 12'hfff;//外框
            else if  ( (v_cnt>=58 & v_cnt<=61) || (v_cnt>=118 & v_cnt<=121) || (v_cnt>=178 & v_cnt<=181) || (v_cnt>=238 & v_cnt<=241) || (v_cnt>=298 & v_cnt<=301) || (v_cnt>=358 & v_cnt<=361) || (v_cnt>=418 & v_cnt<=421))
                    vga_data <= 12'hfff;//橫線
            else if  ( (h_cnt>=58 & h_cnt<=61) || (h_cnt>=118 & h_cnt<=121) || (h_cnt>=178 & h_cnt<=181) || (h_cnt>=238 & h_cnt<=241) || (h_cnt>=298 & h_cnt<=301) || (h_cnt>=358 & h_cnt<=361) || (h_cnt>=418 & h_cnt<=421))
                    vga_data <= 12'hfff;//直線
                    
                           
            else if(bird_area[4]==1 & bird_type[4]==Red & Red_dout!=12'h587)begin    vga_data <=Red_dout; end
                    else if(bird_area[4]==1 & bird_type[4]==Chuck & Chuck_dout!=12'h587)begin    vga_data <= Chuck_dout;end 
                    else if(bird_area[4]==1 & bird_type[4]==Bomb & Bomb_dout!=12'h587)begin    vga_data <= Bomb_dout;end
           
            else if(bird_area[3]==1 & bird_type[3]==Red & Red_dout!=12'h587)begin    vga_data <=Red_dout;end
                    else if(bird_area[3]==1 &bird_type[3]==Chuck & Chuck_dout!=12'h587)begin    vga_data <=Chuck_dout;end
                    else if(bird_area[3]==1 &bird_type[3]==Bomb & Bomb_dout!=12'h587)begin    vga_data <=Bomb_dout;end
           
            else if(bird_area[2]==1 & bird_type[2]==Red & Red_dout!=12'h587)begin    vga_data <=Red_dout;end
                    else if(bird_area[2]==1 & bird_type[2]==Chuck & Chuck_dout!=12'h587)begin    vga_data <=Chuck_dout;end
                    else if(bird_area[2]==1 & bird_type[2]==Bomb & Bomb_dout!=12'h587) begin    vga_data <=Bomb_dout;end
                
           else if(bird_area[1]==1 & bird_type[1]==Red & Red_dout!=12'h587)begin    vga_data <=Red_dout;end
                    else if(bird_area[1]==1 & bird_type[1]==Chuck & Chuck_dout!=12'h587)begin    vga_data <=Chuck_dout;end
                    else if(bird_area[1]==1 & bird_type[1]==Bomb & Bomb_dout!=12'h587) begin    vga_data <=Bomb_dout;end
            
           else if(bird_area[0]==1 & bird_type[0]==Red & Red_dout!=12'h587)begin    vga_data <=Red_dout;end
                    else if(bird_area[0]==1 & bird_type[0]==Chuck & Chuck_dout!=12'h587 )begin    vga_data <=Chuck_dout;end
                    else if(bird_area[0]==1 & bird_type[0]==Bomb & Bomb_dout!=12'h587) begin    vga_data <=Bomb_dout;end
           else if(Wood_area[0] || Wood_area[1] || Wood_area[2] || Wood_area[3] || Wood_area[4] || Wood_area[5] || Wood_area[6] )   vga_data <=Wood_dout;
           else if((MinionPig_area[0] || MinionPig_area[1]) & MinionPig_dout!=12'h587)  vga_data<=MinionPig_dout;
           else if(KingPig_area & KingPig_dout!=12'h587)    vga_data<=KingPig_dout;
           
           else if(h_cnt>=0 & h_cnt<=60 & v_cnt<=480 & v_cnt>=300)  vga_data <=12'hfd6;
           else if(level==level2  & h_cnt>=60 & h_cnt<=180 & v_cnt<=480 & v_cnt>=420)   vga_data <=12'hfd6;                
            else  vga_data <= 12'h9ad;
        end 
        else  vga_data <= 12'h000;
    end

//bird addr
always@(posedge pclk or negedge rst)begin
        if(!rst)  begin
          Red_addr<=0;Chuck_addr<=0;Bomb_addr<=0;
        end
        else if(valid)begin
                    if(bird_area[4]==1 & bird_type[4]==Red)begin    Red_addr<=h_cnt-birdx[4]+60*(v_cnt-birdy[4]);end
                    else if(bird_area[4]==1 & bird_type[4]==Chuck)begin    Chuck_addr<=h_cnt-birdx[4]+60*(v_cnt-birdy[4]);end 
                    else if(bird_area[4]==1 & bird_type[4]==Bomb)begin    Bomb_addr<=h_cnt-birdx[4]+60*(v_cnt-birdy[4]);end
                    
                    else if(bird_area[3]==1 & bird_type[3]==Red)begin Red_addr<=h_cnt-birdx[3]+60*(v_cnt-birdy[3]);end
                    else if(bird_area[3]==1 & bird_type[3]==Chuck)begin    Chuck_addr<=h_cnt-birdx[3]+60*(v_cnt-birdy[3]);end
                    else if(bird_area[3]==1 & bird_type[3]==Bomb)begin    Bomb_addr<=h_cnt-birdx[3]+60*(v_cnt-birdy[3]);end
                    
                    else if(bird_area[2]==1 & bird_type[2]==Red)begin   Red_addr<=h_cnt-birdx[2]+60*(v_cnt-birdy[2]);end
                    else if(bird_area[2]==1 & bird_type[2]==Chuck)begin    Chuck_addr<=h_cnt-birdx[2]+60*(v_cnt-birdy[2]);end
                    else if(bird_area[2]==1 & bird_type[2]==Bomb) begin    Bomb_addr<=h_cnt-birdx[2]+60*(v_cnt-birdy[2]);end
                    
                    else if(bird_area[1]==1 & bird_type[1]==Red)begin    Red_addr<=h_cnt-birdx[1]+60*(v_cnt-birdy[1]);end
                    else if(bird_area[1]==1 & bird_type[1]==Chuck)begin    Chuck_addr<=h_cnt-birdx[1]+60*(v_cnt-birdy[1]);end
                    else if(bird_area[1]==1 & bird_type[1]==Bomb) begin    Bomb_addr<=h_cnt-birdx[1]+60*(v_cnt-birdy[1]);end
                    
                    else if(bird_area[0]==1 & bird_type[0]==Red)begin    Red_addr<=h_cnt-birdx[0]+60*(v_cnt-birdy[0]);end
                    else if(bird_area[0]==1 & bird_type[0]==Chuck)begin    Chuck_addr<=h_cnt-birdx[0]+60*(v_cnt-birdy[0]);end
                    else if(bird_area[0]==1 & bird_type[0]==Bomb ) begin    Bomb_addr<=h_cnt-birdx[0]+60*(v_cnt-birdy[0]);end
                    else begin
                        Red_addr<=0;Chuck_addr<=0;Bomb_addr<=0;
                    end

        end 
        else  begin
            Red_addr<=0;Chuck_addr<=0;Bomb_addr<=0;
        end
    end    
    
//Pig addr
always@(posedge pclk or negedge rst)begin
        if(!rst) begin 
            MinionPig_addr[0]<=0;MinionPig_addr[1]<=0;KingPig_addr<=0;
        end
        else begin
            if(MinionPig_area[0])   MinionPig_addr<=h_cnt-MinionPigx[0]+60*(v_cnt-MinionPigy[0]);
            else if(MinionPig_area[1])   MinionPig_addr<=h_cnt-MinionPigx[1]+60*(v_cnt-MinionPigy[1]);
            else if(KingPig_area)   KingPig_addr<=h_cnt-KingPigx+60*(v_cnt-KingPigy);
            else begin
                MinionPig_addr<=0;KingPig_addr<=0;
            end
        end
end
//Wood addr
always@(posedge pclk or negedge rst)begin
        if(!rst)  Wood_addr<=0;
        else begin
            if(Wood_area[0])    Wood_addr<=h_cnt-Woodx[0]+60*(v_cnt-Woody[0]);
            else if(Wood_area[1])    Wood_addr<=h_cnt-Woodx[1]+60*(v_cnt-Woody[1]);
            else if(Wood_area[2])    Wood_addr<=h_cnt-Woodx[2]+60*(v_cnt-Woody[2]);
            else if(Wood_area[3])    Wood_addr<=h_cnt-Woodx[3]+60*(v_cnt-Woody[3]);
            else if(Wood_area[4])    Wood_addr<=h_cnt-Woodx[4]+60*(v_cnt-Woody[4]);
            else if(Wood_area[5])    Wood_addr<=h_cnt-Woodx[5]+60*(v_cnt-Woody[5]);
            else if(Wood_area[6])    Wood_addr<=h_cnt-Woodx[6]+60*(v_cnt-Woody[6]);
            else Wood_addr<=0;
        end
end
    //segmentvalue
always@(counter[18],peak,direction,Red_remain,Chuck_remain,Bomb_remain)begin
    case(counter[19:18])
        0:begin
           segmentvalue<=(level==level2 & bird_type[bird_order]==Chuck)?direction:peak;
           enable<=4'b1000;
        end
        1:begin
            segmentvalue<={1'b0,Red_remain}; enable<=4'b0100;
        end
        2:begin
             segmentvalue<={1'b0,Chuck_remain}; enable<=4'b0010;//{1'b0,Chuck_remain}
        end
        3:begin
              segmentvalue<={1'b0,Bomb_remain}; enable<=4'b0001;//{1'b0,Bomb_remain}
        end
     endcase
end
   //segment
   always@(posedge clk or negedge rst)begin
        if(!rst)begin
            segment<=0;left_segment<=0;
        end
        else begin
            left_enable<=4'b1000;
            left_segment<=(level==level1)?7'b0110000:7'b1101101;
            case(segmentvalue)
                0: segment=7'b1111110;
                1: segment=7'b0110000;
                2: segment=7'b1101101;
                3: segment=7'b1111001;
                4: segment=7'b0110011;
                5: segment=7'b1011011;
                6: segment=7'b0001001;
                7: segment=7'b0010100;
                default:segment=7'b0000000;
            endcase
        end
   end

endmodule
