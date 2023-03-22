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
// Filename       : mvd_ram_2p_18x32.v                                                                                                                
// version        : 1.0                                                                 
// Author         : Yibo FAN
// Created        : 2013-06-08
// Description    : mvd buf for mvd module and ec module                                                                  
//                                                                   
// $Id$                                                              
//-------------------------------------------------------------------

`include "enc_defines.v"

module mvd_ram_2p_18x32 (
				clk     , 
				w_addr_i,
				wr_i    ,
				data_i  ,
				rd_i    ,
				r_addr_i,
				data_o  
);
//******************************************
//
//  Input / Output DECLARATION 
//
//******************************************
input			clk		;
input [4:0]		w_addr_i;
input			wr_i    ; 
input [17:0]    data_i	;
input			rd_i	;
input [4:0]		r_addr_i;
output[17:0]	data_o  ; 

//******************************************
//
//  Input / Output DECLARATION 
//
//******************************************
`ifdef RTL_MODEL 
rf_2p #(.Addr_Width(5), .Word_Width(18))
rf_2p_18x32(
//read
	.clka	(clk),
	.cena_i (~rd_i),	//low active
	.addra_i(r_addr_i),
	.dataa_o(data_o),
//write 
	.clkb	(clk),
	.cenb_i (~wr_i),	//low active 
	.wenb_i (~wr_i),	//low active 
	.addrb_i(w_addr_i),
	.datab_i(data_i)
);
`endif

`ifdef FPGA_MODEL 
ram_2p_18x32 u_ram_2p_18x32(
	.clock	  (clk		),
	.data	  (data_i	),
	.wraddress(w_addr_i	),
	.wren     (wr_i		),	//high active 
	.rdaddress(r_addr_i	),
	.rden 	  (rd_i		),	//high active 
	.q	  	  (data_o	)
);

`endif

`ifdef SMIC13_MODEL

`endif 


endmodule 
