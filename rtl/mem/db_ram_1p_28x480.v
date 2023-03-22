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
// Filename       : db_ram_1p_28x480.v
// Author         : Yibo FAN 
// Created        : 2013-08-23
// Description    : 1p ram for left 4x4 blocks buffer
// 28bit (include qp) for each 4x4 block, one MB need 4 4x4                                                 
// for 1080p, it need 120 x 4 == 480 words                                                                           
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module db_ram_1p_28x480 (
		        clk    ,
		        cen_i  ,
		        oen_i  ,
		        wen_i  ,
		        addr_i ,
		        data_i ,		
		        data_o		        
);

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter                 Word_Width = 28;
parameter                 Addr_Width = 9;

// ********************************************
//                                             
//    Input/Output DECLARATION                    
//                                             
// ********************************************
input                     clk;      // clock input
input   		          cen_i;    // chip enable, low active
input   		          oen_i;    // data output enable, low active
input   		          wen_i;    // write enable, low active
input   [Addr_Width-1:0]  addr_i;   // address input
input   [Word_Width-1:0]  data_i;   // data input
output	[Word_Width-1:0]  data_o;   // data output

// ********************************************
//                                             
//    Logic DECLARATION                 
//                                             
// ********************************************
`ifdef RTL_MODEL
ram_1p  #(
				.Word_Width ( Word_Width ),
				.Addr_Width ( Addr_Width )
)
ram_1p_28x480(
				.clk    ( clk         ),  
				.cen_i  ( cen_i       ),
				.wen_i  ( wen_i       ),  
				.oen_i  ( oen_i       ),
		        .addr_i ( addr_i 	  ),
		        .data_i ( data_i      ),
		        .data_o ( data_o      )
);
`endif

endmodule