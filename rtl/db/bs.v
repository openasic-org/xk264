//-------------------------------------------------------------------
//                                                                 
//  COPYRIGHT (C) 2011, VIPcore Group, Fudan University
//                                                                  
//  THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE      
//  EXPRESSED WRITTEN CONSENT OF VIPcore Group
//                                                                  
//  VIPcore       : http://soc.fudan.edu.cn/vip    
//  IP Owner 	  : Yibo FAN
//  Contact       : fanyibo@fudan.edu.cn             
//-------------------------------------------------------------------
// Filename       : bs.v
// Author         : shen weiwei
// Created        : 2011-01-07
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
//------------------------------------------------------------------- 

module bs ( clk,
			rst,
            x, y,
			qp_c,
			state,
			count_bs, count_y, count_cbcr,
			code_T,
            transform_type_C,  mbtype_C,   
            
            non_zero_count_C1,  non_zero_count_C2,  non_zero_count_C3,  non_zero_count_C4,
            non_zero_count_C5,  non_zero_count_C6,  non_zero_count_C7,  non_zero_count_C8,
            non_zero_count_C9,  non_zero_count_C10, non_zero_count_C11, non_zero_count_C12,
            non_zero_count_C13, non_zero_count_C14, non_zero_count_C15, non_zero_count_C16,
            
            mv_C1,  mv_C2,  mv_C3,  mv_C4,
            mv_C5,  mv_C6,  mv_C7,  mv_C8,
            mv_C9,  mv_C10, mv_C11, mv_C12,
            mv_C13, mv_C14, mv_C15, mv_C16,      

            
            
            code_T_out, add_out_T, write_en_T,
            add_T, read_en_T,
            
            bs_luma,
            
            bs_chroma_1,
			bs_chroma_2,
			
			qp_1,
			qp_2
			
            );

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************


input clk, rst;
input [7:0] x, y;
input [5:0] qp_c;

input [1:0] state;
input [2:0] count_bs;
input [5:0] count_y;
input [5:0] count_cbcr;


input [27:0] code_T;

input transform_type_C;
input mbtype_C;

input non_zero_count_C1,  non_zero_count_C2,  non_zero_count_C3,  non_zero_count_C4;
input non_zero_count_C5,  non_zero_count_C6,  non_zero_count_C7,  non_zero_count_C8;
input non_zero_count_C9,  non_zero_count_C10, non_zero_count_C11, non_zero_count_C12;
input non_zero_count_C13, non_zero_count_C14, non_zero_count_C15, non_zero_count_C16;

input[19:0] mv_C1,  mv_C2,  mv_C3,  mv_C4;
input[19:0] mv_C5,  mv_C6,  mv_C7,  mv_C8;
input[19:0] mv_C9,  mv_C10, mv_C11, mv_C12;
input[19:0] mv_C13, mv_C14, mv_C15, mv_C16;     

output [27:0] code_T_out;
output [8:0] add_out_T;
output write_en_T;

output [8:0] add_T;
output read_en_T;

output [2:0] bs_luma;
output [2:0] bs_chroma_1;
output [2:0] bs_chroma_2;

output [5:0] qp_1;
output [5:0] qp_2; 



// ********************************************
//                                             
//    Parameter DECLARATION                     
//                                             
// ********************************************

parameter IDLE = 2'b00, BS = 2'b01, Y = 2'b10, CbCr = 2'b11;


// ********************************************      
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************

reg [2:0] bs1_reg;
reg [2:0] bs2_reg;
reg [2:0] bs3_reg;
reg [2:0] bs4_reg;
reg [2:0] bs5_reg;
reg [2:0] bs6_reg;
reg [2:0] bs7_reg;
reg [2:0] bs8_reg;
reg [2:0] bs9_reg;
reg [2:0] bs10_reg;
reg [2:0] bs11_reg;
reg [2:0] bs12_reg;
reg [2:0] bs13_reg;
reg [2:0] bs14_reg;
reg [2:0] bs15_reg;
reg [2:0] bs16_reg;
reg [2:0] bs17_reg;
reg [2:0] bs18_reg;
reg [2:0] bs19_reg;
reg [2:0] bs20_reg;
reg [2:0] bs21_reg;
reg [2:0] bs22_reg;
reg [2:0] bs23_reg;
reg [2:0] bs24_reg;
reg [2:0] bs25_reg;
reg [2:0] bs26_reg;
reg [2:0] bs27_reg;
reg [2:0] bs28_reg;
reg [2:0] bs29_reg;
reg [2:0] bs30_reg;
reg [2:0] bs31_reg;
reg [2:0] bs32_reg;


reg [27:0] code_T_out;
reg [8:0] add_out_T;
reg write_en_T;


reg [27:0] code_T1_reg;
reg [27:0] code_T2_reg;
reg [27:0] code_T3_reg;
reg [27:0] code_T4_reg;

reg [21:0] code_L1_reg;
reg [21:0] code_L2_reg;
reg [21:0] code_L3_reg;
reg [21:0] code_L4_reg;


// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************

reg [8:0] add_T;
reg read_en_T;

wire signed [9:0] mvx_L1; wire signed [9:0] mvy_L1;
wire signed [9:0] mvx_L2; wire signed [9:0] mvy_L2;
wire signed [9:0] mvx_L3; wire signed [9:0] mvy_L3;
wire signed [9:0] mvx_L4; wire signed [9:0] mvy_L4;

wire signed [9:0] mvx_T1; wire signed [9:0] mvy_T1;
wire signed [9:0] mvx_T2; wire signed [9:0] mvy_T2;
wire signed [9:0] mvx_T3; wire signed [9:0] mvy_T3;
wire signed [9:0] mvx_T4; wire signed [9:0] mvy_T4;

wire signed [9:0] mvx_C1;  wire signed [9:0] mvy_C1; 
wire signed [9:0] mvx_C2;  wire signed [9:0] mvy_C2; 
wire signed [9:0] mvx_C3;  wire signed [9:0] mvy_C3; 
wire signed [9:0] mvx_C4;  wire signed [9:0] mvy_C4; 
wire signed [9:0] mvx_C5;  wire signed [9:0] mvy_C5; 
wire signed [9:0] mvx_C6;  wire signed [9:0] mvy_C6; 
wire signed [9:0] mvx_C7;  wire signed [9:0] mvy_C7; 
wire signed [9:0] mvx_C8;  wire signed [9:0] mvy_C8; 
wire signed [9:0] mvx_C9;  wire signed [9:0] mvy_C9; 
wire signed [9:0] mvx_C10; wire signed [9:0] mvy_C10;
wire signed [9:0] mvx_C11; wire signed [9:0] mvy_C11;
wire signed [9:0] mvx_C12; wire signed [9:0] mvy_C12;
wire signed [9:0] mvx_C13; wire signed [9:0] mvy_C13;
wire signed [9:0] mvx_C14; wire signed [9:0] mvy_C14;
wire signed [9:0] mvx_C15; wire signed [9:0] mvy_C15;
wire signed [9:0] mvx_C16; wire signed [9:0] mvy_C16;

