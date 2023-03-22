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
// Created        : 2012-10-09
// Author         : Yibo FAN
// Description    : update Fetch & IME Arch.
//
//------------------------------------------------------------------- 
`include "enc_defines.v"

module fetch_luma(
        clk             	,
        rst_n           	,
        sys_total_x			,
        sys_total_y     	,
        sys_mb_x_i      	,
        sys_mb_y_i      	,
        sys_load_i			,
        sys_done_o			, 
        ext_start_o			,
        ext_done_i      	,
        ext_mb_x_o      	,
        ext_mb_y_o      	,
        ext_valid_i     	,
        ext_data_i      	,
        bank_sel_o			,
        ime_rden_i			,	  
        ime_addr_i	    	,
        ime_data_o	    	,
        fme_rden_i			,
        fme_addr_i	    	,
        fme_data_o	    	
);

// ************************************************* 
//                                             
//    Parameter DECLARATION                         
//                                             
// ************************************************* 
parameter 						IDLE  = 3'd0, // IDLE
          						LD_T  = 3'd1, // LOAD top MB sw strip    
          						LD_S  = 3'd2, // LOAD normal mb sw strip 
          						LD_B  = 3'd3, // LOAD bottom mb sw strip 
          						LD_N  = 3'd4, // Not LOAD                   
          						EXT_WAIT = 1'b0, // ext wait
          						EXT_LOAD = 1'b1; // exit load

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
input [`PIC_W_MB_LEN - 1:0]     sys_mb_x_i      	;
input [`PIC_H_MB_LEN - 1:0]     sys_mb_y_i      	;
input	                        sys_load_i			; // same signal from load cur_mb
output							sys_done_o			; // load sw done
// ext if
output							ext_start_o			;
input							ext_done_i      	;
output [`PIC_W_MB_LEN - 1:0]	ext_mb_x_o      	;
output [`PIC_H_MB_LEN - 1:0]	ext_mb_y_o      	;
input							ext_valid_i     	;
input [8*`BIT_DEPTH - 1:0]		ext_data_i      	;
// ime/fme share if
output [5:0]						bank_sel_o		;
// fetch_ime if
input  				 		 		ime_rden_i		; // read enable for each cache ram bank
input  [`SW_H_LEN-1:0]	 		  	ime_addr_i	    ; // same address for each ram bank
output [6*`MB_WIDTH*`BIT_DEPTH-1:0] ime_data_o	    ; // combined all ram bank data together                                
// fetch_fme if
input  				 		 		fme_rden_i		; // read enable for each cache ram bank
input  [`SW_H_LEN-1:0]	 		  	fme_addr_i	    ; // same address for each ram bank
output [6*`MB_WIDTH*`BIT_DEPTH-1:0] fme_data_o	    ; // combined all ram bank data together

// *************************************************
//                                             
//    REG DECLARATION                         
//                                             
// *************************************************
reg	[2:0]							curr_state	;
reg									ext_cst		;
reg									load_r		;
reg									sys_done_o	;
reg [`PIC_W_MB_LEN - 1:0]			ld_x_pos_r 	;
reg [`PIC_H_MB_LEN - 1:0]			ld_y_pos_r 	;
reg [1:0]							ld_x_num_r 	;
reg [1:0]							ld_y_num_r 	;
reg [1:0]							ld_x_cnt_r	;
reg [1:0]							ld_y_cnt_r	;

reg									ext_load_req_r;
reg									ext_start_o	;
reg	[`PIC_W_MB_LEN - 1:0]			ext_mb_x_o 	;
reg	[`PIC_H_MB_LEN - 1:0]			ext_mb_y_o 	;

reg [`SW_H_LEN-1:0]					ram_wpt_r  		;
reg [`SW_H_LEN-1:0]					ram_waddr_r   	;
reg [5:0]							ram_bank_sel_r  ;
reg [4:0]							ram_cnt_r		;
reg									ram_wsel_r		;

// *************************************************                                                   
//                                                                                               
//    Wire DECLARATION                                                                           
//                                                                                               
// *************************************************  
reg	[2:0]							next_state	;
reg									ext_nst		;
wire [127:0]						ime_data_0, ime_data_1, ime_data_2,
									ime_data_3, ime_data_4, ime_data_5,
									fme_data_0, fme_data_1, fme_data_2,
									fme_data_3, fme_data_4, fme_data_5;
									
// ************************************************* 
//                                             
//    CTRL FSM  Logic                        
//                                             
// ************************************************* 
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    curr_state <= IDLE;
  else
    curr_state <= next_state;
