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
// Filename       : mem_arbiter.v
// Author         : huibo zhong
// Created        : 2011-10-20
// Description    : top datapath of encoder
//               
// Modified by 	  : Yibo FAN
// Date			  : 2013-08-22
// Description	  : change db interface, add ext_mode_o definition
//
//------------------------------------------------------------------- 
`include "enc_defines.v"

module mem_arbiter(
				clk                 ,
				rst_n               ,
				mb_x_total          ,
				mb_y_total          ,
							
				load_luma_en        ,
				load_luma_x         ,
				load_luma_y         ,
				load_luma_valid     ,
				load_luma_data      ,
				load_luma_done      ,
				
				load_chroma_en      ,
				load_chroma_x       ,
				load_chroma_y       ,
				load_chroma_valid   ,
				load_chroma_data    ,
				load_chroma_done    ,
				
				load_db_en 			,
				load_db_done        ,
				load_db_x           ,
				load_db_y           ,
				load_db_mode		,
				load_db_valid       ,
				load_db_data        ,				
				                    
				store_db_en         ,
				store_db_done       ,
				store_db_x          ,
				store_db_y          ,
				store_db_mode	    ,
				store_db_rden       ,
				store_db_raddr      ,
				store_db_rdata      ,
				
				ext_mb_x_o         	,
				ext_mb_y_o         	,
				ext_start_o        	,
				ext_done_i         	,
				ext_mode_o         	,
				ext_wen_i			,
				ext_ren_i			,
				ext_addr_i       	,
				ext_data_i          ,				
				ext_data_o  
);

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ******************************************** 
parameter  IDLE          = 3'b000,    // IDLE 
		   LOAD_LUMA     = 3'b001,    // Load Y from ref MB
		   LOAD_CHROMA   = 3'b010,    // Load UV from ref MB
	 	   LOAD_DB    	 = 3'b011,    // Load YUV for db top ref
	 	   STORE_DB  	 = 3'b100;    // Store filted YUV

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                           clk;
input							rst_n;
// top_ctrl if 
input  [`PIC_W_MB_LEN-1:0]		mb_x_total;
input  [`PIC_H_MB_LEN-1:0]		mb_y_total;

// fetch luma MB IF
input                       	load_luma_en;    
input  [`PIC_W_MB_LEN-1:0]  	load_luma_x;
input  [`PIC_H_MB_LEN-1:0] 		load_luma_y;
output                      	load_luma_valid;
output [63:0]               	load_luma_data;
output                      	load_luma_done; 
// fetch chroma MB IF
input                      		load_chroma_en;   
input  [`PIC_W_MB_LEN-1:0]		load_chroma_x;
input  [`PIC_H_MB_LEN-1:0]		load_chroma_y;
output                      	load_chroma_valid;
output [63:0]               	load_chroma_data;
output                      	load_chroma_done;
// fetch luma/chroma bottom line for DB ref 
input                      		load_db_en 		;	
output                      	load_db_done    ;    
input  [`PIC_W_MB_LEN-1:0]   	load_db_x       ;    
input  [`PIC_H_MB_LEN-1:0]		load_db_y       ;    
input  [1:0]                 	load_db_mode	;	
output                      	load_db_valid   ;    
output [4*4*`BIT_DEPTH - 1:0]	load_db_data    ;    
// store luma/chroma MB or bottom line                    
input                      		store_db_en     ;    
output                      	store_db_done   ;    
input  [`PIC_W_MB_LEN-1:0]   	store_db_x      ;    
input  [`PIC_H_MB_LEN-1:0]		store_db_y      ;    
input  [1:0]                 	store_db_mode	;    
output                         	store_db_rden   ;    
output [4:0]                 	store_db_raddr  ;    
input  [4*4*`BIT_DEPTH - 1:0]	store_db_rdata  ;    
//-----------------------------------------------
// ext memory controller if
//
// ext address mapping:
// [sel][Y/UV][mb_y][mb_x][4x4_index][4_line_index]
//
// mem arbiter address mapping (ext_addr_i)
// [4x4_index]
//             (Y)        (UV)
//           0 1 2 3     U    V
//			 4 5 6 7    0 1  2 3
//           8 9 a b    4 5  6 7
//           c d e f
// 
//  ext_mode_o definition
//  [2]         [1]          [0]
//   0: load     0: luma      0: bottom 4x4 line
//   1: store    1: chroma    1: full MB
//-----------------------------------------------
output [`PIC_W_MB_LEN-1:0]  	ext_mb_x_o		;
output [`PIC_H_MB_LEN-1:0] 		ext_mb_y_o		;
output                      	ext_start_o		;
input                       	ext_done_i		;
output [2:0]              		ext_mode_o		;
input							ext_wen_i		;	
input							ext_ren_i		;	
input  [3:0]					ext_addr_i      ; 	
input  [16*`BIT_DEPTH - 1:0]	ext_data_i      ;    
output [4*4*`BIT_DEPTH - 1:0]	ext_data_o      ; 

// ********************************************
//                                             
//    Register DECLARATION               
//                                             
// ********************************************
reg [2:0]   				curr_state;
reg							load_luma_flag  , load_db_flag ,
							load_chroma_flag, store_db_flag;
reg                         ext_start_o;

// ********************************************
//                                             
//    Wire DECLARATION               
//                                             
// ********************************************
reg [2:0] 					next_state;
reg [2:0]					ext_mode_o;
reg [`PIC_W_MB_LEN-1:0]		ext_mb_x_o;
reg [`PIC_H_MB_LEN-1:0]		ext_mb_y_o;
reg [4:0]					store_db_raddr;

wire						load_luma_valid;
wire						load_chroma_valid;
wire						load_db_valid;
wire [8*`BIT_DEPTH - 1:0]	load_luma_data  ;
wire [8*`BIT_DEPTH - 1:0]	load_chroma_data;
                               	
// ********************************************
//                                             
//    Logic DECLARATION               
//                                             
// ********************************************
// ----------------------------------------------------
//                   req io flag
// ----------------------------------------------------                        	
always @(posedge clk or negedge rst_n) begin       
	if(!rst_n)                               
		load_luma_flag <= 1'b0;                   
	else if(ext_done_i && (curr_state == LOAD_LUMA))
		load_luma_flag <= 1'b0;                     
	else if(load_luma_en)                         
		load_luma_flag <= 1'b1;                    
end

always @(posedge clk or negedge rst_n) begin       
	if(!rst_n)                               
		load_chroma_flag <= 1'b0;
	else if(ext_done_i && (curr_state == LOAD_CHROMA))
		load_chroma_flag <= 1'b0;                 
	else if(load_chroma_en)                         
		load_chroma_flag <= 1'b1;                      
end

always @(posedge clk or negedge rst_n) begin       
	if(!rst_n)                               
		load_db_flag <= 1'b0;                     
	else if(ext_done_i && (curr_state == LOAD_DB))
		load_db_flag <= 1'b0;                   
	else if(load_db_en)                         
		load_db_flag <= 1'b1;                    
end

always @(posedge clk or negedge rst_n) begin       
	if(!rst_n)                               
		store_db_flag <= 1'b0;                    
	else if(ext_done_i && (curr_state == STORE_DB))
		store_db_flag <= 1'b0;                    
	else if(store_db_en)                         
		store_db_flag <= 1'b1;                    
end

// ----------------------------------------------------
//                  FSM
// ----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state   <= IDLE;
	end
	else begin
		curr_state   <= next_state;
	end
end

always @(*)begin
	case(curr_state)
		IDLE: 		if		(load_luma_flag)	next_state = LOAD_LUMA;
			  		else if (load_chroma_flag)	next_state = LOAD_CHROMA;
					else if (load_db_flag)		next_state = LOAD_DB;
					else if (store_db_flag)		next_state = STORE_DB;
		      		else						next_state = IDLE;		
		LOAD_LUMA:	if(ext_done_i)
		        		next_state = IDLE;
					else
			       		next_state = LOAD_LUMA;
		LOAD_CHROMA:if(ext_done_i)
			       		next_state = IDLE;
					else
			       		next_state = LOAD_CHROMA;
        LOAD_DB:	if(ext_done_i)
                   		next_state = IDLE ;
                 	else 
                 		next_state = LOAD_DB;
        STORE_DB:	if(ext_done_i)
                		next_state = IDLE ;
                  	else 
                  		next_state = STORE_DB;	
		default:	next_state = IDLE;	
	endcase
end

// ----------------------------------------------
//       Address Mapping & data re-orgnize
// ----------------------------------------------
// load luma channel
assign  load_luma_valid   = (curr_state==LOAD_LUMA) ? ext_wen_i : 1'b0;
assign  load_luma_done    = (curr_state==LOAD_LUMA) ? ext_done_i: 1'b0;
assign  load_luma_data    = ext_data_i[63:0];

// load chroma channel
assign  load_chroma_valid = (curr_state==LOAD_CHROMA)? ext_wen_i : 1'b0;
assign  load_chroma_done  = (curr_state==LOAD_CHROMA)? ext_done_i: 1'b0;
assign  load_chroma_data  = ext_data_i[63:0];

// load db channel
assign  load_db_valid = (curr_state==LOAD_DB)? ext_wen_i : 1'b0;
assign  load_db_done  = (curr_state==LOAD_DB)? ext_done_i: 1'b0;
assign  load_db_data  = ext_data_i[127:0];

// store db channel
assign store_db_done = (curr_state==STORE_DB)? ext_done_i : 1'b0;
assign store_db_rden = (curr_state==STORE_DB)? ext_ren_i  : 1'b0;
assign ext_data_o    = store_db_rdata;

always @(*) begin
	case (store_db_mode)
		2'b00: store_db_raddr = {1'b1, ext_addr_i} ;       
		2'b01: store_db_raddr = {1'b0, ext_addr_i} ;       
		2'b10: store_db_raddr = {3'b110, ext_addr_i[1:0]} ;
        2'b11: store_db_raddr = {2'b10, ext_addr_i[2:0]}  ; 
	endcase
end

// ----------------------------------------------
//             EXT MEM Channel
// ----------------------------------------------
// ext cmd channel
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		ext_start_o <= 1'b0;
	else if((curr_state==IDLE) && (load_luma_flag|load_chroma_flag|load_db_flag|store_db_flag))
		ext_start_o <= 1'b1;
	else
		ext_start_o <= 1'b0;
end

always @(*) begin
	case (curr_state)
		LOAD_LUMA  : begin ext_mb_x_o = load_luma_x  ; ext_mb_y_o = load_luma_y  ; ext_mode_o = 3'b001; end
		LOAD_CHROMA: begin ext_mb_x_o = load_chroma_x; ext_mb_y_o = load_chroma_y; ext_mode_o = 3'b011; end
		LOAD_DB    : begin ext_mb_x_o = load_db_x    ; ext_mb_y_o = load_db_y    ; ext_mode_o = {1'b0, load_db_mode}; end
		STORE_DB   : begin ext_mb_x_o = store_db_x   ; ext_mb_y_o = store_db_y   ; ext_mode_o = {1'b1, store_db_mode}; end 
		default    : begin ext_mb_x_o = 'b0          ; ext_mb_y_o = 'b0          ; ext_mode_o = 'b0   ; end
	endcase
end		

endmodule
