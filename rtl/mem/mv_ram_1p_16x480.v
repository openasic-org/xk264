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
// Filename       : mv_ram_1p_16x480.v
// Author         : huibo zhong
// Created        : 2011-09-06
// Description    : Word_width = 4 4x4 mv equals to 64 bit
//                  Word_depth = mb_x number,  for 1920x1088 is 120 MB  
//  
// version        :  0.2                                                                  
// Author         : Xing Yuan
// Created        : 2012-5-10
// Description    : Add FPGA_model               
// $Id$  
//------------------------------------------------------------------- 

`include "enc_defines.v"

module mv_ram_1p_16x480(
				clk,
				ce,
				we,
				addr,
				data_i,
				data_o
);
parameter DATAWIDTH = 16;
parameter ADDRWIDTH = 9;

input	  clk ;
input     ce ;
input     we ;

input     [ADDRWIDTH-1 : 0] addr ;
input     [DATAWIDTH-1 : 0] data_i ;
output    [DATAWIDTH-1 : 0] data_o ;

`ifdef   RTL_MODEL
ram_1p      #(	.Word_Width ( DATAWIDTH ),
				.Addr_Width ( ADDRWIDTH )
)
ram_1p_16x480 (
				.clk       ( clk     ),   // write side 
				.cen_i     ( ~ce     ),
		        .oen_i     ( 1'b0    ),
		        .wen_i     ( ~we     ),   //write :low active 
		        .addr_i    ( addr    ),
		        .data_o    ( data_o  ),
		        .data_i    ( data_i  )
); 
`endif


`ifdef   FPGA_MODEL

ram_1p_16x480  u_ram_1p_16x480 (
	.clock  ( clk     ),
    .wren   ( we      ),   // write : high active 
	.address( addr    ),
	.data   ( data_i  ),
	.q      ( data_o  )
);

`endif


`ifdef   SMIC13_MODEL



`endif 


endmodule
