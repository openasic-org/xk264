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
// Filename       : fetch_ram_dp_128x48.v                            
// Author         : xyuan                                            
// Created        : 2012/4/7                                         
//-------------------------------------------------------------------
// Description    : dual port sram                                   
// 
// version        :  0.2                                                  
// Author         : Xing Yuan
// Created        : 2012-5-10
// Description    : Add FPGA_model                                   
// $Id$                                                              
//-------------------------------------------------------------------
 
`include "enc_defines.v"

//fetch_dp_ram_128x48 
module fetch_ram_dp_128x48(
     clk    	,
     rda_i      ,      
     addra_i    ,
     dataa_o    , 
     rdb_i      ,
     web_i      ,
     wsb_i		, 
     addrb_i	,
     datab_o    , 
     datab_i   
);
// *****************************************************
//                                                      
//    INPUT / OUTPUT DECLARATION                        
//                                                      
// *****************************************************
//--------------Input Ports----------------------- 
input            clk             ; // clock
input			 rda_i			 ; // a port : read enable
input [5     :0] addra_i         ; // a port : address
output [127:0]   dataa_o         ; // a port : read data 
input			 rdb_i			 ; // b port : read enable
input			 web_i			 ; // b port : write enable
input			 wsb_i			 ; // b port : write bank sel
input [5     :0] addrb_i         ; // b port : write/read address
output [127:0]   datab_o         ; // b port : read data
input  [63:0]    datab_i         ; // b port : write data

// *****************************************************
//                                                      
//    LOGIC   DECLARATION                        
//                                                      
// *****************************************************

`ifdef RTL_MODEL 
ram_2p #(  .Word_Width(64) ,.Addr_Width(6) )
ram_2p_64x48_l(
		.clka      (clk         )    ,  
		.cena_i    (~rda_i      )    ,    //low active 
		.oena_i    (1'b0        )    ,    //low active 
		.wena_i    (1'b1        )    ,    //write low active 
		.addra_i   (addra_i     )    ,
		.dataa_o   (dataa_o[63:0])    ,
		.dataa_i   (            )    ,
		.clkb      (clk         )    ,     
		.cenb_i    (~(rdb_i|web_i))    ,    //low active      
		.oenb_i    (1'b0        )    ,    //low active      
		.wenb_i    (~(web_i&(~wsb_i)))    ,    //write low active
		.addrb_i   (addrb_i     )    ,
		.datab_o   (datab_o[63:0]     )    ,   
		.datab_i   (datab_i     )  
);

ram_2p #(  .Word_Width(64) ,.Addr_Width(6) )
ram_2p_64x48_r(
		.clka      (clk         )    ,  
		.cena_i    (~rda_i      )    ,    //low active 
		.oena_i    (1'b0        )    ,    //low active 
		.wena_i    (1'b1        )    ,    //write low active 
		.addra_i   (addra_i     )    ,
		.dataa_o   (dataa_o[127:64]     )    ,
		.dataa_i   (            )    ,
		.clkb      (clk         )    ,     
		.cenb_i    (~(rdb_i|web_i))    ,    //low active      
		.oenb_i    (1'b0        )    ,    //low active      
		.wenb_i    (~(web_i&wsb_i))    ,    //write low active
		.addrb_i   (addrb_i     )    ,
		.datab_o   (datab_o[127:64]     )    ,   
		.datab_i   (datab_i     )  
);

`endif 

`ifdef FPGA_MODEL
ram_dp_64x48 u_ram_dp_64x48_l(
    // Port A
	    .clock_a   ( clk        	)    ,
	    .address_a ( addra_i    	)    ,
	    .data_a    (   		)    ,
	    .wren_a    ( 1'b0		)    ,   // write high_active
	    .rden_a    ( rda_i		)    ,
	    .q_a       ( dataa_o[63:0]	)    ,
    // Port B                        
	    .clock_b   ( clk        	)    ,
	    .address_b ( addrb_i	)    ,
	    .data_b    ( datab_i        )    , 
	    .wren_b    ( (web_i&(~wsb_i)))    ,  // write  high_active 
	    .rden_b    ( (rdb_i|web_i)	)    ,
	    .q_b       ( datab_o[63:0]	)    
);
ram_dp_64x48 u_ram_dp_64x48_r(
    // Port A
	    .clock_a   ( clk        	)    ,
	    .address_a ( addra_i	)    ,
	    .data_a    (		)    ,
	    .wren_a    ( 1'b0	       	)    ,   // write high_active 
	    .rden_a    ( rda_i		)    ,
	    .q_a       ( dataa_o[127:64])    ,
    // Port B                        
	    .clock_b   ( clk        	)    ,
	    .address_b ( addrb_i 	)    ,
	    .data_b    ( datab_i	)    ,  
	    .wren_b    ( (web_i&wsb_i)  )    ,  // write  high_active
	    .rden_b    ( (rdb_i|web_i)  )    , 
	    .q_b       ( datab_o[127:64])    
);
`endif

`ifdef SMIC13_MODEL

`endif

endmodule 
