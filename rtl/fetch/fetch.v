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
// Filename       : fetch.v
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
// Edited         : 2012-10-08
// Author         : Yibo FAN
// Description	  : IME & Fetch Arch Update 
//
//------------------------------------------------------------------- 
`include "enc_defines.v"

module fetch(
        clk                        ,
        rst_n                      ,   
        sysif_total_x_i            ,
        sysif_total_y_i            ,
        sysif_luma_mb_x_i		   ,
        sysif_luma_mb_y_i		   ,
        sysif_luma_start_i		   ,
        sysif_luma_done_o		   ,
                                           
        extif_luma_req_o           ,
        extif_luma_done_i          ,
        extif_luma_mb_x_o          ,
        extif_luma_mb_y_o          ,
        extif_luma_data_v_i        ,
        extif_luma_data_i          ,
        
        imeif_start_i              ,
        imeif_valid_o         	   ,
        imeif_mb_x_i          	   ,
        imeif_mb_y_i          	   ,
        imeif_load_i          	   ,
        imeif_addr_i          	   ,
        imeif_data_o          	   ,
        
        fmeif_ld_start_i           ,                           
        fmeif_ld_en_i              ,
        fmeif_ld_done_i            ,
        fmeif_mb_x_i               ,
        fmeif_mb_y_i               ,
        fmeif_sw_xx_i              ,
        fmeif_sw_yy_i              ,
        fmeif_sw_zz_i              ,
        fmeif_lddata_o             ,
        fmeif_ld_valid_o           
);
// *****************************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// *****************************************************
input                       clk                      ;     //clock               
input                       rst_n                    ;     //reset_n             

input  [7              :0]  sysif_total_x_i          ;     //total MB Number in x_coordinate of one frame
input  [7              :0]  sysif_total_y_i          ;     //total MB Number in y_coordinate of one frame  
input  [`PIC_W_MB_LEN - 1:0]sysif_luma_mb_x_i		 ;
input  [`PIC_H_MB_LEN - 1:0]sysif_luma_mb_y_i		 ;
input						sysif_luma_start_i		 ;
output						sysif_luma_done_o		 ;                                                    

output                      extif_luma_req_o         ;     //luma_load_request to external memory             
input                       extif_luma_done_i        ;     //luma_load_done signal from ext_memory            
output [7              :0]  extif_luma_mb_x_o        ;     //luma_load one MB's  x_coordinate to ext_memory   
output [7              :0]  extif_luma_mb_y_o        ;     //luma_load_one MB's  y_coordinate to ext_memory   
input                       extif_luma_data_v_i      ;     //luma_load_MB  data_valid from ext_memory         
input  [8*`BIT_DEPTH-1 :0]  extif_luma_data_i        ;     //luma_load_MB  data_i  from ext_memory            
                                                     
input						imeif_start_i            ;                                                                                                                  
output						imeif_valid_o	         ;     //load_enable  from IME                               
input [`PIC_W_MB_LEN - 1:0] imeif_mb_x_i	         ;      //load search window's data end  from IME             
input [`PIC_H_MB_LEN - 1:0] imeif_mb_y_i	         ;      //MB's x_coordinate   from IME                        
input 						imeif_load_i	         ;      //MB's y_coordinate   from IME                        
input [`SW_H_LEN-1:0]		imeif_addr_i	         ;      //                                                    
output [3*16*`BIT_DEPTH-1:0]imeif_data_o	         ;       //load_data  to IME                                                              

input                       fmeif_ld_start_i         ;                                                                                                                  
input                       fmeif_ld_en_i            ;      //load_enable  from FME                               
input                       fmeif_ld_done_i          ;      //load search window's data end from FME              
input [7              :0]   fmeif_mb_x_i             ;      //MB's x_coordinate   from FME                        
input [7              :0]   fmeif_mb_y_i             ;      //MB's y_coordinate   from FME                        
input [`SW_W_LEN-4    :0]   fmeif_sw_xx_i            ;      //                                                    
input [`SW_H_LEN-4    :0]   fmeif_sw_yy_i            ;      //                                                    
input [3              :0]   fmeif_sw_zz_i            ;      //                                                    
output[16*`BIT_DEPTH-1:0]   fmeif_lddata_o           ;      //load_data  to FME                                   
output                      fmeif_ld_valid_o         ;      //load_data_valid  to FME                             
                                                                                                                                     
// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
wire [5:0]					luma_bank_sel	        ;

wire 						ime_cache_rden 			;
wire [`SW_H_LEN-1:0]		ime_cache_addr 	        ;
wire [6*`MB_WIDTH*`BIT_DEPTH-1:0]ime_cache_data 	;

