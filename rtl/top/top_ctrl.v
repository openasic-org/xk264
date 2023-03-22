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
// Filename       : top_ctrl.v
// Author         : Yibo FAN
// Created        : 2011-9-30
// Description    : top controller of encoder
//               
// Author		  : Yibo FAN
// Time			  : 2013-06-27
// Modified       : Delete cmd if, add reg if. 
//					move parameter settings to bus interface, not in
//					encoder control
//------------------------------------------------------------------- 
`include "enc_defines.v"

module top_ctrl(
				clk,
				rst_n,
				sys_x_total,
				sys_y_total,
				sys_intra_flag,
				sys_mode,
				sys_start,
				sys_done,						
				frame_start_o,	
				frame_done_o,
				fetch_db_done_i,
				fetch_chroma_done_i,
				fetch_luma_done_i,
				load_done_i,		
				intra_done_i,	
				ime_done_i,
				fme_done_i,
				mc_done_i,				
				ec_done_i,
				db_done_i,		
				bs_empty_i, 		
				load_start_o,	
				intra_start_o,		
				ime_start_o,
				fme_start_o,
				mc_start_o,				
				ec_start_o,
				db_start_o,						
				mb_x_load,
				mb_y_load,
				mb_x_intra,
				mb_y_intra,
				mb_x_ime,
				mb_y_ime,
				mb_x_fme,
				mb_y_fme,
				mb_x_mc,
				mb_y_mc,
				mb_x_db,
				mb_y_db,
				mb_x_ec,
				mb_y_ec			
);

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ******************************************** 
parameter	IDLE  = 4'b0000,
			INIT  = 4'b0001,
			LOAD  = 4'b0010,
			I_S0  = 4'b0011,
			I_S1  = 4'b0100,
			I_S2  = 4'b0101,
			I_S3  = 4'b0110,
			P_S0  = 4'b0111,
			P_S1  = 4'b1000,
			P_S2  = 4'b1001,
			P_S3  = 4'b1010,
			P_S4  = 4'b1011,
			P_S5  = 4'b1100,
			P_S6  = 4'b1101,
			P_S7  = 4'b1110,
			STORE = 4'b1111;
							
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input          				clk , rst_n ;
// sys config IF
input						sys_start;     
output						sys_done;		                			
input						sys_intra_flag; 
input 						sys_mode; 				// 1: MB step mode; 0: Frame mode
input [`PIC_W_MB_LEN-1:0] 	sys_x_total;    
input [`PIC_H_MB_LEN-1:0]  	sys_y_total;	
// module control IF
input        				load_done_i;     		// load cur_mb done
input        				fetch_db_done_i;    	// db load ref/store reconstructed mb done
input		 				fetch_luma_done_i;		// fetch luma reference pixels
input        				fetch_chroma_done_i; 	// chroma search windows load done
input        				intra_done_i;    		// intra done
input        				ime_done_i;      		// ime done
input        				fme_done_i;      		// fme done
input        				mc_done_i;       		// mc done
input        				ec_done_i;       		// entropy coding done
input        				db_done_i;       		// deblocking filter done
input						bs_empty_i;				// bs buf empty
output       				load_start_o;      		// start load cur_mb 
output       				intra_start_o;     		// start intra
output       				ime_start_o;       		// start ime
output       				fme_start_o;       		// start fme
output       				mc_start_o;        		// start mc
output       				ec_start_o;        		// start entropy coding
output       				db_start_o;        		// start deblocking filter
output       				frame_start_o;	  		// start fetch reference frame
output       				frame_done_o;			// frame coding done
output [`PIC_W_MB_LEN-1:0] 	mb_x_load;				// current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_load;              // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_intra;             // current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_intra;             // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_ime;               // current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_ime;               // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_fme;               // current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_fme;               // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_mc;                // current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_mc;                // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_db;                // current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_db;                // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_ec;             	// current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_ec;             	// current coding MB index

