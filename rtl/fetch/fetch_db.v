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
// Created        : 2013-08-21
// Author         : Yibo FAN
// Description    : Fetch top 4x4 for deblocking filter
//					Store filted pixel to external memory
//
//------------------------------------------------------------------- 
`include "enc_defines.v"

module fetch_db(
        		clk             	,
        		rst_n           	,
        		sys_total_x			,
        		sys_total_y     	,       
        		sys_ld_x_i      	,
        		sys_ld_y_i      	,
        		sys_st_x_i      	, 
        		sys_st_y_i      	, 
        		sys_start_i			,
        		sys_done_o			,      		
        		
        		load_en_o			,
        		load_done_i    		,
        		load_x_o	   		,
        		load_y_o	   		,
        		load_mode_o			,
        		load_valid_i   		,
        		load_data_i    		,
        		    
        		store_en_o			,
        		store_done_i       	,
        		store_x_o			,	
        		store_y_o          	,
        		store_mode_o		,
        		store_rden_i       	,
        		store_raddr_i      	,
        		store_rdata_o      	,
        		
        		db_done_i			,
        		db_t_rden_i			,	  
        		db_t_radd_i	    	,
        		db_t_rdat_o	    	,
        		db_c_wren_i 		,
        		db_c_wadd_i			,
        		db_c_wdat_i     
);

// ************************************************* 
//                                             
//    Parameter DECLARATION                         
//                                             
// ************************************************* 
parameter		IDLE   = 3'd0, ST_WAIT = 3'd1, // IDLE, WAIT
         		LD_T_Y = 3'd2, LD_T_UV = 3'd3, // load top strip           		
         		ST_T_Y = 3'd4, ST_T_UV = 3'd5, // store top strip	
          		ST_C_Y = 3'd6, ST_C_UV = 3'd7; // store left 4x8 strip					

// *****************************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// *****************************************************
input                  			clk                 ;
input                  			rst_n               ;
// sys if 
input [`PIC_W_MB_LEN - 1:0]		sys_total_x			;	
input [`PIC_H_MB_LEN - 1:0]     sys_total_y     	;
input [`PIC_W_MB_LEN - 1:0]     sys_ld_x_i      	;
input [`PIC_H_MB_LEN - 1:0]     sys_ld_y_i      	;
input [`PIC_W_MB_LEN - 1:0]     sys_st_x_i      	;
input [`PIC_H_MB_LEN - 1:0]     sys_st_y_i      	;
input	                        sys_start_i			; // db load/store start
output							sys_done_o			; // db load/store done
input							db_done_i			; // db filting done
// ext if
output							load_en_o			; // ext mem load start
input							load_done_i      	; // ext mem load done
output [`PIC_W_MB_LEN - 1:0]	load_x_o		    ; // mb x
output [`PIC_H_MB_LEN - 1:0]	load_y_o		    ; // mb y
output [1:0]					load_mode_o			; // load mode: [1]:Y/UV, [0]:Full/Bottom line
input							load_valid_i		; // load data valid
input  [4*4*`BIT_DEPTH - 1:0]	load_data_i         ; // load data

