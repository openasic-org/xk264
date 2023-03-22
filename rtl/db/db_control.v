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
// Filename       : db_control.v
// Author         : shen weiwei
// Created        : 2011-01-07
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
//------------------------------------------------------------------- 

module db_control (		 clk,
						 rst,
						 start,
						 x, y,
						 
						 ram_c,
						 radd_c,
						 ren_c,
						 ram_c_former,
						 wadd_c,
						 wen_c,
						 
						 ram_l,
						 radd_l,
						 ren_l,
						 ram_l_former,
						 wadd_l,
						 wen_l,
						 
						 ram_t,
						 radd_t,
						 ren_t,
						
						 
						 ram_out,
						 wadd_out,
						 wen_out,
						 
						 p3_0_i, p2_0_i, p1_0_i, p0_0_i, q0_0_i, q1_0_i, q2_0_i, q3_0_i,
						 p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i,
                         p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i,
                         p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i,
						 
						 p3_0_o, p2_0_o, p1_0_o, p0_0_o, q0_0_o, q1_0_o, q2_0_o, q3_0_o,
						 p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o,
						 p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o,
						 p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o,	

						 select,
						 
						 state,
						 count_bs,
						 count_y,
						 count_cbcr,

						 db_done
						 
                         );
			
input clk;
input rst;
input start;
input [7:0] x, y;

input  [127:0] ram_c;
output [4:0]   radd_c;
output         ren_c;
output [127:0] ram_c_former;
output [4:0]   wadd_c;
output         wen_c;

input  [127:0] ram_l;
output [2:0]   radd_l;
output         ren_l;
output [127:0] ram_l_former;
output [2:0]   wadd_l;
output         wen_l;

input  [127:0] ram_t;
output [2:0]   radd_t;
output         ren_t;

output [127:0] ram_out;
output [5:0]   wadd_out;
output         wen_out;

output select;

output [1:0] state;
output [2:0] count_bs;
output [5:0] count_y;
output [5:0] count_cbcr;

output db_done;

input [7:0] p3_0_i, p2_0_i, p1_0_i, p0_0_i, q0_0_i, q1_0_i, q2_0_i, q3_0_i;
input [7:0] p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i;
input [7:0] p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i;
input [7:0] p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i;

output reg [7:0] p3_0_o, p2_0_o, p1_0_o, p0_0_o, q0_0_o, q1_0_o, q2_0_o, q3_0_o;
output reg [7:0] p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o;
output reg [7:0] p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o;
output reg [7:0] p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o;


reg [127:0] temp1;
reg [127:0] temp2;			
reg [127:0] temp3;			
reg [127:0] temp4;			
			
			
parameter IDLE = 2'b00, BS = 2'b01, Y = 2'b10, CbCr = 2'b11;

reg [1:0] state;