wire signed [10:0] mvx_bs_1 ;   wire signed [10:0] mvy_bs_1 ;
wire signed [10:0] mvx_bs_2 ;   wire signed [10:0] mvy_bs_2 ;
wire signed [10:0] mvx_bs_3 ;   wire signed [10:0] mvy_bs_3 ;
wire signed [10:0] mvx_bs_4 ;   wire signed [10:0] mvy_bs_4 ;
wire signed [10:0] mvx_bs_5 ;   wire signed [10:0] mvy_bs_5 ;
wire signed [10:0] mvx_bs_6 ;   wire signed [10:0] mvy_bs_6 ;
wire signed [10:0] mvx_bs_7 ;   wire signed [10:0] mvy_bs_7 ;
wire signed [10:0] mvx_bs_8 ;   wire signed [10:0] mvy_bs_8 ;
wire signed [10:0] mvx_bs_9 ;   wire signed [10:0] mvy_bs_9 ;
wire signed [10:0] mvx_bs_10;   wire signed [10:0] mvy_bs_10;
wire signed [10:0] mvx_bs_11;   wire signed [10:0] mvy_bs_11;
wire signed [10:0] mvx_bs_12;   wire signed [10:0] mvy_bs_12;
wire signed [10:0] mvx_bs_13;   wire signed [10:0] mvy_bs_13;
wire signed [10:0] mvx_bs_14;   wire signed [10:0] mvy_bs_14;
wire signed [10:0] mvx_bs_15;   wire signed [10:0] mvy_bs_15;
wire signed [10:0] mvx_bs_16;   wire signed [10:0] mvy_bs_16;
wire signed [10:0] mvx_bs_17;   wire signed [10:0] mvy_bs_17;
wire signed [10:0] mvx_bs_18;   wire signed [10:0] mvy_bs_18;
wire signed [10:0] mvx_bs_19;   wire signed [10:0] mvy_bs_19;
wire signed [10:0] mvx_bs_20;   wire signed [10:0] mvy_bs_20;
wire signed [10:0] mvx_bs_21;   wire signed [10:0] mvy_bs_21;
wire signed [10:0] mvx_bs_22;   wire signed [10:0] mvy_bs_22;
wire signed [10:0] mvx_bs_23;   wire signed [10:0] mvy_bs_23;
wire signed [10:0] mvx_bs_24;   wire signed [10:0] mvy_bs_24;
wire signed [10:0] mvx_bs_25;   wire signed [10:0] mvy_bs_25;
wire signed [10:0] mvx_bs_26;   wire signed [10:0] mvy_bs_26;
wire signed [10:0] mvx_bs_27;   wire signed [10:0] mvy_bs_27;
wire signed [10:0] mvx_bs_28;   wire signed [10:0] mvy_bs_28;
wire signed [10:0] mvx_bs_29;   wire signed [10:0] mvy_bs_29;
wire signed [10:0] mvx_bs_30;   wire signed [10:0] mvy_bs_30;
wire signed [10:0] mvx_bs_31;   wire signed [10:0] mvy_bs_31;
wire signed [10:0] mvx_bs_32;   wire signed [10:0] mvy_bs_32;

wire [10:0] mvx_abs_1 ;   wire [10:0] mvy_abs_1 ;
wire [10:0] mvx_abs_2 ;   wire [10:0] mvy_abs_2 ;
wire [10:0] mvx_abs_3 ;   wire [10:0] mvy_abs_3 ;
wire [10:0] mvx_abs_4 ;   wire [10:0] mvy_abs_4 ;
wire [10:0] mvx_abs_5 ;   wire [10:0] mvy_abs_5 ;
wire [10:0] mvx_abs_6 ;   wire [10:0] mvy_abs_6 ;
wire [10:0] mvx_abs_7 ;   wire [10:0] mvy_abs_7 ;
wire [10:0] mvx_abs_8 ;   wire [10:0] mvy_abs_8 ;
wire [10:0] mvx_abs_9 ;   wire [10:0] mvy_abs_9 ;
wire [10:0] mvx_abs_10;   wire [10:0] mvy_abs_10;
wire [10:0] mvx_abs_11;   wire [10:0] mvy_abs_11;
wire [10:0] mvx_abs_12;   wire [10:0] mvy_abs_12;
wire [10:0] mvx_abs_13;   wire [10:0] mvy_abs_13;
wire [10:0] mvx_abs_14;   wire [10:0] mvy_abs_14;
wire [10:0] mvx_abs_15;   wire [10:0] mvy_abs_15;
wire [10:0] mvx_abs_16;   wire [10:0] mvy_abs_16;
wire [10:0] mvx_abs_17;   wire [10:0] mvy_abs_17;
wire [10:0] mvx_abs_18;   wire [10:0] mvy_abs_18;
wire [10:0] mvx_abs_19;   wire [10:0] mvy_abs_19;
wire [10:0] mvx_abs_20;   wire [10:0] mvy_abs_20;
wire [10:0] mvx_abs_21;   wire [10:0] mvy_abs_21;
wire [10:0] mvx_abs_22;   wire [10:0] mvy_abs_22;
wire [10:0] mvx_abs_23;   wire [10:0] mvy_abs_23;
wire [10:0] mvx_abs_24;   wire [10:0] mvy_abs_24;
wire [10:0] mvx_abs_25;   wire [10:0] mvy_abs_25;
wire [10:0] mvx_abs_26;   wire [10:0] mvy_abs_26;
wire [10:0] mvx_abs_27;   wire [10:0] mvy_abs_27;
wire [10:0] mvx_abs_28;   wire [10:0] mvy_abs_28;
wire [10:0] mvx_abs_29;   wire [10:0] mvy_abs_29;
wire [10:0] mvx_abs_30;   wire [10:0] mvy_abs_30;
wire [10:0] mvx_abs_31;   wire [10:0] mvy_abs_31;
wire [10:0] mvx_abs_32;   wire [10:0] mvy_abs_32;

reg [2:0] bs1;
reg [2:0] bs2;
reg [2:0] bs3;
reg [2:0] bs4;

reg [2:0] bs17;
reg [2:0] bs18;
reg [2:0] bs19;
reg [2:0] bs20;

reg [2:0] bs5;
reg [2:0] bs6;
reg [2:0] bs7;
reg [2:0] bs8;
reg [2:0] bs9;
reg [2:0] bs10;
reg [2:0] bs11;
reg [2:0] bs12;
reg [2:0] bs13;
reg [2:0] bs14;
reg [2:0] bs15;
reg [2:0] bs16;

reg [2:0] bs21;
reg [2:0] bs22;
reg [2:0] bs23;
reg [2:0] bs24;
reg [2:0] bs25;
reg [2:0] bs26;
reg [2:0] bs27;
reg [2:0] bs28;
reg [2:0] bs29;
reg [2:0] bs30;
reg [2:0] bs31;
reg [2:0] bs32;

// *******************************************
//                                             
//    Combinational Logic                         
//                                             
// ********************************************

//load
always@(*)begin
    if(state==BS)
        add_T = (x<<2) + count_bs;
    else
        add_T =  'd0;
end 

