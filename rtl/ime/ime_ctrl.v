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
// Filename       : ime_ctrl.v
// Author         : Yibo FAN
// Created        : 2012-10-07
// Description    : IME ctrl
//					1. load pixel from fetch
//               	2. manage ref_mb systolic array 
//				    3. output ref_mb to sad_top for SAD computing
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_ctrl(
    			clk,
    			rstn,    
    			sysif_start_i,
    			sysif_qp_i,
    			sysif_total_x_i,
    			sysif_total_y_i,
    			sysif_mb_x_i,
    			sysif_mb_y_i,    	
    			fetchif_start_o,		
    			fetchif_valid_i, 			
    			fetchif_mb_x_o,
    			fetchif_mb_y_o,
    			fetchif_load_o,
    			fetchif_addr_o,
    			fetchif_data_i,
    			sadtree_end_o,
    			sadtree_imv_o,
    			sadtree_lamda_o,
    			sadtree_run_o,
    			sadtree_refmb_o
);

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter 							IDLE = 3'd0, // idle
          							INIT = 3'd1, // wait fetch complete sw loading
          							LOAD = 3'd2, // load sys_array
          							S_DN = 3'd3, // search down 
          							S_UP = 3'd4, // search up
          							S_RS = 3'd5; // search right shift
          
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input  								clk;
input  								rstn;
// sys if
input  								sysif_start_i;
input  [5:0]                        sysif_qp_i;
input  [`PIC_W_MB_LEN-1:0]     		sysif_total_x_i;
input  [`PIC_H_MB_LEN-1:0]  		sysif_total_y_i;
input  [`PIC_W_MB_LEN-1:0]     		sysif_mb_x_i;
input  [`PIC_H_MB_LEN-1:0]  		sysif_mb_y_i;
// fetch if
output                              fetchif_start_o;
input								fetchif_valid_i; 	
output	[`PIC_W_MB_LEN-1:0]			fetchif_mb_x_o;     
output	[`PIC_H_MB_LEN-1:0]			fetchif_mb_y_o;     
output								fetchif_load_o;     
output	[`SW_H_LEN-1:0]				fetchif_addr_o;     
input	[3*16*`BIT_DEPTH-1:0]		fetchif_data_i;     
// sadtree if
output								sadtree_end_o;
output [2*`IMVD_LEN-1:0]			sadtree_imv_o;  
output [8:0] 						sadtree_lamda_o;
output 								sadtree_run_o;  
output [(`MB_WIDTH+`PE_NUM-1)*`MB_WIDTH*`BIT_DEPTH-1:0] sadtree_refmb_o;  

// ********************************************
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
reg [2:0]							curr_state;
reg [5:0]							ime_cnt_r;
reg [2:0]							ref_shift_r;
reg [8:0]							lambda;
reg									fetchif_load_o;
reg									sadtree_end_o;
reg									sadtree_run_o;

reg [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:0] sys_array_r0, sys_array_r1, sys_array_r2, sys_array_r3, 
											 sys_array_r4, sys_array_r5, sys_array_r6, sys_array_r7,
											 sys_array_r8, sys_array_r9, sys_array_r10, sys_array_r11,
											 sys_array_r12, sys_array_r13, sys_array_r14, sys_array_r15;  

reg									sys_array_ld_dn_r, sys_array_ld_up_r, sys_array_ld_rt_r;

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************     
reg  [2:0]									  next_state;
wire [(3*16+`PE_NUM-1)*`BIT_DEPTH-1:0]		  fetch_data;
reg  [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:0] fetch_data_shift;       
reg signed [`IMVD_LEN-1:0]					  imv_x, imv_y, imv_y_up, imv_y_dn;						