reg [2:0] count_bs;		
always@(posedge clk or negedge rst) begin
    if(!rst)
        count_bs <= 3'd0;
    else if(state==BS) begin
            if( count_bs==3'd6 )
                count_bs <= 0;
            else
				count_bs <= count_bs+ 1'b1;
    end
end

reg [5:0] count_y;
always@(posedge clk or negedge rst) begin
    if(!rst)
        count_y <= 6'd0;
    else if(state==Y) begin
            //if( count_y==6'd46 )
			if (count_y=='d47)
			    count_y <= 0;
            else
                count_y <= count_y + 1'b1;          
        end
end

reg [5:0] count_cbcr;
always@(posedge clk or negedge rst) begin
    if(!rst)
        count_cbcr <= 6'd0;
    else if(state==CbCr) begin
            if( count_cbcr==6'd32 )          ///31,32 is exclusive for orignal pixels
                count_cbcr <= 0;
            else
                count_cbcr <= count_cbcr + 1'b1;          
        end
end



always@(posedge clk or negedge rst) begin
    if(!rst)
        state <= IDLE;
    else
        case(state)
            IDLE: begin
                    if(start==1'b1)
                        state <= BS;
                    else 
                        state <= IDLE;
            end
            BS  : begin
                    if(count_bs==3'd6)
                        state <= Y;
                    else
                        state <= BS;
            end
            Y   : begin
                    //if(count_y==6'd46)
                     if(count_y==6'd47) 
					  state <= CbCr;
                    else
                        state <= Y;           
            end
			CbCr: begin
                    if(count_cbcr==6'd32)
                        state <= IDLE;
                    else
                        state <= CbCr;           
            end
        endcase
end

reg db_done;
always@(posedge clk or negedge rst)begin
	if(!rst)
		db_done <= 1'b0;
	else if( (state==CbCr) && (count_cbcr==6'd32) )
		db_done <= 1'b1;
	else
		db_done <= 1'b0;



end


reg select;
always @(posedge clk or negedge rst)begin
	if(!rst)
		select <= 1'b0;
	else if(state==CbCr)
		select <= 1'b1;
	else
		select <= 1'b0;
end



///////temp1, temp2, temp3, temp4
always@(posedge clk or negedge rst) begin
    if(!rst) 
		temp1 <= 128'd0;
		
	else if(state==Y)begin
		if((count_y>=6'd4)&&(count_y<=6'd19)&&(count_y[1:0]==2'd0))
			temp1 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
			           q0_1_i, q1_1_i, q2_1_i, q3_1_i,
			           q0_2_i, q1_2_i, q2_2_i, q3_2_i,
			           q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_y>=6'd27)&&(count_y<=6'd42)&&(count_y[1:0]==2'd3))
			temp1 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
			           q1_0_i, q1_1_i, q1_2_i, q1_3_i,
			           q2_0_i, q2_1_i, q2_2_i, q2_3_i,
			           q3_0_i, q3_1_i, q3_2_i, q3_3_i };
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd11)&&(count_cbcr[1:0]==2'd0))
			temp1 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
			           q0_1_i, q1_1_i, q2_1_i, q3_1_i,
			           q0_2_i, q1_2_i, q2_2_i, q3_2_i,
			           q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd26)&&(count_cbcr[1:0]==2'd3))
			temp1 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
			           q1_0_i, q1_1_i, q1_2_i, q1_3_i,
			           q2_0_i, q2_1_i, q2_2_i, q2_3_i,
			           q3_0_i, q3_1_i, q3_2_i, q3_3_i };	
	end   
	
    else 
		temp1 <= temp1;
end

always@(posedge clk or negedge rst) begin
    if(!rst) 
		temp2 <= 128'd0;
		
	else if(state==Y)begin
		if((count_y>=6'd4)&&(count_y<=6'd19)&&(count_y[1:0]==2'd1))
			temp2 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
			           q0_1_i, q1_1_i, q2_1_i, q3_1_i,
			           q0_2_i, q1_2_i, q2_2_i, q3_2_i,
			           q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_y>=6'd27)&&(count_y<=6'd42)&&(count_y[1:0]==2'd0))
			temp2 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
			           q1_0_i, q1_1_i, q1_2_i, q1_3_i,
			           q2_0_i, q2_1_i, q2_2_i, q2_3_i,
			           q3_0_i, q3_1_i, q3_2_i, q3_3_i };
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd11)&&(count_cbcr[1:0]==2'd1))
			temp2 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
			           q0_1_i, q1_1_i, q2_1_i, q3_1_i,
			           q0_2_i, q1_2_i, q2_2_i, q3_2_i,
			           q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd26)&&(count_cbcr[1:0]==2'd0))
			temp2 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
			           q1_0_i, q1_1_i, q1_2_i, q1_3_i,
			           q2_0_i, q2_1_i, q2_2_i, q2_3_i,
			           q3_0_i, q3_1_i, q3_2_i, q3_3_i };	
	end       
	
    else 
		temp2 <= temp2;
end

always@(posedge clk or negedge rst) begin
    if(!rst) 
		temp3 <= 128'd0;
		
	else if(state==Y)begin
		if((count_y>=6'd4)&&(count_y<=6'd19)&&(count_y[1:0]==2'd2))
			temp3 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
					   q0_1_i, q1_1_i, q2_1_i, q3_1_i,
					   q0_2_i, q1_2_i, q2_2_i, q3_2_i,
					   q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_y>=6'd27)&&(count_y<=6'd42)&&(count_y[1:0]==2'd1))
			temp3 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
					   q1_0_i, q1_1_i, q1_2_i, q1_3_i,
					   q2_0_i, q2_1_i, q2_2_i, q2_3_i,
					   q3_0_i, q3_1_i, q3_2_i, q3_3_i };
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd11)&&(count_cbcr[1:0]==2'd2))
			temp3 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
			           q0_1_i, q1_1_i, q2_1_i, q3_1_i,
			           q0_2_i, q1_2_i, q2_2_i, q3_2_i,
			           q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd26)&&(count_cbcr[1:0]==2'd1))
			temp3 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
			           q1_0_i, q1_1_i, q1_2_i, q1_3_i,
			           q2_0_i, q2_1_i, q2_2_i, q2_3_i,
			           q3_0_i, q3_1_i, q3_2_i, q3_3_i };	
	end 
	
    else 
		temp3 <= temp3;
end

always@(posedge clk or negedge rst) begin
    if(!rst) 
		temp4 <= 128'd0;
		
	else if(state==Y)begin
		if((count_y>=6'd4)&&(count_y<=6'd19)&&(count_y[1:0]==2'd3))
			temp4 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
					   q0_1_i, q1_1_i, q2_1_i, q3_1_i,
					   q0_2_i, q1_2_i, q2_2_i, q3_2_i,
					   q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_y>=6'd27)&&(count_y<=6'd42)&&(count_y[1:0]==2'd2))
			temp4 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
					   q1_0_i, q1_1_i, q1_2_i, q1_3_i,
					   q2_0_i, q2_1_i, q2_2_i, q2_3_i,
					   q3_0_i, q3_1_i, q3_2_i, q3_3_i };
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd11)&&(count_cbcr[1:0]==2'd3))
			temp4 <= { q0_0_i, q1_0_i, q2_0_i, q3_0_i,
			           q0_1_i, q1_1_i, q2_1_i, q3_1_i,
			           q0_2_i, q1_2_i, q2_2_i, q3_2_i,
			           q0_3_i, q1_3_i, q2_3_i, q3_3_i };
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd26)&&(count_cbcr[1:0]==2'd2))
			temp4 <= { q0_0_i, q0_1_i, q0_2_i, q0_3_i,
			           q1_0_i, q1_1_i, q1_2_i, q1_3_i,
			           q2_0_i, q2_1_i, q2_2_i, q2_3_i,
			           q3_0_i, q3_1_i, q3_2_i, q3_3_i };	
	end 
	
    else 
		temp4 <= temp4;
end

//////p q out
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		p3_0_o <= 8'd0; p2_0_o <= 8'd0; p1_0_o <= 8'd0; p0_0_o <= 8'd0;
		p3_1_o <= 8'd0; p2_1_o <= 8'd0; p1_1_o <= 8'd0; p0_1_o <= 8'd0;
		p3_2_o <= 8'd0; p2_2_o <= 8'd0; p1_2_o <= 8'd0; p0_2_o <= 8'd0;
		p3_3_o <= 8'd0; p2_3_o <= 8'd0; p1_3_o <= 8'd0; p0_3_o <= 8'd0;
	end
	
	else if(state==Y)begin
		if((count_y>=6'd1)&&(count_y<=6'd4))begin
		    p3_0_o <= ram_l[127:120]; p2_0_o <= ram_l[119:112]; p1_0_o <= ram_l[111:104]; p0_0_o <= ram_l[103:96];
		    p3_1_o <= ram_l[95:88];   p2_1_o <= ram_l[87:80];   p1_1_o <= ram_l[79:72];   p0_1_o <= ram_l[71:64];
		    p3_2_o <= ram_l[63:56];   p2_2_o <= ram_l[55:48];   p1_2_o <= ram_l[47:40];   p0_2_o <= ram_l[39:32];
		    p3_3_o <= ram_l[31:24];   p2_3_o <= ram_l[23:16];   p1_3_o <= ram_l[15:8];    p0_3_o <= ram_l[7:0];					
		end
		else if((count_y>=6'd5)&&(count_y<=6'd16))begin
			case(count_y[1:0])
				2'd0:begin
					p3_0_o <= temp4[127:120]; p2_0_o <= temp4[119:112]; p1_0_o <= temp4[111:104]; p0_0_o <= temp4[103:96];
					p3_1_o <= temp4[95:88];   p2_1_o <= temp4[87:80];   p1_1_o <= temp4[79:72];   p0_1_o <= temp4[71:64];
					p3_2_o <= temp4[63:56];   p2_2_o <= temp4[55:48];   p1_2_o <= temp4[47:40];   p0_2_o <= temp4[39:32];
					p3_3_o <= temp4[31:24];   p2_3_o <= temp4[23:16];   p1_3_o <= temp4[15:8];    p0_3_o <= temp4[7:0];			
				end                                                                                         
				2'd1:begin                                                                                  
					p3_0_o <= temp1[127:120]; p2_0_o <= temp1[119:112]; p1_0_o <= temp1[111:104]; p0_0_o <= temp1[103:96];
					p3_1_o <= temp1[95:88];   p2_1_o <= temp1[87:80];   p1_1_o <= temp1[79:72];   p0_1_o <= temp1[71:64];
					p3_2_o <= temp1[63:56];   p2_2_o <= temp1[55:48];   p1_2_o <= temp1[47:40];   p0_2_o <= temp1[39:32];
					p3_3_o <= temp1[31:24];   p2_3_o <= temp1[23:16];   p1_3_o <= temp1[15:8];    p0_3_o <= temp1[7:0];			
				end                                                                                         
				2'd2:begin                                                                                  
					p3_0_o <= temp2[127:120]; p2_0_o <= temp2[119:112]; p1_0_o <= temp2[111:104]; p0_0_o <= temp2[103:96];
					p3_1_o <= temp2[95:88];   p2_1_o <= temp2[87:80];   p1_1_o <= temp2[79:72];   p0_1_o <= temp2[71:64];
					p3_2_o <= temp2[63:56];   p2_2_o <= temp2[55:48];   p1_2_o <= temp2[47:40];   p0_2_o <= temp2[39:32];
					p3_3_o <= temp2[31:24];   p2_3_o <= temp2[23:16];   p1_3_o <= temp2[15:8];    p0_3_o <= temp2[7:0];			
				end                                                                                         
				2'd3:begin                                                                                  
					p3_0_o <= temp3[127:120]; p2_0_o <= temp3[119:112]; p1_0_o <= temp3[111:104]; p0_0_o <= temp3[103:96];
					p3_1_o <= temp3[95:88];   p2_1_o <= temp3[87:80];   p1_1_o <= temp3[79:72];   p0_1_o <= temp3[71:64];
					p3_2_o <= temp3[63:56];   p2_2_o <= temp3[55:48];   p1_2_o <= temp3[47:40];   p0_2_o <= temp3[39:32];
					p3_3_o <= temp3[31:24];   p2_3_o <= temp3[23:16];   p1_3_o <= temp3[15:8];    p0_3_o <= temp3[7:0];			
				end
			endcase
		end		
		else if((count_y>=6'd24)&&(count_y<=6'd27))begin
			p3_0_o <= ram_t[127:120]; p2_0_o <= ram_t[95:88]; p1_0_o <= ram_t[63:56]; p0_0_o <= ram_t[31:24];
			p3_1_o <= ram_t[119:112]; p2_1_o <= ram_t[87:80]; p1_1_o <= ram_t[55:48]; p0_1_o <= ram_t[23:16];
			p3_2_o <= ram_t[111:104]; p2_2_o <= ram_t[79:72]; p1_2_o <= ram_t[47:40]; p0_2_o <= ram_t[15:8];
			p3_3_o <= ram_t[103:96];  p2_3_o <= ram_t[71:64]; p1_3_o <= ram_t[39:32]; p0_3_o <= ram_t[7:0];		
		end		
		else if((count_y>=6'd28)&&(count_y<=6'd39))begin
			case(count_y[1:0])
				2'd0:begin
					p3_0_o <= temp1[127:120]; p2_0_o <= temp1[95:88]; p1_0_o <= temp1[63:56]; p0_0_o <= temp1[31:24];
					p3_1_o <= temp1[119:112]; p2_1_o <= temp1[87:80]; p1_1_o <= temp1[55:48]; p0_1_o <= temp1[23:16];
					p3_2_o <= temp1[111:104]; p2_2_o <= temp1[79:72]; p1_2_o <= temp1[47:40]; p0_2_o <= temp1[15:8];
					p3_3_o <= temp1[103:96];  p2_3_o <= temp1[71:64]; p1_3_o <= temp1[39:32]; p0_3_o <= temp1[7:0];			
				end                                                                                              
				2'd1:begin                                                                                       
					p3_0_o <= temp2[127:120]; p2_0_o <= temp2[95:88]; p1_0_o <= temp2[63:56]; p0_0_o <= temp2[31:24];
					p3_1_o <= temp2[119:112]; p2_1_o <= temp2[87:80]; p1_1_o <= temp2[55:48]; p0_1_o <= temp2[23:16];
					p3_2_o <= temp2[111:104]; p2_2_o <= temp2[79:72]; p1_2_o <= temp2[47:40]; p0_2_o <= temp2[15:8];
					p3_3_o <= temp2[103:96];  p2_3_o <= temp2[71:64]; p1_3_o <= temp2[39:32]; p0_3_o <= temp2[7:0];			
				end                                                                                              
				2'd2:begin                                                                                       
					p3_0_o <= temp3[127:120]; p2_0_o <= temp3[95:88]; p1_0_o <= temp3[63:56]; p0_0_o <= temp3[31:24];
					p3_1_o <= temp3[119:112]; p2_1_o <= temp3[87:80]; p1_1_o <= temp3[55:48]; p0_1_o <= temp3[23:16];
					p3_2_o <= temp3[111:104]; p2_2_o <= temp3[79:72]; p1_2_o <= temp3[47:40]; p0_2_o <= temp3[15:8];
					p3_3_o <= temp3[103:96];  p2_3_o <= temp3[71:64]; p1_3_o <= temp3[39:32]; p0_3_o <= temp3[7:0];			
				end                                                                                              
				2'd3:begin                                                                                       
					p3_0_o <= temp4[127:120]; p2_0_o <= temp4[95:88]; p1_0_o <= temp4[63:56]; p0_0_o <= temp4[31:24];
					p3_1_o <= temp4[119:112]; p2_1_o <= temp4[87:80]; p1_1_o <= temp4[55:48]; p0_1_o <= temp4[23:16];
					p3_2_o <= temp4[111:104]; p2_2_o <= temp4[79:72]; p1_2_o <= temp4[47:40]; p0_2_o <= temp4[15:8];
					p3_3_o <= temp4[103:96];  p2_3_o <= temp4[71:64]; p1_3_o <= temp4[39:32]; p0_3_o <= temp4[7:0];			
				end
			endcase
		end
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd1)&&(count_cbcr<=6'd4))begin
		    p3_0_o <= ram_l[127:120]; p2_0_o <= ram_l[119:112]; p1_0_o <= ram_l[111:104]; p0_0_o <= ram_l[103:96];
		    p3_1_o <= ram_l[95:88];   p2_1_o <= ram_l[87:80];   p1_1_o <= ram_l[79:72];   p0_1_o <= ram_l[71:64];
		    p3_2_o <= ram_l[63:56];   p2_2_o <= ram_l[55:48];   p1_2_o <= ram_l[47:40];   p0_2_o <= ram_l[39:32];
		    p3_3_o <= ram_l[31:24];   p2_3_o <= ram_l[23:16];   p1_3_o <= ram_l[15:8];    p0_3_o <= ram_l[7:0];					
		end
		else if((count_cbcr>=6'd5)&&(count_cbcr<=6'd8))begin
			case(count_cbcr[1:0])
				2'd0:begin
					p3_0_o <= temp4[127:120]; p2_0_o <= temp4[119:112]; p1_0_o <= temp4[111:104]; p0_0_o <= temp4[103:96];
					p3_1_o <= temp4[95:88];   p2_1_o <= temp4[87:80];   p1_1_o <= temp4[79:72];   p0_1_o <= temp4[71:64];
					p3_2_o <= temp4[63:56];   p2_2_o <= temp4[55:48];   p1_2_o <= temp4[47:40];   p0_2_o <= temp4[39:32];
					p3_3_o <= temp4[31:24];   p2_3_o <= temp4[23:16];   p1_3_o <= temp4[15:8];    p0_3_o <= temp4[7:0];			
				end                                                                                         
				2'd1:begin                                                                                  
					p3_0_o <= temp1[127:120]; p2_0_o <= temp1[119:112]; p1_0_o <= temp1[111:104]; p0_0_o <= temp1[103:96];
					p3_1_o <= temp1[95:88];   p2_1_o <= temp1[87:80];   p1_1_o <= temp1[79:72];   p0_1_o <= temp1[71:64];
					p3_2_o <= temp1[63:56];   p2_2_o <= temp1[55:48];   p1_2_o <= temp1[47:40];   p0_2_o <= temp1[39:32];
					p3_3_o <= temp1[31:24];   p2_3_o <= temp1[23:16];   p1_3_o <= temp1[15:8];    p0_3_o <= temp1[7:0];			
				end                                                                                         
				2'd2:begin                                                                                  
					p3_0_o <= temp2[127:120]; p2_0_o <= temp2[119:112]; p1_0_o <= temp2[111:104]; p0_0_o <= temp2[103:96];
					p3_1_o <= temp2[95:88];   p2_1_o <= temp2[87:80];   p1_1_o <= temp2[79:72];   p0_1_o <= temp2[71:64];
					p3_2_o <= temp2[63:56];   p2_2_o <= temp2[55:48];   p1_2_o <= temp2[47:40];   p0_2_o <= temp2[39:32];
					p3_3_o <= temp2[31:24];   p2_3_o <= temp2[23:16];   p1_3_o <= temp2[15:8];    p0_3_o <= temp2[7:0];			
				end                                                                                         
				2'd3:begin                                                                                  
					p3_0_o <= temp3[127:120]; p2_0_o <= temp3[119:112]; p1_0_o <= temp3[111:104]; p0_0_o <= temp3[103:96];
					p3_1_o <= temp3[95:88];   p2_1_o <= temp3[87:80];   p1_1_o <= temp3[79:72];   p0_1_o <= temp3[71:64];
					p3_2_o <= temp3[63:56];   p2_2_o <= temp3[55:48];   p1_2_o <= temp3[47:40];   p0_2_o <= temp3[39:32];
					p3_3_o <= temp3[31:24];   p2_3_o <= temp3[23:16];   p1_3_o <= temp3[15:8];    p0_3_o <= temp3[7:0];			
				end			
			endcase	
		end
		else if((count_cbcr>=6'd16)&&(count_cbcr<=6'd19))begin
			p3_0_o <= ram_t[127:120]; p2_0_o <= ram_t[95:88]; p1_0_o <= ram_t[63:56]; p0_0_o <= ram_t[31:24];
			p3_1_o <= ram_t[119:112]; p2_1_o <= ram_t[87:80]; p1_1_o <= ram_t[55:48]; p0_1_o <= ram_t[23:16];
			p3_2_o <= ram_t[111:104]; p2_2_o <= ram_t[79:72]; p1_2_o <= ram_t[47:40]; p0_2_o <= ram_t[15:8];
			p3_3_o <= ram_t[103:96];  p2_3_o <= ram_t[71:64]; p1_3_o <= ram_t[39:32]; p0_3_o <= ram_t[7:0];		
		end	
		else if((count_cbcr>=6'd20)&&(count_cbcr<=6'd23))begin
			case(count_cbcr[1:0])
				2'd0:begin
					p3_0_o <= temp1[127:120]; p2_0_o <= temp1[95:88]; p1_0_o <= temp1[63:56]; p0_0_o <= temp1[31:24];
					p3_1_o <= temp1[119:112]; p2_1_o <= temp1[87:80]; p1_1_o <= temp1[55:48]; p0_1_o <= temp1[23:16];
					p3_2_o <= temp1[111:104]; p2_2_o <= temp1[79:72]; p1_2_o <= temp1[47:40]; p0_2_o <= temp1[15:8];
					p3_3_o <= temp1[103:96];  p2_3_o <= temp1[71:64]; p1_3_o <= temp1[39:32]; p0_3_o <= temp1[7:0];			
				end                                                                                              
				2'd1:begin                                                                                       
					p3_0_o <= temp2[127:120]; p2_0_o <= temp2[95:88]; p1_0_o <= temp2[63:56]; p0_0_o <= temp2[31:24];
					p3_1_o <= temp2[119:112]; p2_1_o <= temp2[87:80]; p1_1_o <= temp2[55:48]; p0_1_o <= temp2[23:16];
					p3_2_o <= temp2[111:104]; p2_2_o <= temp2[79:72]; p1_2_o <= temp2[47:40]; p0_2_o <= temp2[15:8];
					p3_3_o <= temp2[103:96];  p2_3_o <= temp2[71:64]; p1_3_o <= temp2[39:32]; p0_3_o <= temp2[7:0];			
				end                                                                                              
				2'd2:begin                                                                                       
					p3_0_o <= temp3[127:120]; p2_0_o <= temp3[95:88]; p1_0_o <= temp3[63:56]; p0_0_o <= temp3[31:24];
					p3_1_o <= temp3[119:112]; p2_1_o <= temp3[87:80]; p1_1_o <= temp3[55:48]; p0_1_o <= temp3[23:16];
					p3_2_o <= temp3[111:104]; p2_2_o <= temp3[79:72]; p1_2_o <= temp3[47:40]; p0_2_o <= temp3[15:8];
					p3_3_o <= temp3[103:96];  p2_3_o <= temp3[71:64]; p1_3_o <= temp3[39:32]; p0_3_o <= temp3[7:0];			
				end                                                                                              
				2'd3:begin                                                                                       
					p3_0_o <= temp4[127:120]; p2_0_o <= temp4[95:88]; p1_0_o <= temp4[63:56]; p0_0_o <= temp4[31:24];
					p3_1_o <= temp4[119:112]; p2_1_o <= temp4[87:80]; p1_1_o <= temp4[55:48]; p0_1_o <= temp4[23:16];
					p3_2_o <= temp4[111:104]; p2_2_o <= temp4[79:72]; p1_2_o <= temp4[47:40]; p0_2_o <= temp4[15:8];
					p3_3_o <= temp4[103:96];  p2_3_o <= temp4[71:64]; p1_3_o <= temp4[39:32]; p0_3_o <= temp4[7:0];			
				end
			endcase
		end
	end	

	else begin
		p3_0_o <= p3_0_o; p2_0_o <= p2_0_o; p1_0_o <= p1_0_o; p0_0_o <= p0_0_o;
	    p3_1_o <= p3_1_o; p2_1_o <= p2_1_o; p1_1_o <= p1_1_o; p0_1_o <= p0_1_o;
	    p3_2_o <= p3_2_o; p2_2_o <= p2_2_o; p1_2_o <= p1_2_o; p0_2_o <= p0_2_o;
	    p3_3_o <= p3_3_o; p2_3_o <= p2_3_o; p1_3_o <= p1_3_o; p0_3_o <= p0_3_o;
	end                                                        
end		


always@(posedge clk or negedge rst)begin
	if(!rst)begin
		q0_0_o <= 8'd0; q1_0_o <= 8'd0; q2_0_o <= 8'd0; q3_0_o <= 8'd0;
        q0_1_o <= 8'd0; q1_1_o <= 8'd0; q2_1_o <= 8'd0; q3_1_o <= 8'd0;
        q0_2_o <= 8'd0; q1_2_o <= 8'd0; q2_2_o <= 8'd0; q3_2_o <= 8'd0;
        q0_3_o <= 8'd0; q1_3_o <= 8'd0; q2_3_o <= 8'd0; q3_3_o <= 8'd0;
	end
	
	else if(state==Y)begin
		if((count_y>=6'd1)&&(count_y<=6'd16))begin
			q0_0_o <= ram_c[127:120]; q1_0_o <= ram_c[119:112]; q2_0_o <= ram_c[111:104]; q3_0_o <= ram_c[103:96];
			q0_1_o <= ram_c[95:88];   q1_1_o <= ram_c[87:80];   q2_1_o <= ram_c[79:72];   q3_1_o <= ram_c[71:64];
			q0_2_o <= ram_c[63:56];   q1_2_o <= ram_c[55:48];   q2_2_o <= ram_c[47:40];   q3_2_o <= ram_c[39:32];
			q0_3_o <= ram_c[31:24];   q1_3_o <= ram_c[23:16];   q2_3_o <= ram_c[15:8];    q3_3_o <= ram_c[7:0];		
		end
		else if((count_y>=6'd24)&&(count_y<=6'd39))begin
			q0_0_o <= ram_c[127:120]; q1_0_o <= ram_c[95:88]; q2_0_o <= ram_c[63:56]; q3_0_o <= ram_c[31:24];
			q0_1_o <= ram_c[119:112]; q1_1_o <= ram_c[87:80]; q2_1_o <= ram_c[55:48]; q3_1_o <= ram_c[23:16];
			q0_2_o <= ram_c[111:104]; q1_2_o <= ram_c[79:72]; q2_2_o <= ram_c[47:40]; q3_2_o <= ram_c[15:8];
			q0_3_o <= ram_c[103:96];  q1_3_o <= ram_c[71:64]; q2_3_o <= ram_c[39:32]; q3_3_o <= ram_c[7:0];				
		end	
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd1)&&(count_cbcr<=6'd8))begin
			q0_0_o <= ram_c[127:120]; q1_0_o <= ram_c[119:112]; q2_0_o <= ram_c[111:104]; q3_0_o <= ram_c[103:96];
			q0_1_o <= ram_c[95:88];   q1_1_o <= ram_c[87:80];   q2_1_o <= ram_c[79:72];   q3_1_o <= ram_c[71:64];
			q0_2_o <= ram_c[63:56];   q1_2_o <= ram_c[55:48];   q2_2_o <= ram_c[47:40];   q3_2_o <= ram_c[39:32];
			q0_3_o <= ram_c[31:24];   q1_3_o <= ram_c[23:16];   q2_3_o <= ram_c[15:8];    q3_3_o <= ram_c[7:0];		
		end
		else if((count_cbcr>=6'd16)&&(count_cbcr<=6'd23))begin
			q0_0_o <= ram_c[127:120]; q1_0_o <= ram_c[95:88]; q2_0_o <= ram_c[63:56]; q3_0_o <= ram_c[31:24];
			q0_1_o <= ram_c[119:112]; q1_1_o <= ram_c[87:80]; q2_1_o <= ram_c[55:48]; q3_1_o <= ram_c[23:16];
			q0_2_o <= ram_c[111:104]; q1_2_o <= ram_c[79:72]; q2_2_o <= ram_c[47:40]; q3_2_o <= ram_c[15:8];
			q0_3_o <= ram_c[103:96];  q1_3_o <= ram_c[71:64]; q2_3_o <= ram_c[39:32]; q3_3_o <= ram_c[7:0];				
		end	
	end
	
	else begin
		q0_0_o <= q0_0_o; q1_0_o <= q1_0_o; q2_0_o <= q2_0_o; q3_0_o <= q3_0_o;
        q0_1_o <= q0_1_o; q1_1_o <= q1_1_o; q2_1_o <= q2_1_o; q3_1_o <= q3_1_o;
        q0_2_o <= q0_2_o; q1_2_o <= q1_2_o; q2_2_o <= q2_2_o; q3_2_o <= q3_2_o;
        q0_3_o <= q0_3_o; q1_3_o <= q1_3_o; q2_3_o <= q2_3_o; q3_3_o <= q3_3_o;	
	end
end

////////////////////sram signal
//////ram_c
reg [4:0] radd_c;
always@(*)begin
	radd_c = 5'd0;

	if(state==Y)begin
		if((count_y>=6'd0)&&(count_y<=6'd15))begin
			case(count_y[3:0])
				4'd0 : radd_c = 5'd0 ;
				4'd1 : radd_c = 5'd4 ;
				4'd2 : radd_c = 5'd8 ;
				4'd3 : radd_c = 5'd12;
				4'd4 : radd_c = 5'd1 ;
				4'd5 : radd_c = 5'd5 ;
				4'd6 : radd_c = 5'd9 ;
				4'd7 : radd_c = 5'd13;
				4'd8 : radd_c = 5'd2 ;
				4'd9 : radd_c = 5'd6 ;
				4'd10: radd_c = 5'd10;
				4'd11: radd_c = 5'd14;
				4'd12: radd_c = 5'd3 ;
				4'd13: radd_c = 5'd7 ;
				4'd14: radd_c = 5'd11;
				4'd15: radd_c = 5'd15;
			endcase
		end
		else if((count_y>=6'd23)&&(count_y<=6'd38))
			radd_c = count_y - 5'd23;	
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd0)&&(count_cbcr<=6'd7))begin
			case(count_cbcr[2:0])
				3'd0: radd_c = 5'd16;
				3'd1: radd_c = 5'd18;
				3'd2: radd_c = 5'd20;
				3'd3: radd_c = 5'd22;
				3'd4: radd_c = 5'd17;
				3'd5: radd_c = 5'd19;
				3'd6: radd_c = 5'd21;
				3'd7: radd_c = 5'd23;
			endcase
		end
		else if((count_cbcr>=6'd15)&&(count_cbcr<=6'd22))begin
			case(count_cbcr[2:0])
				3'd0: radd_c = 5'd17;
				3'd1: radd_c = 5'd20;
				3'd2: radd_c = 5'd21;
				3'd3: radd_c = 5'd18;
				3'd4: radd_c = 5'd19;
				3'd5: radd_c = 5'd22;
				3'd6: radd_c = 5'd23;
				3'd7: radd_c = 5'd16;
			endcase		
		end
	end	
	
	
end

reg ren_c;
always@(*)begin
		ren_c = 1'b0;
		
	if(state==Y)begin
		if((count_y>=6'd0)&&(count_y<=6'd15))
			ren_c = 1'b1;			
		else if((count_y>=6'd23)&&(count_y<=6'd38))
			ren_c = 1'b1;		
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd0)&&(count_cbcr<=6'd7))
			ren_c = 1'b1;		
		else if((count_cbcr>=6'd15)&&(count_cbcr<=6'd22))
			ren_c = 1'b1;	
	end	
end


reg [127:0] ram_c_former;
always@(posedge clk or negedge rst)begin
	if(!rst)
		ram_c_former <= 128'd0;
		
	else if(state==Y)begin
		if((count_y>=6'd8)&&(count_y<=6'd19))
			ram_c_former <= { p3_0_i, p2_0_i, p1_0_i, p0_0_i,
	                          p3_1_i, p2_1_i, p1_1_i, p0_1_i,
	                          p3_2_i, p2_2_i, p1_2_i, p0_2_i,
	                          p3_3_i, p2_3_i, p1_3_i, p0_3_i };
		else if((count_y>=6'd20)&&(count_y<=6'd23))begin
			case(count_y[1:0])
				2'd0: ram_c_former <= temp1;
				2'd1: ram_c_former <= temp2;
				2'd2: ram_c_former <= temp3;
				2'd3: ram_c_former <= temp4;
			endcase		
		end
		else
			ram_c_former <= ram_c_former;
	end
		
	else if(state==CbCr)begin
		if((count_cbcr>=6'd8)&&(count_cbcr<=6'd11))
			ram_c_former <= { p3_0_i, p2_0_i, p1_0_i, p0_0_i,
	                          p3_1_i, p2_1_i, p1_1_i, p0_1_i,
	                          p3_2_i, p2_2_i, p1_2_i, p0_2_i,
	                          p3_3_i, p2_3_i, p1_3_i, p0_3_i };
		else if((count_cbcr>=6'd12)&&(count_cbcr<=6'd15))begin
			case(count_cbcr[1:0])
				2'd0: ram_c_former <= temp1;
				2'd1: ram_c_former <= temp2;
				2'd2: ram_c_former <= temp3;
				2'd3: ram_c_former <= temp4;
			endcase		
		end	
		else
			ram_c_former <= ram_c_former;
	end

	else
		ram_c_former <= ram_c_former;
end

reg [4:0] wadd_c;
always@(posedge clk or negedge rst)begin
	if(!rst)
		wadd_c <= 5'd0;
	
	else if(state==Y)begin
		if((count_y>=6'd8)&&(count_y<=6'd23))begin
			case(count_y[3:0])
				4'd0 : wadd_c = 5'd2 ;
				4'd1 : wadd_c = 5'd6 ;
				4'd2 : wadd_c = 5'd10;
				4'd3 : wadd_c = 5'd14;
				4'd4 : wadd_c = 5'd3 ;
				4'd5 : wadd_c = 5'd7 ;
				4'd6 : wadd_c = 5'd11;
				4'd7 : wadd_c = 5'd15;
				4'd8 : wadd_c = 5'd0 ;
				4'd9 : wadd_c = 5'd4 ;
				4'd10: wadd_c = 5'd8 ;
				4'd11: wadd_c = 5'd12;
				4'd12: wadd_c = 5'd1 ;
				4'd13: wadd_c = 5'd5 ;
				4'd14: wadd_c = 5'd9 ;
				4'd15: wadd_c = 5'd13;
			endcase		
		end	
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd8)&&(count_cbcr<=6'd15))begin
			case(count_cbcr[2:0])
				3'd0: wadd_c = 5'd16;
				3'd1: wadd_c = 5'd18;
				3'd2: wadd_c = 5'd20;
				3'd3: wadd_c = 5'd22;
				3'd4: wadd_c = 5'd17;
				3'd5: wadd_c = 5'd19;
				3'd6: wadd_c = 5'd21;
				3'd7: wadd_c = 5'd23;
			endcase
		end
	end		
		
	else
		wadd_c <= wadd_c;
end

reg wen_c;
always@(posedge clk or negedge rst)begin
	if(!rst)
		wen_c <= 1'b0;
	
	else if(state==Y)begin
		if((count_y>=6'd8)&&(count_y<=6'd23))
			wen_c <= 1'b1;
		else
			wen_c <= 1'b0;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd8)&&(count_cbcr<=6'd15))
			wen_c <= 1'b1;
		else
			wen_c <= 1'b0;
	end
	
	else
		wen_c <= 1'b0;
end



//////ram_l
reg [2:0] radd_l;
always@(*)begin
	radd_l = 3'd0;
	
	if(state==Y)begin
		if((count_y>=6'd0)&&(count_y<=6'd3))
			radd_l = count_y[1:0];	
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd0)&&(count_cbcr<=6'd3))
			radd_l = count_cbcr[1:0] + 3'd4;	
	end
	
			
end

reg ren_l;
always@(*)begin
	ren_l = 1'b0;
		
	if(x!='d0)begin
		if((state==Y)&&(count_y>=6'd0)&&(count_y<=6'd3))
			ren_l = 1'b1;	
	
		else if((state==CbCr)&&(count_cbcr>=6'd0)&&(count_cbcr<=6'd3))
			ren_l = 1'b1;
	end
end
		
	


reg [127:0] ram_l_former;
always@(posedge clk or negedge rst)begin
	if(!rst)
		ram_l_former <= 128'd0;
	
	else if(state==Y)begin
		if((count_y==6'd34)||(count_y==6'd38)||(count_y==6'd42))
			ram_l_former <= { p3_0_i, p3_1_i, p3_2_i, p3_3_i,
			                  p2_0_i, p2_1_i, p2_2_i, p2_3_i,
			                  p1_0_i, p1_1_i, p1_2_i, p1_3_i,
			                  p0_0_i, p0_1_i, p0_2_i, p0_3_i };			
		else if(count_y==6'd46)
			ram_l_former <= temp4;
		else
			ram_l_former <= ram_l_former;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr==6'd24)||(count_cbcr==6'd26))
			ram_l_former <= { p3_0_i, p3_1_i, p3_2_i, p3_3_i,
			                  p2_0_i, p2_1_i, p2_2_i, p2_3_i,
			                  p1_0_i, p1_1_i, p1_2_i, p1_3_i,
			                  p0_0_i, p0_1_i, p0_2_i, p0_3_i };	
		else if(count_cbcr==6'd28)
			ram_l_former <= temp2;
		else if(count_cbcr==6'd30)
			ram_l_former <= temp4;
		else
			ram_l_former <= ram_l_former;
	end	
		
	else
	    ram_l_former <= ram_l_former;
end

reg [2:0] wadd_l;
always@(posedge clk or negedge rst)begin
	if(!rst)
		wadd_l <= 3'd0;
	
	else if(state==Y)begin
		if(count_y==6'd34)
			wadd_l <= 3'd0;	
		else if(count_y==6'd38)
			wadd_l <= 3'd1;	
		else if(count_y==6'd42)
			wadd_l <= 3'd2;	
		else if(count_y==6'd46)
			wadd_l <= 3'd3;
		else
			wadd_l <= wadd_l;
	end
	
	else if(state==CbCr)begin
		if(count_cbcr==6'd24)
			wadd_l <= 3'd4;	
		else if(count_cbcr==6'd26)
			wadd_l <= 3'd6;	
		else if(count_cbcr==6'd28)
			wadd_l <= 3'd5;
		else if(count_cbcr==6'd30)
			wadd_l <= 3'd7;
		else
			wadd_l <= wadd_l;
	end	
		
	else
	    wadd_l <= wadd_l;
end

reg wen_l;
always@(posedge clk or negedge rst)begin
	if(!rst)
		wen_l <= 1'b0;
	
	else if(state==Y)begin
		if((count_y==6'd34)||(count_y==6'd38)||(count_y==6'd42)||(count_y==6'd46))
			wen_l <= 1'b1;
		else
			wen_l <= 1'b0;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr==6'd24)||(count_cbcr==6'd26)||(count_cbcr==6'd28)||(count_cbcr==6'd30))
			wen_l <= 1'b1;
		else
			wen_l <= 1'b0;
	end	
		
	else
	    wen_l <= 1'b0;
end


//////ram_t
reg [2:0] radd_t;
always@(*)begin
	radd_t = 3'd0;
	
	if(state==Y)begin
		if((count_y>=6'd23)&&(count_y<=6'd26))
			radd_t = count_y[2:0] + 'd1;	
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd15)&&(count_cbcr<=6'd18))
			radd_t = count_cbcr[2:0] + 'd5;	
	end
	

		
end

reg ren_t;
always@(*)begin
	ren_t = 1'b0;
		
	if((state==Y)&&(count_y>=6'd23)&&(count_y<=6'd26))
		ren_t = 1'b1;	
		
	else if((state==CbCr)&&(count_cbcr>=6'd15)&&(count_cbcr<=6'd18))
		ren_t = 1'b1;	
	end

	    



//////ram_out
reg [127:0] ram_out;
always@(posedge clk or negedge rst)begin
	if(!rst)
		ram_out <= 128'd0;
	
	if(state==Y)begin
		if((count_y>=6'd4)&&(count_y<=6'd7))
			ram_out <= { p3_0_i, p2_0_i, p1_0_i, p0_0_i,
			             p3_1_i, p2_1_i, p1_1_i, p0_1_i,
			             p3_2_i, p2_2_i, p1_2_i, p0_2_i,
			             p3_3_i, p2_3_i, p1_3_i, p0_3_i };	
		else if((count_y>=6'd27)&&(count_y<=6'd30))
			ram_out <= { p3_0_i, p3_1_i, p3_2_i, p3_3_i,
			             p2_0_i, p2_1_i, p2_2_i, p2_3_i,
			             p1_0_i, p1_1_i, p1_2_i, p1_3_i,
			             p0_0_i, p0_1_i, p0_2_i, p0_3_i };	
		else if((count_y>=6'd31)&&(count_y<=6'd42))
			ram_out <= { p3_0_i, p3_1_i, p3_2_i, p3_3_i,
			             p2_0_i, p2_1_i, p2_2_i, p2_3_i,
			             p1_0_i, p1_1_i, p1_2_i, p1_3_i,
			             p0_0_i, p0_1_i, p0_2_i, p0_3_i };
		else if((count_y>=6'd43)&&(count_y<=6'd46))begin
			case(count_y[1:0])
				2'd0: ram_out <= temp2;
				2'd1: ram_out <= temp3;
				2'd2: ram_out <= temp4;
				2'd3: ram_out <= temp1;
			endcase	
		end	
		else
			ram_out <= ram_out;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd7))
			ram_out <= { p3_0_i, p2_0_i, p1_0_i, p0_0_i,
			             p3_1_i, p2_1_i, p1_1_i, p0_1_i,
			             p3_2_i, p2_2_i, p1_2_i, p0_2_i,
			             p3_3_i, p2_3_i, p1_3_i, p0_3_i };	
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd22)) 
			ram_out <= { p3_0_i, p3_1_i, p3_2_i, p3_3_i,
			             p2_0_i, p2_1_i, p2_2_i, p2_3_i,
			             p1_0_i, p1_1_i, p1_2_i, p1_3_i,
			             p0_0_i, p0_1_i, p0_2_i, p0_3_i };
		else if((count_cbcr>=6'd23)&&(count_cbcr<=6'd26)) 
			ram_out <= { p3_0_i, p3_1_i, p3_2_i, p3_3_i,
			             p2_0_i, p2_1_i, p2_2_i, p2_3_i,
			             p1_0_i, p1_1_i, p1_2_i, p1_3_i,
			             p0_0_i, p0_1_i, p0_2_i, p0_3_i };
		else if((count_cbcr>=6'd27)&&(count_cbcr<=6'd30))begin
			case(count_cbcr[1:0])
				2'd0: ram_out <= temp2;
				2'd1: ram_out <= temp3;
				2'd2: ram_out <= temp4;
				2'd3: ram_out <= temp1;
			endcase	
		end	
		/*else if(count_cbcr==6'd31)
			ram_out <= y_orignal;
		else if(count_cbcr==6'd32)
			ram_out <= uv_orignal;*/	
		else
			ram_out <= ram_out;
	end	
		
	else
		ram_out <= ram_out;
end


reg [5:0] wadd_out;
always@(posedge clk or negedge rst)begin
	if(!rst)
		wadd_out <= 6'd0;
	
	else if(state==Y)begin
	  	if((count_y>=6'd4)&&(count_y<=6'd7))begin
			case(count_y[1:0])
				2'd0: wadd_out <= 6'd35;
				2'd1: wadd_out <= 6'd39;
				2'd2: wadd_out <= 6'd43;
				2'd3: wadd_out <= 6'd47;
			endcase			
		end
		else if((count_y>=6'd27)&&(count_y<=6'd30))
			wadd_out <= count_y + 'd1;    
		else if((count_y>=6'd31)&&(count_y<=6'd42))
			wadd_out <= count_y - 'd31;
		else if((count_y>=6'd43)&&(count_y<=6'd46))begin
			wadd_out <= count_y - 'd31;	
		end	
		else
		    wadd_out <= wadd_out;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd7))begin
			case(count_cbcr[1:0])
				2'd0: wadd_out <= 6'd49;
				2'd1: wadd_out <= 6'd53;
				2'd2: wadd_out <= 6'd51;
				2'd3: wadd_out <= 6'd55;
			endcase
		end	
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd22))begin
			case(count_cbcr[1:0])
				2'd0: wadd_out <= 6'd25;
				2'd1: wadd_out <= 6'd26;
				2'd2: wadd_out <= 6'd27;
				2'd3: wadd_out <= 6'd24;
			endcase
		end	
		else if ((count_cbcr>=6'd23)&&(count_cbcr<=6'd30))
			case(count_cbcr[2:0])
				3'd0: wadd_out <= 6'd17;
				3'd1: wadd_out <= 6'd18;
				3'd2: wadd_out <= 6'd19;
				3'd3: wadd_out <= 6'd20;
				3'd4: wadd_out <= 6'd21;
				3'd5: wadd_out <= 6'd22;
				3'd6: wadd_out <= 6'd23;
				3'd7: wadd_out <= 6'd16;
			endcase
		
		
		/*else if(count_cbcr==6'd31)
			wadd_out <=	6'd40;	
		else if(count_cbcr==6'd32)
			wadd_out <= 6'd41;*/		
		else
			wadd_out <= wadd_out;
	end	
	
	else
		wadd_out <= wadd_out;
end

reg wen_out;
always@(posedge clk or negedge rst)begin
	if(!rst)
		wen_out <= 1'b0;
	
	else if(state==Y)begin
		if((count_y>=6'd4)&&(count_y<=6'd7))
			wen_out <= 1'b1;
		else if((count_y>=6'd27)&&(count_y<=6'd30))
			wen_out <= 1'b1;
		else if((count_y>=6'd31)&&(count_y<=6'd42))
			wen_out <= 1'b1;
		else if((count_y>=6'd43)&&(count_y<=6'd46))
			wen_out <= 1'b1;
		else
			wen_out <= 1'b0;
	end
	
	else if(state==CbCr)begin
		if((count_cbcr>=6'd4)&&(count_cbcr<=6'd7))
			wen_out <= 1'b1;
		else if((count_cbcr>=6'd19)&&(count_cbcr<=6'd22)) 
			wen_out <= 1'b1;
		else if((count_cbcr>=6'd23)&&(count_cbcr<=6'd30))
			wen_out <= 1'b1;
		/*else if((count_cbcr==6'd31)||(count_cbcr==6'd32))
			wen_out <= 1'b1;*/
		else
			wen_out <= 1'b0;
	end	
	
	else
		wen_out <= 1'b0;
end

/*
integer fp_data_out;
initial begin
	fp_data_out = $fopen("data_out.dat","wb");
end

always@(posedge clk)begin
	if (start=='b1)
	    $fdisplay(fp_data_out, "mb_x= 0 mb_y= 0" );
	else if ((state==Y)&&( ((count_y>=6'd2)&&(count_y<=6'd17))||((count_y>=6'd19)&&(count_y<=6'd34)) ))begin
		$fdisplay(fp_data_out, "%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n",
								p3_0_o, p2_0_o, p1_0_o, p0_0_o, q0_0_o, q1_0_o, q2_0_o, q3_0_o,
								p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o,
								p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o,
								p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o );
	end
	else if ((state==CbCr)&&( ((count_cbcr>=6'd2)&&(count_cbcr<=6'd9))||((count_cbcr>=6'd11)&&(count_cbcr<=6'd18)) )) begin   
		$fdisplay(fp_data_out, "%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n",
								p3_0_o, p2_0_o, p1_0_o, p0_0_o, q0_0_o, q1_0_o, q2_0_o, q3_0_o,
								p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o,
								p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o,
								p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o );
	end	
end

integer fp_data_in;
initial begin
	fp_data_in = $fopen("data_in.dat","wb");
end

always@(posedge clk)begin
	if (start=='b1)
	    $fdisplay(fp_data_in, "mb_x= 0 mb_y= 0" );
	else if ((state==Y)&&( ((count_y>=6'd4)&&(count_y<=6'd19))||((count_y>=6'd21)&&(count_y<=6'd36)) ))begin
		$fdisplay(fp_data_in, "%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n",
								p3_0_i, p2_0_i, p1_0_i, p0_0_i, q0_0_i, q1_0_i, q2_0_i, q3_0_i,
								p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i,
								p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i,
								p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i );
	end
	else if ((state==CbCr)&&( ((count_cbcr>=6'd4)&&(count_cbcr<=6'd11))||((count_cbcr>=6'd13)&&(count_cbcr<=6'd20)) )) begin   
		$fdisplay(fp_data_in, "%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n%3d %3d %3d %3d %3d %3d %3d %3d \n",
								p3_0_i, p2_0_i, p1_0_i, p0_0_i, q0_0_i, q1_0_i, q2_0_i, q3_0_i,
								p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i,
								p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i,
								p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i );
	end	
end
*/
/*reg signed [5:0] frame_num;
always@(posedge clk or negedge rst)begin
	if(!rst)
		frame_num <= -1;
	else if((x==0)&&(y==0)&&(state==Y)&&(count_y==1))
		frame_num <= frame_num + 1;
	else 
		frame_num <= frame_num;
end






reg [5:0] count_out1;
always@(posedge clk or negedge rst)begin
	if(!rst)
		count_out1 <= 0;
	else if ( (state==Y)&&((count_y>=6'd4)&&(count_y<=6'd7)) )begin
		if(count_y==6'd4)
			count_out1 <= 'd1;
		else
			count_out1 <= count_out1 + 1;	
	end
	else if ( (state==Y)&&((count_y>=6'd27)&&(count_y<=6'd46)) )begin
		if(count_y==6'd27)
			count_out1 <= 'd5;
		else
			count_out1 <= count_out1 + 1;		
	end	
	else if ( (state==CbCr)&&((count_cbcr>=6'd4)&&(count_cbcr<=6'd7)) )begin
		if(count_cbcr==6'd4)
			count_out1 <= 'd25;
		else
			count_out1 <= count_out1 + 1;	
	end	
	else if ( (state==CbCr)&& ((count_cbcr>=6'd19)&&(count_cbcr<=6'd30)) )begin
		if(count_cbcr==6'd19)
			count_out1 <= 'd29;
		else
			count_out1 <= count_out1 + 1;		
	end
	else
		count_out1 <= 0;
end



integer fp_data_ram_out;
initial begin
	fp_data_ram_out = $fopen("data_ram_out.dat","wb");
end

always@(posedge clk)begin
	if ((state==Y)&&(count_y==6'd2))
	    $fdisplay(fp_data_ram_out, "===== Frame:  %1d MB x: %2d y: %2d =====", frame_num, x , y );
	else if ((state==Y)&&( ((count_y>=6'd5)&&(count_y<=6'd8))||((count_y>=6'd28)&&(count_y<=6'd47)) ) )begin
		$fdisplay(fp_data_ram_out, "%2d:%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h",count_out1,
								ram_out[127:120], ram_out[119:112], ram_out[111:104], ram_out[103:96],
								ram_out[95:88],   ram_out[87:80],   ram_out[79:72],   ram_out[71:64],
								ram_out[63:56],   ram_out[55:48],   ram_out[47:40],   ram_out[39:32],
								ram_out[31:24],   ram_out[23:16],   ram_out[15:8],    ram_out[7:0] );
	end
		
	
	else if ((state==CbCr)&&( ((count_cbcr>=6'd5)&&(count_cbcr<=6'd8))||((count_cbcr>=6'd20)&&(count_cbcr<=6'd31)) ) )begin
		$fdisplay(fp_data_ram_out, "%2d:%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h%2h",count_out1,
								 ram_out[127:120], ram_out[119:112], ram_out[111:104], ram_out[103:96],
								 ram_out[95:88],   ram_out[87:80],   ram_out[79:72],   ram_out[71:64],
								 ram_out[63:56],   ram_out[55:48],   ram_out[47:40],   ram_out[39:32],
								 ram_out[31:24],   ram_out[23:16],   ram_out[15:8],    ram_out[7:0] );
	end
	
end*/



			
endmodule
