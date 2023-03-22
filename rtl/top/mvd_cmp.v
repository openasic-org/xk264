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
// Filename       : mvd_cmp.v
// Author         : fanyibo
// Created        : 2012-04-26
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
// 2012-4-10   Bomb   modification
// 2013-8-6    ybfan  use mem for mvd (to entropy coding)
//------------------------------------------------------------------- 
`include "enc_defines.v"

module mvd_cmp(
				clk,
				rst_n,
				mb_x_total,
				mb_y_total,
				mb_x_i,
				mb_y_i,
				start_i,
				done_o,
				mb_type_inter,
				sub_partition,
				fmv_i,
				mv_o,		
				mem_sw_i,								
				mvd_rd,	 
				mvd_raddr,
				mvd_rdata
);

// ********************************************
//                                             
//    Parameter DECLARATION                     
//                                             
// ********************************************
parameter  	IDLE    = 2'b00,
			RUN     = 2'b01,
			LOAD    = 2'b10,
			STORE   = 2'b11;


parameter   P_16x16 = 2'b00,
			P_16x8  = 2'b01,
			P_8x16  = 2'b10,
			P_8x8   = 2'b11;	

parameter   D_8x8   = 2'd0,
			D_8x4   = 2'd1,
			D_4x8   = 2'd2,
			D_4x4   = 2'd3;

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                           clk, rst_n;
input  [`PIC_W_MB_LEN-1:0]      mb_x_total;       // total mb x
input  [`PIC_H_MB_LEN-1 :0]     mb_y_total;       // total mb y
input  [`PIC_W_MB_LEN-1 :0]     mb_x_i;           // current mb X coordinate
input  [`PIC_H_MB_LEN-1 :0]     mb_y_i;           // current mb Y coordinate
                                                
input                           start_i;          // start
output                          done_o ;          // done 
input  [1:0]                    mb_type_inter;    // 16*16 block partition
input  [7:0]                    sub_partition;    // 4 sub 8x8 blocks partition
input  [`FMVD_LEN*2*16-1:0]     fmv_i;	          // every 4x4 block fmv    
output [`FMVD_LEN*2*16-1:0]     mv_o;             // fmv_i reg buff (to db)  
input							mem_sw_i;		  // switch mem bank of mv output to ec      
input							mvd_rd	 ;		  // ec if: read enable
input  [3:0]					mvd_raddr;		  // ec if: read address
output [17:0]					mvd_rdata;		  // ec if: read data

// ********************************************      
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
reg [1:0]						curr_state;
reg [3:0]                   	ld_st_cnt;
reg [8:0]						mem_addr_r;      // one MB need 4 words, for HD, it needs 120x4 = 480 words
 
reg [16*2*`FMVD_LEN-1:0] 		fmv_r;                           	
reg [2*`FMVD_LEN-1:0]			mv_L0, mv_L1, mv_L2, mv_L3,
								mv_U0, mv_U1, mv_U2, mv_U3,
								mv_UR;
								
reg                             done_o;
reg								mem_sel;    	// mvd output ram buffer, pingpong sel 

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
reg [1:0]   					next_state;
wire							ld_done, st_done, cal_done;
// mv top line memory
reg  [2*`FMVD_LEN-1:0]			mem_data_i;
wire [2*`FMVD_LEN-1:0]			mem_data_o;
wire [8:0]                      mem_addr;
wire                          	mem_cs;
wire                          	mem_we;
// mvd output buffer memory
wire							mvd_we	 ;
wire [4:0]						mvd_waddr;
wire [17:0]						mvd_wdata;
// mv array
reg [`FMVD_LEN*2-1:0]			mv_00, mv_10, mv_20, mv_30,         
								mv_01, mv_11, mv_21, mv_31,         
								mv_02, mv_12, mv_22, mv_32,         
								mv_03, mv_13, mv_23, mv_33,         
								mv_L_00 , mv_L_10 , mv_L_20 , mv_L_30 , smv_L_00,  smv_L_10,  smv_L_20,  smv_L_30,
								mv_L_01 , mv_L_11 , mv_L_21 , mv_L_31 , smv_L_01,  smv_L_11,  smv_L_21,  smv_L_31,
								mv_L_02 , mv_L_12 , mv_L_22 , mv_L_32 , smv_L_02,  smv_L_12,  smv_L_22,  smv_L_32,
								mv_L_03 , mv_L_13 , mv_L_23 , mv_L_33 ,	smv_L_03,  smv_L_13,  smv_L_23,  smv_L_33,
								mv_U_00 , mv_U_10 , mv_U_20 , mv_U_30 ,	smv_U_00,  smv_U_10,  smv_U_20,  smv_U_30,					
								mv_U_01 , mv_U_11 , mv_U_21 , mv_U_31 , smv_U_01,  smv_U_11,  smv_U_21,  smv_U_31,
								mv_U_02 , mv_U_12 , mv_U_22 , mv_U_32 , smv_U_02,  smv_U_12,  smv_U_22,  smv_U_32,
								mv_U_03 , mv_U_13 , mv_U_23 , mv_U_33 , smv_U_03,  smv_U_13,  smv_U_23,  smv_U_33,
								mv_UR_00, mv_UR_10, mv_UR_20, mv_UR_30, smv_UR_00, smv_UR_10, smv_UR_20, smv_UR_30,
								mv_UR_01, mv_UR_11, mv_UR_21, mv_UR_31, smv_UR_01, smv_UR_11, smv_UR_21, smv_UR_31,
								mv_UR_02, mv_UR_12, mv_UR_22, mv_UR_32, smv_UR_02, smv_UR_12, smv_UR_22, smv_UR_32,
								mv_UR_03, mv_UR_13, mv_UR_23, mv_UR_33, smv_UR_03, smv_UR_13, smv_UR_23, smv_UR_33,
								mv_C_L, mv_C_U, mv_C_UR, mv_C, mv_UR_right, smv_UR_right;        								