wire [(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] sys_array_ref_0 , sys_array_ref_1 , sys_array_ref_2 ,  sys_array_ref_3 ,
  											sys_array_ref_4 , sys_array_ref_5 , sys_array_ref_6 ,  sys_array_ref_7 ,
  											sys_array_ref_8 , sys_array_ref_9 , sys_array_ref_10,  sys_array_ref_11,
  											sys_array_ref_12, sys_array_ref_13, sys_array_ref_14,  sys_array_ref_15;

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
// --------------------------------------------
//   IME FSM
// --------------------------------------------
always @(posedge clk or negedge rstn) begin
  	if(!rstn) 
    	curr_state   <= IDLE;
  	else
    	curr_state <= next_state;
end

always @( * ) begin
  	case(curr_state)
    	IDLE: if (sysif_start_i)
    			next_state = INIT;
    		  else
    		  	next_state = IDLE;
        INIT: if (fetchif_valid_i)
        		next_state = LOAD;
        	  else
        	  	next_state = INIT;
        LOAD: if(ime_cnt_r == 6'd18)
        		next_state = S_DN;
        	  else 
        	    next_state = LOAD;
    	S_DN: if(ime_cnt_r == 6'd44)
    			next_state = S_RS;
    		  else
    		  	next_state = S_DN;
    	S_UP: if (ime_cnt_r == 6'd3) begin
    			if (ref_shift_r == 3'd7)
    				next_state = IDLE;
    		  	else
    				next_state = S_RS;
    		  end
    		  else
    		    next_state = S_UP;    	
    	S_RS: if (ime_cnt_r == 6'd45)
        		next_state = S_UP;
      		  else 
        		next_state = S_DN;
    	default:
      		next_state = IDLE;
  	endcase
end

always @(posedge clk or negedge rstn) begin
  	if(!rstn)
    	ime_cnt_r <= 6'd3;
    else if (curr_state==IDLE)
    	ime_cnt_r <= 6'd3;
  	else if (curr_state==LOAD || curr_state==S_DN)
    	ime_cnt_r <= ime_cnt_r + 1;
    else if (curr_state==S_UP)
    	ime_cnt_r <= ime_cnt_r - 1;
    else if (curr_state==S_RS) begin
    	if (ime_cnt_r==6'd45)
    		ime_cnt_r <= 6'd28;
    	else
    		ime_cnt_r <= 6'd19;
    	end
    else
    	ime_cnt_r <= ime_cnt_r;
end

always @(posedge clk or negedge rstn) begin
  	if(!rstn)
    	ref_shift_r <= 3'd0;
    else if (curr_state==IDLE)
    	ref_shift_r <= 3'd0;
    else if (curr_state==S_RS) 
    	ref_shift_r <= ref_shift_r+1;
end



// ---------------------------------------------
//   ref mb systolic array
// ---------------------------------------------
always @(posedge clk or negedge rstn) begin
  	if(!rstn) begin
    	sys_array_ld_dn_r <= 1'b0;
    	sys_array_ld_up_r <= 1'b0;
    	sys_array_ld_rt_r <= 1'b0;
    end
    else begin
    	case (curr_state)
    		IDLE : 	begin
    					sys_array_ld_dn_r <= 1'b0;
    					sys_array_ld_up_r <= 1'b0;
    					sys_array_ld_rt_r <= 1'b0;
    				end
    		LOAD :	begin
    					sys_array_ld_dn_r <= 1'b1;
    					sys_array_ld_up_r <= 1'b0;
    					sys_array_ld_rt_r <= 1'b0;
    				end
    		S_DN :	begin
    					sys_array_ld_dn_r <= 1'b1;
    					sys_array_ld_up_r <= 1'b0;
    					sys_array_ld_rt_r <= 1'b0;
    				end
    		S_UP :	begin
    					sys_array_ld_dn_r <= 1'b0;
    					sys_array_ld_up_r <= 1'b1;
    					sys_array_ld_rt_r <= 1'b0;
    				end
    		S_RS :	begin
    					sys_array_ld_dn_r <= 1'b0;
    					sys_array_ld_up_r <= 1'b0;
    					sys_array_ld_rt_r <= 1'b1;
    				end
    		default:begin
    					sys_array_ld_dn_r <= 1'b0;
    					sys_array_ld_up_r <= 1'b0;
    					sys_array_ld_rt_r <= 1'b0;
    				end
    	endcase
    end    	
end

always @(posedge clk or negedge rstn) begin
  if(!rstn) begin  	
  		sys_array_r0  <= 'b0;  	
  		sys_array_r1  <= 'b0;
  		sys_array_r2  <= 'b0;
  		sys_array_r3  <= 'b0;
  		sys_array_r4  <= 'b0;
  		sys_array_r5  <= 'b0;
  		sys_array_r6  <= 'b0;
  		sys_array_r7  <= 'b0;
  		sys_array_r8  <= 'b0;
  		sys_array_r9  <= 'b0;
  		sys_array_r10 <= 'b0;
  		sys_array_r11 <= 'b0;
  		sys_array_r12 <= 'b0;
  		sys_array_r13 <= 'b0;
  		sys_array_r14 <= 'b0;		
  		sys_array_r15 <= 'b0;     		
  end
  else if (sys_array_ld_dn_r) begin
        sys_array_r0  <= fetch_data_shift;
        sys_array_r1  <= sys_array_r0 ;
        sys_array_r2  <= sys_array_r1 ;
        sys_array_r3  <= sys_array_r2 ;
        sys_array_r4  <= sys_array_r3 ;
        sys_array_r5  <= sys_array_r4 ;
        sys_array_r6  <= sys_array_r5 ;
        sys_array_r7  <= sys_array_r6 ;
        sys_array_r8  <= sys_array_r7 ;
        sys_array_r9  <= sys_array_r8 ;
        sys_array_r10 <= sys_array_r9 ;
        sys_array_r11 <= sys_array_r10;
        sys_array_r12 <= sys_array_r11;
        sys_array_r13 <= sys_array_r12;
        sys_array_r14 <= sys_array_r13;
        sys_array_r15 <= sys_array_r14;          
  end
  else if (sys_array_ld_up_r) begin
        sys_array_r0  <= sys_array_r1 ;            
        sys_array_r1  <= sys_array_r2 ;
        sys_array_r2  <= sys_array_r3 ;
        sys_array_r3  <= sys_array_r4 ;
        sys_array_r4  <= sys_array_r5 ;
        sys_array_r5  <= sys_array_r6 ;
        sys_array_r6  <= sys_array_r7 ;
        sys_array_r7  <= sys_array_r8 ;
        sys_array_r8  <= sys_array_r9 ;
        sys_array_r9  <= sys_array_r10;
        sys_array_r10 <= sys_array_r11;
        sys_array_r11 <= sys_array_r12;
        sys_array_r12 <= sys_array_r13;
        sys_array_r13 <= sys_array_r14;
        sys_array_r14 <= sys_array_r15;
        sys_array_r15 <= fetch_data_shift;   
  end
  else if (sys_array_ld_rt_r) begin
        sys_array_r0  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r0 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r1  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r1 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r2  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r2 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r3  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r3 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r4  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r4 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r5  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r5 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r6  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r6 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
  	    sys_array_r7  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r7 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r8  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r8 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r9  <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r9 [(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r10 <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r10[(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r11 <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r11[(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r12 <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r12[(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r13 <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r13[(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r14 <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r14[(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};
        sys_array_r15 <= {{`PE_NUM*`BIT_DEPTH{1'b0}}, sys_array_r15[(`MB_WIDTH+2*`PE_NUM-1)*`BIT_DEPTH-1:`PE_NUM*`BIT_DEPTH]};         
  end  
end
                                       
assign fetch_data = {{(`PE_NUM-1)*`BIT_DEPTH{1'b0}}, fetchif_data_i};                                      
always @(*) begin
	case (ref_shift_r)
		3'd0: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+0)*`PE_NUM-1)*`BIT_DEPTH-1:0*`PE_NUM*`BIT_DEPTH]; 
		3'd1: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+1)*`PE_NUM-1)*`BIT_DEPTH-1:1*`PE_NUM*`BIT_DEPTH]; 
		3'd2: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+2)*`PE_NUM-1)*`BIT_DEPTH-1:2*`PE_NUM*`BIT_DEPTH];
		3'd3: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+3)*`PE_NUM-1)*`BIT_DEPTH-1:3*`PE_NUM*`BIT_DEPTH];	
		3'd4: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+4)*`PE_NUM-1)*`BIT_DEPTH-1:4*`PE_NUM*`BIT_DEPTH];
		3'd5: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+5)*`PE_NUM-1)*`BIT_DEPTH-1:5*`PE_NUM*`BIT_DEPTH];
		3'd6: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+6)*`PE_NUM-1)*`BIT_DEPTH-1:6*`PE_NUM*`BIT_DEPTH];
		3'd7: fetch_data_shift = fetch_data[(`MB_WIDTH+(2+7)*`PE_NUM-1)*`BIT_DEPTH-1:7*`PE_NUM*`BIT_DEPTH];
	endcase
end

// --------------------------------------------
//   fetch if output signal
// --------------------------------------------
always @(posedge clk or negedge rstn) begin
  	if(!rstn)
    	fetchif_load_o <= 1'b0;
    else if (next_state==IDLE)
    	fetchif_load_o <= 1'b0;
    else if (next_state==LOAD || next_state==S_DN || next_state==S_UP || next_state==S_RS) 
    	fetchif_load_o <= 1'b1;
end

assign fetchif_start_o = sysif_start_i;
assign fetchif_mb_x_o = sysif_mb_x_i;
assign fetchif_mb_y_o = sysif_mb_y_i;
assign fetchif_addr_o = ime_cnt_r;

// --------------------------------------------
//   sad_tree_top output signal
// --------------------------------------------
always @(posedge clk or negedge rstn) begin
  	if(!rstn)
    	sadtree_end_o <= 1'b0;
    else if (curr_state==IDLE && sys_array_ld_up_r)
    	sadtree_end_o <= 1'b1;
    else
    	sadtree_end_o <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
  	if(!rstn)
    	sadtree_run_o <= 1'b0;
    else if (curr_state!=LOAD && (sys_array_ld_dn_r || sys_array_ld_up_r || sys_array_ld_rt_r))
    	sadtree_run_o <= 1'b1;
    else
    	sadtree_run_o <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
	if(!rstn) begin
    	imv_x    <= 'b0;
    	imv_y_up <= 'b0;
    	imv_y_dn <= 'b0;
	end
	else begin
		imv_x    <= ref_shift_r*4   - 6'd16;
		imv_y_up <= ime_cnt_r     - 6'd16;
		imv_y_dn <= ime_cnt_r     - 6'd31;		
	end
end

always @(posedge clk or negedge rstn) begin
  	if(!rstn)
    	imv_y <= 'b0;
    else if (sys_array_ld_dn_r)
    	imv_y <= imv_y_dn;
    else if (sys_array_ld_up_r)
    	imv_y <= imv_y_up;
    else if (sys_array_ld_rt_r)
    	imv_y <= imv_y; 
end

assign sadtree_imv_o = {imv_y, imv_x};
      
assign sadtree_lamda_o = lambda;

assign sys_array_ref_0  = sys_array_r0[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_1  = sys_array_r1[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_2  = sys_array_r2[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_3  = sys_array_r3[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_4  = sys_array_r4[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_5  = sys_array_r5[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_6  = sys_array_r6[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_7  = sys_array_r7[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_8  = sys_array_r8[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_9  = sys_array_r9[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0] ;
assign sys_array_ref_10 = sys_array_r10[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0];
assign sys_array_ref_11 = sys_array_r11[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0];
assign sys_array_ref_12 = sys_array_r12[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0];
assign sys_array_ref_13 = sys_array_r13[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0];
assign sys_array_ref_14 = sys_array_r14[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0];
assign sys_array_ref_15 = sys_array_r15[(`MB_WIDTH+`PE_NUM-1)*`BIT_DEPTH-1:0];
  
assign sadtree_refmb_o = { sys_array_ref_0 , sys_array_ref_1 , sys_array_ref_2 ,  sys_array_ref_3 ,
						   sys_array_ref_4 , sys_array_ref_5 , sys_array_ref_6 ,  sys_array_ref_7 ,
						   sys_array_ref_8 , sys_array_ref_9 , sys_array_ref_10,  sys_array_ref_11,
						   sys_array_ref_12, sys_array_ref_13, sys_array_ref_14,  sys_array_ref_15};

// ---------------------------------------------
//   					lambda
// 
// convert qp to lambda
// const uint16_t x264_lambda_tab[QP_MAX_MAX+1] = {
//    1,   1,   1,   1,   1,   1,   1,   1, /*  0- 7 */
//    1,   1,   1,   1,   1,   1,   1,   1, /*  8-15 */
//    2,   2,   2,   2,   3,   3,   3,   4, /* 16-23 */
//    4,   4,   5,   6,   6,   7,   8,   9, /* 24-31 */
//   10,  11,  13,  14,  16,  18,  20,  23, /* 32-39 */
//   25,  29,  32,  36,  40,  45,  51,  57, /* 40-47 */
//   64,  72,  81,  91, 102, 114, 128, 144, /* 48-55 */
//  161, 181, 203, 228, 256, 287, 323, 362, /* 56-63 */
// ---------------------------------------------

always@(posedge clk or negedge rstn) begin
	if(!rstn)
    	lambda <= 'b0;
  	else if (curr_state==INIT)begin
    	case(sysif_qp_i)
        	 0:lambda <= 1;    1:lambda <= 1;    2:lambda <= 1;    3:lambda <= 1;    4:lambda <= 1;    5:lambda <= 1;    6:lambda <= 1;    7:lambda <= 1;
        	 8:lambda <= 1;    9:lambda <= 1;   10:lambda <= 1;   11:lambda <= 1;   12:lambda <= 1;   13:lambda <= 1;   14:lambda <= 1;   15:lambda <= 1;
        	16:lambda <= 2;   17:lambda <= 2;   18:lambda <= 2;   19:lambda <= 2;   20:lambda <= 3;   21:lambda <= 3;   22:lambda <= 3;   23:lambda <= 4;
        	24:lambda <= 4;   25:lambda <= 4;   26:lambda <= 5;   27:lambda <= 6;   28:lambda <= 6;   29:lambda <= 7;   30:lambda <= 8;   31:lambda <= 9;
        	32:lambda <= 10;  33:lambda <= 11;  34:lambda <= 13;  35:lambda <= 14;  36:lambda <= 16;  37:lambda <= 18;  38:lambda <= 20;  39:lambda <= 23;               
        	40:lambda  <= 25; 41:lambda <= 29;  42:lambda <= 32;  43:lambda <= 36;  44:lambda <= 40;  45:lambda <= 45;  46:lambda <= 51;  47:lambda <= 57;
        	48:lambda <= 64;  49:lambda <= 72;  50:lambda <= 81;  51:lambda <= 91;  52:lambda <= 102; 53:lambda <= 114; 54:lambda <= 128; 55:lambda <= 144;
        	56:lambda <= 161; 57:lambda <= 181; 58:lambda <= 203; 59:lambda <= 228; 60:lambda <= 256; 61:lambda <= 287; 62:lambda <= 323; 63:lambda <= 362;
        	default:lambda <=0;
     	endcase
 	end
end

endmodule