wire 						fme_cache_rden 			;
wire [`SW_H_LEN-1:0]		fme_cache_addr 	        ;
wire [6*`MB_WIDTH*`BIT_DEPTH-1:0]fme_cache_data 	;

// ******************************************************
//                                             
//    Sub Modules                              
//                                             
// ******************************************************         
//external control
fetch_luma u_fetch_luma (
        .clk             	(clk             	),
        .rst_n           	(rst_n           	),
        .sys_total_x		(sysif_total_x_i	),
        .sys_total_y     	(sysif_total_y_i	),
        .sys_mb_x_i      	(sysif_luma_mb_x_i	),
        .sys_mb_y_i      	(sysif_luma_mb_y_i	),
        .sys_load_i			(sysif_luma_start_i	),
        .sys_done_o			(sysif_luma_done_o	), 
        .ext_start_o		(extif_luma_req_o   ),
        .ext_done_i      	(extif_luma_done_i  ),
        .ext_mb_x_o      	(extif_luma_mb_x_o  ),
        .ext_mb_y_o      	(extif_luma_mb_y_o  ),
        .ext_valid_i     	(extif_luma_data_v_i),
        .ext_data_i      	(extif_luma_data_i  ),
        .bank_sel_o			(luma_bank_sel		),
        .ime_rden_i			(ime_cache_rden 	),	  
        .ime_addr_i	    	(ime_cache_addr 	),
        .ime_data_o	    	(ime_cache_data 	),
        .fme_rden_i			(fme_cache_rden 	),
        .fme_addr_i	    	(fme_cache_addr 	),
        .fme_data_o	    	(fme_cache_data 	)  
);

//ime interface
fetch_ime u_fetch_ime(
        .clk         	( clk                    ),
        .rst_n       	( rst_n                  ),
        .sys_total_x 	( sysif_total_x_i      	 ),
        .sys_total_y 	( sysif_total_y_i      	 ),
        .ime_start_i    ( imeif_start_i		     ),
        .ime_valid_o 	( imeif_valid_o  	     ),
        .ime_mb_x_i		( imeif_mb_x_i	         ),
        .ime_mb_y_i		( imeif_mb_y_i	         ),  
        .ime_load_i		( imeif_load_i	         ),
        .ime_addr_i		( imeif_addr_i	         ),
        .ime_data_o		( imeif_data_o	         ),                                                      
        .cache_rden_o	( ime_cache_rden         ),
        .cache_addr_o	( ime_cache_addr         ),
        .cache_data_i	( ime_cache_data         ),                                                      
        .cache_bsel_i   ( luma_bank_sel          )
);

//fme interface
fetch_fme u_fetch_fme(
        .clk       		( clk                  ),
        .rst_n     		( rst_n                ),
        .sys_total_x 	( sysif_total_x_i      ),
        .sys_total_y 	( sysif_total_y_i      ),
        .fme_ld_start_i ( fmeif_ld_start_i     ),                                                     
        .fme_ld_en_i   	( fmeif_ld_en_i        ),
        .fme_ld_done_i 	( fmeif_ld_done_i      ),
        .fme_mb_x_i    	( fmeif_mb_x_i         ),  
        .fme_mb_y_i    	( fmeif_mb_y_i         ),  
        .fme_sw_xx_i   	( fmeif_sw_xx_i        ),  
        .fme_sw_yy_i   	( fmeif_sw_yy_i        ),  
        .fme_sw_zz_i   	( fmeif_sw_zz_i        ),  
        .fme_lddata_o  	( fmeif_lddata_o       ),
        .fme_ld_valid_o	( fmeif_ld_valid_o     ),                                                     
        .cache_rden_o	( fme_cache_rden       ),
        .cache_addr_o	( fme_cache_addr       ),
        .cache_data_i	( fme_cache_data       ),                                                                                                         
        .cache_bsel_i 	( luma_bank_sel        )
);

endmodule