wire [2*`FMVD_LEN+1:0]			mvd_C;
								
// ********************************************
//                                             
//     Logic Definition
//                                             
// ********************************************
//----------------------------------------------------
//              MV Mapping
//   fmv input         mv after mapping 
//
//  0  1  4  5           00 10 20 30 
//  2  3  6  7     =>    01 11 21 31
//  8  9 12 13           02 12 22 32
// 10 11 14 15           03 13 23 33
//
//----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		fmv_r <= 'b0;
	else if (start_i)
		fmv_r <= fmv_i;
end

assign mv_o = fmv_r;

always @( * )begin
    mv_00 = fmv_r[(0 +1)*2*`FMVD_LEN-1 : 0 *2*`FMVD_LEN]; 
	mv_10 = fmv_r[(1 +1)*2*`FMVD_LEN-1 : 1 *2*`FMVD_LEN];
    mv_01 = fmv_r[(2 +1)*2*`FMVD_LEN-1 : 2 *2*`FMVD_LEN];
	mv_11 = fmv_r[(3 +1)*2*`FMVD_LEN-1 : 3 *2*`FMVD_LEN];
    mv_20 = fmv_r[(4 +1)*2*`FMVD_LEN-1 : 4 *2*`FMVD_LEN];
	mv_30 = fmv_r[(5 +1)*2*`FMVD_LEN-1 : 5 *2*`FMVD_LEN];
    mv_21 = fmv_r[(6 +1)*2*`FMVD_LEN-1 : 6 *2*`FMVD_LEN];
	mv_31 = fmv_r[(7 +1)*2*`FMVD_LEN-1 : 7 *2*`FMVD_LEN];
    mv_02 = fmv_r[(8 +1)*2*`FMVD_LEN-1 : 8 *2*`FMVD_LEN];
	mv_12 = fmv_r[(9 +1)*2*`FMVD_LEN-1 : 9 *2*`FMVD_LEN];
    mv_03 = fmv_r[(10+1)*2*`FMVD_LEN-1 : 10*2*`FMVD_LEN];
	mv_13 = fmv_r[(11+1)*2*`FMVD_LEN-1 : 11*2*`FMVD_LEN];
    mv_22 = fmv_r[(12+1)*2*`FMVD_LEN-1 : 12*2*`FMVD_LEN];
	mv_32 = fmv_r[(13+1)*2*`FMVD_LEN-1 : 13*2*`FMVD_LEN];
    mv_23 = fmv_r[(14+1)*2*`FMVD_LEN-1 : 14*2*`FMVD_LEN];
	mv_33 = fmv_r[(15+1)*2*`FMVD_LEN-1 : 15*2*`FMVD_LEN];
end

//-----------------------------------------------------
//               MV LEFT UP UR Mapping
//
//  ul u0 u1 u2 u3 ur
//  l0 00 10 20 30
//  l1 01 11 21 31
//  l2 02 12 22 32
//  l3 03 13 23 33
//-----------------------------------------------------
always @(*) begin
	case (mb_type_inter)
		P_16x16: begin 	mv_L_00 = mv_L0; mv_U_00 = mv_U0; mv_UR_00 = mv_UR; 
					   	mv_L_10 = mv_L0; mv_U_10 = mv_U0; mv_UR_10 = mv_UR;
						mv_L_20 = mv_L0; mv_U_20 = mv_U0; mv_UR_20 = mv_UR;
						mv_L_30 = mv_L0; mv_U_30 = mv_U0; mv_UR_30 = mv_UR;
						mv_L_01 = mv_L0; mv_U_01 = mv_U0; mv_UR_01 = mv_UR;
						mv_L_11 = mv_L0; mv_U_11 = mv_U0; mv_UR_11 = mv_UR;
						mv_L_21 = mv_L0; mv_U_21 = mv_U0; mv_UR_21 = mv_UR;
						mv_L_31 = mv_L0; mv_U_31 = mv_U0; mv_UR_31 = mv_UR;
						mv_L_02 = mv_L0; mv_U_02 = mv_U0; mv_UR_02 = mv_UR;
						mv_L_12 = mv_L0; mv_U_12 = mv_U0; mv_UR_12 = mv_UR;
						mv_L_22 = mv_L0; mv_U_22 = mv_U0; mv_UR_22 = mv_UR;
						mv_L_32 = mv_L0; mv_U_32 = mv_U0; mv_UR_32 = mv_UR;
						mv_L_03 = mv_L0; mv_U_03 = mv_U0; mv_UR_03 = mv_UR;
						mv_L_13 = mv_L0; mv_U_13 = mv_U0; mv_UR_13 = mv_UR;
						mv_L_23 = mv_L0; mv_U_23 = mv_U0; mv_UR_23 = mv_UR;
						mv_L_33 = mv_L0; mv_U_33 = mv_U0; mv_UR_33 = mv_UR;	
				 end						
		P_16x8 : begin 	mv_L_00 = mv_U0; mv_U_00 = mv_U0; mv_UR_00 = mv_U0; 
					   	mv_L_10 = mv_U0; mv_U_10 = mv_U0; mv_UR_10 = mv_U0;
						mv_L_20 = mv_U0; mv_U_20 = mv_U0; mv_UR_20 = mv_U0;
						mv_L_30 = mv_U0; mv_U_30 = mv_U0; mv_UR_30 = mv_U0;
						mv_L_01 = mv_U0; mv_U_01 = mv_U0; mv_UR_01 = mv_U0;
						mv_L_11 = mv_U0; mv_U_11 = mv_U0; mv_UR_11 = mv_U0;
						mv_L_21 = mv_U0; mv_U_21 = mv_U0; mv_UR_21 = mv_U0;
						mv_L_31 = mv_U0; mv_U_31 = mv_U0; mv_UR_31 = mv_U0;
						mv_L_02 = mv_L2; mv_U_02 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_02 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_12 = mv_L2; mv_U_12 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_12 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_22 = mv_L2; mv_U_22 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_22 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_32 = mv_L2; mv_U_32 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_32 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_03 = mv_L2; mv_U_03 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_03 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_13 = mv_L2; mv_U_13 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_13 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_23 = mv_L2; mv_U_23 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_23 = (mb_x_i=='b0)?mv_00:mv_L2;
						mv_L_33 = mv_L2; mv_U_33 = (mb_x_i=='b0)?mv_00:mv_L2; mv_UR_33 = (mb_x_i=='b0)?mv_00:mv_L2;	
				 end
		P_8x16 : begin 	mv_L_00 = mv_L0; mv_U_00 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_00 = (mb_x_i=='b0)?mv_U2:mv_L0; 
					   	mv_L_10 = mv_L0; mv_U_10 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_10 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_20 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_20 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_20 = mv_UR;
						mv_L_30 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_30 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_30 = mv_UR;
						mv_L_01 = mv_L0; mv_U_01 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_01 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_11 = mv_L0; mv_U_11 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_11 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_21 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_21 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_21 = mv_UR;
						mv_L_31 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_31 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_31 = mv_UR;
						mv_L_02 = mv_L0; mv_U_02 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_02 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_12 = mv_L0; mv_U_12 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_12 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_22 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_22 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_22 = mv_UR;
						mv_L_32 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_32 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_32 = mv_UR;
						mv_L_03 = mv_L0; mv_U_03 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_03 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_13 = mv_L0; mv_U_13 = (mb_x_i=='b0)?mv_U0:mv_L0; mv_UR_13 = (mb_x_i=='b0)?mv_U2:mv_L0;
						mv_L_23 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_23 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_23 = mv_UR;
						mv_L_33 = (mb_x_i==mb_x_total)?mv_10:mv_UR; mv_U_33 = (mb_x_i==mb_x_total)?mv_U1:mv_UR; mv_UR_33 = mv_UR;	
				 end
		P_8x8  : begin  mv_L_00 = smv_L_00; mv_U_00 = smv_U_00; mv_UR_00 = smv_UR_00;
						mv_L_10 = smv_L_10; mv_U_10 = smv_U_10; mv_UR_10 = smv_UR_10;
						mv_L_20 = smv_L_20; mv_U_20 = smv_U_20; mv_UR_20 = smv_UR_20;
						mv_L_30 = smv_L_30; mv_U_30 = smv_U_30; mv_UR_30 = smv_UR_30;
						mv_L_01 = smv_L_01; mv_U_01 = smv_U_01; mv_UR_01 = smv_UR_01;
						mv_L_11 = smv_L_11; mv_U_11 = smv_U_11; mv_UR_11 = smv_UR_11;
						mv_L_21 = smv_L_21; mv_U_21 = smv_U_21; mv_UR_21 = smv_UR_21;
						mv_L_31 = smv_L_31; mv_U_31 = smv_U_31; mv_UR_31 = smv_UR_31;
						mv_L_02 = smv_L_02; mv_U_02 = smv_U_02; mv_UR_02 = smv_UR_02;
						mv_L_12 = smv_L_12; mv_U_12 = smv_U_12; mv_UR_12 = smv_UR_12;
						mv_L_22 = smv_L_22; mv_U_22 = smv_U_22; mv_UR_22 = smv_UR_22;
						mv_L_32 = smv_L_32; mv_U_32 = smv_U_32; mv_UR_32 = smv_UR_32;
						mv_L_03 = smv_L_03; mv_U_03 = smv_U_03; mv_UR_03 = smv_UR_03;
						mv_L_13 = smv_L_13; mv_U_13 = smv_U_13; mv_UR_13 = smv_UR_13;
						mv_L_23 = smv_L_23; mv_U_23 = smv_U_23; mv_UR_23 = smv_UR_23;
						mv_L_33 = smv_L_33; mv_U_33 = smv_U_33; mv_UR_33 = smv_UR_33;
				 end
		endcase
end		
			
always @(*)	begin	
	case (sub_partition[1:0])
		D_8x8  : begin 	smv_L_00 = mv_L0; smv_U_00 = mv_U0; smv_UR_00 = mv_U2; 
					   	smv_L_10 = mv_L0; smv_U_10 = mv_U0; smv_UR_10 = mv_U2;
					   	smv_L_01 = mv_L0; smv_U_01 = mv_U0; smv_UR_01 = mv_U2;
					   	smv_L_11 = mv_L0; smv_U_11 = mv_U0; smv_UR_11 = mv_U2; end
		D_8x4  : begin  smv_L_00 = mv_L0; smv_U_00 = mv_U0; smv_UR_00 = mv_U2;
					   	smv_L_10 = mv_L0; smv_U_10 = mv_U0; smv_UR_10 = mv_U2;
					   	smv_L_01 = mv_L1; smv_U_01 = mv_00; smv_UR_01 = (mb_x_i == 'b0) ? mv_00 : mv_L0;
					   	smv_L_11 = mv_L1; smv_U_11 = mv_00; smv_UR_11 = (mb_x_i == 'b0) ? mv_00 : mv_L0; end					   	
		D_4x8  : begin  smv_L_00 = mv_L0; smv_U_00 = mv_U0; smv_UR_00 = mv_U1;			   	
					   	smv_L_10 = mv_00; smv_U_10 = mv_U1; smv_UR_10 = mv_U2;
					   	smv_L_01 = mv_L0; smv_U_01 = mv_U0; smv_UR_01 = mv_U1;
					   	smv_L_11 = mv_00; smv_U_11 = mv_U1; smv_UR_11 = mv_U2; end
		D_4x4  : begin  smv_L_00 = mv_L0; smv_U_00 = mv_U0; smv_UR_00 = mv_U1;			   	
					   	smv_L_10 = mv_00; smv_U_10 = mv_U1; smv_UR_10 = mv_U2;
					   	smv_L_01 = mv_L1; smv_U_01 = mv_00; smv_UR_01 = mv_10;
					   	smv_L_11 = mv_01; smv_U_11 = mv_10; smv_UR_11 = mv_00; end
	endcase			   	
end

always @(*) begin
	case (sub_partition[3:2])	
		D_8x8  : begin 	smv_L_20 = mv_10; smv_U_20 = mv_U2; smv_UR_20 = mv_UR;
					   	smv_L_30 = mv_10; smv_U_30 = mv_U2; smv_UR_30 = mv_UR;
					   	smv_L_21 = mv_10; smv_U_21 = mv_U2; smv_UR_21 = mv_UR;
					   	smv_L_31 = mv_10; smv_U_31 = mv_U2; smv_UR_31 = mv_UR; end 
		D_8x4  : begin  smv_L_20 = mv_10; smv_U_20 = mv_U2; smv_UR_20 = mv_UR;     
					   	smv_L_30 = mv_10; smv_U_30 = mv_U2; smv_UR_30 = mv_UR;     
					   	smv_L_21 = mv_11; smv_U_21 = mv_20; smv_UR_21 = mv_10;     
					   	smv_L_31 = mv_11; smv_U_31 = mv_20; smv_UR_31 = mv_10; end 				   	
		D_4x8  : begin  smv_L_20 = mv_10; smv_U_20 = mv_U2; smv_UR_20 = mv_U3; 	
					   	smv_L_30 = mv_20; smv_U_30 = mv_U3; smv_UR_30 = mv_UR;     
					   	smv_L_21 = mv_10; smv_U_21 = mv_U2; smv_UR_21 = mv_U3;     
					   	smv_L_31 = mv_20; smv_U_31 = mv_U3; smv_UR_31 = mv_UR; end 
		D_4x4  : begin  smv_L_20 = mv_10; smv_U_20 = mv_U2; smv_UR_20 = mv_U3; 	
					   	smv_L_30 = mv_20; smv_U_30 = mv_U3; smv_UR_30 = mv_UR;     
					   	smv_L_21 = mv_11; smv_U_21 = mv_20; smv_UR_21 = mv_30;       	
					   	smv_L_31 = mv_21; smv_U_31 = mv_30; smv_UR_31 = mv_20; end 		   	
	endcase
end

always @(*) begin
	case (sub_partition[5:4])	
		D_8x8  : begin  smv_L_02 = mv_L2; smv_U_02 = mv_01; smv_UR_02 = mv_21;
					    smv_L_12 = mv_L2; smv_U_12 = mv_01; smv_UR_12 = mv_21;  
					    smv_L_03 = mv_L2; smv_U_03 = mv_01; smv_UR_03 = mv_21;  
					    smv_L_13 = mv_L2; smv_U_13 = mv_01; smv_UR_13 = mv_21; end  
		D_8x4  : begin  smv_L_02 = mv_L2; smv_U_02 = mv_01; smv_UR_02 = mv_21;     
					    smv_L_12 = mv_L2; smv_U_12 = mv_01; smv_UR_12 = mv_21;      
					    smv_L_03 = mv_L3; smv_U_03 = mv_02; smv_UR_03 = (mb_x_i == 'b0) ? mv_02 : mv_L2;      
					    smv_L_13 = mv_L3; smv_U_13 = mv_02; smv_UR_13 = (mb_x_i == 'b0) ? mv_02 : mv_L2; end  
		D_4x8  : begin  smv_L_02 = mv_L2; smv_U_02 = mv_01; smv_UR_02 = mv_11; 	
					    smv_L_12 = mv_02; smv_U_12 = mv_11; smv_UR_12 = mv_21;      
					    smv_L_03 = mv_L2; smv_U_03 = mv_01; smv_UR_03 = mv_11;         	
					    smv_L_13 = mv_02; smv_U_13 = mv_11; smv_UR_13 = mv_21; end  							   	
		D_4x4  : begin 	smv_L_02 = mv_L2; smv_U_02 = mv_01; smv_UR_02 = mv_11;			   	
					   	smv_L_12 = mv_02; smv_U_12 = mv_11; smv_UR_12 = mv_21;     
					   	smv_L_03 = mv_L3; smv_U_03 = mv_02; smv_UR_03 = mv_12;     
					   	smv_L_13 = mv_03; smv_U_13 = mv_12; smv_UR_13 = mv_02; end 
	endcase
end

always @(*) begin
	case (sub_partition[7:6])
		D_8x8  : begin  smv_L_22 = mv_12; smv_U_22 = mv_21; smv_UR_22 = mv_11;
					    smv_L_32 = mv_12; smv_U_32 = mv_21; smv_UR_32 = mv_11;
					    smv_L_23 = mv_12; smv_U_23 = mv_21; smv_UR_23 = mv_11;
					    smv_L_33 = mv_12; smv_U_33 = mv_21; smv_UR_33 = mv_11; end 
		D_8x4  : begin  smv_L_22 = mv_12; smv_U_22 = mv_21; smv_UR_22 = mv_11;     
					    smv_L_32 = mv_12; smv_U_32 = mv_21; smv_UR_32 = mv_11;     
					    smv_L_23 = mv_13; smv_U_23 = mv_22; smv_UR_23 = mv_12;     
					    smv_L_33 = mv_13; smv_U_33 = mv_22; smv_UR_33 = mv_12; end 
		D_4x8  : begin  smv_L_22 = mv_12; smv_U_22 = mv_21; smv_UR_22 = mv_31; 	
					    smv_L_32 = mv_22; smv_U_32 = mv_31; smv_UR_32 = mv_21;	    	
					    smv_L_23 = mv_12; smv_U_23 = mv_21; smv_UR_23 = mv_31;	    			
					    smv_L_33 = mv_22; smv_U_33 = mv_31; smv_UR_33 = mv_21; end 			
		D_4x4  : begin 	smv_L_22 = mv_12; smv_U_22 = mv_21; smv_UR_22 = mv_31;					
					   	smv_L_32 = mv_22; smv_U_32 = mv_31; smv_UR_32 = mv_21;	    			
					   	smv_L_23 = mv_13; smv_U_23 = mv_22; smv_UR_23 = mv_32;	    			
					   	smv_L_33 = mv_23; smv_U_33 = mv_32; smv_UR_33 = mv_22; end 
	endcase
end

always @(*) begin
	case (ld_st_cnt)
		'd0 : begin mv_C_L = mv_L_00; mv_C_U = mv_U_00; mv_C_UR = mv_UR_00; mv_C = mv_00; end
		'd1 : begin mv_C_L = mv_L_10; mv_C_U = mv_U_10; mv_C_UR = mv_UR_10; mv_C = mv_10; end
		'd2 : begin mv_C_L = mv_L_01; mv_C_U = mv_U_01; mv_C_UR = mv_UR_01; mv_C = mv_01; end
		'd3 : begin mv_C_L = mv_L_11; mv_C_U = mv_U_11; mv_C_UR = mv_UR_11; mv_C = mv_11; end
		'd4 : begin mv_C_L = mv_L_20; mv_C_U = mv_U_20; mv_C_UR = mv_UR_20; mv_C = mv_20; end
		'd5 : begin mv_C_L = mv_L_30; mv_C_U = mv_U_30; mv_C_UR = mv_UR_30; mv_C = mv_30; end
		'd6 : begin mv_C_L = mv_L_21; mv_C_U = mv_U_21; mv_C_UR = mv_UR_21; mv_C = mv_21; end
		'd7 : begin mv_C_L = mv_L_31; mv_C_U = mv_U_31; mv_C_UR = mv_UR_31; mv_C = mv_31; end
		'd8 : begin mv_C_L = mv_L_02; mv_C_U = mv_U_02; mv_C_UR = mv_UR_02; mv_C = mv_02; end
		'd9 : begin mv_C_L = mv_L_12; mv_C_U = mv_U_12; mv_C_UR = mv_UR_12; mv_C = mv_12; end
		'd10: begin mv_C_L = mv_L_03; mv_C_U = mv_U_03; mv_C_UR = mv_UR_03; mv_C = mv_03; end
		'd11: begin mv_C_L = mv_L_13; mv_C_U = mv_U_13; mv_C_UR = mv_UR_13; mv_C = mv_13; end
		'd12: begin mv_C_L = mv_L_22; mv_C_U = mv_U_22; mv_C_UR = mv_UR_22; mv_C = mv_22; end
		'd13: begin mv_C_L = mv_L_32; mv_C_U = mv_U_32; mv_C_UR = mv_UR_32; mv_C = mv_32; end
		'd14: begin mv_C_L = mv_L_23; mv_C_U = mv_U_23; mv_C_UR = mv_UR_23; mv_C = mv_23; end
		'd15: begin mv_C_L = mv_L_33; mv_C_U = mv_U_33; mv_C_UR = mv_UR_33; mv_C = mv_33; end
    endcase
end

//-----------------------------------------------------
//                      FSM
//-----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		curr_state <= IDLE;
	else
		curr_state <= next_state;
end

always @(*) begin
	case (curr_state)
		IDLE: if (start_i)
				next_state = LOAD;
			  else
			  	next_state = IDLE;
		LOAD: if (ld_done)
				next_state = RUN;
			  else 
			    next_state = LOAD;
		RUN : if (cal_done)
				next_state = STORE;
			  else
			  	next_state = RUN;
		STORE:if (st_done)
				next_state = IDLE;
			  else
			  	next_state = STORE; 
	    default:next_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		ld_st_cnt <= 'd0;
	else if (st_done | ld_done | cal_done)
		ld_st_cnt <= 'd0;
	else if ((curr_state == LOAD && mb_y_i != 'd0) || (curr_state == STORE) || (curr_state == RUN))
		ld_st_cnt <= ld_st_cnt + 4'd1;
end
		
assign ld_done  = ((curr_state == LOAD) && ((mb_y_i == 'b0) || (ld_st_cnt == 'd5))) ? 1'b1 : 1'b0;
assign st_done  = ((curr_state == STORE)&& (ld_st_cnt == 'd3 )) ? 1'b1: 1'b0;	
assign cal_done = ((curr_state == RUN)  && (ld_st_cnt == 'd15)) ? 1'b1: 1'b0;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		done_o <= 1'b0;
	else if ((curr_state == STORE) && st_done)
		done_o <= 1'b1;
	else
		done_o <= 1'b0;
end


//-----------------------------------------------------
//              MV LEFT UP LOAD
//-----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		mv_L0 <= 'd0;
		mv_L1 <= 'd0;
		mv_L2 <= 'd0;
		mv_L3 <= 'd0;
	end
	else if (st_done) begin
		if (mb_x_i == mb_x_total) begin
			mv_L0 <= 'd0;
			mv_L1 <= 'd0;
			mv_L2 <= 'd0;
			mv_L3 <= 'd0;
		end
		else begin
			mv_L0 <= mv_30;
			mv_L1 <= mv_31;
			mv_L2 <= mv_32;
			mv_L3 <= mv_33;		
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		mv_U0 <= 'd0;
		mv_U1 <= 'd0;
		mv_U2 <= 'd0;
		mv_U3 <= 'd0;
		mv_UR <= 'd0;
	end
	else if (curr_state == LOAD) begin
		if (mb_y_i == 'b0) begin
			mv_U0 <= mv_L0;
			mv_U1 <= mv_00;
			mv_U2 <= mv_10;
			mv_U3 <= mv_20;
			mv_UR <= mv_10;  // for 8x16 mode
		end
		else begin
			mv_U0 <= (ld_st_cnt=='d1) ? mem_data_o:mv_U0;
			mv_U1 <= (ld_st_cnt=='d2) ? mem_data_o:mv_U1;
			mv_U2 <= (ld_st_cnt=='d3) ? mem_data_o:mv_U2;
			mv_U3 <= (ld_st_cnt=='d4) ? mem_data_o:mv_U3;	
			mv_UR <= ((mb_x_i == mb_x_total) && (ld_st_cnt=='d4)) ? mv_UR_right:
			         ((mb_x_i != mb_x_total) && (ld_st_cnt=='d5)) ? mem_data_o : mv_UR;	
		end
	end
end

always @(*) begin
	case (mb_type_inter)
		P_16x16: mv_UR_right = mv_U3;
		P_16x8 : mv_UR_right = mv_U3;
		P_8x16 : mv_UR_right = mv_U1;
		P_8x8  : mv_UR_right = smv_UR_right;
	endcase
end

always @(*) begin
	case (sub_partition[3:2])
		D_8x8: smv_UR_right = mv_U1;
		D_8x4: smv_UR_right = mv_U1;
		D_4x8: smv_UR_right = mv_U2;
		D_4x4: smv_UR_right = mv_U2;
	endcase
end


//------------------------------------------------
//               u_mv_ram
//------------------------------------------------
assign mem_cs = (curr_state == LOAD) | (curr_state == STORE);
assign mem_we = (curr_state == STORE) ? 1'b1 : 1'b0;
assign mem_addr = mem_addr_r + ld_st_cnt ;

always @(*) begin
	case (ld_st_cnt[1:0])
		'd0: mem_data_i = mv_03;
		'd1: mem_data_i = mv_13;
		'd2: mem_data_i = mv_23;
		'd3: mem_data_i = mv_33;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		mem_addr_r <= 'b0;
	else if (st_done)
		mem_addr_r <= (mb_x_i == mb_x_total) ? 9'b0 : mem_addr_r + 9'd4;
end

mv_ram_1p_16x480 u_mv_ram (
		        .clk    ( clk        ),
		        .ce     ( mem_cs     ),
		        .we     ( mem_we     ),
		        .addr   ( mem_addr   ),
		        .data_i ( mem_data_i ),
		        .data_o	( mem_data_o )        
);

//------------------------------------------------
//               u_mvd_ram
//------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		mem_sel <= 1'b0;
	else if (mem_sw_i)
		mem_sel <= ~mem_sel;
end

assign mvd_we 	 = (curr_state == RUN) ? 1'b1 : 1'b0;
assign mvd_waddr = {mem_sel, ld_st_cnt};
assign mvd_wdata = mvd_C;

mvd_ram_2p_18x32 u_mvd_ram (
				.clk     	( clk		), 
				.w_addr_i	( mvd_waddr	),
				.wr_i    	( mvd_we	),
				.data_i  	( mvd_wdata	),
				.rd_i    	( mvd_rd	),
				.r_addr_i	( {~mem_sel, mvd_raddr}),
				.data_o  	( mvd_rdata	)    
);

//------------------------------------------------
//               u_mvd_median
//------------------------------------------------
mvd_median  u_mvd_median(	
				.mv_L  ( mv_C_L  ),
				.mv_U  ( mv_C_U  ),
				.mv_UR ( mv_C_UR ),
				.mv_C  ( mv_C    ),
	            .mvd   ( mvd_C   )
);	

endmodule

//#####################################################
//               mvd_median definition
//#####################################################
module mvd_median(
				mv_L,
				mv_U,
				mv_UR,
				mv_C,
				mvd
);

input  [2*`FMVD_LEN-1:0] mv_L  ;
input  [2*`FMVD_LEN-1:0] mv_U  ;
input  [2*`FMVD_LEN-1:0] mv_UR ;
input  [2*`FMVD_LEN-1:0] mv_C  ;
output [2*`FMVD_LEN+1:0] mvd   ;