output							store_en_o			; // store enable	
input							store_done_i       	; // store done
output [`PIC_W_MB_LEN - 1:0]	store_x_o			; // mb x
output [`PIC_H_MB_LEN - 1:0]	store_y_o          	; // mb y
output [1:0]					store_mode_o		; // store mode: [1]:Y/UV, [0]:Full/Bottom line
input							store_rden_i       	; // ext read enabe
output [4:0]					store_raddr_i      	; // ext read address
input  [4*4*`BIT_DEPTH - 1:0]	store_rdata_o      	; // ext read data
// db if
input 							db_t_rden_i			; // db top ref. read
input  [2:0]					db_t_radd_i         ; // db top ref. read address
output [4*4*`BIT_DEPTH - 1:0] 	db_t_rdat_o         ; // db top ref. read data
input 							db_c_wren_i         ; // db filted pixel write
input  [5:0]					db_c_wadd_i         ; // db filted pixel write address
input  [4*4*`BIT_DEPTH - 1:0] 	db_c_wdat_i         ; // db filted pixel write data

// *************************************************
//                                             
//    REG DECLARATION                         
//                                             
// *************************************************
reg	[2:0]						curr_state;
reg	[1:0]						cnt4;			// counter 4
reg								store_en_flag;  // db filting is done, ready for store
reg [1:0]						store_cnt; 		// how many time to store
reg								buf_sel; 		// buffer sel for store memory							

// *************************************************                                                   
//                                                                                               
//    Wire DECLARATION                                                                           
//                                                                                               
// *************************************************  
reg	[3:0]						next_state	;
// db top ref address   
wire							yuv_flag	;

// *************************************************                                                   
//                                                                                               
//    Logic DECLARATION                                                                           
//                                                                                               
// *************************************************
// ----------------------------------------------------
//                  Outputs
//
//   load/store mode definition
//   bits:       [1]               [0]
//                0: Y              0: Last 4x4 Line
//                1: UV             1: Full MB
// ----------------------------------------------------
assign load_en_o 	= (curr_state == LD_T_Y || curr_state == LD_T_UV) ? 1'b1:1'b0;
assign load_x_o 	= sys_ld_x_i;
assign load_y_o 	= sys_ld_y_i-1'b1;
assign load_mode_o  = (curr_state == LD_T_Y) ? 2'b00:
					  (curr_state == LD_T_UV)? 2'b10:
					 						   2'b00;
assign store_en_o	= (curr_state == ST_T_Y || curr_state == ST_T_UV || 
					   curr_state == ST_C_Y || curr_state == ST_C_UV) ? 1'b1:1'b0; 
assign store_x_o 	= (store_cnt == 'd1) ? sys_st_x_i : (sys_st_x_i - 1'b1);
assign store_y_o 	= store_mode_o[0] ? sys_st_y_i : (sys_st_y_i - 1'b1);
assign store_mode_o = (curr_state == ST_T_Y) ? 2'b00:
					  (curr_state == ST_T_UV)? 2'b10:
					  (curr_state == ST_C_Y) ? 2'b01:
					  (curr_state == ST_C_UV)? 2'b11:
					 						   2'b00;

assign sys_done_o   = (next_state==IDLE) ? 1'b1: 1'b0;
					 						   
// ---------------------------------------------------- 
//                                             
//    CTRL FSM  Logic                        
//                        
//    T T T T   T T   T T       MB_st_X = 0     : NO Store
//    C C C C   C C   C C       MB_st_X = Total : Twice Store
//    C C C C   C C   C C       Other           : Once Store
//    C C C C   (U)   (V)       MB_st_Y = 0     : No Top Store
//    C C C C                   MB_st_Y >0      : Top Store
//      (Y)                     MB_ld_Y = 0     : No Load Top 
//                              MB_ld_Y >0      : Load Top
//    Pingpong Buffer
//
//                     
// ---------------------------------------------------- 
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    curr_state <= IDLE;
  else
    curr_state <= next_state;
end

always @(*)begin
  case(curr_state)
    IDLE :	if(sys_start_i) begin
    			if (sys_ld_y_i>0)
            		next_state = LD_T_Y;
            	else 
            		next_state = ST_WAIT;
            end
            else
            	next_state = IDLE; 
    LD_T_Y: if(load_done_i)
    			next_state = LD_T_UV;
    	  	else
            	next_state = LD_T_Y;        	
    LD_T_UV:if(load_done_i)
    			next_state = ST_WAIT;
    	  	else
            	next_state = LD_T_UV;       	
    ST_WAIT:if(store_en_flag) begin
    			if (store_cnt=='d0)
    				next_state = IDLE;
    			else if (sys_st_y_i>'d0)
    				next_state = ST_T_Y;
    			else 
    				next_state = ST_C_Y;
    		end
    		else
    			next_state = ST_WAIT;
    ST_T_Y: if(store_done_i)
    			next_state = ST_T_UV;
    		else
    			next_state = ST_T_Y;
    ST_T_UV:if(store_done_i) 
    			next_state = ST_C_Y;
    		else
    			next_state = ST_T_UV;
    ST_C_Y: if(store_done_i) 
    			next_state = ST_C_UV;
    		else
    			next_state = ST_C_Y;
    ST_C_UV:if(store_done_i) 
    			next_state = ST_WAIT;
    		else
    			next_state = ST_C_UV;
    default:next_state = IDLE;
  endcase
end                 

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    store_en_flag <= 1'b0;
  else if (curr_state == IDLE)
    store_en_flag <= 1'b0;
  else if (db_done_i)
  	store_en_flag <= 1'b1;
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    store_cnt <= 'b0;
  else if (curr_state == IDLE)
    store_cnt <= 'b0;
  else if (db_done_i) begin
  	if (sys_st_x_i==0)
  		store_cnt <= 'b0;
  	else if (sys_st_x_i==sys_total_x)
  		store_cnt <= 'd2;
  	else
  		store_cnt <= 'd1;
  end
  else if (curr_state == ST_WAIT && store_en_flag && store_cnt!='d0)
  	store_cnt <= store_cnt - 1'b1;
end

// ----------------------------------------------------
//                  Memory Operation
// ----------------------------------------------------
// buf sel
always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		buf_sel <= 1'b0;
	else if (sys_start_i)
		buf_sel <= ~buf_sel;
end

// Top Ref Memory         
always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		cnt4 <= 2'b0;
	else if (load_done_i)
		cnt4 <= 2'b0;
	else if (load_valid_i) 
		cnt4 <= cnt4 + 1'b1;
end

assign yuv_flag = (curr_state == LD_T_UV) ? 1'b1 : 1'b0;
 
fetch_ram_2p_128x16 u_db_top_128x16(
				.clk     ( clk           			),
				.wdata   ( load_data_i 				),
				.waddr   ( {buf_sel, yuv_flag, cnt4}),
				.we      ( load_valid_i 			),
				.rd      ( db_t_rden_i   			),
				.raddr   ( {~buf_sel, db_t_radd_i}  ),
				.rdata   ( db_t_rdat_o   			)
);

// Store Filted Memory
fetch_ram_2p_128x64 u_db_rec_128x64(
				.clk     ( clk           			),
				.wdata   ( db_c_wdat_i 	 			),
				.waddr   ( {db_c_wadd_i[5]^buf_sel, db_c_wadd_i[4:0]}),
				.we      ( db_c_wren_i				),
				.rd      ( store_rden_i     		),
				.raddr   ( {((~buf_sel)^store_cnt[0]), store_raddr_i}),
				.rdata   ( store_rdata_o    		)
);

endmodule