// ********************************************
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
// fsm reg
reg    [3:0]  curr_state, curr_state_r;     
reg			  sys_done;

// module done register
reg           load_done_r       , ime_done_r   , fme_done_r   , mc_done_r   , intra_done_r   , ec_done_r   , db_done_r   , fetch_chroma_done_r   , fetch_luma_done_r   , fetch_db_done_r   ,
              load_done_flag    , ime_done_flag, fme_done_flag, mc_done_flag, intra_done_flag, ec_done_flag, db_done_flag, fetch_chroma_done_flag, fetch_luma_done_flag, fetch_db_done_flag,              
              load_start        , ime_start    , fme_start    , mc_start    , intra_start    , ec_start    , db_start    , frame_start, frame_done;             
reg  [7:0]    mb_x_load, mb_x_ime, mb_x_fme, mb_x_mc, mb_x_intra, mb_x_ec, mb_x_db,           
              mb_y_load, mb_y_ime, mb_y_fme, mb_y_mc, mb_y_intra, mb_y_ec, mb_y_db;
reg           mb_done_flag_r;
              
// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
reg    [3:0] next_state;
reg		     load_working  , ime_working  , fme_working  , mc_working  , intra_working  , ec_working  , db_working;
reg          mb_done_flag;

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************           
always @(posedge clk or negedge rst_n)begin
	if (!rst_n) 
		sys_done <= 1'b1;
	else if (sys_start)
		sys_done <= 1'b0;
	else if (curr_state==IDLE && curr_state_r!=IDLE)
		sys_done <= 1'b1;
end

assign load_start_o  = load_start   ; 
assign ime_start_o   = ime_start    ;
assign fme_start_o   = fme_start    ;
assign mc_start_o    = mc_start     ;
assign intra_start_o = intra_start  ;
assign ec_start_o    = ec_start     ;
assign db_start_o    = db_start     ;
assign frame_start_o = frame_start  ;
assign frame_done_o  = frame_done   ;

//--------------------------------------------------------------
//               module status update
//--------------------------------------------------------------
// module_done_flag
always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		load_done_r            <= 1'b0;
		fetch_db_done_r        <= 1'b0;
		fetch_chroma_done_r    <= 1'b0;   
		fetch_luma_done_r	   <= 1'b0; 
		intra_done_r           <= 1'b0; 		
		ime_done_r             <= 1'b0;
		fme_done_r             <= 1'b0;		
		mc_done_r              <= 1'b0;
		db_done_r              <= 1'b0;
		ec_done_r              <= 1'b0;		
	end	else begin
	    load_done_r            <= load_done_i          ; 
	    fetch_db_done_r        <= fetch_db_done_i      ; 
	    fetch_chroma_done_r    <= fetch_chroma_done_i  ; 
	    fetch_luma_done_r	   <= fetch_luma_done_i	   ; 
	    intra_done_r           <= intra_done_i         ; 
	    ime_done_r             <= ime_done_i           ; 
	    fme_done_r             <= fme_done_i           ; 	    
	    mc_done_r              <= mc_done_i            ; 
	    db_done_r              <= db_done_i            ; 
	    ec_done_r              <= ec_done_i            ;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		load_done_flag <= 1'b0;
	else if (load_done_i && ~load_done_r)
	    load_done_flag <= 1'b1;
	else if (mb_done_flag)
		load_done_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		fetch_chroma_done_flag <= 1'b0;
	else if (fetch_chroma_done_i && ~fetch_chroma_done_r)
	    fetch_chroma_done_flag <= 1'b1;
	else if (mb_done_flag)
		fetch_chroma_done_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		fetch_luma_done_flag <= 1'b0;
	else if (fetch_luma_done_i && ~fetch_luma_done_r)
	    fetch_luma_done_flag <= 1'b1;
	else if (mb_done_flag)
		fetch_luma_done_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		fetch_db_done_flag <= 1'b0;
	else if (fetch_db_done_i && ~fetch_db_done_r)
	    fetch_db_done_flag <= 1'b1;
	else if (mb_done_flag)
		fetch_db_done_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ime_done_flag <= 1'b0;
	else if (ime_done_i && ~ime_done_r)
	    ime_done_flag <= 1'b1;
	else if (mb_done_flag)
		ime_done_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		fme_done_flag <= 1'b0;
	else if (fme_done_i && ~fme_done_r)
	    fme_done_flag <= 1'b1;
	else if (mb_done_flag)
		fme_done_flag <= 1'b0;
