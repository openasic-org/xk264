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
// Filename       : ime_defines.v
// Author         : Yibo FAN
// Created        : 2012-04-06
// Description    : IME Defines
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_top(
    			clk,
    			rstn,    
    			sysif_start_i,
    			sysif_done_o,
    			sysif_qp_i,
    			sysif_total_x_i,
    			sysif_total_y_i,
    			sysif_mb_x_i,
    			sysif_mb_y_i,
    			sysif_cmb_i,
    			fetchif_start_o,
    			fetchif_valid_i, 
    			fetchif_mb_x_o,  
    			fetchif_mb_y_o,  
    			fetchif_load_o,  
    			fetchif_addr_o,  
    			fetchif_data_i,
    			fmeif_valid_o,
    			fmeif_imv_o,
    			fmeif_mb_type_o
);
         
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input  								clk;
input  								rstn;
// sys if
input  								sysif_start_i;
output 								sysif_done_o;
input  [5:0]                        sysif_qp_i;
input  [`PIC_W_MB_LEN-1:0]     		sysif_total_x_i;
input  [`PIC_H_MB_LEN-1:0]     		sysif_total_y_i;
input  [`PIC_W_MB_LEN-1:0]     		sysif_mb_x_i;
input  [`PIC_H_MB_LEN-1:0]     		sysif_mb_y_i;
input  [`MB_SIZE*`BIT_DEPTH-1:0]    sysif_cmb_i; 
// fetch if
output                              fetchif_start_o;
input                               fetchif_valid_i;
output [`PIC_W_MB_LEN - 1:0]        fetchif_mb_x_o;
output [`PIC_H_MB_LEN - 1:0]        fetchif_mb_y_o;
output 								fetchif_load_o;
output [`SW_H_LEN-1:0]				fetchif_addr_o;
input  [3*16*`BIT_DEPTH-1:0]		fetchif_data_i; 
//fme if
output                                          fmeif_valid_o;
output [16*2*`IMVD_LEN-1:0]                     fmeif_imv_o;
output [`MB_TYPE_LEN + 4*`SUB_MB_TYPE_LEN-1:0]  fmeif_mb_type_o; 

// ********************************************
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
reg									sysif_done_o;
reg									fmeif_valid_o;
reg [`MB_TYPE_LEN + 4*`SUB_MB_TYPE_LEN-1:0]  	fmeif_mb_type_o; 

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************     
wire 													sadtree_end	  		;  
wire 													sadtree_done  		;
wire 													sadtree_run	  		;  
wire [2*`IMVD_LEN-1:0]									sadtree_imv	  		;  
wire [8:0]												sadtree_lamda 		;		    
wire [(`MB_WIDTH+`PE_NUM-1)*`MB_WIDTH*`BIT_DEPTH-1:0]	sadtree_refmb 		;  		    		    
wire [`MB_TYPE_LEN-1:0]									sadtree_mb_type		;    
wire [4*`SUB_MB_TYPE_LEN-1:0]							sadtree_sub_mb_type	;    
wire [16*2*`IMVD_LEN-1:0]								sadtree_mvd			;   

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
ime_sad_top u_ime_sad_top(
    .clk             ( clk					),
    .rstn            ( rstn					),   
    .end_ld_i        ( sadtree_end			), 
    .mvd_i           ( sadtree_imv			),    
    .data_v_i        ( sadtree_run			),
    .ref_i           ( sadtree_refmb		),             
    .end_ime_o       ( sadtree_done			),   
    .cmb_i           ( sysif_cmb_i			), 
    .lambda_i        ( sadtree_lamda		),    
    .mb_type_o       ( sadtree_mb_type		),
    .sub_mb_type_o   ( sadtree_sub_mb_type	),
    .mvd_o           ( sadtree_mvd			)
);

ime_ctrl u_ime_ctrl( 	
	.clk 			( clk 					), 
	.rstn			( rstn					),    
	.sysif_start_i	( sysif_start_i			),
	.sysif_qp_i		( sysif_qp_i			),
	.sysif_total_x_i( sysif_total_x_i		),
	.sysif_total_y_i( sysif_total_y_i		),
	.sysif_mb_x_i	( sysif_mb_x_i			),
	.sysif_mb_y_i	( sysif_mb_y_i			),    
	.fetchif_start_o( fetchif_start_o       ),			
	.fetchif_valid_i( fetchif_valid_i   	), 			
	.fetchif_mb_x_o	( fetchif_mb_x_o		),
	.fetchif_mb_y_o	( fetchif_mb_y_o		),
	.fetchif_load_o	( fetchif_load_o		),
	.fetchif_addr_o	( fetchif_addr_o		),
	.fetchif_data_i	( fetchif_data_i		),
	.sadtree_end_o	( sadtree_end			),
	.sadtree_imv_o	( sadtree_imv			),
	.sadtree_lamda_o( sadtree_lamda			),
	.sadtree_run_o	( sadtree_run			),
	.sadtree_refmb_o( sadtree_refmb			)
);

// ---------------------------------------------
//   IME Output                     
// ---------------------------------------------
always @(posedge clk or negedge rstn) begin
  if(!rstn)
    sysif_done_o <= 1'b0;
  else if (sysif_done_o)
  	sysif_done_o <= 1'b0;
  else if (sadtree_done)
  	sysif_done_o <= 1'b1;
end

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    fmeif_mb_type_o <= 'b0;
  else if (sadtree_done)
  	fmeif_mb_type_o <= {sadtree_sub_mb_type, sadtree_mb_type};
end

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    fmeif_valid_o <= 1'b0;
  else if (sysif_start_i)
  	fmeif_valid_o <= 1'b0;
  else if (sadtree_done)
  	fmeif_valid_o <= 1'b1;
end

assign fmeif_imv_o = sadtree_mvd ; 

endmodule
