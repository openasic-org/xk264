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
// Filename       : ime_mux.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                select the minimu cost among the PEs
//                
// Modification   : Xyuan 
// Date           : 2012-6-17              
// Description    : Remove  excess logic             
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_mux(
        clk,
        rstn,
        
        rst_mux_i,
        
        cost_v_i,
        cost_i,
        mvd_x_i,
        mvd_y_i,
        
        mvd_x_o,
        mvd_y_o,
        cost_o
);
parameter COST_LEN = `SAD4X4_LEN;

input                           rstn;
input                           clk;

input                           rst_mux_i;

input                           cost_v_i;
input   [`PE_NUM* COST_LEN-1:0] cost_i;   //4x13  
input   [`IMVD_LEN-1        :0] mvd_x_i;
input   [`IMVD_LEN-1        :0] mvd_y_i;

output  [ COST_LEN-1:0]         cost_o;
output  [`IMVD_LEN-1:0]         mvd_x_o;
output  [`IMVD_LEN-1:0]         mvd_y_o;

reg     [`IMVD_LEN-1:0]         mvd_y_o;

reg [(`PE_NUM+1)/2*`IMVD_LEN-1:0]   mvd_x_1;
reg [(`PE_NUM+1)/2* COST_LEN-1:0]   cost_1;

