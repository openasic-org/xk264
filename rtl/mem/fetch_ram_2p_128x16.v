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
// Filename       : fetch_ram_2p_128x16.v                            
// Author         : Yibo FAN                                            
// Created        : 2013/08/23
// Description    : db top ref buffer
//                                         
//-------------------------------------------------------------------
`include "enc_defines.v"

module fetch_ram_2p_128x16 ( 
    					clk     ,
    					wdata   ,
    					waddr   ,
    					we      ,
    					rd      ,
    					raddr   ,
    					rdata    
);
// *****************************************************
//                                                      
//    INPUT / OUTPUT DECLARATION                        
//                                                      
// *****************************************************
input               clk      ;  
input  [127:0]		wdata    ;  
input  [3:0]    	waddr    ;  
input   			we       ;  
input    			rd       ;  
input  [3:0]  		raddr    ;  
output [127:0]   	rdata    ;  

// *****************************************************
//                                                      
//    LOGIC   DECLARATION                        
//                                                      
// *****************************************************
`ifdef RTL_MODEL
rf_2p #(.Addr_Width(4), .Word_Width(128))	
	   rf_2p_128x16 (
				.clka    ( clk      ),  
				.cena_i  ( ~rd      ),
		        .addra_i ( raddr    ),
		        .dataa_o ( rdata    ),
				.clkb    ( clk      ),     
				.cenb_i  ( ~we      ),  
				.wenb_i  ( ~we      ),   
				.addrb_i ( waddr    ),
				.datab_i ( wdata    )
);
`endif 

`ifdef FPGA_MODEL
ram_2p_128x16 u_ram_2p_128x16(
	      .clock     ( clk_i  )       ,
	      .wraddress ( wraddr )       ,
	      .wren      ( wren   )       ,  //high active 
	      .data      ( wrdata )       ,
	      .rdaddress ( rdaddr )       ,
	      .rden      ( rden   )       ,  //high active 
	      .q         ( rddata )       
);
`endif 

`ifdef SMIC13_MODEL

`endif

endmodule 