end

always @(*)begin
  case(curr_state)
    IDLE :if(sys_load_i)
            next_state = LD_T;
          else
            next_state = IDLE;
    LD_T :if(sys_load_i && (sys_mb_x_i+1'b1)>sys_total_x)
    		next_state = LD_S;
    	  else
            next_state = LD_T;
 	LD_S :if(sys_load_i && (sys_mb_x_i+1'b1)>sys_total_x && sys_mb_y_i==(sys_total_y-1'b1))
 			next_state = LD_B;
 		  else
 		  	next_state = LD_S;
 	LD_B :if(sys_load_i && (sys_mb_x_i+1'b1)>sys_total_x)
 			next_state = LD_N;
 		  else
 		  	next_state = LD_B;
 	LD_N :  next_state = IDLE;
    default:next_state = IDLE;
  endcase
end                 

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    load_r <= 1'b0;
  else
    load_r <= sys_load_i;
end

// set ext_load & ram_bank parameters
always @(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
   	ld_x_pos_r <= 'b0;
   	ld_y_pos_r <= 'b0;
   	ld_x_num_r <= 'b0;
   	ld_y_num_r <= 'b0;
   	ram_wpt_r  <= 'b0;
  end
  else begin
  	case (curr_state)
  		LD_T	: if (sys_mb_x_i=='b0 && sys_mb_y_i=='b0) begin 		 
  					ld_x_pos_r <= 'd0;
  					ld_y_pos_r <= 'd0;
  					ld_x_num_r <= 'd1;
  					ld_y_num_r <= 'd1;
  					ram_wpt_r  <= 'd16;
  				  end
    			  else begin 
    				ld_x_pos_r <= sys_mb_x_i+1'b1;
    				ld_y_pos_r <= 'd0;
    				ld_x_num_r <= 'd0;
    				ld_y_num_r <= 'd1;
    				ram_wpt_r  <= 'd16;
    			  end
    	LD_S 	: begin 
  					ld_x_pos_r <= (sys_mb_x_i+1'b1)>sys_total_x ? 'd0 : sys_mb_x_i+1'b1;
  					ld_y_pos_r <= (sys_mb_x_i+1'b1)>sys_total_x ? sys_mb_y_i : (sys_mb_y_i-2'd1);
  					ld_x_num_r <= 'd0;
  					ld_y_num_r <= 'd2;
  					ram_wpt_r  <= 'd0;
  				  end
    	LD_B 	: begin 
  					ld_x_pos_r <= (sys_mb_x_i+1'b1)>sys_total_x ? 'd0 : sys_mb_x_i+1'b1;
  					ld_y_pos_r <= sys_total_y-1'b1;
  					ld_x_num_r <= 'd0;
  					ld_y_num_r <= 'd1;
  					ram_wpt_r  <= 'd0;
  				  end
    	default	: begin 
  					ld_x_pos_r <= 'd0;
  					ld_y_pos_r <= 'd0;
  					ld_x_num_r <= 'd0;
  					ld_y_num_r <= 'd0;
  					ram_wpt_r  <= 'd0;
  				  end
    endcase
  end
end

// set ext load req
always @(posedge clk or negedge rst_n)begin
  if(!rst_n) 
	ext_load_req_r <= 1'b0;
  else if (ext_cst == EXT_LOAD && ext_done_i && ld_x_cnt_r==ld_x_num_r && ld_y_cnt_r==ld_y_num_r )
  	ext_load_req_r <= 1'b0;
  else if (load_r && (curr_state==LD_T || curr_state==LD_S || curr_state==LD_B))
  	ext_load_req_r <= 1'b1;
end

// *************************************************
//                                                  
//   EXT LOAD Logic                
//                                                  
// *************************************************
// ext load FSM
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    ext_cst <= EXT_WAIT;
  else
    ext_cst <= ext_nst;
end

always @(*)begin
  case(ext_cst)
    EXT_WAIT:if(ext_load_req_r)
            ext_nst = EXT_LOAD;
          else
            ext_nst = EXT_WAIT;
    EXT_LOAD :if(ext_done_i)
            ext_nst = EXT_WAIT;
          else
            ext_nst = EXT_LOAD;
    default:ext_nst = EXT_WAIT;
  endcase
end

// ext load cnt
always @(posedge clk or negedge rst_n)begin
  if(!rst_n) 
  	ld_x_cnt_r <= 'b0;
  else if (ext_cst == EXT_LOAD && ext_done_i && ld_y_cnt_r == ld_y_num_r) begin
  	if (ld_x_cnt_r == ld_x_num_r)
  		ld_x_cnt_r <= 'b0;
  	else
  		ld_x_cnt_r <= ld_x_cnt_r + 1'b1;
  end
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n) 
  	ld_y_cnt_r <= 'b0;
  else if (ext_cst == EXT_LOAD && ext_done_i) begin
  	if (ld_y_cnt_r == ld_y_num_r)
  		ld_y_cnt_r <= 'b0;
  	else
  		ld_y_cnt_r <= ld_y_cnt_r + 1'b1;
  end
end

// ext load output
always @(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
  	ext_start_o <= 1'b0;
  	ext_mb_x_o  <= 'b0;
  	ext_mb_y_o  <= 'b0;    
  end
  else if (ext_cst == EXT_LOAD) begin
  	if (ext_done_i) begin
		ext_start_o <= 1'b0;
  		ext_mb_x_o  <= 'b0; 
  		ext_mb_y_o  <= 'b0;  	
  	end
  	else begin
  		ext_start_o <= 1'b1;                   
  		ext_mb_x_o  <= ld_x_pos_r + ld_x_cnt_r;
  		ext_mb_y_o  <= ld_y_pos_r + ld_y_cnt_r;  	
  	end
  end
end

// ************************************************* 
//                                             
//    RAM BANKs                         
//                                             
// ************************************************* 
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
	ram_cnt_r <= 'b0;
  else if (ext_cst == EXT_WAIT)
  	ram_cnt_r <= 'b0;
  else if (ext_cst == EXT_LOAD && ext_valid_i)
	ram_cnt_r <= ram_cnt_r + 1'b1;
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
	ram_waddr_r <= 'b0;
	ram_wsel_r  <= 1'b0;
  end
  else if (ext_cst == EXT_WAIT) begin
  	ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r;
  	ram_wsel_r  <= 1'b0;
  end
  else if (ext_cst == EXT_LOAD && ext_valid_i) begin
  	case(ram_cnt_r)
  		5'd3 : begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r		; ram_wsel_r<= 1'b1 ; end
  		5'd7 : begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r + 5'd4; ram_wsel_r<= 1'b0 ; end
  		5'd11: begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r + 5'd4; ram_wsel_r<= 1'b1 ; end
  		5'd15: begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r + 5'd8; ram_wsel_r<= 1'b0	; end
  		5'd19: begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r + 5'd8; ram_wsel_r<= 1'b1	; end
  		5'd23: begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r + 5'd12; ram_wsel_r<= 1'b0; end
  		5'd27: begin ram_waddr_r <= ld_y_cnt_r*16 + ram_wpt_r + 5'd12; ram_wsel_r<= 1'b1; end
  		5'd31: begin ram_waddr_r <= 'b0								; ram_wsel_r<= 1'b0	; end
  		default: ram_waddr_r <= ram_waddr_r + 1'b1;
	endcase
  end	
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
	ram_bank_sel_r <= 'b1;
  else if ((ext_cst == EXT_LOAD && ext_done_i && ld_y_cnt_r == ld_y_num_r) || (curr_state==LD_N))
  	ram_bank_sel_r <= {ram_bank_sel_r[4:0], ram_bank_sel_r[5]};
end

// always @(posedge clk or negedge rst_n)begin
//   if(!rst_n)
// 	ram_bank_sel_r <= 'b1;
//   else if (ext_cst == EXT_LOAD && ext_done_i && ld_y_cnt_r == ld_y_num_r)
//   	ram_bank_sel_r <= {ram_bank_sel_r[4:0], ram_bank_sel_r[5]};
// end

fetch_ram_dp_128x48  u_ram0 (
        .clk     	( clk											),
        .rda_i      ( ime_rden_i									),
        .addra_i    ( ime_addr_i									),
        .dataa_o    ( ime_data_0									),
        .rdb_i      ( fme_rden_i									),
        .web_i      ( ram_bank_sel_r[0] ? ext_valid_i   : 1'b0		),
        .wsb_i		( ram_wsel_r									),
        .addrb_i	( (curr_state==IDLE)? fme_addr_i : (ext_cst?((ram_bank_sel_r[0] ? ram_waddr_r: fme_addr_i)):fme_addr_i)	),
        .datab_o    ( fme_data_0									),
        .datab_i    ( ext_data_i									)
); 

fetch_ram_dp_128x48  u_ram1 (
        .clk    	( clk											),
        .rda_i      ( ime_rden_i									),
        .addra_i    ( ime_addr_i									),
        .dataa_o    ( ime_data_1									),
        .rdb_i      ( fme_rden_i									),
        .web_i      ( ram_bank_sel_r[1] ? ext_valid_i   : 1'b0		),
        .wsb_i		( ram_wsel_r									),
        .addrb_i	( (curr_state==IDLE)? fme_addr_i : (ext_cst?((ram_bank_sel_r[1] ? ram_waddr_r: fme_addr_i)):fme_addr_i)		),
        .datab_o    ( fme_data_1									),
        .datab_i    ( ext_data_i									)
); 

fetch_ram_dp_128x48  u_ram2 (
        .clk    	( clk											),
        .rda_i      ( ime_rden_i									),
        .addra_i    ( ime_addr_i									),
        .dataa_o    ( ime_data_2									),
        .rdb_i      ( fme_rden_i									),
        .web_i      ( ram_bank_sel_r[2] ? ext_valid_i   : 1'b0		),
        .wsb_i		( ram_wsel_r									),
        .addrb_i	( (curr_state==IDLE)? fme_addr_i : (ext_cst?((ram_bank_sel_r[2] ? ram_waddr_r: fme_addr_i)):fme_addr_i)		),
        .datab_o    ( fme_data_2									),
        .datab_i    ( ext_data_i									)
); 

fetch_ram_dp_128x48  u_ram3 (
        .clk    	( clk											),
        .rda_i      ( ime_rden_i									),
        .addra_i    ( ime_addr_i									),
        .dataa_o    ( ime_data_3									),
        .rdb_i      ( fme_rden_i									),
        .web_i      ( ram_bank_sel_r[3] ? ext_valid_i   : 1'b0		),
        .wsb_i		( ram_wsel_r									),
        .addrb_i	( (curr_state==IDLE)? fme_addr_i : (ext_cst?((ram_bank_sel_r[3] ? ram_waddr_r: fme_addr_i)):fme_addr_i)		),
        .datab_o    ( fme_data_3									),
        .datab_i    ( ext_data_i									)
); 

fetch_ram_dp_128x48  u_ram4 (
        .clk    	( clk											),
        .rda_i      ( ime_rden_i									),
        .addra_i    ( ime_addr_i									),
        .dataa_o    ( ime_data_4									),
        .rdb_i      ( fme_rden_i									),
        .web_i      ( ram_bank_sel_r[4] ? ext_valid_i   : 1'b0		),
        .wsb_i		( ram_wsel_r									),
        .addrb_i	( (curr_state==IDLE)? fme_addr_i : (ext_cst?((ram_bank_sel_r[4] ? ram_waddr_r: fme_addr_i)):fme_addr_i)		),
        .datab_o    ( fme_data_4									),
        .datab_i    ( ext_data_i									)
); 

fetch_ram_dp_128x48  u_ram5 (
        .clk    	( clk											),
        .rda_i      ( ime_rden_i									),
        .addra_i    ( ime_addr_i									),
        .dataa_o    ( ime_data_5									),
        .rdb_i      ( fme_rden_i									),
        .web_i      ( ram_bank_sel_r[5] ? ext_valid_i   : 1'b0		),
        .wsb_i		( ram_wsel_r									),
        .addrb_i	( (curr_state==IDLE)? fme_addr_i : (ext_cst?((ram_bank_sel_r[5] ? ram_waddr_r: fme_addr_i)):fme_addr_i)		),
        .datab_o    ( fme_data_5									),
        .datab_i    ( ext_data_i									)
); 


// ************************************************* 
//                                                   
//    IME/FME/SYS OUTPUT                                      
//                                                   
// ************************************************* 
assign bank_sel_o = ram_bank_sel_r;

assign ime_data_o = {ime_data_5, ime_data_4, ime_data_3, ime_data_2, ime_data_1, ime_data_0};
assign fme_data_o = {fme_data_5, fme_data_4, fme_data_3, fme_data_2, fme_data_1, fme_data_0}; 

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
	sys_done_o <= 1'b0;
  else if (sys_done_o)
  	sys_done_o <= 1'b0;
  else if ((ext_cst == EXT_LOAD && ext_done_i && ld_x_cnt_r==ld_x_num_r && ld_y_cnt_r==ld_y_num_r) || (curr_state==LD_N))
  	sys_done_o <= 1'b1;
end

endmodule