end		

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		intra_done_flag <= 1'b0;
	else if (intra_done_i && ~intra_done_r)
	    intra_done_flag <= 1'b1;
	else if (mb_done_flag)
		intra_done_flag <= 1'b0;
end	

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		mc_done_flag <= 1'b0;
	else if (mc_done_i && ~mc_done_r)
	    mc_done_flag <= 1'b1;
	else if (mb_done_flag)
		mc_done_flag <= 1'b0;
end	

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		db_done_flag <= 1'b0;
	else if (db_done_i && ~db_done_r)
	    db_done_flag <= 1'b1;
	else if (mb_done_flag)
		db_done_flag <= 1'b0;
end	

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ec_done_flag <= 1'b0;
	else if (ec_done_i && ~ec_done_r)
	    ec_done_flag <= 1'b1;
	else if (mb_done_flag)
		ec_done_flag <= 1'b0;
end	

//--------------------------------------------------------------
//               finite state machine                           
//--------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		curr_state   <= IDLE ;
		curr_state_r <= IDLE;
    end
	else begin 
		curr_state   <= next_state ;
		curr_state_r <= curr_state;
    end
end

always @(*)begin
	case(curr_state)
		 IDLE: begin
		 			 if(sys_start) begin
		 				 next_state = INIT  ;
		 				 mb_done_flag = 1'b0;
		 			 end	 
		 			 else begin
		 				 next_state = IDLE ;
		 				 mb_done_flag = 1'b0;
		 		     end
		 	   end
		 INIT: begin
		 			 next_state = LOAD;
		 			 mb_done_flag = 1'b0;
		 	   end
		 LOAD : begin
		 			 if(load_done_flag && (fetch_luma_done_flag|sys_intra_flag) && (sys_mode ? sys_start: 1 )) begin
		 			     next_state =  sys_intra_flag ? I_S0 : P_S0;
		 			     mb_done_flag = 1'b1;
		 			 end
		 			 else begin
		 			 	 next_state = LOAD ;
		 			 	 mb_done_flag = 1'b0;
		 			 end
		       end
		 I_S0: begin
		 			 if(load_done_flag && intra_done_flag && (sys_mode ? sys_start: 1 )) begin
		 			     next_state = I_S1 ;
		 			     mb_done_flag = 1'b1;
		 			 end
		 			 else begin
		 			 	 next_state = I_S0 ;
		 			 	 mb_done_flag = 1'b0;
		 			 end
		 	   end 
		 I_S1: begin
		             if (load_done_flag && intra_done_flag && ec_done_flag && db_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		                  mb_done_flag = 1'b1;
		                  if ((mb_x_load == sys_x_total) && (mb_y_load == sys_y_total)) 
		                      next_state = I_S2;
		                  else 
		                      next_state = I_S1;
		             end
		             else begin
		                  next_state = I_S1;
		                  mb_done_flag = 1'b0;
		             end
		       end
		 I_S2: begin
		 	         if(intra_done_flag && ec_done_flag && db_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	             next_state = I_S3  ;
		 	             mb_done_flag = 1'b1;
		 	         end
		 	         else begin
		 	             next_state = I_S2 ;
		 	             mb_done_flag = 1'b0;
		 	         end
		       end 
		 I_S3: begin
		 	         if(ec_done_flag && db_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	             next_state = STORE ;
		 	             mb_done_flag = 1'b1;
		 	         end
		 	         else begin
		 	             next_state = I_S3 ;
		 	             mb_done_flag = 1'b0;
		 	         end
		       end
		 P_S0: begin
		 	     if(ime_done_flag && load_done_flag && fetch_luma_done_flag && fetch_chroma_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	       next_state = P_S1 ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S0 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end 
		 P_S1: begin
		 	     if(fme_done_flag && ime_done_flag && load_done_flag && fetch_luma_done_flag && fetch_chroma_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	       next_state = P_S2 ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S1 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end
		 P_S2: begin
		 	     if(mc_done_flag && fme_done_flag && ime_done_flag && load_done_flag && fetch_luma_done_flag && fetch_chroma_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	       next_state = P_S3 ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S2 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end 
		 P_S3: begin
		         if (ec_done_flag && db_done_flag && mc_done_flag && fme_done_flag && ime_done_flag &&  load_done_flag && fetch_luma_done_flag && fetch_chroma_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	         mb_done_flag = 1'b1;
		 	         if ((mb_x_load == sys_x_total) && (mb_y_load == sys_y_total)) 
		 	             next_state = P_S4 ;
		 	         else 
		 	             next_state = P_S3 ;
		 	     end
		 	     else begin
		 	         next_state = P_S3 ;		 	       
		 	         mb_done_flag = 1'b0;
		 	     end
		       end 
		 P_S4: begin //no load
		 	     if(ec_done_flag && db_done_flag && mc_done_flag && fme_done_flag && ime_done_flag && fetch_db_done_flag &&(sys_mode ? sys_start: 1 )) begin
		 	       next_state = P_S5 ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S4 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end 
		 P_S5: begin //no load+ime
		 	     if(ec_done_flag && db_done_flag && mc_done_flag && fme_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	       next_state = P_S6 ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S5 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end 
		 P_S6: begin //no load+ime+fme
		 	     if(ec_done_flag && db_done_flag && mc_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	       next_state = P_S7 ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S6 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end 
		 P_S7: begin //no load+ime+fme+intra
		 	     if(ec_done_flag && db_done_flag && fetch_db_done_flag && (sys_mode ? sys_start: 1 )) begin
		 	       next_state = STORE  ;
		 	       mb_done_flag = 1'b1;
		 	     end
		 	     else begin
		 	       next_state = P_S7 ;
		 	       mb_done_flag = 1'b0;
		 	     end
		       end
		 STORE: begin //wait for store complete (not needed any more, since fetch_db_done_flag is done in DB)
		 	      if (bs_empty_i && (sys_mode ? sys_start: 1 )) begin		 	       
		 	       	next_state = IDLE;
		 	       	mb_done_flag = 1'b0;
		 	      end
		 	      else begin
		 	      	next_state = STORE  ;
		 	      	mb_done_flag = 1'b0;
		 	      end
		       end
		 default:begin
		 	       next_state = IDLE ;
		 	       mb_done_flag = 1'b0;
		       end 
	endcase
end

//--------------------------------------------------------------
//               output control signals                           
//--------------------------------------------------------------
// module start 
always @(*)begin
	case(curr_state)
			 IDLE: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0;
			 INIT: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0;
			 LOAD: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1000000;
			 I_S0: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1000100;
			 I_S1: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1000111;
			 I_S2: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0000111;		       
			 I_S3: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0000011;
			 P_S0: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1100000;
			 P_S1: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1110000;
			 P_S2: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1111000;
			 P_S3: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b1111011;
			 P_S4: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0111011;
			 P_S5: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0011011;
			 P_S6: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0001011;
			 P_S7: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0000011;			 
			 STORE:{ load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0; 
		  default: { load_working, ime_working, fme_working, mc_working, intra_working, ec_working, db_working } <= 7'b0;
   endcase
end 

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
        mb_done_flag_r <= 'b0;
    else 
        mb_done_flag_r <= mb_done_flag;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		load_start <= 1'b0;
	else if(mb_done_flag_r || frame_start)
		load_start <= load_working;
	else
		load_start <= 1'b0;	
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ime_start <= 1'b0;
	else if(mb_done_flag_r)
		ime_start <= ime_working;
	else
		ime_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		fme_start <= 1'b0;
	else if(mb_done_flag_r)
		fme_start <= fme_working;
	else
		fme_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		intra_start <= 1'b0;
	else if(mb_done_flag_r)
		intra_start <= intra_working;
	else
		intra_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		mc_start <= 1'b0;
	else if(mb_done_flag_r)
		mc_start <= mc_working;
	else
		mc_start <= 1'b0;	
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		db_start <= 1'b0;
	else if(mb_done_flag_r)
		db_start <= db_working;
	else
		db_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ec_start <= 1'b0;
	else if(mb_done_flag_r)
		ec_start <= ec_working;
	else
		ec_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		frame_start <= 1'b0;
	else if(curr_state_r==INIT)
		frame_start <= 1'b1;
	else
		frame_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		frame_done <= 1'b0;
	else if((next_state==STORE) &&(curr_state!=STORE))
		frame_done <= 1'b1;
	else
		frame_done <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_load <= 'b0;
		mb_y_load <= 'b0;
	end
	else if(curr_state == INIT)begin
		mb_x_load <= 'b0;
		mb_y_load <= 'b0;
	end
	else if(load_done_flag && mb_done_flag)begin
		if(mb_x_load == sys_x_total)begin
			mb_x_load <= 'b0;
			if (mb_y_load == sys_y_total)
			      mb_y_load <= 'b0;
			else 
			      mb_y_load <= mb_y_load + 1'b1;
		end
		else begin
			mb_x_load <= mb_x_load + 1'b1;
			mb_y_load <= mb_y_load;
		end
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_ime <= 'b0;
		mb_y_ime <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_ime <= 'b0;
		mb_y_ime <= 'b0;
	end
	else if(ime_done_flag && mb_done_flag)begin
		mb_x_ime <= mb_x_load;
		mb_y_ime <= mb_y_load;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_fme <= 'b0;
		mb_y_fme <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_fme <= 'b0;
		mb_y_fme <= 'b0;
	end
	else if(fme_done_flag && mb_done_flag)begin
		mb_x_fme <= mb_x_ime;
		mb_y_fme <= mb_y_ime;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_mc <= 'b0;
		mb_y_mc <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_mc <= 'b0;
		mb_y_mc <= 'b0;
	end
	else if(mc_done_flag && mb_done_flag)begin
		mb_x_mc <= mb_x_fme;
		mb_y_mc <= mb_y_fme;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_intra <= 'b0;
		mb_y_intra <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_intra <= 'b0;
		mb_y_intra <= 'b0;
	end
	else if(intra_done_flag && mb_done_flag)begin
		mb_x_intra <= mb_x_load;
		mb_y_intra <= mb_y_load;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_ec <= 'b0;
		mb_y_ec <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_ec <= 'b0;
		mb_y_ec <= 'b0;
	end
	else if(ec_done_flag && mb_done_flag)begin
		mb_x_ec <= sys_intra_flag ? mb_x_intra : mb_x_mc;
		mb_y_ec <= sys_intra_flag ? mb_y_intra : mb_y_mc;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_db <= 'b0;
		mb_y_db <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_db <= 'b0;
		mb_y_db <= 'b0;
	end
	else if(db_done_flag && mb_done_flag)begin
		mb_x_db <= sys_intra_flag ? mb_x_intra : mb_x_mc;
		mb_y_db <= sys_intra_flag ? mb_y_intra : mb_y_mc;
	end
end

endmodule