reg [(`PE_NUM+3)/4*`IMVD_LEN-1:0]   mvd_x_2;
reg [(`PE_NUM+3)/4* COST_LEN-1:0]   cost_2;

reg  [ COST_LEN-1:0] cost_o;
reg  [`IMVD_LEN-1:0] mvd_x_o;

wire [ COST_LEN-1:0] cost_final;
wire [`IMVD_LEN-1:0] mvd_x_final;

always@(posedge clk or negedge rstn)
begin
    if(rstn==1'b0) begin
        cost_o  <= -13'd1; 
        mvd_x_o  <='b0; 
        mvd_y_o  <='b0;
    end    
    else if(rst_mux_i)
      cost_o <= -13'd1;
    else
    if((cost_final< cost_o) && (cost_v_i)) begin   /// enable signal may needed ?????????????????
        cost_o  <=  cost_final; 
        mvd_x_o <= mvd_x_final; 
        mvd_y_o <= mvd_y_i;
    end
end

reg  [`IMVD_LEN*`PE_NUM-1:0] mvd_x_0;
//reg  [`IMVD_LEN-1:        0] mvd_y_0;

genvar i;

always @( * ) begin
  mvd_x_0[`IMVD_LEN-1:0] = mvd_x_i;
//  mvd_y_0[`IMVD_LEN-1:0] = mvd_y_i;
end
generate
    for(i = 1; i < `PE_NUM; i= i+1 ) begin : mvd_x_0_n
      always @( * ) begin
        mvd_x_0[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN] = mvd_x_0[i*`IMVD_LEN-1:(i-1)*`IMVD_LEN] + 1'b1;
      end
    end
endgenerate

//first level compare
//edit by xyuan 
generate
    for(i = 0; i < `PE_NUM/2; i = i +1 ) begin : ime_mux_1 //`PE_NUM/2 2-to-1 mux for (`PE_NUM) inputs
        always@(*) begin
            if (cost_i[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_i[(2*i+1)*COST_LEN-1:2*i*COST_LEN])   begin
                cost_1[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_i[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_1[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_0[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_1[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_i[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_1[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_0[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        
        end
    end
endgenerate

//the second level
generate 
   for(i = 0; i < (`PE_NUM+1)/4; i = i +1 ) begin : ime_mux_2 
        always@(*) begin
            if ( cost_1[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_1[(2*i+1)*COST_LEN-1:2*i*COST_LEN])  begin
                cost_2[(i+1)*COST_LEN-1:i*COST_LEN]     =  cost_1[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_2[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_1[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_2[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_1[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_2[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_1[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        end
    end
endgenerate

assign      cost_final  = cost_2;
assign      mvd_x_final = mvd_x_2;
//end by xyuan 

endmodule

/* Pre  Version  */
/*
reg [(`PE_NUM+7)/8*`IMVD_LEN-1:0]   mvd_x_3;
reg [(`PE_NUM+7)/8* COST_LEN-1:0]   cost_3;

reg [(`PE_NUM+15)/16*`IMVD_LEN-1:0]  mvd_x_4;
reg [(`PE_NUM+15)/16* COST_LEN-1:0]  cost_4;

reg [(`PE_NUM+31)/32*`IMVD_LEN-1:0]  mvd_x_5;
reg [(`PE_NUM+31)/32* COST_LEN-1:0]  cost_5;

//first level compare
generate
    for(i = 0; i < `PE_NUM/2; i = i +1 ) begin : ime_mux_1 //`PE_NUM/2 2-to-1 mux for (`PE_NUM) inputs
        always@(*) begin
            if (cost_i[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_i[(2*i+1)*COST_LEN-1:2*i*COST_LEN])   begin
                cost_1[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_i[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_1[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_0[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_1[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_i[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_1[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_0[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        
        end
    end
    
    if(6'd`PE_NUM%2 != 0) begin//link directly
       always @( * ) begin
         cost_1 [((`PE_NUM+1)/2)*COST_LEN-1:((`PE_NUM+1)/2 - 1)*COST_LEN] = cost_i[`PE_NUM*COST_LEN-1:(`PE_NUM-1)*COST_LEN];
         mvd_x_1[((`PE_NUM+1)/2)*`IMVD_LEN-1:((`PE_NUM+1)/2 - 1)*`IMVD_LEN] = mvd_x_i + `PE_NUM-1;
       end
    end
endgenerate

//the second level
generate 
   for(i = 0; i < (`PE_NUM+1)/4; i = i +1 ) begin : ime_mux_2 
        always@(*) begin
            if ( cost_1[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_1[(2*i+1)*COST_LEN-1:2*i*COST_LEN])  begin
                cost_2[(i+1)*COST_LEN-1:i*COST_LEN]     =  cost_1[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_2[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_1[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_2[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_1[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_2[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_1[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        end
    end
    
    if (6'd`PE_NUM%4 != 0) begin
      always @( * ) begin
        cost_2 [((`PE_NUM+3)/4)*COST_LEN-1 :((`PE_NUM+3)/4 - 1)*COST_LEN ] = cost_1 [((`PE_NUM+1)/2)*COST_LEN-1 :((`PE_NUM+1)/2-1)*COST_LEN];
        mvd_x_2[((`PE_NUM+3)/4)*`IMVD_LEN-1:((`PE_NUM+3)/4 - 1)*`IMVD_LEN] = mvd_x_1[((`PE_NUM+1)/2)*`IMVD_LEN-1:((`PE_NUM+1)/2-1)*`IMVD_LEN];
      end
    end
endgenerate


//the third level
generate 
    for(i = 0; i < (`PE_NUM+3)/8; i = i +1 ) begin : ime_mux_3
        always@(*) begin
            if (cost_2[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_2[(2*i+1)*COST_LEN-1:2*i*COST_LEN])  begin
                cost_3[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_2[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_3[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_2[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_3[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_2[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_3[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_2[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        end        
    
        if(6'd`PE_NUM%8 != 0) 
          always @( * ) begin
            cost_3 [((`PE_NUM+7)/8)*COST_LEN-1 :((`PE_NUM+7)/8 - 1)*COST_LEN ] = cost_2 [((`PE_NUM+3)/4)*COST_LEN-1 :((`PE_NUM+3)/4 - 1)*COST_LEN ];
            mvd_x_3[((`PE_NUM+7)/8)*`IMVD_LEN-1:((`PE_NUM+7)/8 - 1)*`IMVD_LEN] = mvd_x_2[((`PE_NUM+3)/4)*`IMVD_LEN-1:((`PE_NUM+3)/4 - 1)*`IMVD_LEN];
          end
    end
endgenerate

//the forth level
generate 
    for(i = 0; i < (`PE_NUM+7)/16; i = i +1 ) begin : ime_mux_4
        always@(*) begin
            if (cost_3[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_3[(2*i+1)*COST_LEN-1:2*i*COST_LEN])  begin
                cost_4[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_3[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_4[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_3[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_4[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_3[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_4[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_3[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        end
    end
    
    if(6'd`PE_NUM%16 !=0 ) begin
      always @( * ) begin
        cost_4 [((`PE_NUM+15)/16)*COST_LEN-1:((`PE_NUM+15)/16-1)*COST_LEN] = cost_3 [((`PE_NUM+7)/8)*COST_LEN-1:((`PE_NUM+7)/8-1)*COST_LEN];
        mvd_x_4[((`PE_NUM+15)/16)*`IMVD_LEN-1:((`PE_NUM+15)/16-1)*`IMVD_LEN] = mvd_x_3[((`PE_NUM+7)/8)*`IMVD_LEN-1:((`PE_NUM+7)/8-1)*`IMVD_LEN];
      end
    end
    
endgenerate

//the five level
generate 
    for(i = 0; i < (`PE_NUM+15)/32; i = i +1 ) begin : ime_mux_5
        always@(*) begin
            if (cost_4[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN] < cost_4[(2*i+1)*COST_LEN-1:2*i*COST_LEN])  begin
                cost_5[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_4[(2*i+2)*COST_LEN-1:(2*i+1)*COST_LEN];
                mvd_x_5[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_4[(2*i+2)*`IMVD_LEN-1:(2*i+1)*`IMVD_LEN];
            end
            else begin
                cost_5[(i+1)*COST_LEN-1:i*COST_LEN]     = cost_4[(2*i+1)*COST_LEN-1:2*i*COST_LEN];
                mvd_x_5[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]  = mvd_x_4[(2*i+1)*`IMVD_LEN-1:2*i*`IMVD_LEN];
            end
        end
    end
endgenerate

generate
always @( * ) begin
  if((6'd`PE_NUM -1)/2 == 0) begin
    	cost_final  = cost_1;
    	mvd_x_final = mvd_x_1;
  end
  else if((6'd`PE_NUM-1)/4 == 0) begin
      	cost_final  = cost_2;
      	mvd_x_final = mvd_x_2;
  end
  else if((6'd`PE_NUM-1)/8 == 0) begin
        cost_final  = cost_3;
        mvd_x_final = mvd_x_3;
  end
  else if((6'd`PE_NUM-1)/16 == 0) begin
        cost_final  = cost_4;
        mvd_x_final = mvd_x_4;
  end
  else if((6'd`PE_NUM-1)/32 == 0) begin
      	cost_final  = cost_5;
        mvd_x_final = mvd_x_5;
  end
end
endgenerate
 */