always@(*) begin
    if(y!='d0)begin
		if((state==BS) && (count_bs=='d0||count_bs=='d1||count_bs=='d2||count_bs=='d3))
			read_en_T = 1'b1;
		else
			read_en_T = 1'b0;
	end
	else 
		read_en_T = 1'b0;
end

//caculate
assign mvx_L1 = code_L1_reg[9:0]; assign mvy_L1 = code_L1_reg[19:10]; 
assign mvx_L2 = code_L2_reg[9:0]; assign mvy_L2 = code_L2_reg[19:10]; 
assign mvx_L3 = code_L3_reg[9:0]; assign mvy_L3 = code_L3_reg[19:10]; 
assign mvx_L4 = code_L4_reg[9:0]; assign mvy_L4 = code_L4_reg[19:10]; 

assign mvx_T1 = code_T1_reg[9:0]; assign mvy_T1 = code_T1_reg[19:10]; 
assign mvx_T2 = code_T2_reg[9:0]; assign mvy_T2 = code_T2_reg[19:10]; 
assign mvx_T3 = code_T3_reg[9:0]; assign mvy_T3 = code_T3_reg[19:10]; 
assign mvx_T4 = code_T4_reg[9:0]; assign mvy_T4 = code_T4_reg[19:10]; 

assign mvx_C1  = mv_C1[9:0];  assign mvy_C1  = mv_C1[19:10]; 
assign mvx_C2  = mv_C2[9:0];  assign mvy_C2  = mv_C2[19:10]; 
assign mvx_C3  = mv_C3[9:0];  assign mvy_C3  = mv_C3[19:10]; 
assign mvx_C4  = mv_C4[9:0];  assign mvy_C4  = mv_C4[19:10]; 
assign mvx_C5  = mv_C5[9:0];  assign mvy_C5  = mv_C5[19:10]; 
assign mvx_C6  = mv_C6[9:0];  assign mvy_C6  = mv_C6[19:10]; 
assign mvx_C7  = mv_C7[9:0];  assign mvy_C7  = mv_C7[19:10]; 
assign mvx_C8  = mv_C8[9:0];  assign mvy_C8  = mv_C8[19:10]; 
assign mvx_C9  = mv_C9[9:0];  assign mvy_C9  = mv_C9[19:10]; 
assign mvx_C10 = mv_C10[9:0]; assign mvy_C10 = mv_C10[19:10]; 
assign mvx_C11 = mv_C11[9:0]; assign mvy_C11 = mv_C11[19:10]; 
assign mvx_C12 = mv_C12[9:0]; assign mvy_C12 = mv_C12[19:10]; 
assign mvx_C13 = mv_C13[9:0]; assign mvy_C13 = mv_C13[19:10]; 
assign mvx_C14 = mv_C14[9:0]; assign mvy_C14 = mv_C14[19:10]; 
assign mvx_C15 = mv_C15[9:0]; assign mvy_C15 = mv_C15[19:10]; 
assign mvx_C16 = mv_C16[9:0]; assign mvy_C16 = mv_C16[19:10]; 

assign mvx_bs_1  = mvx_L1  - mvx_C1 ;  assign mvy_bs_1  = mvy_L1  - mvy_C1 ;
assign mvx_bs_2  = mvx_L2  - mvx_C5 ;  assign mvy_bs_2  = mvy_L2  - mvy_C5 ;
assign mvx_bs_3  = mvx_L3  - mvx_C9 ;  assign mvy_bs_3  = mvy_L3  - mvy_C9 ;
assign mvx_bs_4  = mvx_L4  - mvx_C13;  assign mvy_bs_4  = mvy_L4  - mvy_C13;
assign mvx_bs_5  = mvx_C1  - mvx_C2 ;  assign mvy_bs_5  = mvy_C1  - mvy_C2 ;
assign mvx_bs_6  = mvx_C5  - mvx_C6 ;  assign mvy_bs_6  = mvy_C5  - mvy_C6 ;
assign mvx_bs_7  = mvx_C9  - mvx_C10;  assign mvy_bs_7  = mvy_C9  - mvy_C10;
assign mvx_bs_8  = mvx_C13 - mvx_C14;  assign mvy_bs_8  = mvy_C13 - mvy_C14;
assign mvx_bs_9  = mvx_C2  - mvx_C3 ;  assign mvy_bs_9  = mvy_C2  - mvy_C3 ;
assign mvx_bs_10 = mvx_C6  - mvx_C7 ;  assign mvy_bs_10 = mvy_C6  - mvy_C7 ;
assign mvx_bs_11 = mvx_C10 - mvx_C11;  assign mvy_bs_11 = mvy_C10 - mvy_C11;
assign mvx_bs_12 = mvx_C14 - mvx_C15;  assign mvy_bs_12 = mvy_C14 - mvy_C15;
assign mvx_bs_13 = mvx_C3  - mvx_C4 ;  assign mvy_bs_13 = mvy_C3  - mvy_C4 ;
assign mvx_bs_14 = mvx_C7  - mvx_C8 ;  assign mvy_bs_14 = mvy_C7  - mvy_C8 ;
assign mvx_bs_15 = mvx_C11 - mvx_C12;  assign mvy_bs_15 = mvy_C11 - mvy_C12;
assign mvx_bs_16 = mvx_C15 - mvx_C16;  assign mvy_bs_16 = mvy_C15 - mvy_C16;
assign mvx_bs_17 = mvx_T1  - mvx_C1 ;  assign mvy_bs_17 = mvy_T1  - mvy_C1 ;
assign mvx_bs_18 = mvx_T2  - mvx_C2 ;  assign mvy_bs_18 = mvy_T2  - mvy_C2 ;
assign mvx_bs_19 = mvx_T3  - mvx_C3 ;  assign mvy_bs_19 = mvy_T3  - mvy_C3 ;
assign mvx_bs_20 = mvx_T4  - mvx_C4 ;  assign mvy_bs_20 = mvy_T4  - mvy_C4 ;
assign mvx_bs_21 = mvx_C1  - mvx_C5;   assign mvy_bs_21 = mvy_C1  - mvy_C5;
assign mvx_bs_22 = mvx_C2  - mvx_C6 ;  assign mvy_bs_22 = mvy_C2  - mvy_C6 ;
assign mvx_bs_23 = mvx_C3  - mvx_C7 ;  assign mvy_bs_23 = mvy_C3  - mvy_C7 ;
assign mvx_bs_24 = mvx_C4  - mvx_C8 ;  assign mvy_bs_24 = mvy_C4  - mvy_C8 ;
assign mvx_bs_25 = mvx_C5  - mvx_C9 ;  assign mvy_bs_25 = mvy_C5  - mvy_C9 ;
assign mvx_bs_26 = mvx_C6  - mvx_C10;  assign mvy_bs_26 = mvy_C6  - mvy_C10;
assign mvx_bs_27 = mvx_C7  - mvx_C11;  assign mvy_bs_27 = mvy_C7  - mvy_C11;
assign mvx_bs_28 = mvx_C8  - mvx_C12;  assign mvy_bs_28 = mvy_C8  - mvy_C12;
assign mvx_bs_29 = mvx_C9  - mvx_C13;  assign mvy_bs_29 = mvy_C9  - mvy_C13;
assign mvx_bs_30 = mvx_C10 - mvx_C14;  assign mvy_bs_30 = mvy_C10 - mvy_C14;
assign mvx_bs_31 = mvx_C11 - mvx_C15;  assign mvy_bs_31 = mvy_C11 - mvy_C15;
assign mvx_bs_32 = mvx_C12 - mvx_C16;  assign mvy_bs_32 = mvy_C12 - mvy_C16; 

assign mvx_abs_1  = (mvx_bs_1 [10]==0)?mvx_bs_1 :(~mvx_bs_1  +11'sd1);    assign mvy_abs_1  = (mvy_bs_1 [10]==0)?mvy_bs_1 :(~mvy_bs_1  +11'sd1);
assign mvx_abs_2  = (mvx_bs_2 [10]==0)?mvx_bs_2 :(~mvx_bs_2  +11'sd1);    assign mvy_abs_2  = (mvy_bs_2 [10]==0)?mvy_bs_2 :(~mvy_bs_2  +11'sd1);
assign mvx_abs_3  = (mvx_bs_3 [10]==0)?mvx_bs_3 :(~mvx_bs_3  +11'sd1);    assign mvy_abs_3  = (mvy_bs_3 [10]==0)?mvy_bs_3 :(~mvy_bs_3  +11'sd1);
assign mvx_abs_4  = (mvx_bs_4 [10]==0)?mvx_bs_4 :(~mvx_bs_4  +11'sd1);    assign mvy_abs_4  = (mvy_bs_4 [10]==0)?mvy_bs_4 :(~mvy_bs_4  +11'sd1);
assign mvx_abs_5  = (mvx_bs_5 [10]==0)?mvx_bs_5 :(~mvx_bs_5  +11'sd1);    assign mvy_abs_5  = (mvy_bs_5 [10]==0)?mvy_bs_5 :(~mvy_bs_5  +11'sd1);
assign mvx_abs_6  = (mvx_bs_6 [10]==0)?mvx_bs_6 :(~mvx_bs_6  +11'sd1);    assign mvy_abs_6  = (mvy_bs_6 [10]==0)?mvy_bs_6 :(~mvy_bs_6  +11'sd1);
assign mvx_abs_7  = (mvx_bs_7 [10]==0)?mvx_bs_7 :(~mvx_bs_7  +11'sd1);    assign mvy_abs_7  = (mvy_bs_7 [10]==0)?mvy_bs_7 :(~mvy_bs_7  +11'sd1);
assign mvx_abs_8  = (mvx_bs_8 [10]==0)?mvx_bs_8 :(~mvx_bs_8  +11'sd1);    assign mvy_abs_8  = (mvy_bs_8 [10]==0)?mvy_bs_8 :(~mvy_bs_8  +11'sd1);
assign mvx_abs_9  = (mvx_bs_9 [10]==0)?mvx_bs_9 :(~mvx_bs_9  +11'sd1);    assign mvy_abs_9  = (mvy_bs_9 [10]==0)?mvy_bs_9 :(~mvy_bs_9  +11'sd1);
assign mvx_abs_10 = (mvx_bs_10[10]==0)?mvx_bs_10:(~mvx_bs_10 +11'sd1);    assign mvy_abs_10 = (mvy_bs_10[10]==0)?mvy_bs_10:(~mvy_bs_10 +11'sd1);
assign mvx_abs_11 = (mvx_bs_11[10]==0)?mvx_bs_11:(~mvx_bs_11 +11'sd1);    assign mvy_abs_11 = (mvy_bs_11[10]==0)?mvy_bs_11:(~mvy_bs_11 +11'sd1);
assign mvx_abs_12 = (mvx_bs_12[10]==0)?mvx_bs_12:(~mvx_bs_12 +11'sd1);    assign mvy_abs_12 = (mvy_bs_12[10]==0)?mvy_bs_12:(~mvy_bs_12 +11'sd1);
assign mvx_abs_13 = (mvx_bs_13[10]==0)?mvx_bs_13:(~mvx_bs_13 +11'sd1);    assign mvy_abs_13 = (mvy_bs_13[10]==0)?mvy_bs_13:(~mvy_bs_13 +11'sd1);
assign mvx_abs_14 = (mvx_bs_14[10]==0)?mvx_bs_14:(~mvx_bs_14 +11'sd1);    assign mvy_abs_14 = (mvy_bs_14[10]==0)?mvy_bs_14:(~mvy_bs_14 +11'sd1);
assign mvx_abs_15 = (mvx_bs_15[10]==0)?mvx_bs_15:(~mvx_bs_15 +11'sd1);    assign mvy_abs_15 = (mvy_bs_15[10]==0)?mvy_bs_15:(~mvy_bs_15 +11'sd1);
assign mvx_abs_16 = (mvx_bs_16[10]==0)?mvx_bs_16:(~mvx_bs_16 +11'sd1);    assign mvy_abs_16 = (mvy_bs_16[10]==0)?mvy_bs_16:(~mvy_bs_16 +11'sd1);
assign mvx_abs_17 = (mvx_bs_17[10]==0)?mvx_bs_17:(~mvx_bs_17 +11'sd1);    assign mvy_abs_17 = (mvy_bs_17[10]==0)?mvy_bs_17:(~mvy_bs_17 +11'sd1);
assign mvx_abs_18 = (mvx_bs_18[10]==0)?mvx_bs_18:(~mvx_bs_18 +11'sd1);    assign mvy_abs_18 = (mvy_bs_18[10]==0)?mvy_bs_18:(~mvy_bs_18 +11'sd1);
assign mvx_abs_19 = (mvx_bs_19[10]==0)?mvx_bs_19:(~mvx_bs_19 +11'sd1);    assign mvy_abs_19 = (mvy_bs_19[10]==0)?mvy_bs_19:(~mvy_bs_19 +11'sd1);
assign mvx_abs_20 = (mvx_bs_20[10]==0)?mvx_bs_20:(~mvx_bs_20 +11'sd1);    assign mvy_abs_20 = (mvy_bs_20[10]==0)?mvy_bs_20:(~mvy_bs_20 +11'sd1);
assign mvx_abs_21 = (mvx_bs_21[10]==0)?mvx_bs_21:(~mvx_bs_21 +11'sd1);    assign mvy_abs_21 = (mvy_bs_21[10]==0)?mvy_bs_21:(~mvy_bs_21 +11'sd1);
assign mvx_abs_22 = (mvx_bs_22[10]==0)?mvx_bs_22:(~mvx_bs_22 +11'sd1);    assign mvy_abs_22 = (mvy_bs_22[10]==0)?mvy_bs_22:(~mvy_bs_22 +11'sd1);
assign mvx_abs_23 = (mvx_bs_23[10]==0)?mvx_bs_23:(~mvx_bs_23 +11'sd1);    assign mvy_abs_23 = (mvy_bs_23[10]==0)?mvy_bs_23:(~mvy_bs_23 +11'sd1);
assign mvx_abs_24 = (mvx_bs_24[10]==0)?mvx_bs_24:(~mvx_bs_24 +11'sd1);    assign mvy_abs_24 = (mvy_bs_24[10]==0)?mvy_bs_24:(~mvy_bs_24 +11'sd1);
assign mvx_abs_25 = (mvx_bs_25[10]==0)?mvx_bs_25:(~mvx_bs_25 +11'sd1);    assign mvy_abs_25 = (mvy_bs_25[10]==0)?mvy_bs_25:(~mvy_bs_25 +11'sd1);
assign mvx_abs_26 = (mvx_bs_26[10]==0)?mvx_bs_26:(~mvx_bs_26 +11'sd1);    assign mvy_abs_26 = (mvy_bs_26[10]==0)?mvy_bs_26:(~mvy_bs_26 +11'sd1);
assign mvx_abs_27 = (mvx_bs_27[10]==0)?mvx_bs_27:(~mvx_bs_27 +11'sd1);    assign mvy_abs_27 = (mvy_bs_27[10]==0)?mvy_bs_27:(~mvy_bs_27 +11'sd1);
assign mvx_abs_28 = (mvx_bs_28[10]==0)?mvx_bs_28:(~mvx_bs_28 +11'sd1);    assign mvy_abs_28 = (mvy_bs_28[10]==0)?mvy_bs_28:(~mvy_bs_28 +11'sd1);
assign mvx_abs_29 = (mvx_bs_29[10]==0)?mvx_bs_29:(~mvx_bs_29 +11'sd1);    assign mvy_abs_29 = (mvy_bs_29[10]==0)?mvy_bs_29:(~mvy_bs_29 +11'sd1);
assign mvx_abs_30 = (mvx_bs_30[10]==0)?mvx_bs_30:(~mvx_bs_30 +11'sd1);    assign mvy_abs_30 = (mvy_bs_30[10]==0)?mvy_bs_30:(~mvy_bs_30 +11'sd1);
assign mvx_abs_31 = (mvx_bs_31[10]==0)?mvx_bs_31:(~mvx_bs_31 +11'sd1);    assign mvy_abs_31 = (mvy_bs_31[10]==0)?mvy_bs_31:(~mvy_bs_31 +11'sd1);
assign mvx_abs_32 = (mvx_bs_32[10]==0)?mvx_bs_32:(~mvx_bs_32 +11'sd1);    assign mvy_abs_32 = (mvy_bs_32[10]==0)?mvy_bs_32:(~mvy_bs_32 +11'sd1);


//
always@(*)begin
    if (x==0)
        bs1 = 3'd0;
    else if (mbtype_C==1'b0)
        bs1 = 3'd4;
    else if ((code_L1_reg[20])||(non_zero_count_C1))
        bs1 = 3'd2;
    else if (( mvx_abs_1>=4)||( mvy_abs_1>=4))
        bs1 = 3'd1;
    else
        bs1 = 3'd0;
end

always@(*)begin
    if (x==0)
        bs2 = 3'd0;
    else if (mbtype_C==1'b0)
        bs2 = 3'd4;
    else if ((code_L2_reg[20])||(non_zero_count_C5))
        bs2 = 3'd2;
    else if (( mvx_abs_2>=4)||( mvy_abs_2>=4))
        bs2 = 3'd1;
    else
        bs2 = 3'd0;
end

always@(*)begin
    if (x==0)
        bs3 = 3'd0;
    else if (mbtype_C==1'b0)
        bs3 = 3'd4;
    else if ((code_L3_reg[20])||(non_zero_count_C9))
        bs3 = 3'd2;
    else if (( mvx_abs_3>=4)||( mvy_abs_3>=4))
        bs3 = 3'd1;
    else
        bs3 = 3'd0;
end

always@(*)begin
    if (x==0)
        bs4 = 3'd0;
    else if (mbtype_C==1'b0)
        bs4 = 3'd4;
    else if ((code_L4_reg[20])||(non_zero_count_C13))
        bs4 = 3'd2;
    else if (( mvx_abs_4>=4)||( mvy_abs_4>=4))
        bs4 = 3'd1;
    else
        bs4 = 3'd0;
end


always@(*)begin
    if (y==0)
        bs17 = 3'd0;
    else if (mbtype_C==1'b0)
        bs17 = 3'd4;
    else if ((code_T1_reg[20])||(non_zero_count_C1))
        bs17 = 3'd2;
    else if (( mvx_abs_17>=4)||( mvy_abs_17>=4))
        bs17 = 3'd1;
    else
        bs17 = 3'd0;
end

always@(*)begin
    if (y==0)
        bs18 = 3'd0;
    else if (mbtype_C==1'b0)
        bs18 = 3'd4;
    else if ((code_T2_reg[20])||(non_zero_count_C2))
        bs18 = 3'd2;
    else if (( mvx_abs_18>=4)||( mvy_abs_18>=4))
        bs18 = 3'd1;
    else
        bs18 = 3'd0;
end

always@(*)begin
    if (y==0)
        bs19 = 3'd0;
    else if (mbtype_C==1'b0)
        bs19 = 3'd4;
    else if ((code_T3_reg[20])||(non_zero_count_C3))
        bs19 = 3'd2;
    else if (( mvx_abs_19>=4)||( mvy_abs_19>=4))
        bs19 = 3'd1;
    else
        bs19 = 3'd0;
end

always@(*)begin
    if (y==0)
        bs20 = 3'd0;
    else if (mbtype_C==1'b0)
        bs20 = 3'd4;
    else if ((code_T4_reg[20])||(non_zero_count_C4))
        bs20 = 3'd2;
    else if (( mvx_abs_20>=4)||( mvy_abs_20>=4))
        bs20 = 3'd1;
    else
        bs20 = 3'd0;
end

//
always@(*)begin
    if (transform_type_C==1'b1)
        bs5 =0;
    else if (mbtype_C==1'b0)
        bs5 = 3'd3;
    else if ((non_zero_count_C1)||(non_zero_count_C2))
        bs5 = 3'd2;
    else if (( mvx_abs_5>=4)||( mvy_abs_5>=4))
        bs5 = 3'd1;
    else
        bs5 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs6 =0;
    else if (mbtype_C==1'b0)
        bs6 = 3'd3;
    else if ((non_zero_count_C5)||(non_zero_count_C6))
        bs6 = 3'd2;
    else if (( mvx_abs_6>=4)||( mvy_abs_6>=4))
        bs6 = 3'd1;
    else
        bs6 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs7 =0;
    else if (mbtype_C==1'b0)
        bs7 = 3'd3;
    else if ((non_zero_count_C9)||(non_zero_count_C10))
        bs7 = 3'd2;
    else if (( mvx_abs_7>=4)||( mvy_abs_7>=4))
        bs7 = 3'd1;
    else
        bs7 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs8 =0;
    else if (mbtype_C==1'b0)
        bs8 = 3'd3;
    else if ((non_zero_count_C13)||(non_zero_count_C14))
        bs8 = 3'd2;
    else if (( mvx_abs_8>=4)||( mvy_abs_8>=4))
        bs8 = 3'd1;
    else
        bs8 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs9 = 3'd3;
    else if ((non_zero_count_C2)||(non_zero_count_C3))
        bs9 = 3'd2;
    else if (( mvx_abs_9>=4)||( mvy_abs_9>=4))
        bs9 = 3'd1;
    else
        bs9 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs10 = 3'd3;
    else if ((non_zero_count_C6)||(non_zero_count_C7))
        bs10 = 3'd2;
    else if (( mvx_abs_10>=4)||( mvy_abs_10>=4))
        bs10 = 3'd1;
    else
        bs10 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs11 = 3'd3;
    else if ((non_zero_count_C10)||(non_zero_count_C11))
        bs11 = 3'd2;
    else if (( mvx_abs_11>=4)||( mvy_abs_11>=4))
        bs11 = 3'd1;
    else
        bs11 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs12 = 3'd3;
    else if ((non_zero_count_C14)||(non_zero_count_C15))
        bs12 = 3'd2;
    else if (( mvx_abs_12>=4)||( mvy_abs_12>=4))
        bs12 = 3'd1;
    else
        bs12 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs13 =0;
    else if (mbtype_C==1'b0)
        bs13 = 3'd3;
    else if ((non_zero_count_C3)||(non_zero_count_C4))
        bs13 = 3'd2;
    else if (( mvx_abs_13>=4)||( mvy_abs_13>=4))
        bs13 = 3'd1;
    else
        bs13 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs14 =0;
    else if (mbtype_C==1'b0)
        bs14 = 3'd3;
    else if ((non_zero_count_C7)||(non_zero_count_C8))
        bs14 = 3'd2;
    else if (( mvx_abs_14>=4)||( mvy_abs_14>=4))
        bs14 = 3'd1;
    else
        bs14 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs15 =0;
    else if (mbtype_C==1'b0)
        bs15 = 3'd3;
    else if ((non_zero_count_C11)||(non_zero_count_C12))
        bs15 = 3'd2;
    else if (( mvx_abs_15>=4)||( mvy_abs_15>=4))
        bs15 = 3'd1;
    else
        bs15 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs16 =0;
    else if (mbtype_C==1'b0)
        bs16 = 3'd3;
    else if ((non_zero_count_C15)||(non_zero_count_C16))
        bs16 = 3'd2;
    else if (( mvx_abs_16>=4)||( mvy_abs_16>=4))
        bs16 = 3'd1;
    else
        bs16 = 3'd0;
end


always@(*)begin
    if (transform_type_C==1'b1)
        bs21 =0;
    else if (mbtype_C==1'b0)
        bs21 = 3'd3;
    else if ((non_zero_count_C1)||(non_zero_count_C5))
        bs21 = 3'd2;
    else if (( mvx_abs_21>=4)||( mvy_abs_21>=4))
        bs21 = 3'd1;
    else
        bs21 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs22 =0;
    else if (mbtype_C==1'b0)
        bs22 = 3'd3;
    else if ((non_zero_count_C2)||(non_zero_count_C6))
        bs22 = 3'd2;
    else if (( mvx_abs_22>=4)||( mvy_abs_22>=4))
        bs22 = 3'd1;
    else
        bs22 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs23 =0;
    else if (mbtype_C==1'b0)
        bs23 = 3'd3;
    else if ((non_zero_count_C3)||(non_zero_count_C7))
        bs23 = 3'd2;
    else if (( mvx_abs_23>=4)||( mvy_abs_23>=4))
        bs23 = 3'd1;
    else
        bs23 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs24 =0;
    else if (mbtype_C==1'b0)
        bs24 = 3'd3;
    else if ((non_zero_count_C4)||(non_zero_count_C8))
        bs24 = 3'd2;
    else if (( mvx_abs_24>=4)||( mvy_abs_24>=4))
        bs24 = 3'd1;
    else
        bs24 = 3'd0;
end

always@(*)begin
   if (mbtype_C==1'b0)
        bs25 = 3'd3;
    else if ((non_zero_count_C5)||(non_zero_count_C9))
        bs25 = 3'd2;
    else if (( mvx_abs_25>=4)||( mvy_abs_25>=4))
        bs25 = 3'd1;
    else
        bs25 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs26 = 3'd3;
    else if ((non_zero_count_C6)||(non_zero_count_C10))
        bs26 = 3'd2;
    else if (( mvx_abs_26>=4)||( mvy_abs_26>=4))
        bs26 = 3'd1;
    else
        bs26 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs27 = 3'd3;
    else if ((non_zero_count_C7)||(non_zero_count_C11))
        bs27 = 3'd2;
    else if (( mvx_abs_27>=4)||( mvy_abs_27>=4))
        bs27 = 3'd1;
    else
        bs27 = 3'd0;
end

always@(*)begin
    if (mbtype_C==1'b0)
        bs28 = 3'd3;
    else if ((non_zero_count_C8)||(non_zero_count_C12))
        bs28 = 3'd2;
    else if (( mvx_abs_28>=4)||( mvy_abs_28>=4))
        bs28 = 3'd1;
    else
        bs28 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs29 =0;
    else if (mbtype_C==1'b0)
        bs29 = 3'd3;
    else if ((non_zero_count_C9)||(non_zero_count_C13))
        bs29 = 3'd2;
    else if (( mvx_abs_29>=4)||( mvy_abs_29>=4))
        bs29 = 3'd1;
    else
        bs29 = 3'd0;
end

always@(*)begin
   if (transform_type_C==1'b1)
        bs30 =0;
    else if (mbtype_C==1'b0)
        bs30 = 3'd3;
    else if ((non_zero_count_C10)||(non_zero_count_C14))
        bs30 = 3'd2;
    else if (( mvx_abs_30>=4)||( mvy_abs_30>=4))
        bs30 = 3'd1;
    else
        bs30 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs31 =0;
    else if (mbtype_C==1'b0)
        bs31 = 3'd3;
    else if ((non_zero_count_C11)||(non_zero_count_C15))
        bs31 = 3'd2;
    else if (( mvx_abs_31>=4)||( mvy_abs_31>=4))
        bs31 = 3'd1;
    else
        bs31 = 3'd0;
end

always@(*)begin
    if (transform_type_C==1'b1)
        bs32 =0;
    else if (mbtype_C==1'b0)
        bs32 = 3'd3;
    else if ((non_zero_count_C12)||(non_zero_count_C16))
        bs32 = 3'd2;
    else if (( mvx_abs_32>=4)||( mvy_abs_32>=4))
        bs32 = 3'd1;
    else
        bs32 = 3'd0;
end


// ********************************************
//                                             
//    Sequential Logic                         
//                                             
// ********************************************


//write code information
always@(posedge clk or negedge rst)begin
    if(!rst)
            code_T_out <= 'd0;
        else if ((state==Y)&&(count_y==6'd0))
            code_T_out <= {qp_c,mbtype_C,non_zero_count_C13,mv_C13};
        else if ((state==Y)&&(count_y==6'd1))
            code_T_out <= {qp_c,mbtype_C,non_zero_count_C14,mv_C14};
        else if ((state==Y)&&(count_y==6'd2))
            code_T_out <= {qp_c,mbtype_C,non_zero_count_C15,mv_C15};
        else if ((state==Y)&&(count_y==6'd3))
            code_T_out <= {qp_c,mbtype_C,non_zero_count_C16,mv_C16};
        else 
            code_T_out <= code_T_out;
end

always@(posedge clk or negedge rst)begin
    if(!rst)
        add_out_T <=  'd0;
    else if ((state==Y)&&(count_y==6'd0))
        add_out_T <= (x<<2) + 6'd0;
    else if ((state==Y)&&(count_y==6'd1))
        add_out_T <= (x<<2) + 6'd1;
    else if ((state==Y)&&(count_y==6'd2))
        add_out_T <= (x<<2) + 6'd2;
    else if ((state==Y)&&(count_y==6'd3))
        add_out_T <= (x<<2) + 6'd3;
    else 
        add_out_T <= add_out_T;

end

always@(posedge clk or negedge rst) begin
    if(!rst)
        write_en_T <= 1'b0;
    else if((state==Y) && (count_y==6'd0||count_y==6'd1||count_y==6'd2||count_y==6'd3)&&count_y<'d15)
        write_en_T <= 1'b1;
    else
        write_en_T <= 1'b0;
end



always@(posedge clk or negedge rst) begin
    if(!rst)
        code_T1_reg <= 28'b0;
    else if( (state==BS) && (count_bs=='d1))
        code_T1_reg <= code_T;
    else
        code_T1_reg <= code_T1_reg;           
end

always@(posedge clk or negedge rst) begin
    if(!rst)
        code_T2_reg <= 28'b0;
    else if( (state==BS) && (count_bs=='d2) )
        code_T2_reg <= code_T;
    else
        code_T2_reg <= code_T2_reg;           
end

always@(posedge clk or negedge rst) begin
    if(!rst)
        code_T3_reg <= 28'b0;
    else if( (state==BS) && (count_bs=='d3) )
        code_T3_reg <= code_T;
    else
        code_T3_reg <= code_T3_reg;           
end

always@(posedge clk or negedge rst) begin
    if(!rst)
        code_T4_reg <= 28'b0;
    else if( (state==BS) && (count_bs=='d4) )
        code_T4_reg <= code_T;
    else
        code_T4_reg <= code_T4_reg;           
end

//left information
always@(posedge clk or negedge rst)begin
    if(!rst)
        code_L1_reg <= 22'b0;
    else if( (state==Y) && (count_y==6'd2) )
        code_L1_reg <= {mbtype_C,non_zero_count_C4,mv_C4};
    else
        code_L1_reg <= code_L1_reg;    
end

always@(posedge clk or negedge rst)begin
    if(!rst)
        code_L2_reg <= 22'b0;
    else if( (state==Y) && (count_y==6'd2) )
        code_L2_reg <= {mbtype_C,non_zero_count_C8,mv_C8};
    else
        code_L2_reg <= code_L2_reg;    
end

always@(posedge clk or negedge rst)begin
    if(!rst)
        code_L3_reg <= 22'b0;
    else if( (state==Y) && (count_y==6'd2) )
        code_L3_reg <= {mbtype_C,non_zero_count_C12,mv_C12};
    else
        code_L3_reg <= code_L3_reg;    
end

always@(posedge clk or negedge rst)begin
    if(!rst)
        code_L4_reg <= 22'b0;
    else if( (state==Y) && (count_y==6'd2) )
        code_L4_reg <= {mbtype_C,non_zero_count_C16,mv_C16};
    else
        code_L4_reg <= code_L4_reg;    
end


always@(posedge clk or negedge rst)begin
    if(!rst)begin
        bs1_reg  <= 3'd0;    
        bs2_reg  <= 3'd0;     
        bs3_reg  <= 3'd0;     
        bs4_reg  <= 3'd0;     
        bs5_reg  <= 3'd0;     
        bs6_reg  <= 3'd0;     
        bs7_reg  <= 3'd0;     
        bs8_reg  <= 3'd0;     
        bs9_reg  <= 3'd0;     
        bs10_reg <= 3'd0;    
        bs11_reg <= 3'd0;    
        bs12_reg <= 3'd0;    
        bs13_reg <= 3'd0;    
        bs14_reg <= 3'd0;    
        bs15_reg <= 3'd0;    
        bs16_reg <= 3'd0;    
        bs17_reg <= 3'd0;    
        bs18_reg <= 3'd0;    
        bs19_reg <= 3'd0;    
        bs20_reg <= 3'd0;    
        bs21_reg <= 3'd0;    
        bs22_reg <= 3'd0;    
        bs23_reg <= 3'd0;    
        bs24_reg <= 3'd0;    
        bs25_reg <= 3'd0;    
        bs26_reg <= 3'd0;    
        bs27_reg <= 3'd0;    
        bs28_reg <= 3'd0;    
        bs29_reg <= 3'd0;    
        bs30_reg <= 3'd0;    
        bs31_reg <= 3'd0;    
        bs32_reg <= 3'd0;    
    end
    else if ((state==BS)||(count_bs=='d5))begin
        bs1_reg  <= bs1 ;     
        bs2_reg  <= bs2 ;     
        bs3_reg  <= bs3 ;     
        bs4_reg  <= bs4 ;     
        bs5_reg  <= bs5 ;     
        bs6_reg  <= bs6 ;     
        bs7_reg  <= bs7 ;     
        bs8_reg  <= bs8 ;     
        bs9_reg  <= bs9 ;     
        bs10_reg <= bs10;     
        bs11_reg <= bs11;     
        bs12_reg <= bs12;     
        bs13_reg <= bs13;     
        bs14_reg <= bs14;     
        bs15_reg <= bs15;     
        bs16_reg <= bs16;     
        bs17_reg <= bs17;     
        bs18_reg <= bs18;
        bs19_reg <= bs19;
        bs20_reg <= bs20;
        bs21_reg <= bs21;
        bs22_reg <= bs22;
        bs23_reg <= bs23;
        bs24_reg <= bs24;
        bs25_reg <= bs25;
        bs26_reg <= bs26;
        bs27_reg <= bs27;
        bs28_reg <= bs28;
        bs29_reg <= bs29;
        bs30_reg <= bs30;
        bs31_reg <= bs31;
        bs32_reg <= bs32;
    end
    else begin
        bs1_reg  <= bs1_reg ; 
        bs2_reg  <= bs2_reg ; 
        bs3_reg  <= bs3_reg ; 
        bs4_reg  <= bs4_reg ; 
        bs5_reg  <= bs5_reg ; 
        bs6_reg  <= bs6_reg ; 
        bs7_reg  <= bs7_reg ; 
        bs8_reg  <= bs8_reg ; 
        bs9_reg  <= bs9_reg ; 
        bs10_reg <= bs10_reg; 
        bs11_reg <= bs11_reg; 
        bs12_reg <= bs12_reg; 
        bs13_reg <= bs13_reg; 
        bs14_reg <= bs14_reg; 
        bs15_reg <= bs15_reg; 
        bs16_reg <= bs16_reg; 
        bs17_reg <= bs17_reg; 
        bs18_reg <= bs18_reg; 
        bs19_reg <= bs19_reg; 
        bs20_reg <= bs20_reg; 
        bs21_reg <= bs21_reg; 
        bs22_reg <= bs22_reg; 
        bs23_reg <= bs23_reg; 
        bs24_reg <= bs24_reg; 
        bs25_reg <= bs25_reg; 
        bs26_reg <= bs26_reg; 
        bs27_reg <= bs27_reg; 
        bs28_reg <= bs28_reg; 
        bs29_reg <= bs29_reg; 
        bs30_reg <= bs30_reg; 
        bs31_reg <= bs31_reg; 
        bs32_reg <= bs32_reg; 
    end
end
    
//CACULATE
reg [3:0] count1;
/*
always@(*)begin
	if(count_y==6'd1)
		count1 = 3'd0;
	else
	    count1 = count1 + 1'd1;
end
*/

always@(*)begin
	
	    count1 = count_y - 1'd1;
end


reg [3:0] count2;
/*
always@(*)begin
	if(count_y==6'd24)
		count2 = 3'd0;
	else
	    count2 = count2 + 1'd1;
end
*/

always@(*)begin
	
	    count2 = count_y - 'd24;
end

reg [2:0] bs_luma;
always@(posedge clk or negedge rst)begin
    if(!rst)
        bs_luma <=3'd0;
	
	else if(state==Y)begin
		if((count_y>=6'd1)&&(count_y<=6'd16))begin
			case(count1)
				4'd0 : bs_luma <= bs1_reg;
				4'd1 : bs_luma <= bs2_reg;
				4'd2 : bs_luma <= bs3_reg;
				4'd3 : bs_luma <= bs4_reg;
				4'd4 : bs_luma <= bs5_reg;
				4'd5 : bs_luma <= bs6_reg;
				4'd6 : bs_luma <= bs7_reg;
				4'd7 : bs_luma <= bs8_reg;
				4'd8 : bs_luma <= bs9_reg;
				4'd9 : bs_luma <= bs10_reg;
				4'd10: bs_luma <= bs11_reg;
				4'd11: bs_luma <= bs12_reg;
				4'd12: bs_luma <= bs13_reg;
				4'd13: bs_luma <= bs14_reg;
				4'd14: bs_luma <= bs15_reg;
				4'd15: bs_luma <= bs16_reg;
			endcase	
		end
		else if((count_y>=6'd24)&&(count_y<=6'd39))begin
			case(count2)
				4'd0 : bs_luma <= bs17_reg;
				4'd1 : bs_luma <= bs18_reg;
				4'd2 : bs_luma <= bs19_reg;
				4'd3 : bs_luma <= bs20_reg;
				4'd4 : bs_luma <= bs21_reg;
				4'd5 : bs_luma <= bs22_reg;
				4'd6 : bs_luma <= bs23_reg;
				4'd7 : bs_luma <= bs24_reg;
				4'd8 : bs_luma <= bs25_reg;
				4'd9 : bs_luma <= bs26_reg;
				4'd10: bs_luma <= bs27_reg;
				4'd11: bs_luma <= bs28_reg;
				4'd12: bs_luma <= bs29_reg;
				4'd13: bs_luma <= bs30_reg;
				4'd14: bs_luma <= bs31_reg;
				4'd15: bs_luma <= bs32_reg;
			endcase		
		end
		else
			bs_luma <= 3'd0;
	end
			
	else
        bs_luma <= 3'd0;
end

  
reg [2:0] count3;
/*
always@(*)begin
	if(count_cbcr==6'd1)
		count3 = 3'd0;
	else
	    count3 = count3 + 1'd1;
end
*/
always@(*)begin
	count3 = count_cbcr - 1'd1;
end

reg [2:0] count4;
/*
always@(*)begin
	if(count_cbcr==6'd16)
		count4 = 3'd0;
	else
	    count4 = count4 + 1'd1;
end
*/
always@(*)begin
	count4 = count_cbcr - 'd16;
end


reg [2:0] bs_chroma_1;
always@(posedge clk or negedge rst)begin
    if(!rst)
        bs_chroma_1 <=3'd0;
		
	else if(state==CbCr)begin
		if((count_cbcr>=6'd1)&&(count_cbcr<=6'd8))begin
			case(count3)
				3'd0: bs_chroma_1 <= bs1_reg;
				3'd1: bs_chroma_1 <= bs3_reg;
				3'd2: bs_chroma_1 <= bs1_reg;
				3'd3: bs_chroma_1 <= bs3_reg;
				3'd4: bs_chroma_1 <= bs9_reg;
				3'd5: bs_chroma_1 <= bs11_reg;
				3'd6: bs_chroma_1 <= bs9_reg;
				3'd7: bs_chroma_1 <= bs11_reg;
			endcase
		end
		else if((count_cbcr>=6'd16)&&(count_cbcr<=6'd23))begin
			case(count4)
				3'd0: bs_chroma_1 <= bs17_reg;
				3'd1: bs_chroma_1 <= bs19_reg;
				3'd2: bs_chroma_1 <= bs17_reg;
				3'd3: bs_chroma_1 <= bs19_reg;
				3'd4: bs_chroma_1 <= bs25_reg;
				3'd5: bs_chroma_1 <= bs27_reg;
				3'd6: bs_chroma_1 <= bs25_reg;
				3'd7: bs_chroma_1 <= bs27_reg;
			endcase
		end	
		else
			bs_chroma_1 <= 3'd0;
	end
    
    else
        bs_chroma_1 <= 3'd0;
end   

reg [2:0] bs_chroma_2;
always@(posedge clk or negedge rst)begin
    if(!rst)
        bs_chroma_2 <=3'd0;
		
	else if(state==CbCr)begin
		if((count_cbcr>=6'd1)&&(count_cbcr<=6'd8))begin
			case(count3)
				3'd0: bs_chroma_2 <= bs2_reg;
				3'd1: bs_chroma_2 <= bs4_reg;
				3'd2: bs_chroma_2 <= bs2_reg;
				3'd3: bs_chroma_2 <= bs4_reg;
				3'd4: bs_chroma_2 <= bs10_reg;
				3'd5: bs_chroma_2 <= bs12_reg;
				3'd6: bs_chroma_2 <= bs10_reg;
				3'd7: bs_chroma_2 <= bs12_reg;
			endcase
		end
		else if((count_cbcr>=6'd16)&&(count_cbcr<=6'd23))begin
			case(count4)
				3'd0: bs_chroma_2 <= bs18_reg;
				3'd1: bs_chroma_2 <= bs20_reg;
				3'd2: bs_chroma_2 <= bs18_reg;
				3'd3: bs_chroma_2 <= bs20_reg;
				3'd4: bs_chroma_2 <= bs26_reg;
				3'd5: bs_chroma_2 <= bs28_reg;
				3'd6: bs_chroma_2 <= bs26_reg;
				3'd7: bs_chroma_2 <= bs28_reg;
			endcase
		end	
		else
			bs_chroma_2 <= 3'd0;
	end
    
    else
        bs_chroma_2 <= 3'd0;
end

////////////////////////////////////////////////qp output for luma and chroma
reg [5:0] qp_c_reg;
always@(posedge clk or negedge rst)begin
    if(!rst)
        qp_c_reg <= 6'b0;
    else if( (state==BS) && (count_bs=='d2) )
        qp_c_reg <= qp_c;
    else
        qp_c_reg <= qp_c_reg;    
end

reg [5:0] qp_l_reg;
always@(posedge clk or negedge rst)begin
    if(!rst)
        qp_l_reg <= 6'b0;
    else if( (state==CbCr) && (count_cbcr=='d32) )
        qp_l_reg <= qp_c_reg;
    else
        qp_l_reg <= qp_l_reg;    
end

reg [5:0] qp_t_reg;
always@(posedge clk or negedge rst)begin
	if(!rst)
		qp_t_reg <= 6'b0;
	else if( (state==BS) && (count_bs=='d2) )
		qp_t_reg <= code_T1_reg[27:22];
	else 
		qp_t_reg <= qp_t_reg;
end

reg [5:0] qp_c_chroma;
always@(*)begin
	if(qp_c_reg<='d29)
		qp_c_chroma <= qp_c_reg;
	else 
		case(qp_c_reg)
			6'd30: qp_c_chroma <= 'd29;
			6'd31: qp_c_chroma <= 'd30;
			6'd32: qp_c_chroma <= 'd31;
			6'd33: qp_c_chroma <= 'd32;
			6'd34: qp_c_chroma <= 'd32;
			6'd35: qp_c_chroma <= 'd33;
			6'd36: qp_c_chroma <= 'd34;
			6'd37: qp_c_chroma <= 'd34;
			6'd38: qp_c_chroma <= 'd35;
			6'd39: qp_c_chroma <= 'd35;
			6'd40: qp_c_chroma <= 'd36;	
			6'd41: qp_c_chroma <= 'd36;
			6'd42: qp_c_chroma <= 'd37;
			6'd43: qp_c_chroma <= 'd37;
			6'd44: qp_c_chroma <= 'd37;
			6'd45: qp_c_chroma <= 'd38;
			6'd46: qp_c_chroma <= 'd38;
			6'd47: qp_c_chroma <= 'd38;
			6'd48: qp_c_chroma <= 'd39;
			6'd49: qp_c_chroma <= 'd39;
			6'd50: qp_c_chroma <= 'd39;
			6'd51: qp_c_chroma <= 'd39;
			default: qp_c_chroma <= 0;
		endcase
end

reg [5:0] qp_l_chroma;
always@(*)begin
	if(qp_l_reg<='d29)
		qp_l_chroma <= qp_l_reg;
	else 
		case(qp_l_reg)
			6'd30: qp_l_chroma <= 'd29;
			6'd31: qp_l_chroma <= 'd30;
			6'd32: qp_l_chroma <= 'd31;
			6'd33: qp_l_chroma <= 'd32;
			6'd34: qp_l_chroma <= 'd32;
			6'd35: qp_l_chroma <= 'd33;
			6'd36: qp_l_chroma <= 'd34;
			6'd37: qp_l_chroma <= 'd34;
			6'd38: qp_l_chroma <= 'd35;
			6'd39: qp_l_chroma <= 'd35;
			6'd40: qp_l_chroma <= 'd36;	
			6'd41: qp_l_chroma <= 'd36;
			6'd42: qp_l_chroma <= 'd37;
			6'd43: qp_l_chroma <= 'd37;
			6'd44: qp_l_chroma <= 'd37;
			6'd45: qp_l_chroma <= 'd38;
			6'd46: qp_l_chroma <= 'd38;
			6'd47: qp_l_chroma <= 'd38;
			6'd48: qp_l_chroma <= 'd39;
			6'd49: qp_l_chroma <= 'd39;
			6'd50: qp_l_chroma <= 'd39;
			6'd51: qp_l_chroma <= 'd39;
			default: qp_l_chroma <= 0;
		endcase
end

reg [5:0] qp_t_chroma;
always@(*)begin
	if(qp_t_reg<='d29)
		qp_t_chroma <= qp_t_reg;
	else 
		case(qp_t_reg)
			6'd30: qp_t_chroma <= 'd29;
			6'd31: qp_t_chroma <= 'd30;
			6'd32: qp_t_chroma <= 'd31;
			6'd33: qp_t_chroma <= 'd32;
			6'd34: qp_t_chroma <= 'd32;
			6'd35: qp_t_chroma <= 'd33;
			6'd36: qp_t_chroma <= 'd34;
			6'd37: qp_t_chroma <= 'd34;
			6'd38: qp_t_chroma <= 'd35;
			6'd39: qp_t_chroma <= 'd35;
			6'd40: qp_t_chroma <= 'd36;	
			6'd41: qp_t_chroma <= 'd36;
			6'd42: qp_t_chroma <= 'd37;
			6'd43: qp_t_chroma <= 'd37;
			6'd44: qp_t_chroma <= 'd37;
			6'd45: qp_t_chroma <= 'd38;
			6'd46: qp_t_chroma <= 'd38;
			6'd47: qp_t_chroma <= 'd38;
			6'd48: qp_t_chroma <= 'd39;
			6'd49: qp_t_chroma <= 'd39;
			6'd50: qp_t_chroma <= 'd39;
			6'd51: qp_t_chroma <= 'd39;
			default: qp_t_chroma <= 0;
		endcase
end


reg [5:0] qp_1;
always@(posedge clk or negedge rst)begin
    if(!rst)
        qp_1 <= 'd0;
		
	else if(state==Y)begin
		if((count_y>=6'd1)&&(count_y<=6'd4))
			qp_1 <= qp_l_reg;
		else if((count_y>=6'd24)&&(count_y<=6'd27))
			qp_1 <= qp_t_reg;
		else
			qp_1 <= qp_c_reg;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd1)&&(count_cbcr<=6'd4))
			qp_1 <= qp_l_chroma;
		else if((count_cbcr>=6'd16)&&(count_cbcr<=6'd19))
			qp_1 <= qp_t_chroma;
		else
			qp_1 <= qp_c_chroma;
	end 
    
    else
		qp_1 <= qp_1;  
end


reg [5:0] qp_2;
always@(posedge clk or negedge rst)begin
    if(!rst)
        qp_2 <= 'd0;	
	else if(state==Y)
		qp_2 <= qp_c_reg;	
	else if(state==CbCr)
		qp_2 <= qp_c_chroma;    
    else
		qp_2 <= qp_2;  
end







endmodule
