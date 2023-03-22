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
// Filename       : fme_ram_2p_160x128.v                                               
// Author         : Yibo FAN                                         
// Created        : 2012-05-08                                       
// Description    : chroma, 16x16, mc coefficient ram                                                
//                                                                   
//                                                                   
// version        :  0.2                                                                  
// Author         : Xing Yuan
// Created        : 2012-5-10
// Description    : Add FPGA_model                                                                     
// $Id$                                                              
//-------------------------------------------------------------------

`include "enc_defines.v"


//module fme_dpram_160x128 

module fme_ram_2p_160x128 (
    				clk       , 
    				addr_a    , 
    				rdata_a   , 
    				wdata_a   , 
    				csn_a     ,
    				wen_a     ,
    				addr_b    , 
    				rdata_b   , 
    				wdata_b   , 
    				csn_b     ,
                    wen_b     
);                                             

// ********************************************
//                                             
//    Input/Output DECLARATION                    
//                                             
// ********************************************
input               clk      ; 
input  [159:0]		wdata_a, wdata_b;
output [159:0]   	rdata_a, rdata_b;
input  [6:0]    	addr_a , addr_b ;
input   			wen_a, csn_a, wen_b, csn_b;

// ********************************************
//                                             
//    Logic DECLARATION                 
//                                             
// ********************************************
`ifdef RTL_MODEL

ram_2p #(.Addr_Width(7), .Word_Width(160)) 
		ram_2p_160x128 (
				.clka    ( clk         ),  
				.cena_i  ( csn_a       ),
		        .oena_i  ( 1'b0        ),
		        .wena_i  ( wen_a       ),
		        .addra_i ( addr_a      ),
		        .dataa_o ( rdata_a     ),
		        .dataa_i ( wdata_a     ),
				.clkb    ( clk         ),     
				.cenb_i  ( csn_b       ),   
				.oenb_i  ( 1'b0        ),   
				.wenb_i  ( wen_b       ),   
				.addrb_i ( addr_b      ),
				.datab_o ( rdata_b     ),   
				.datab_i ( wdata_b     )
);
`endif 

`ifdef FPGA_MODEL

ram_dp_160x128 u_ram_dp_160x128(
	.clock    (clk      ),
  //Port_A              
	.address_a(addr_a   ),
	.wren_a   (~wen_a   ),  //write high active 
	.data_a   (wdata_a  ),
	.q_a      (rdata_a  ),
  //Port_B              
	.address_b(addr_b   ),
	.data_b   (wdata_b  ),
	.wren_b   (~wen_b   ), //write high active 
	.q_b      (rdata_b  )
);

`endif 

`ifdef SMIC13_MODEL 

`endif 

endmodule
