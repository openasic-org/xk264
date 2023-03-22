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
// Filename       : fetch_ram_2p_64x144.v                            
// Author         : xyuan                                            
// Created        : 2012/4/7                                         
//-------------------------------------------------------------------
// Description    : two port sram                                    
// 
// version        :  0.2                                             
// Author         : Xing Yuan
// Created        : 2012-5-10
// Description    : Add FPGA_model                                   
// $Id$                                                              
//-------------------------------------------------------------------

`include "enc_defines.v"

module fetch_ram_2p_64x144 ( 
    clk_i  ,
    wren   ,
    wraddr ,
    wrdata ,
    rden   ,
    rdaddr ,
    rddata 
);
// *****************************************************
//                                                      
//    INPUT / OUTPUT DECLARATION                        
//                                                      
// *****************************************************
input  clk_i                            ;  //clock
input  wren                             ;  //write_enbale
input  [7           :0] wraddr          ;
input  [63          :0] wrdata          ;
input  rden                             ;  //read_enbale 
input  [7           :0] rdaddr          ;
output [63          :0] rddata          ;

// *****************************************************
//                                                      
//    LOGIC   DECLARATION                        
//                                                      
// *****************************************************
`ifdef  RTL_MODEL
rf_2p #( .Word_Width(64), .Addr_Width (8))
    rf_2p_64x144(
	      .clka      (clk_i  )         ,  
	      .cena_i    (~rden  )         ,  //low active 
	      .addra_i   (rdaddr )         ,
	      .dataa_o   (rddata )         ,
	      .clkb      (clk_i  )         ,      
	      .cenb_i    (~wren  )         ,  //low active   
	      .wenb_i    (~wren  )         ,  //low active 
	      .addrb_i   (wraddr )         ,  
	      .datab_i   (wrdata )   
);
`endif

`ifdef FPGA_MODEL
ram_2p_64x144 u_ram_2p_64x144(
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
