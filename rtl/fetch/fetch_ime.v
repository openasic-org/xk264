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
// Filename       : fetch_ime.v
// Author         : huibo zhong
// Created        : 2011-08-24
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// Edited         : 2012-04-07 
// Author         : xing yuan 
//
// Edited         : 2012-10-08
// Author         : Yibo FAN
// Description	  : IME & Fetch Arch Update 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module fetch_ime(
        clk         	,
        rst_n       	,
        sys_total_x 	,
        sys_total_y 	,
        ime_start_i		,
        ime_valid_o 	,
        ime_mb_x_i		,
        ime_mb_y_i		,
        ime_load_i		,
        ime_addr_i		,
        ime_data_o		,
        cache_rden_o	,
        cache_addr_o	,
		cache_data_i	,
		cache_bsel_i
);
// *****************************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// *****************************************************
input                        clk                    ; //clock    
input                        rst_n                  ; //reset_n 
// sys if
input [`PIC_W_MB_LEN - 1:0]  sys_total_x            ; //total MB Number in x_coordinate of one frame
input [`PIC_H_MB_LEN - 1:0]  sys_total_y            ; //total MB Number in y_coordinate of one frame
// ime if                 
input						 ime_start_i			;            
output						 ime_valid_o	        ;      
input [`PIC_W_MB_LEN - 1:0]  ime_mb_x_i	            ;   
input [`PIC_H_MB_LEN - 1:0]  ime_mb_y_i	            ;   
input 						 ime_load_i	            ;   
input [`SW_H_LEN-1:0]		 ime_addr_i	            ;   
output [3*`MB_WIDTH*`BIT_DEPTH-1:0] ime_data_o	    ;   
// cache if
output 				 		 		cache_rden_o	; // cache read enable
output [`SW_H_LEN-1:0]		 		cache_addr_o	; // cache read address
input  [6*`MB_WIDTH*`BIT_DEPTH-1:0] cache_data_i	; // cache read data 
input  [5:0]				 		cache_bsel_i    ; // cache bank valid            

// *************************************************                       
//                                                                    
//    REG DECLARATION                                                
//                                                                    
// *************************************************
reg [5:0]							ime_valid_r;
                                                        
// *************************************************                       
//                                                                    
//    Wire DECLARATION                                                
//                                                                    
// *************************************************  
reg [3*`MB_WIDTH*`BIT_DEPTH-1:0] 	cache_data;
wire 								left_out_of_region  ;   
wire 								right_out_of_region	;
wire 								top_out_of_region	;    
wire 								bottom_out_of_region;	
wire [`MB_WIDTH*`BIT_DEPTH-1 : 0] 	ram_bank_0, ram_bank_1, ram_bank_2,
									ram_bank_3, ram_bank_4, ram_bank_5;

// *************************************************
//                                                  
//    Logic  DECLARATION                            
//                                                  
// *************************************************
// out of region
assign left_out_of_region   = (ime_mb_x_i == 'b0) ? 1'b1 : 1'b0;
assign right_out_of_region	= (ime_mb_x_i == sys_total_x) ? 1'b1 : 1'b0;
assign top_out_of_region	= (ime_mb_y_i=='b0 && ime_addr_i<'d16) ? 1'b1 : 1'b0;
assign bottom_out_of_region	= (ime_mb_y_i==sys_total_y && ime_addr_i>'d31) ? 1'b1 : 1'b0;

// cache read
assign cache_addr_o = top_out_of_region 	? 'd16:
					  bottom_out_of_region	? 'd31:
					  						  ime_addr_i;
assign cache_rden_o = ime_load_i;

// ime read
assign ram_bank_0 = cache_data_i[1*`MB_WIDTH*`BIT_DEPTH-1 : 0*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_1 = cache_data_i[2*`MB_WIDTH*`BIT_DEPTH-1 : 1*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_2 = cache_data_i[3*`MB_WIDTH*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_3 = cache_data_i[4*`MB_WIDTH*`BIT_DEPTH-1 : 3*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_4 = cache_data_i[5*`MB_WIDTH*`BIT_DEPTH-1 : 4*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_5 = cache_data_i[6*`MB_WIDTH*`BIT_DEPTH-1 : 5*`MB_WIDTH*`BIT_DEPTH];

always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		ime_valid_r <= 6'b0;
	else if (ime_start_i) begin
		case (cache_bsel_i)
			6'b000001: ime_valid_r <= 6'b111000; 
			6'b000010: ime_valid_r <= 6'b110001; 
			6'b000100: ime_valid_r <= 6'b100011; 
			6'b001000: ime_valid_r <= 6'b000111; 
			6'b010000: ime_valid_r <= 6'b001110; 
			6'b100000: ime_valid_r <= 6'b011100; 
			default	 : ime_valid_r <= 6'b0;
		endcase
	end
end

always @(*) begin
	case (ime_valid_r)
		6'b111000: cache_data = {ram_bank_5, ram_bank_4, ram_bank_3};
		6'b110001: cache_data = {ram_bank_0, ram_bank_5, ram_bank_4};
		6'b100011: cache_data = {ram_bank_1, ram_bank_0, ram_bank_5};
		6'b000111: cache_data = {ram_bank_2, ram_bank_1, ram_bank_0};
		6'b001110: cache_data = {ram_bank_3, ram_bank_2, ram_bank_1};
		6'b011100: cache_data = {ram_bank_4, ram_bank_3, ram_bank_2};
		default: cache_data = {ram_bank_5, ram_bank_4, ram_bank_3};
	endcase
end

assign ime_data_o = { right_out_of_region ? {`MB_WIDTH{cache_data[(2*`MB_WIDTH)*`BIT_DEPTH-1 : (2*`MB_WIDTH-1)*`BIT_DEPTH]}} 
										  : cache_data[(3*`MB_WIDTH)*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH],
					  cache_data[(2*`MB_WIDTH)*`BIT_DEPTH-1 : `MB_WIDTH*`BIT_DEPTH],
					  left_out_of_region  ? {`MB_WIDTH{cache_data[(`MB_WIDTH+1)*`BIT_DEPTH-1 : `MB_WIDTH*`BIT_DEPTH]}}
					  					  : cache_data[(1*`MB_WIDTH)*`BIT_DEPTH-1 : 0*`MB_WIDTH*`BIT_DEPTH]
					};

assign ime_valid_o = 1'b1;

endmodule
