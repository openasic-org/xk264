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
// Filename       : cur_mb_data.v
// Author         : huibo zhong
// Created        : 2011-10-02
// Description    : top datapath of encoder
//               
// $Id$ 
//------------------------------------------------------------------- 

module cur_mb   (
				clk,
				rst_n,
				load_start,	
				load_done,
				pvalid_i,			
				pinc_o,
				pdata_i,	
				mb_switch,		
				intra_flag_i,		
				ime_cur_luma,
				fme_cur_luma,
				mc_cur_luma,
				mc_cur_u,
				mc_cur_v
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input	        clk ;
input	        rst_n  ;
// raw pixel input                
input           load_start;	       // start load new mb from outside
output          load_done;         // load done
input           pvalid_i;		   // pixel valid for input
output          pinc_o;            // read next pixel
input [8*`BIT_DEPTH - 1:0]   pdata_i; // pixel data : 4 pixel input parallel
// from top control        
input           mb_switch;		   // start current_mb pipeline	
input           intra_flag_i;	   // all intra prediction
// pixel data for inter
output [256*8-1 : 0] ime_cur_luma; // output luma 16x16 for ime
output [256*8-1 : 0] fme_cur_luma; // output luma 16x16 for fme
output [256*8-1 : 0] mc_cur_luma;  // outout luma 16x16 for mc
output [64*8-1 : 0] mc_cur_u;      // output chroma 8x8 for mc and intra 
output [64*8-1 : 0] mc_cur_v;      // output chroma 8x8 for mc and intra

// ********************************************
//                                             
//    Parameter DECLARATION                     
//                                             
// ********************************************


// ********************************************
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
reg [7:0] cur_y[0:255];
reg [7:0] cur_y_s0[0:255];
reg [7:0] cur_y_s1[0:255];
reg [7:0] cur_y_s2[0:255];

reg [7:0] cur_u[0:63];
reg [7:0] cur_u_s0[0:63];
reg [7:0] cur_u_s1[0:63];
reg [7:0] cur_u_s2[0:63];

reg [7:0] cur_v[0:63];
reg [7:0] cur_v_s0[0:63];
reg [7:0] cur_v_s1[0:63];
reg [7:0] cur_v_s2[0:63];

reg         pinc_o ;
reg         load_done;
reg [5:0]   addr_p;

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
reg [256*8-1 : 0] ime_cur_luma;
reg [256*8-1 : 0] fme_cur_luma;
reg [256*8-1 : 0] mc_cur_luma;
reg [64*8-1 : 0]  mc_cur_u;
reg [64*8-1 : 0]  mc_cur_v;
wire [4:0] 		  addr_y;
wire [3:0] 		  addr_uv;

genvar j; 
generate
  for(j=0;j<256; j=j+1) begin:j_n 
  	always @( * ) begin
			ime_cur_luma[(j+1)*8-1:j*8] = cur_y_s0[j];
			fme_cur_luma[(j+1)*8-1:j*8] = cur_y_s1[j];
			mc_cur_luma [(j+1)*8-1:j*8] = cur_y_s2[j];   
    end
	end
endgenerate

genvar k; 
generate 
  for(k=0;k<64; k=k+1) begin:k_n
  	always @( * ) begin
    	mc_cur_u [(k+1)*8-1:k*8] = cur_u_s2[k];
        mc_cur_v [(k+1)*8-1:k*8] = cur_v_s2[k];   
    end
  end
endgenerate

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		load_done <= 1'b0;
    else if((addr_p == 8'd47) && pvalid_i) // load complete: 16x16x1.5/8=48 cycles 
		load_done <= 1'b1;
	else
		load_done <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		pinc_o <= 1'b0;
	else if((addr_p == 8'd47) && pvalid_i) // read complete 
		pinc_o <= 1'b0;	
	else if(load_start)
		pinc_o <= 1'b1;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		addr_p <= 'b0 ;
	else if((addr_p == 8'd47) && pvalid_i) //edit by xyuan 
		addr_p <= 'b0 ;
	else if(pvalid_i)
		addr_p <= addr_p + 1'b1;	
end

assign addr_y = addr_p[4:0];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:cur_luma
	 integer i;
        for(i=0; i<256; i=i+1) begin
             cur_y[i] <= 0;
        end
    end              
	else if(pvalid_i && ~addr_p[5])
		{cur_y[{addr_y,3'b000}],cur_y[{addr_y, 3'b001}],cur_y[{addr_y, 3'b010}],cur_y[{addr_y, 3'b011}],
		 cur_y[{addr_y,3'b100}],cur_y[{addr_y, 3'b101}],cur_y[{addr_y, 3'b110}],cur_y[{addr_y, 3'b111}]}<= pdata_i;
end
		
assign addr_uv = addr_y[3:0];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:cur_uv
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_u[i] <= 0;
             cur_v[i] <= 0;
        end
    end 
	else if(pvalid_i && addr_p[5])begin
		{cur_u[{addr_uv, 2'b00}],cur_v[{addr_uv, 2'b00}],cur_u[{addr_uv, 2'b01}],cur_v[{addr_uv, 2'b01}],
		 cur_u[{addr_uv, 2'b10}],cur_v[{addr_uv, 2'b10}],cur_u[{addr_uv, 2'b11}],cur_v[{addr_uv, 2'b11}]} <= pdata_i;
	end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:y_s0
	 integer i;
        for(i=0; i<256; i=i+1) begin
             cur_y_s0[i] <= 0;
             cur_y_s1[i] <= 0;
        end
    end
	else if(mb_switch)begin:y_s1
	integer i;
		for(i=0; i<256; i=i+1)begin
			cur_y_s0[i] <= cur_y[i];
			cur_y_s1[i] <= cur_y_s0[i];
		end
	end
end
	
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:u_s0
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_u_s0[i] <= 0;
             cur_u_s1[i] <= 0;
        end
    end
	else if(mb_switch)begin:u_s1
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_u_s0[i] <= cur_u[i];
			cur_u_s1[i] <= cur_u_s0[i];
		end
	end
end
	                     
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:v_s0
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_v_s0[i] <= 0;
             cur_v_s1[i] <= 0;
        end
    end
	else if(mb_switch)begin:v_s1
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_v_s0[i] <= cur_v[i];
			cur_v_s1[i] <= cur_v_s0[i];
		end
	end 
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:y_s2
	 integer i;
        for(i=0; i<256; i=i+1) begin
             cur_y_s2[i] <= 0;
        end
    end
	else if(mb_switch&&~intra_flag_i)begin:y_s2_1
	integer i;
		for(i=0; i<256; i=i+1)begin
			cur_y_s2[i] <= cur_y_s1[i];
		end
	end
	else if(mb_switch)begin:y_s2_2
	integer i;
		for(i=0; i<256; i=i+1)begin
			cur_y_s2[i] <= cur_y[i];
		end
	end
end
		
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:u_s2
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_u_s2[i] <= 0;
        end
    end
	else if(mb_switch&&~intra_flag_i)begin:u_s2_1
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_u_s2[i] <= cur_u_s1[i];
		end
	end 
	else if(mb_switch)begin:u_s2_2
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_u_s2[i] <= cur_u[i];
		end
	end   
end
 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:v_s2
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_v_s2[i] <= 0;
        end
    end
	else if(mb_switch&&~intra_flag_i)begin:v_s2_1
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_v_s2[i] <= cur_v_s1[i];
		end
	end 
	else  if(mb_switch)begin:v_s2_2
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_v_s2[i] <= cur_v[i];
		end
	end
end

endmodule
