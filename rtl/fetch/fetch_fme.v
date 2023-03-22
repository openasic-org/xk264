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
// Filename       : fetch_fme.v
// Author         : huibo zhong
// Created        : 2011-08-24
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
// Edited         : 2012-04-07 
// Author         : xing yuan 
//
// Edited         : 2012-10-17
// Author         : Yibo FAN
// Description	  : IME & Fetch Arch Update 
//
//------------------------------------------------------------------- 
`include "enc_defines.v"

module fetch_fme(
        clk                      ,
        rst_n                    ,
        sys_total_x           	 ,
        sys_total_y           	 ,                                 
        fme_ld_start_i			 ,
        fme_ld_done_i            ,
        fme_mb_x_i               ,        
        fme_mb_y_i               ,
        fme_ld_en_i              ,
        fme_sw_xx_i              ,        
        fme_sw_yy_i              ,
        fme_sw_zz_i              ,       
        fme_lddata_o             ,
        fme_ld_valid_o           ,
       	cache_rden_o	   		 ,                       
        cache_addr_o	         ,
        cache_data_i	         ,
        cache_bsel_i   
);
// *****************************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// *****************************************************
input                            clk                  ;       //clock   
input                            rst_n                ;       //reset_n 
// sys if
input  [`PIC_W_MB_LEN - 1:0] 	 sys_total_x       	  ;       //total MB Number in x_coordinate of one frame
input  [`PIC_H_MB_LEN - 1:0] 	 sys_total_y       	  ;       //total MB Number in y_coordinate of one frame
// fme_if
input							 fme_ld_start_i		  ;
input                            fme_ld_en_i          ;       //load_enable  FME                                                                                 
input                            fme_ld_done_i        ;       //load_done    FME                                                                                 
input        [7              :0] fme_mb_x_i           ;       //sw is in a default order for store (according to our regulations)                                
input        [7              :0] fme_mb_y_i           ;       //y_coordinate FME                                                                                 
input signed [`SW_W_LEN-4    :0] fme_sw_xx_i          ;       //16x16// the MSB is signed bit  //in search_window, the 16x16's position ; SW_W_LEN-4 = 6-4 =2    
input        [`SW_H_LEN-4    :0] fme_sw_yy_i          ;       //16X16  ; `SW_H_LEN-4 = 6-4 =2                                                                    
input        [3              :0] fme_sw_zz_i          ;       //In xx and yy ,designate zz line in 16x16 block                                                   
output[`MB_WIDTH*`BIT_DEPTH-1:0] fme_lddata_o         ;       //load_data_signal  FME                                                                            
output                           fme_ld_valid_o       ;       //load_data_valid  FME                                                                             
// cache if                                                          
output 				 		 		cache_rden_o	; // cache read enable
output [`SW_H_LEN-1:0]		 		cache_addr_o	; // cache read addres
input  [6*`MB_WIDTH*`BIT_DEPTH-1:0] cache_data_i	; // cache read data  
input  [5:0]				 		cache_bsel_i    ; // cache bank valid 

// *************************************************
//                                             
//    REG DECLARATION                         
//                                             
// *************************************************
reg                            		fme_ld_valid_o;
reg [5:0]							fme_valid_r;
reg [2:0]							bank_sel_r;
reg 								left_out_of_region  ;   
reg 								right_out_of_region	;
reg 								left2_out_of_region ;   
reg 								right2_out_of_region;
								
// *************************************************
//                                             
//    Wire DECLARATION                         
//                                             
// *************************************************
reg [5*`MB_WIDTH*`BIT_DEPTH-1:0] 	cache_data;
wire [`MB_WIDTH*`BIT_DEPTH-1 : 0] 	ram_bank_0, ram_bank_1, ram_bank_2,
									ram_bank_3, ram_bank_4, ram_bank_5;
reg [`MB_WIDTH*`BIT_DEPTH-1:0] 		fme_lddata_o  ;
wire 								top_out_of_region	;    
wire 								bottom_out_of_region;

// *************************************************
//                                                  
//    Logic  DECLARATION                            
//                                                  
// *************************************************
// out of region
assign top_out_of_region	= (fme_mb_y_i=='b0 && fme_sw_yy_i=='d0) ? 1'b1 : 1'b0;          
assign bottom_out_of_region = (fme_mb_y_i==sys_total_y && fme_sw_yy_i=='d2) ? 1'b1 : 1'b0;  

// cache data
assign ram_bank_0 = cache_data_i[1*`MB_WIDTH*`BIT_DEPTH-1 : 0*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_1 = cache_data_i[2*`MB_WIDTH*`BIT_DEPTH-1 : 1*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_2 = cache_data_i[3*`MB_WIDTH*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_3 = cache_data_i[4*`MB_WIDTH*`BIT_DEPTH-1 : 3*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_4 = cache_data_i[5*`MB_WIDTH*`BIT_DEPTH-1 : 4*`MB_WIDTH*`BIT_DEPTH];
assign ram_bank_5 = cache_data_i[6*`MB_WIDTH*`BIT_DEPTH-1 : 5*`MB_WIDTH*`BIT_DEPTH];

// cache read
assign cache_addr_o = top_out_of_region 	? 'd16:
					  bottom_out_of_region	? 'd31:
					  						  fme_sw_yy_i*16+fme_sw_zz_i;
assign cache_rden_o = fme_ld_en_i;


always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		fme_valid_r <= 6'b0;
	else if (fme_ld_start_i) begin
		if (fme_mb_x_i==sys_total_x && fme_mb_y_i==sys_total_y )
			fme_valid_r <= {fme_valid_r[4:0], fme_valid_r[5]};
		else begin
			case (cache_bsel_i)
				6'b000001: fme_valid_r <= 6'b111110; 
				6'b000010: fme_valid_r <= 6'b111101; 
				6'b000100: fme_valid_r <= 6'b111011; 
				6'b001000: fme_valid_r <= 6'b110111; 
				6'b010000: fme_valid_r <= 6'b101111; 
				6'b100000: fme_valid_r <= 6'b011111; 
				default	 : fme_valid_r <= 6'b0;
			endcase
		end
	end
end

always @(*) begin
	case (fme_valid_r)
		6'b111110: cache_data = {ram_bank_5, ram_bank_4, ram_bank_3, ram_bank_2, ram_bank_1};
		6'b111101: cache_data = {ram_bank_0, ram_bank_5, ram_bank_4, ram_bank_3, ram_bank_2};
		6'b111011: cache_data = {ram_bank_1, ram_bank_0, ram_bank_5, ram_bank_4, ram_bank_3};
		6'b110111: cache_data = {ram_bank_2, ram_bank_1, ram_bank_0, ram_bank_5, ram_bank_4};
		6'b101111: cache_data = {ram_bank_3, ram_bank_2, ram_bank_1, ram_bank_0, ram_bank_5};
		6'b011111: cache_data = {ram_bank_4, ram_bank_3, ram_bank_2, ram_bank_1, ram_bank_0};
		default: cache_data   = {ram_bank_5, ram_bank_4, ram_bank_3, ram_bank_2, ram_bank_1};
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fme_ld_valid_o 		 <= 1'b0;
		left_out_of_region   <= 1'b0;
		left2_out_of_region  <= 1'b0;
		right_out_of_region	 <= 1'b0;
		right2_out_of_region <= 1'b0;
		bank_sel_r			 <= 3'b0;
	end
	else  begin
		fme_ld_valid_o 		 <= fme_ld_en_i;
		left_out_of_region   <= (fme_mb_x_i == 'b0) ? 1'b1 : 1'b0;                                                                    
		left2_out_of_region  <= (fme_mb_x_i == 'b0 || (fme_mb_x_i == 'b1 && fme_sw_xx_i==3'b111)) ? 1'b1 : 1'b0;                      
		right_out_of_region	 <= (fme_mb_x_i == sys_total_x) ? 1'b1 : 1'b0;                                                             
		right2_out_of_region <= (fme_mb_x_i == sys_total_x || (fme_mb_x_i==sys_total_x-1'b1 && (fme_sw_xx_i==3'd2||fme_sw_xx_i==3'd3))) ? 1'b1 : 1'b0;  
		bank_sel_r			 <= fme_sw_xx_i;
	end
end

always @(*) begin
	case (bank_sel_r)
		3'b111: fme_lddata_o = left_out_of_region  ? {`MB_WIDTH{cache_data[(2*`MB_WIDTH+1)*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH]}} : 
							   left2_out_of_region ? {`MB_WIDTH{cache_data[(1*`MB_WIDTH+1)*`BIT_DEPTH-1 : 1*`MB_WIDTH*`BIT_DEPTH]}} : 
							   cache_data[1*`MB_WIDTH*`BIT_DEPTH-1 : 0*`MB_WIDTH*`BIT_DEPTH];
		3'd0  : fme_lddata_o = left_out_of_region  ? {`MB_WIDTH{cache_data[(2*`MB_WIDTH+1)*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH]}} : 
							   cache_data[2*`MB_WIDTH*`BIT_DEPTH-1 : 1*`MB_WIDTH*`BIT_DEPTH];                   
		3'd1  : fme_lddata_o = cache_data[3*`MB_WIDTH*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH];                      
		3'd2  : fme_lddata_o = right_out_of_region ? {`MB_WIDTH{cache_data[3*`MB_WIDTH*`BIT_DEPTH-1 : (3*`MB_WIDTH-1)*`BIT_DEPTH]}} : 
							   cache_data[4*`MB_WIDTH*`BIT_DEPTH-1 : 3*`MB_WIDTH*`BIT_DEPTH];               
	    3'd3  : fme_lddata_o = right_out_of_region ? {`MB_WIDTH{cache_data[3*`MB_WIDTH*`BIT_DEPTH-1 : (3*`MB_WIDTH-1)*`BIT_DEPTH]}} : 
	    					   right2_out_of_region? {`MB_WIDTH{cache_data[4*`MB_WIDTH*`BIT_DEPTH-1 : (4*`MB_WIDTH-1)*`BIT_DEPTH]}} :
	    					   cache_data[5*`MB_WIDTH*`BIT_DEPTH-1 : 4*`MB_WIDTH*`BIT_DEPTH];           
	    default:fme_lddata_o = cache_data[3*`MB_WIDTH*`BIT_DEPTH-1 : 2*`MB_WIDTH*`BIT_DEPTH];           
	endcase
end

endmodule