wire signed [`FMVD_LEN-1:0] mv_L_x , mv_L_y ;              
wire signed [`FMVD_LEN-1:0] mv_U_x , mv_U_y ;              
wire signed [`FMVD_LEN-1:0] mv_UR_x, mv_UR_y; 
wire signed [`FMVD_LEN-1:0] mv_C_x , mv_C_y ;    
reg  signed [`FMVD_LEN-1:0] mvp_x  , mvp_y  ;        
wire signed [`FMVD_LEN  :0] mvd_x  , mvd_y  ;                         
wire state_x0, state_x1, state_x2;
wire state_y0, state_y1, state_y2;


assign {mv_L_y , mv_L_x } = mv_L  ;
assign {mv_U_y , mv_U_x } = mv_U  ;
assign {mv_UR_y, mv_UR_x} = mv_UR ;
assign {mv_C_y , mv_C_x } = mv_C  ;

//--------------------------------------------------
//                median calculate
//--------------------------------------------------
assign state_x0=(mv_U_x<=mv_L_x )? 1'b1 : 1'b0;
assign state_x1=(mv_U_x<=mv_UR_x)? 1'b1 : 1'b0;
assign state_x2=(mv_L_x<=mv_UR_x)? 1'b1 : 1'b0;

assign state_y0=(mv_U_y<=mv_L_y )? 1'b1 : 1'b0;
assign state_y1=(mv_U_y<=mv_UR_y)? 1'b1 : 1'b0;
assign state_y2=(mv_L_y<=mv_UR_y)? 1'b1 : 1'b0;

//mvp_x
always @(*) begin
	case({state_x0, state_x1, state_x2})
		3'b000:mvp_x = mv_L_x;
		3'b001:mvp_x = mv_UR_x;
		3'b010:mvp_x = mv_U_x;
		3'b011:mvp_x = mv_U_x;
		3'b100:mvp_x = mv_U_x;
		3'b101:mvp_x = mv_L_x;
		3'b110:mvp_x = mv_UR_x;
		3'b111:mvp_x = mv_L_x;
	endcase
end

//mvp_y
always @(*) begin
	case({state_y0, state_y1, state_y2})
		3'b000:mvp_y = mv_L_y  ;
		3'b001:mvp_y = mv_UR_y ;
		3'b010:mvp_y = mv_U_y  ;
		3'b011:mvp_y = mv_U_y  ;
		3'b100:mvp_y = mv_U_y  ;
		3'b101:mvp_y = mv_L_y  ;
		3'b110:mvp_y = mv_UR_y ;
		3'b111:mvp_y = mv_L_y  ;
	endcase
end

assign mvd_x = mv_C_x - mvp_x;
assign mvd_y = mv_C_y - mvp_y;
assign mvd   = {mvd_x, mvd_y};

endmodule