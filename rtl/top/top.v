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
// Filename       : top.v
// Author         : Yibo FAN
// Created        : 2012-5-02
// Description    : top of encoder
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module top     (
				clk				,
				rst_n			,		
				sys_start		,      
				sys_done		,		
				sys_intra_flag	,
				sys_qp			, 
				sys_mode		,       
				sys_x_total		,    
				sys_y_total		,
				enc_ld_start	,
				enc_ld_x		,
				enc_ld_y		,	
				rdata_i			,
				rvalid_i		,
				rinc_o			,
				wdata_o			,
				wfull_i			,
				winc_o			,				
				ext_mb_x_o  	,       	
				ext_mb_y_o  	,       	
				ext_start_o 	,       	
				ext_done_i  	,       	
				ext_mode_o  	,       	
				ext_wen_i		,		
				ext_ren_i		,		
				ext_addr_i  	,     	
				ext_data_i  	,        
				ext_data_o 			
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input 		  					clk, rst_n;
// SYS IF
input							sys_start;     
output							sys_done;		                			
input							sys_intra_flag; 
input [5:0]						sys_qp;
input 							sys_mode; 
input [`PIC_W_MB_LEN-1:0] 		sys_x_total;    
input [`PIC_H_MB_LEN-1:0]  		sys_y_total;
output							enc_ld_start;
output [`PIC_W_MB_LEN-1:0]		enc_ld_x;
output [`PIC_H_MB_LEN-1:0]  	enc_ld_y;
// RAW INPUT IF
input [8*`BIT_DEPTH - 1:0]   	rdata_i;
input          					rvalid_i;
output         					rinc_o;
// STREAM OUTPUT IF
output [7:0]   					wdata_o;
input          					wfull_i;
output         					winc_o;
// EXT MEM IF
output [`PIC_W_MB_LEN-1:0]  	ext_mb_x_o  ;	
output [`PIC_H_MB_LEN-1:0] 		ext_mb_y_o  ;	
output                      	ext_start_o ;	
input                       	ext_done_i  ;	
output [2:0]              		ext_mode_o  ;	
input							ext_wen_i	;	
input							ext_ren_i	;	
input  [3:0]					ext_addr_i  ;	
input  [16*`BIT_DEPTH - 1:0]	ext_data_i  ;	
output [4*4*`BIT_DEPTH - 1:0]	ext_data_o 	;	

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
//------------------ u_top_ctrl ------------------//
wire                       	load_start, ime_start, fme_start, mc_start, intra_start, ec_start, db_start, frame_start, fetch_chroma_start, fetch_luma_start, fetch_db_start;
wire                       	load_done , ime_done , fme_done , mc_done , intra_done , ec_done , db_done , frame_done , fetch_chroma_done , fetch_luma_done , fetch_db_done ; 
wire [`PIC_W_MB_LEN-1:0]   	mb_x_total, mb_x_load, mb_x_intra, mb_x_ime, mb_x_fme, mb_x_mc, mb_x_db, mb_x_ec;   
wire [`PIC_H_MB_LEN-1:0]   	mb_y_total, mb_y_load, mb_y_intra, mb_y_ime, mb_y_fme, mb_y_mc, mb_y_db, mb_y_ec;                           
wire          				intra_flag;
wire [5:0]    				ime_qp, fme_qp, mc_qp, intra_qp, ec_qp, db_qp;  
reg  [5:0]					tq_qp, qp_r, qp_r1, qp_r2, qp_r3;  
wire               			bs_empty;

//------------------ u_cur_mb -----------------//
wire                 		mb_switch;
wire   [256*8-1:0]   		ime_cur_luma, fme_cur_luma, mc_cur_luma;       
wire   [64*8-1 :0]   		mc_cur_u, mc_cur_v;
	    
//-------------------- fetch -------------------//
//ime if
wire                        fetch_ime_start;
wire						fetch_ime_valid;
wire [`PIC_W_MB_LEN - 1:0]  fetch_ime_mb_x;
wire [`PIC_H_MB_LEN - 1:0]  fetch_ime_mb_y;
wire 						fetch_ime_load;
wire [`SW_H_LEN-1:0]		fetch_ime_addr;
wire [3*16*`BIT_DEPTH-1:0]	fetch_ime_data;
//fme if
wire            			fme_ld_start, fme_ld_en, fme_ld_done;
wire [`PIC_W_MB_LEN-1:0] 	fme_ld_mb_x  ;
wire [`PIC_H_MB_LEN-1:0] 	fme_ld_mb_y  ;
wire [`SW_W_LEN      :0] 	fme_sw_x     ;
wire [`SW_H_LEN      :0] 	fme_sw_y     ;
wire [16*`BIT_DEPTH-1:0] 	fme_lddata   ;
wire                     	fme_ld_valid ;
//mc if
wire                        mc_chroma_ld_en   ;
wire                        mc_chroma_ld_done ;
wire						mc_chroma_rd_crcb ;
wire                        mc_chroma_ld_ack  ;
wire [`PIC_W_MB_LEN-1:0]    mc_chroma_ld_mb_x ;
wire [`PIC_H_MB_LEN-1:0]    mc_chroma_ld_mb_y ;
wire [`SW_W_LEN-1    :0]    mc_chroma_ld_sw_x ;
wire [`SW_H_LEN-1    :0]    mc_chroma_ld_sw_y ;
wire [8*`BIT_DEPTH-1:0]     mc_chroma_ld_data ;

//-------------------- mem_arb --------------------//
//luma/chroma ref MB req channel 
wire           				load_luma_en   , load_chroma_en   ;
wire           				load_luma_done , load_chroma_done ;
wire [`PIC_W_MB_LEN-1:0]  	load_luma_mb_x , load_chroma_mb_x ;
wire [`PIC_H_MB_LEN-1:0]  	load_luma_mb_y , load_chroma_mb_y ;
wire						load_luma_valid, load_chroma_valid;
wire [63:0]  				load_luma_data , load_chroma_data ;
// db load/store req channel
wire 						load_db_en 	   , store_db_en   	  ; 	    
wire 						load_db_done   , store_db_done    ;
wire [`PIC_W_MB_LEN-1:0]  	load_db_x      , store_db_x       ;
wire [`PIC_H_MB_LEN-1:0]  	load_db_y      , store_db_y       ;
wire [1:0]					load_db_mode   , store_db_mode    ;
wire 						load_db_valid  , store_db_rden    ;
wire [127:0]				load_db_data   , store_db_rdata   ;
wire [4:0]								     store_db_raddr   ;

//--------------------- u_ime ---------------------//
wire                        ime_valid;
wire [16*2*`IMVD_LEN-1:0]   ime_imv;
wire [`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] ime_mb_type_info;

//--------------------- u_fme ---------------------//
wire [16*2*`FMVD_LEN-1:0] 	fme_fmv;
wire [16*2*`IMVD_LEN-1:0]  	fme_imv;
wire [`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] fme_mb_type_info;
wire [`BIT_DEPTH+10-1:0] 	fme_cost;
wire                        fme_mc_luma_rden;
wire                        fme_mc_luma_rdack;
wire [6:0]                  fme_mc_luma_addr;
wire [20*`BIT_DEPTH-1:0]    fme_mc_luma_data;

//--------------------- u_mvd/MC--------------------//
wire [1:0]    				mc_mb_type_info ;
wire [7:0]    				mc_sub_partition;
wire  [2*16*`FMVD_LEN-1:0] 	mc_fmv;

//-------------------- u_intra --------------------//
wire          				intra_mb_type_info;
wire [1:0]    				intra_16x16_mode; 
wire [1:0]    				intra_chroma_mode;              				
wire [63:0]   				intra_4x4_bm;   // intra 4x4 used mode 
wire [63:0]   				intra_4x4_pm;   // intra 4x4 predicted mode (base on surrounding blocks)
      
//-------------------- u_tq --------------------//
// TQ i4x4 IF
wire 						tq_i4x4_en;  
wire [3:0]					tq_i4x4_mod; 
wire [3:0]					tq_i4x4_blk; 
wire 						tq_i4x4_min; 
wire 						tq_i4x4_end; 
wire 						tq_i4x4_val; 
wire [3:0]					tq_i4x4_num;   
// TQ i16x16 IF         	
wire 						tq_i16x16_en; 
wire [3:0] 					tq_i16x16_blk;
wire 						tq_i16x16_val;
wire [3:0]					tq_i16x16_num; 
// TQ p16x16 IF         	   
wire 						tq_p16x16_en; 
wire [3:0] 					tq_p16x16_blk;
wire 						tq_p16x16_val;
wire [3:0]					tq_p16x16_num; 
// TQ Chroma IF, two source: intra/inter frame            
wire 						i_tq_chroma_en	, p_tq_chroma_en	, tq_chroma_en	;		
wire [2:0]					i_tq_chroma_num	, p_tq_chroma_num	, tq_chroma_num	;
wire 						tq_cb_val		;	    
wire [3:0]					tq_cb_num		;	    
wire 						tq_cr_val		;	    
wire [3:0]					tq_cr_num		;	  
// intra/inter and mux predicted pixels    
wire  [`BIT_DEPTH-1:0]		i_pre00, i_pre01, i_pre02, i_pre03, p_pre00, p_pre01, p_pre02, p_pre03, 
							i_pre10, i_pre11, i_pre12, i_pre13, p_pre10, p_pre11, p_pre12, p_pre13, 
							i_pre20, i_pre21, i_pre22, i_pre23, p_pre20, p_pre21, p_pre22, p_pre23, 
							i_pre30, i_pre31, i_pre32, i_pre33,	p_pre30, p_pre31, p_pre32, p_pre33;
reg  [`BIT_DEPTH-1:0]		tq_pre00, tq_pre01, tq_pre02, tq_pre03,
							tq_pre10, tq_pre11, tq_pre12, tq_pre13,
							tq_pre20, tq_pre21, tq_pre22, tq_pre23,
							tq_pre30, tq_pre31, tq_pre32, tq_pre33;		
// intra/inter and mux residual pixels 																	                      
wire  [`BIT_DEPTH:0]		i_res00, i_res01, i_res02, i_res03, p_res00, p_res01, p_res02, p_res03, 
							i_res10, i_res11, i_res12, i_res13, p_res10, p_res11, p_res12, p_res13, 
							i_res20, i_res21, i_res22, i_res23, p_res20, p_res21, p_res22, p_res23, 
							i_res30, i_res31, i_res32, i_res33,	p_res30, p_res31, p_res32, p_res33;
reg  [`BIT_DEPTH:0]			tq_res00, tq_res01, tq_res02, tq_res03,
							tq_res10, tq_res11, tq_res12, tq_res13,
							tq_res20, tq_res21, tq_res22, tq_res23,
							tq_res30, tq_res31, tq_res32, tq_res33;	
// rec pixels from tq												
wire [`BIT_DEPTH-1:0]		tq_rec00, tq_rec01, tq_rec02, tq_rec03,
							tq_rec10, tq_rec11, tq_rec12, tq_rec13,
							tq_rec20, tq_rec21, tq_rec22, tq_rec23,
							tq_rec30, tq_rec31, tq_rec32, tq_rec33;	
// EC/DB Output IF
wire [8:0]    				tq_cbp ;
wire [3:0]					tq_cbp_luma;
wire [1:0]					tq_cbp_chroma;
wire [2:0]					tq_cbp_dc;
wire [15:0]   				tq_non_zero_luma;
wire [3:0]    				tq_non_zero_cr;
wire [3:0]    				tq_non_zero_cb;

//--------------------- u_db ----------------------//
wire  [2*16*`FMVD_LEN-1:0]  db_4x4_mv;
// reconstructed pixel mem for db read/write
wire [127:0]				db_rec_rdat;
wire [4:0]					db_rec_radd;
wire 						db_rec_rden;
wire [127:0]				db_rec_wdat;
wire [4:0]					db_rec_wadd;
wire 						db_rec_wren;
// top ref pixel mem for db read         
wire [127:0]				db_t_rdat;
wire [2:0]					db_t_radd;
wire 						db_t_rden;
// filted pixel for ext store          
wire [127:0]				db_c_wdat;
wire [5:0]					db_c_wadd;
wire 						db_c_wren;

//---------------------- u_ec ---------------------//
// from intra
reg          				ec_intra_type;
reg [1:0]    				ec_16x16_mode;
reg [1:0]    				ec_chroma_mode;
reg [63:0]   				ec_4x4_bm;   
reg [63:0]   				ec_4x4_pm;   
// from inter
reg [1:0]    				ec_mb_partition ;
reg [7:0]    				ec_sub_partition;
// from tq
reg  [8:0]    				ec_cbp ;			
wire [4:0]					ec_level_raddr;
wire [255:0]				ec_level_rdata;
// from mvd
wire 						ec_mvd_rd;
wire [3:0]					ec_mvd_raddr;
wire [2*`FMVD_LEN+1:0]      ec_mvd_rdata;
// cavlc & bs_buf
wire          				cavlc_we ;
wire [3:0]    				cavlc_inc;
wire [83:0]   				cavlc_codebit;
wire [7:0]    				cavlc_rbsp_trailing;

//-------------------------------------------------------------------
//               
//                global signals assignment 
// 
//------------------------------------------------------------------- 
assign mb_x_total = sys_x_total;
assign mb_y_total = sys_y_total;
assign intra_flag = sys_intra_flag;

assign enc_ld_start = load_start; 
assign enc_ld_x		= mb_x_load;     
assign enc_ld_y		= mb_y_load; 

// qp pipeline
always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		qp_r <= 'b0;
	else if (ime_start || intra_start)
		qp_r <= sys_qp;
end

always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		qp_r1 <= 'b0;
	else if (!intra_flag && fme_start)
		qp_r1 <= qp_r;
end

always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		qp_r2 <= 'b0;
	else if (!intra_flag && mc_start)
		qp_r2 <= qp_r1;
end

always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		qp_r3 <= 'b0;
	else if (!intra_flag && ec_start)
		qp_r3 <= qp_r2;
	else if (intra_flag && ec_start)
		qp_r3 <= qp_r;
end

assign ime_qp   = qp_r;
assign intra_qp = qp_r;
assign fme_qp   = qp_r1;
assign mc_qp    = qp_r2;
assign ec_qp    = qp_r3;
assign db_qp    = qp_r3;

//-------------------------------------------------------------------
//               
//                top module controller 
// 
//-------------------------------------------------------------------
top_ctrl      u_top_ctrl(
				.clk                 ( clk              ),
				.rst_n               ( rst_n            ),
				
				.sys_start		     ( sys_start		),
				.sys_done		     ( sys_done		    ),			
				.sys_intra_flag      ( sys_intra_flag   ),
				.sys_mode            ( sys_mode         ),
				.sys_x_total         ( sys_x_total      ),
				.sys_y_total	     ( sys_y_total	    ),
				
				.frame_start_o       ( frame_start      ),
				.frame_done_o        ( frame_done       ),
				.load_start_o        ( load_start       ),
				.ime_start_o         ( ime_start        ),
				.fme_start_o         ( fme_start        ),
				.mc_start_o          ( mc_start         ),
				.intra_start_o       ( intra_start      ),
				.ec_start_o          ( ec_start         ),
				.db_start_o          ( db_start         ),
				
				.load_done_i       	 ( load_done        ),
				.fetch_db_done_i     ( fetch_db_done    ),
				.fetch_chroma_done_i ( fetch_chroma_done),
				.fetch_luma_done_i   ( fetch_luma_done  ),								
				.ime_done_i          ( ime_done         ),
				.fme_done_i          ( fme_done         ),
				.mc_done_i           ( mc_done          ),
				.intra_done_i        ( intra_done       ),
				.ec_done_i           ( ec_done          ),
				.db_done_i           ( db_done          ),
				.bs_empty_i          ( bs_empty         ),
				
				.mb_x_load           ( mb_x_load        ),
				.mb_y_load           ( mb_y_load        ),
				.mb_x_intra          ( mb_x_intra       ),
				.mb_y_intra          ( mb_y_intra       ),
				.mb_x_ime            ( mb_x_ime         ),
				.mb_y_ime            ( mb_y_ime         ),
				.mb_x_fme            ( mb_x_fme         ),
				.mb_y_fme            ( mb_y_fme         ),
				.mb_x_mc             ( mb_x_mc          ),
				.mb_y_mc             ( mb_y_mc          ),
				.mb_x_db             ( mb_x_db          ),
				.mb_y_db             ( mb_y_db          ),
				.mb_x_ec             ( mb_x_ec          ),
				.mb_y_ec             ( mb_y_ec          )		
);              
                
//-------------------------------------------------------------------
//               
//          current macroblock loading 
// 
//------------------------------------------------------------------- 
assign mb_switch = load_start||ime_start||fme_start||intra_start||mc_start;

cur_mb  u_cur_mb(  
				.clk              ( clk             ),  
				.rst_n            ( rst_n           ),  
				.load_start	      ( load_start      ),
				.load_done        ( load_done       ),
				.pvalid_i		  ( rvalid_i        ),
				.pinc_o           ( rinc_o          ),
				.pdata_i	      ( rdata_i         ),
				.mb_switch		  ( mb_switch       ),
				.intra_flag_i     ( intra_flag      ),
				.ime_cur_luma     ( ime_cur_luma    ),  
				.fme_cur_luma     ( fme_cur_luma    ),  
				.mc_cur_luma      ( mc_cur_luma     ),  
				.mc_cur_u         ( mc_cur_u        ),  
				.mc_cur_v         ( mc_cur_v        )  
);

//-------------------------------------------------------------------
//               
//          Fetch Block
// 
//------------------------------------------------------------------- 
assign fetch_luma_start   = load_start&(~intra_flag);
assign fetch_chroma_start = ime_start;
assign fetch_db_start	  = db_start ;

fetch fetch(
        .clk                    ( clk                    ),
        .rst_n                  ( rst_n                  ),
        .sysif_total_x_i        ( mb_x_total             ),
        .sysif_total_y_i        ( mb_y_total             ),
        .sysif_luma_mb_x_i		( mb_x_load 			 ),
        .sysif_luma_mb_y_i	    ( mb_y_load 			 ),
        .sysif_luma_start_i	    ( fetch_luma_start       ),
        .sysif_luma_done_o	    ( fetch_luma_done		 ),    
            
        .extif_luma_req_o       ( load_luma_en           ),
        .extif_luma_mb_x_o      ( load_luma_mb_x 		 ),
        .extif_luma_mb_y_o      ( load_luma_mb_y 		 ),
        .extif_luma_data_v_i    ( load_luma_valid        ),
        .extif_luma_data_i      ( load_luma_data         ),   
        .extif_luma_done_i      ( load_luma_done         ),   
        
        .imeif_start_i          ( fetch_ime_start        ),
        .imeif_valid_o	        ( fetch_ime_valid        ),
        .imeif_mb_x_i	        ( fetch_ime_mb_x         ),
        .imeif_mb_y_i	        ( fetch_ime_mb_y      	 ),
        .imeif_load_i	        ( fetch_ime_load      	 ),
        .imeif_addr_i	        ( fetch_ime_addr         ),
        .imeif_data_o	        ( fetch_ime_data         ),
              
        .fmeif_ld_start_i       ( fme_ld_start           ),
        .fmeif_ld_en_i          ( fme_ld_en              ),
        .fmeif_ld_done_i        ( fme_ld_done            ),
        .fmeif_mb_x_i           ( fme_ld_mb_x     		 ),
        .fmeif_mb_y_i           ( fme_ld_mb_y     		 ),
        .fmeif_sw_xx_i          ( fme_sw_x[`SW_W_LEN:4]  ),
        .fmeif_sw_yy_i          ( fme_sw_y[`SW_H_LEN:4]  ),
        .fmeif_sw_zz_i          ( fme_sw_y[3:0]          ),
        .fmeif_lddata_o         ( fme_lddata             ),
        .fmeif_ld_valid_o       ( fme_ld_valid           )
);

fetch_chroma u_fetch_chroma(
        .clk                    ( clk                    ),
        .rst_n                  ( rst_n                  ),
        .sys_total_mb_x         ( mb_x_total             ),
        .sys_total_mb_y         ( mb_y_total             ),
        .sysif_mb_x_i           ( mb_x_ime      		 ),
        .sysif_mb_y_i           ( mb_y_ime      		 ),        
        .sysif_start_ld_chroma_i( fetch_chroma_start     ),
        .sysif_done_ld_chroma_o ( fetch_chroma_done      ),       

        .chroma_req_ext_o       ( load_chroma_en         ),
        .chroma_done_ext_i      ( load_chroma_done       ),
        .chroma_mb_x_ext_o      ( load_chroma_mb_x 		 ),
        .chroma_mb_y_ext_o      ( load_chroma_mb_y 		 ),
        .chroma_data_v_ext_i    ( load_chroma_valid      ),
        .chroma_data_ext_i      ( load_chroma_data       ),

        .mc_chroma_rd_en_i      ( mc_chroma_ld_en        ), 
        .mc_chroma_rd_done_i    ( mc_chroma_ld_done      ), 
        .mc_chroma_rd_crcb_i    ( mc_chroma_rd_crcb      ), 
        .mc_chroma_rd_ack_o     ( mc_chroma_ld_ack       ), 
        .mc_chroma_rd_mb_x_i    ( mc_chroma_ld_mb_x      ), 
        .mc_chroma_rd_mb_y_i    ( mc_chroma_ld_mb_y      ), 
        .mc_chroma_rd_sw_x_i    ( mc_chroma_ld_sw_x      ), 
        .mc_chroma_rd_sw_y_i    ( mc_chroma_ld_sw_y      ), 
        .mc_chroma_rd_data_o    ( mc_chroma_ld_data      ) 
);

fetch_db u_fetch_db(
        .clk             		( clk               	),
        .rst_n           		( rst_n             	),
        .sys_total_x			( mb_x_total        	),
        .sys_total_y     		( mb_y_total        	),       
        .sys_ld_x_i      		( intra_flag ? mb_x_intra : mb_x_mc ),
        .sys_ld_y_i      		( intra_flag ? mb_y_intra : mb_y_mc ),
        .sys_st_x_i      		( mb_x_db 			 	), 
        .sys_st_y_i      		( mb_y_db 			 	), 
        .sys_start_i			( fetch_db_start		),
        .sys_done_o				( fetch_db_done			),      		

        .load_en_o				( load_db_en 	 		),
        .load_done_i    		( load_db_done   		),
        .load_x_o	   			( load_db_x      		),
        .load_y_o	   			( load_db_y      		),
        .load_mode_o			( load_db_mode	 		),
        .load_valid_i   		( load_db_valid  		),
        .load_data_i    		( load_db_data   		),
                                                 		
        .store_en_o				( store_db_en    		),
        .store_done_i       	( store_db_done  		),
        .store_x_o				( store_db_x     		),	
        .store_y_o          	( store_db_y     		),
        .store_mode_o			( store_db_mode	 		),
        .store_rden_i       	( store_db_rden  		),
        .store_raddr_i      	( store_db_raddr 		),
        .store_rdata_o      	( store_db_rdata		),

        .db_done_i				( db_done				),
        .db_t_rden_i			( db_t_rden				),	  
        .db_t_radd_i	   		( db_t_radd				),
        .db_t_rdat_o	   		( db_t_rdat				),
        .db_c_wren_i 			( db_c_wren				),
        .db_c_wadd_i			( db_c_wadd				),
        .db_c_wdat_i        	( db_c_wdat				)
);

//-------------------------------------------------------------------
//               
//       memory arbiter module 
// 
//------------------------------------------------------------------- 
mem_arbiter u_mem_arb(  
		.clk               		( clk              	),
		.rst_n             		( rst_n            	),
		.mb_x_total        		( mb_x_total       	),
		.mb_y_total        		( mb_y_total       	),
		.load_luma_en      		( load_luma_en     	),
		.load_luma_x       		( load_luma_mb_x   	),
		.load_luma_y       		( load_luma_mb_y   	),
		.load_luma_valid   		( load_luma_valid  	),
		.load_luma_data    		( load_luma_data   	),
		.load_luma_done    		( load_luma_done   	),
		.load_chroma_en    		( load_chroma_en   	),
		.load_chroma_x     		( load_chroma_mb_x 	),
		.load_chroma_y     		( load_chroma_mb_y 	),
		.load_chroma_valid 		( load_chroma_valid	),
		.load_chroma_data  		( load_chroma_data 	),
		.load_chroma_done  		( load_chroma_done 	),
		.load_db_en 	   		( load_db_en 	  	),		
		.load_db_done      		( load_db_done     	),    
		.load_db_x         		( load_db_x        	),    
		.load_db_y         		( load_db_y        	),    
		.load_db_mode	   		( load_db_mode	  	),    
		.load_db_valid     		( load_db_valid    	),    
		.load_db_data      		( load_db_data     	),                    
		.store_db_en       		( store_db_en      	),    
		.store_db_done     		( store_db_done    	),    
		.store_db_x        		( store_db_x       	),    
		.store_db_y        		( store_db_y       	),    
		.store_db_mode	   		( store_db_mode	  	),    
		.store_db_rden     		( store_db_rden    	),    
		.store_db_raddr    		( store_db_raddr   	),    
		.store_db_rdata    		( store_db_rdata   	),    
		.ext_mb_x_o  	   		( ext_mb_x_o  		),
		.ext_mb_y_o        		( ext_mb_y_o        ),
		.ext_start_o       		( ext_start_o       ),
		.ext_done_i        		( ext_done_i        ),
		.ext_mode_o        		( ext_mode_o        ),
		.ext_wen_i	       		( ext_wen_i	        ),
		.ext_ren_i	       		( ext_ren_i	        ),
		.ext_addr_i        		( ext_addr_i        ),
		.ext_data_i        		( ext_data_i        ),
		.ext_data_o        		( ext_data_o        ) 
);

//-------------------------------------------------------------------
//               
//          IME Block
// 
//------------------------------------------------------------------- 
ime_top u_ime(
        .clk                	( clk              ),
        .rstn               	( rst_n            ),  
        .sysif_start_i      	( ime_start        ),
        .sysif_done_o       	( ime_done         ),
        .sysif_qp_i         	( ime_qp           ),
        .sysif_total_x_i    	( mb_x_total       ),
        .sysif_total_y_i    	( mb_y_total       ),  
        .sysif_mb_x_i			( mb_x_ime		   ),
        .sysif_mb_y_i 			( mb_y_ime		   ),
        .sysif_cmb_i        	( ime_cur_luma     ),
                            	
        .fetchif_start_o    	( fetch_ime_start  ),
        .fetchif_valid_i    	( fetch_ime_valid  ), 
        .fetchif_mb_x_o     	( fetch_ime_mb_x   ),
        .fetchif_mb_y_o     	( fetch_ime_mb_y   ),
        .fetchif_load_o     	( fetch_ime_load   ),
        .fetchif_addr_o     	( fetch_ime_addr   ),
        .fetchif_data_i     	( fetch_ime_data   ), 
                            	
        .fmeif_valid_o      	( ime_valid        ),
        .fmeif_imv_o        	( ime_imv          ),
        .fmeif_mb_type_o    	( ime_mb_type_info )
);

//-------------------------------------------------------------------
//               
//          FME Block
// 
//------------------------------------------------------------------- 
fme_top u_fme(
       .clk_i                   ( clk               ),
       .rst_n_i                 ( rst_n             ),
       .sysif_cmb_x_i           ( mb_x_fme   		),
       .sysif_cmb_y_i           ( mb_y_fme   		),
       .sysif_qp_i              ( fme_qp            ),
       .sysif_cmb_i             ( fme_cur_luma      ),
       .sysif_start_fme_i       ( fme_start         ),
       .sysif_done_fme_o        ( fme_done          ),
       
       .imeif_imv_i             ( ime_imv           ),
       .imeif_mb_type_info_i    ( ime_mb_type_info  ),
       
       .fetchif_ldstart_o       ( fme_ld_start      ),
       .fetchif_lden_o          ( fme_ld_en         ),
       .fetchif_lddone_o        ( fme_ld_done       ),
       .fetchif_cmb_x_o         ( fme_ld_mb_x     	),
       .fetchif_cmb_y_o         ( fme_ld_mb_y     	),
       .fetchif_sw_x_o          ( fme_sw_x          ),
       .fetchif_sw_y_o          ( fme_sw_y          ),
       .fetchif_valid_i         ( fme_ld_valid      ),
       .fetchif_data_i          ( fme_lddata        ),
       
       .mcif_fmv_o              ( fme_fmv           ),
       .mcif_imv_o              ( fme_imv           ),
       .mcif_ecif_mb_type_info_o( fme_mb_type_info  ),
       .mcif_ecif_valid_o       (                   ),
       .mcif_rden_mc_i          ( fme_mc_luma_rden  ),
       .mcif_addr_mc_i          ( fme_mc_luma_addr  ),
       .mcif_data_mc_o          ( fme_mc_luma_data  ),
       .mcif_rdack_mc_o         ( fme_mc_luma_rdack ),
       
       .mdif_valid_o            (                   ),
       .mdif_intercost_o        ( fme_cost          )
);

//-------------------------------------------------------------------
//               
//          MC Block
// 
//------------------------------------------------------------------- 
mc_top u_mc(
       .clk_i                      ( clk               ),
       .rst_n_i                    ( rst_n             ),
       
       .sysif_start_mc_i           ( mc_start          ),
       .sysif_done_mc_o			   ( mc_done		   ),
       .sysif_cmb_x_i              ( mb_x_mc           ),
       .sysif_cmb_y_i              ( mb_y_mc           ),
       .sysif_qp_i                 ( mc_qp             ),
       .sysif_cmb_luma_i           ( mc_cur_luma       ),
       .sysif_cmb_cb_i             ( mc_cur_u          ),
       .sysif_cmb_cr_i             ( mc_cur_v          ),
       .sysif_transform8x8_mode_i  ( 1'b1              ),
       
       .fmeif_mb_type_info_i       ( fme_mb_type_info  ),
       .fmeif_fmv_i                ( fme_fmv           ),
       .fmeif_imv_i                ( fme_imv           ),
       .fmeif_luma_rden_mc_o       ( fme_mc_luma_rden  ),
       .fmeif_luma_addr_mc_o       ( fme_mc_luma_addr  ),
       .fmeif_luma_data_mc_i       ( fme_mc_luma_data  ),
       .fmeif_luma_rdack_mc_i      ( fme_mc_luma_rdack ),
       
       .fetchif_chroma_rden_mc_o   ( mc_chroma_ld_en   ),
       .fetchif_chroma_rddone_mc_o ( mc_chroma_ld_done ),
       .fetchif_chroma_rdcrcb_mc_o ( mc_chroma_rd_crcb ),
       .fetchif_chroma_rdack_mc_i  ( mc_chroma_ld_ack  ),
       .fetchif_chroma_rdmb_x_mc_o ( mc_chroma_ld_mb_x ),
       .fetchif_chroma_rdmb_y_mc_o ( mc_chroma_ld_mb_y ),
       .fetchif_chroma_rdsw_x_mc_o ( mc_chroma_ld_sw_x ),
       .fetchif_chroma_rdsw_y_mc_o ( mc_chroma_ld_sw_y ),
       .fetchif_chroma_rddata_mc_i ( mc_chroma_ld_data ),
       
       .ecif_mb_type_info_o 	   ( mc_mb_type_info   ),
       .ecif_sub_partition_o       ( mc_sub_partition  ),

       .tq_p16x16_en_o    		   ( tq_p16x16_en      ), 
       .tq_p16x16_num_o   		   ( tq_p16x16_blk     ),
       .tq_p16x16_val_i   		   ( tq_p16x16_val     ),       
       .tq_p16x16_num_i   		   ( tq_p16x16_num     ),       
       .tq_chroma_en_o   		   ( p_tq_chroma_en    ), 
       .tq_chroma_num_o            ( p_tq_chroma_num   ),
       .tq_cb_val_i				   ( tq_cb_val         ),
       .tq_cb_num_i				   ( tq_cb_num         ),
       .tq_cr_val_i				   ( tq_cr_val         ),
       .tq_cr_num_i				   ( tq_cr_num         ),
             
       .pre00 ( p_pre00 ), .pre01 ( p_pre01 ), .pre02 ( p_pre02 ), .pre03 ( p_pre03 ),
       .pre10 ( p_pre10 ), .pre11 ( p_pre11 ), .pre12 ( p_pre12 ), .pre13 ( p_pre13 ),
       .pre20 ( p_pre20 ), .pre21 ( p_pre21 ), .pre22 ( p_pre22 ), .pre23 ( p_pre23 ),
       .pre30 ( p_pre30 ), .pre31 ( p_pre31 ), .pre32 ( p_pre32 ), .pre33 ( p_pre33 ),
                                                                                      
       .res00 ( p_res00 ), .res01 ( p_res01 ), .res02 ( p_res02 ), .res03 ( p_res03 ),
       .res10 ( p_res10 ), .res11 ( p_res11 ), .res12 ( p_res12 ), .res13 ( p_res13 ),
       .res20 ( p_res20 ), .res21 ( p_res21 ), .res22 ( p_res22 ), .res23 ( p_res23 ),
       .res30 ( p_res30 ), .res31 ( p_res31 ), .res32 ( p_res32 ), .res33 ( p_res33 )     	 
);

//-------------------------------------------------------------------
//               
//          MVP Calculate Block
// 
//------------------------------------------------------------------- 
assign ec_mvd_rd = 1'b1;

mvd_cmp u_mvd_cmp(
				.clk            ( clk              ),             
				.rst_n          ( rst_n            ),             
				.mb_x_total     ( mb_x_total       ),             
				.mb_y_total     ( mb_y_total       ),          
				.mb_x_i         ( mb_x_mc          ),
				.mb_y_i         ( mb_y_mc          ),
				.start_i        ( mc_start         ),
				.done_o         (                  ),             
				.mb_type_inter  ( mc_mb_type_info  ),             
				.sub_partition  ( mc_sub_partition ),       		
				.fmv_i          ( fme_fmv          ),
				.mv_o           ( mc_fmv       	   ), 
				.mem_sw_i 		( ec_start		   ),
				.mvd_rd			( ec_mvd_rd		   ),		 
				.mvd_raddr      ( ec_mvd_raddr     ),
				.mvd_rdata      ( ec_mvd_rdata     )
);

//-------------------------------------------------------------------
//               
//          Intra Block
// 
//------------------------------------------------------------------- 						
intra_top u_intra_top(
				.clk             ( clk                 	),
				.rst_n           ( rst_n               	),
				.mb_x_total      ( mb_x_total 		 	), 
				.mb_x            ( mb_x_intra 		 	),
				.mb_y            ( mb_y_intra 		 	),
				.mb_luma         ( mc_cur_luma         	),
				.mb_cb           ( mc_cur_u   		 	),  
				.mb_cr			 ( mc_cur_v   		 	),  
				.intra_flag		 ( intra_flag          	),		
				.qp		         ( intra_qp             ),
							
				.start_i         ( intra_start         	),
				.done_o	         ( intra_done          	),
								
				.intra_mode_o    ( intra_mb_type_info  	),
				.i4x4_bm_o   	 ( intra_4x4_bm        	),
				.i4x4_pm_o       ( intra_4x4_pm        	),
				.i16x16_mode_o   ( intra_16x16_mode     ),
				.chroma_mode_o	 ( intra_chroma_mode   	),	
				
				.tq_i4x4_en_o    ( tq_i4x4_en	        ), 
				.tq_i4x4_mod_o   ( tq_i4x4_mod          ), 
				.tq_i4x4_num_o   ( tq_i4x4_blk          ), 
				.tq_i4x4_min_o   ( tq_i4x4_min          ), 
				.tq_i4x4_end_o   ( tq_i4x4_end          ), 
				.tq_i4x4_val_i   ( tq_i4x4_val          ), 
				.tq_i4x4_num_i   ( tq_i4x4_num          ), 
				 				                                        
				.tq_i16x16_en_o  ( tq_i16x16_en         ), 
				.tq_i16x16_num_o ( tq_i16x16_blk        ), 
				.tq_i16x16_val_i ( tq_i16x16_val        ), 
				.tq_i16x16_num_i ( tq_i16x16_num		), 
				
				.tq_chroma_en_o  ( i_tq_chroma_en		), 
				.tq_chroma_num_o ( i_tq_chroma_num     	),    
				.tq_cb_val_i     ( tq_cb_val         	),    
				.tq_cb_num_i     ( tq_cb_num         	),    
				.tq_cr_val_i     ( tq_cr_val         	),    
				.tq_cr_num_i     ( tq_cr_num         	),    		
				
				.pre00 ( i_pre00 ), .pre01 ( i_pre01 ), .pre02 ( i_pre02 ), .pre03 ( i_pre03 ),
                .pre10 ( i_pre10 ), .pre11 ( i_pre11 ), .pre12 ( i_pre12 ), .pre13 ( i_pre13 ),
                .pre20 ( i_pre20 ), .pre21 ( i_pre21 ), .pre22 ( i_pre22 ), .pre23 ( i_pre23 ),
                .pre30 ( i_pre30 ), .pre31 ( i_pre31 ), .pre32 ( i_pre32 ), .pre33 ( i_pre33 ),
          
                .res00 ( i_res00 ), .res01 ( i_res01 ), .res02 ( i_res02 ), .res03 ( i_res03 ),
                .res10 ( i_res10 ), .res11 ( i_res11 ), .res12 ( i_res12 ), .res13 ( i_res13 ),
                .res20 ( i_res20 ), .res21 ( i_res21 ), .res22 ( i_res22 ), .res23 ( i_res23 ),
                .res30 ( i_res30 ), .res31 ( i_res31 ), .res32 ( i_res32 ), .res33 ( i_res33 ),
       
                .rec00 ( tq_rec00 ), .rec01 ( tq_rec01 ), .rec02 ( tq_rec02 ), .rec03 ( tq_rec03 ),
                .rec10 ( tq_rec10 ), .rec11 ( tq_rec11 ), .rec12 ( tq_rec12 ), .rec13 ( tq_rec13 ),
                .rec20 ( tq_rec20 ), .rec21 ( tq_rec21 ), .rec22 ( tq_rec22 ), .rec23 ( tq_rec23 ),
                .rec30 ( tq_rec30 ), .rec31 ( tq_rec31 ), .rec32 ( tq_rec32 ), .rec33 ( tq_rec33 )
);

//-------------------------------------------------------------------
//                                                                   
//          TQ Block                                              
//                                                                   
//-------------------------------------------------------------------
assign tq_chroma_en	 = intra_flag ? i_tq_chroma_en	: p_tq_chroma_en ;	
assign tq_chroma_num = intra_flag ? i_tq_chroma_num	: p_tq_chroma_num;

always @(*) begin
	if (intra_flag) begin
		tq_pre00 = i_pre00; tq_pre01 = i_pre01; tq_pre02 = i_pre02; tq_pre03 = i_pre03;
		tq_pre10 = i_pre10; tq_pre11 = i_pre11; tq_pre12 = i_pre12; tq_pre13 = i_pre13;
		tq_pre20 = i_pre20; tq_pre21 = i_pre21; tq_pre22 = i_pre22; tq_pre23 = i_pre23;
		tq_pre30 = i_pre30; tq_pre31 = i_pre31; tq_pre32 = i_pre32; tq_pre33 = i_pre33;
			
		tq_res00 = i_res00; tq_res01 = i_res01; tq_res02 = i_res02; tq_res03 = i_res03;
		tq_res10 = i_res10; tq_res11 = i_res11; tq_res12 = i_res12; tq_res13 = i_res13;
		tq_res20 = i_res20; tq_res21 = i_res21; tq_res22 = i_res22; tq_res23 = i_res23;
		tq_res30 = i_res30; tq_res31 = i_res31; tq_res32 = i_res32; tq_res33 = i_res33;	
		
		tq_qp    = intra_qp;
	end                                                                         
	else begin                                                                  
		tq_pre00 = p_pre00; tq_pre01 = p_pre01; tq_pre02 = p_pre02; tq_pre03 = p_pre03;
		tq_pre10 = p_pre10; tq_pre11 = p_pre11; tq_pre12 = p_pre12; tq_pre13 = p_pre13;
		tq_pre20 = p_pre20; tq_pre21 = p_pre21; tq_pre22 = p_pre22; tq_pre23 = p_pre23;
		tq_pre30 = p_pre30; tq_pre31 = p_pre31; tq_pre32 = p_pre32; tq_pre33 = p_pre33;
			
		tq_res00 = p_res00; tq_res01 = p_res01; tq_res02 = p_res02; tq_res03 = p_res03;
		tq_res10 = p_res10; tq_res11 = p_res11; tq_res12 = p_res12; tq_res13 = p_res13;
	    tq_res20 = p_res20; tq_res21 = p_res21; tq_res22 = p_res22; tq_res23 = p_res23;
	    tq_res30 = p_res30; tq_res31 = p_res31; tq_res32 = p_res32; tq_res33 = p_res33;
	    
	    tq_qp    = mc_qp;
	end
end

tq_top u_tq_top(
				.clk             ( clk                 	),
				.rst_n           ( rst_n               	),		
				.qp		         ( tq_qp                ),

				.i4x4_en_i 		 ( tq_i4x4_en	        ),      	
				.i4x4_mod_i		 ( tq_i4x4_mod          ),
				.i4x4_num_i		 ( tq_i4x4_blk          ),
				.i4x4_min_i		 ( tq_i4x4_min          ),
				.i4x4_end_i		 ( tq_i4x4_end          ),
				.i4x4_val_o		 ( tq_i4x4_val          ),
				.i4x4_num_o		 ( tq_i4x4_num          ),
				
				.i16x16_en_i     ( tq_i16x16_en         ),
				.i16x16_num_i    ( tq_i16x16_blk        ),
				.i16x16_val_o    ( tq_i16x16_val        ),
				.i16x16_num_o    ( tq_i16x16_num		),
				
				.p16x16_en_i     ( tq_p16x16_en		    ),
				.p16x16_num_i    ( tq_p16x16_blk        ),
				.p16x16_val_o    ( tq_p16x16_val        ),
				.p16x16_num_o    ( tq_p16x16_num        ),
				
				.chroma_en_i     ( tq_chroma_en			),
				.chroma_num_i    ( tq_chroma_num        ),
				.cb_val_o        ( tq_cb_val            ),
				.cb_num_o        ( tq_cb_num            ),
				.cr_val_o        ( tq_cr_val            ),
				.cr_num_o        ( tq_cr_num            ),
				
				.pre00 ( tq_pre00 ), .pre01 ( tq_pre01 ), .pre02 ( tq_pre02 ), .pre03 ( tq_pre03 ),
                .pre10 ( tq_pre10 ), .pre11 ( tq_pre11 ), .pre12 ( tq_pre12 ), .pre13 ( tq_pre13 ),
                .pre20 ( tq_pre20 ), .pre21 ( tq_pre21 ), .pre22 ( tq_pre22 ), .pre23 ( tq_pre23 ),
                .pre30 ( tq_pre30 ), .pre31 ( tq_pre31 ), .pre32 ( tq_pre32 ), .pre33 ( tq_pre33 ),
                    
                .res00 ( tq_res00 ), .res01 ( tq_res01 ), .res02 ( tq_res02 ), .res03 ( tq_res03 ),
                .res10 ( tq_res10 ), .res11 ( tq_res11 ), .res12 ( tq_res12 ), .res13 ( tq_res13 ),
                .res20 ( tq_res20 ), .res21 ( tq_res21 ), .res22 ( tq_res22 ), .res23 ( tq_res23 ),
                .res30 ( tq_res30 ), .res31 ( tq_res31 ), .res32 ( tq_res32 ), .res33 ( tq_res33 ),
       
                .rec00 ( tq_rec00 ), .rec01 ( tq_rec01 ), .rec02 ( tq_rec02 ), .rec03 ( tq_rec03 ),
                .rec10 ( tq_rec10 ), .rec11 ( tq_rec11 ), .rec12 ( tq_rec12 ), .rec13 ( tq_rec13 ),
                .rec20 ( tq_rec20 ), .rec21 ( tq_rec21 ), .rec22 ( tq_rec22 ), .rec23 ( tq_rec23 ),
                .rec30 ( tq_rec30 ), .rec31 ( tq_rec31 ), .rec32 ( tq_rec32 ), .rec33 ( tq_rec33 ),
                
                .mem_sw	  			( ec_start			),     
                			
                .ec_mem_rd			( 1'b1    			),   
                .ec_mem_raddr		( ec_level_raddr	),     
                .ec_mem_rdata		( ec_level_rdata	),         
                                                                    
                .db_mem_rdata  		( db_rec_rdat		),
                .db_mem_raddr		( db_rec_radd		),
                .db_mem_rd   		( db_rec_rden		),
                .db_mem_wdata		( db_rec_wdat		),
                .db_mem_waddr		( db_rec_wadd		),
                .db_mem_wr  		( db_rec_wren		),       
                                                                          	
                .non_zero_flag4x4	( tq_non_zero_luma 	),
				.non_zero_flag_cr	( tq_non_zero_cr   	),
				.non_zero_flag_cb	( tq_non_zero_cb   	),				                                          	
				.cbp_luma           ( tq_cbp_luma       ),
				.cbp_chroma			( tq_cbp_chroma		),
				.cbp_dc				( tq_cbp_dc			)	          
);

// for Intra_16x16, cbp_luma=4'b1111 or 4'b0000 (has one non_zero equals to 4'b1111)
// for Intra_4x4 and P Frame, cbp_luma = {non_zero_8x8}x4
assign tq_cbp = {tq_cbp_dc, tq_cbp_chroma, (intra_flag&intra_mb_type_info)?{4{|tq_cbp_luma}}:tq_cbp_luma};

//-------------------------------------------------------------------
//               
//       deblocking filter module 
// 
//------------------------------------------------------------------- 
assign db_4x4_mv = intra_flag ? 'd0 : mc_fmv;

db_top u_db_top( 
				.clk     			( clk         		), 
				.rst     			( rst_n       		), 
				.start   			( db_start    		),			                     
            	.db_done 			( db_done     		),
            	.x       			( mb_x_db   	    ), 
            	.y       			( mb_y_db   	    ), 
            	.QP      			( db_qp             ),                           
            	.transform_type_C   ( 1'b0             	), 
            	.mb_mode            ( ~intra_flag     	),
            	.non_zero_count     ( tq_non_zero_luma  ),           
            	.db_mv 			    ( db_4x4_mv 		),
				
				.ram_c              ( db_rec_rdat      	),
				.radd_c             ( db_rec_radd      	),
				.ren_c              ( db_rec_rden      	),
				.ram_c_former       ( db_rec_wdat     	),
				.wadd_c             ( db_rec_wadd     	),
				.wen_c              ( db_rec_wren     	),
				                   
				.ram_t              ( db_t_rdat      	),
				.radd_t             ( db_t_radd      	),
				.ren_t              ( db_t_rden      	),
				                       
				.ram_out            ( db_c_wdat        	),
				.wadd_out           ( db_c_wadd        	),
				.wen_out            ( db_c_wren        	)
);

//-------------------------------------------------------------------
//               
//  entropy coding (CAVLC) module 
// 
//------------------------------------------------------------------- 
// save mc/intra outputs for ec coding
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		ec_mb_partition  <= 'd0;
		ec_sub_partition <= 'd0;
		
		ec_intra_type  	 <= 'b0;
		ec_chroma_mode   <= 'b0;
		ec_16x16_mode    <= 'b0;
		ec_4x4_bm        <= 'b0;
		ec_4x4_pm        <= 'b0;
		
		ec_cbp			 <= 'b0;		
	end
	else if(ec_start)begin
		ec_mb_partition  <= mc_mb_type_info    ;
		ec_sub_partition <= mc_sub_partition   ;
		
		ec_intra_type  	 <= intra_mb_type_info ; 
		ec_chroma_mode   <= intra_chroma_mode  ; 
		ec_16x16_mode    <= intra_16x16_mode   ; 
		ec_4x4_bm        <= intra_4x4_bm       ; 
		ec_4x4_pm        <= intra_4x4_pm       ;
		
		ec_cbp			 <= tq_cbp             ;		
	end
end


cavlc_top u_cavlc_top (
				.clk              ( clk                 ),
				.rst_n            ( rst_n               ),
				.mb_x             ( mb_x_ec		        ),
				.mb_y             ( mb_y_ec		        ),
				.qp				  ( ec_qp				),
				.ref_idx          (                     ),
				.mode_i           ( ~intra_flag         ),
				// start done
				.start            ( ec_start            ),
				.cavlc_done       ( ec_done          	),
				// slice header state
				.sh_enc_done      ( frame_start         ),
				.remain_bit_sh    ( 8'b0                ),
				.remain_len_sh    ( 3'b0                ),
				// tq
				.cbp_i            ( ec_cbp           	),
				.addr_o		 	  ( ec_level_raddr		),
				.data_i		  	  ( ec_level_rdata		),
				// intra
				.mb_type_intra_i  ( ec_intra_type  		),
				.chroma_mode_i    ( ec_chroma_mode   	),
				.intra16x16_mode_i( ec_16x16_mode    	),
				.intra4x4_bm_i    ( ec_4x4_bm        	),
				.intra4x4_pm_i    ( ec_4x4_pm        	),
				// inter
				.mb_type_inter    ( ec_mb_partition  	),
				.sub_partition    ( ec_sub_partition 	),
				.mvd_addr         ( ec_mvd_raddr        ),
				.mvd              ( ec_mvd_rdata        ),
				// output
				.we               ( cavlc_we            ),
				.tmpAddr          ( cavlc_inc           ),
				.codebit          ( cavlc_codebit       ),
				.rbsp_trailing    ( cavlc_rbsp_trailing )
);

// bitstream output module
bs_buf  u_bs_buf(
				.clk              ( clk                 ),
				.rst_n            ( rst_n               ),
				.frame_done       ( frame_done          ),
				.sh_we 			  ( 1'b0				),
				.sh_inc           ( 2'b0				),
				.sh_bit           ( 24'b0				),
				.cavlc_we         ( cavlc_we            ),
				.cavlc_inc        ( cavlc_inc           ),
				.cavlc_bit        ( cavlc_codebit       ),
				.rbsp_trailing    ( cavlc_rbsp_trailing ),
				.bs_valid         ( winc_o              ),
				.bs_o             ( wdata_o             ),
				.bs_empty_o       ( bs_empty            )
);
		

endmodule
