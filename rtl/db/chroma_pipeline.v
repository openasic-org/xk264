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
// Filename       : bs.v
// Author         : shen weiwei
// Created        : 2011-01-07
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
//------------------------------------------------------------------- 

module chroma_pipeline( clk, rst, 
                         bs, 
                         qp1_i, qp2_i,
                         p0_i, p1_i, p2_i, p3_i, q0_i, q1_i, q2_i, q3_i,
                         p0_filtered, p1_filtered, p2_filtered, p3_filtered,
                         q0_filtered, q1_filtered, q2_filtered, q3_filtered );

  
input clk;
input rst;


input [2:0] bs;
input [5:0] qp1_i;
input [5:0] qp2_i;
input [7:0] p0_i, p1_i, p2_i, p3_i, q0_i, q1_i, q2_i, q3_i;

output [7:0] p0_filtered, p1_filtered, p2_filtered, p3_filtered;
output [7:0] q0_filtered, q1_filtered, q2_filtered, q3_filtered;


//pipeline 1
wire [6:0]      qpav1;
assign          qpav1=qp1_i+qp2_i+7'd1;
wire [5:0]      qpav;
assign          qpav=qpav1[6:1];

wire [5:0]      indexA;
wire [5:0]      indexB;
assign          indexA=(qpav<=0)?6'd0:((qpav>=6'd51)?6'd51:qpav);
assign          indexB=(qpav<=0)?6'd0:((qpav>=6'd51)?6'd51:qpav);

reg [5:0] indexA_reg;
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		indexA_reg<=0;
	end
	else begin
		indexA_reg<=indexA;//!!!!!!
	end	
end

wire [7:0]      alpha;
wire [4:0]      beta;

    rom_alpha alpha1 ( .address_i(indexA), .q_o(alpha));
    rom_beta beta1( .address_i(indexB), .q_o(beta) );

wire [8:0]      con_1;
wire [8:0]      con_2;
wire [8:0]      con_3;
assign          con_1=p0_i-q0_i;
assign          con_2=p1_i-p0_i;
assign          con_3=q1_i-q0_i;
wire [8:0]      con_1_1;
wire [8:0]      con_2_1;
wire [8:0]      con_3_1;
assign          con_1_1=(con_1[8]==9'd0)?con_1:(~con_1+9'd1);
assign          con_2_1=(con_2[8]==9'd0)?con_2:(~con_2+9'd1);//
assign          con_3_1=(con_3[8]==9'd0)?con_3:(~con_3+9'd1);//
wire            con_1_2;
wire            con_2_2;
wire            con_3_2;
assign          con_1_2=(con_1_1<alpha)?1'b1:1'b0;//!!!!!!
assign          con_2_2=(con_2_1<beta )?1'b1:1'b0;//!!!!!!
assign          con_3_2=(con_3_1<beta )?1'b1:1'b0;//!!!!!!

wire con_bs;//!!
assign con_bs=con_1_2&con_2_2&con_3_2;//!!!

reg [2:0] bs_link;//!!!
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		bs_link<=0;
	end
	else begin
		bs_link<=bs;
	end	
end

reg con_bs_reg;//!!!
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		con_bs_reg<=0;
	end
	else begin
		con_bs_reg<=con_bs;
	end	
end



wire signed [8:0]       p0_i_1;
wire signed [8:0]       p1_i_1;
wire signed [8:0]       q0_i_1;
wire signed [8:0]       q1_i_1;
assign                  p0_i_1={1'b0,p0_i};
assign                  p1_i_1={1'b0,p1_i};
assign                  q0_i_1={1'b0,q0_i};
assign                  q1_i_1={1'b0,q1_i};
wire signed [10:0]      con_s_1;
assign                  con_s_1=(q0_i_1-p0_i_1)<<2;
wire signed [9:0]       con_s_2;
assign                  con_s_2=p1_i_1-q1_i_1+10'sb0000000100;
wire signed [11:0]      con_s_3;
assign                  con_s_3=con_s_1+con_s_2;
wire signed [8:0]       con_s_tc;
assign                  con_s_tc=con_s_3[11:3];

reg signed [8:0] con_s_tc_reg;
always @( posedge clk or negedge rst) begin
	if(!rst) begin
		con_s_tc_reg<=0;
	end
	else begin
		con_s_tc_reg<=con_s_tc;
	end
end

reg [7:0] p0_link, p1_link, p2_link, p3_link, q0_link,q1_link,q2_link,q3_link;
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		p0_link <= 0;
        p1_link <= 0;
        p2_link <= 0;
        p3_link <= 0;
        q0_link <= 0;
        q1_link <= 0;
        q2_link <= 0;
        q3_link <= 0;        
	end
	else begin
		p0_link <= p0_i;
        p1_link <= p1_i;
        p2_link <= p2_i;
        p3_link <= p3_i;
        q0_link <= q0_i;
        q1_link <= q1_i;
        q2_link <= q2_i;
        q3_link <= q3_i; 
	end	
end


//pipeline2 

//w
wire [4:0]       tc0;

rom_clip clip1(.address_i(({bs_link[2:0],indexA_reg[5:0]})), .q_o(tc0));//!!!

wire signed [5:0]       tc0_1={1'b0,tc0[4:0]};

wire signed [5:0]       tc;
assign                  tc=tc0_1+2'sb01;

wire signed [5:0]       dif;
wire signed [8:0]       dif_w; 
assign                  dif_w=(con_s_tc_reg<(-tc))?(-tc):((con_s_tc_reg>tc)?tc:con_s_tc_reg);
assign                  dif = dif_w[5:0];

wire signed [8:0]       p0_w;
assign                  p0_w={1'b0,p0_link[7:0]};
wire signed [8:0]       q0_w;
assign                  q0_w={1'b0,q0_link[7:0]};

wire signed [9:0]       p0dif;
assign                  p0dif=p0_w+dif;

wire signed [9:0]       q0dif;
assign                  q0dif=q0_w-dif;

wire signed [8:0]       p01_w;
assign                  p01_w=(p0dif<0)?9'sd0:((p0dif>9'sb011111111)?9'sb011111111:p0dif[8:0]);
wire signed [8:0]       q01_w;
assign                  q01_w=(q0dif<0)?9'sd0:((q0dif>9'sb011111111)?9'sb011111111:q0dif[8:0]);

//s
wire [9:0]              p0_s;
assign                  p0_s={p1_link[7:0],1'b0}+p0_link+q1_link+2'b10;

wire [9:0]              q0_s;
assign                  q0_s={q1_link[7:0],1'b0}+q0_link+p1_link+2'b10;

//
reg [7:0]               p0_filtered;
reg [7:0]               p1_filtered;
reg [7:0]               p2_filtered;
reg [7:0]               p3_filtered;
reg [7:0]               q0_filtered;
reg [7:0]               q1_filtered;
reg [7:0]               q2_filtered;
reg [7:0]               q3_filtered;

`ifdef DB_BYPASS
always @(posedge clk or negedge rst) begin
	if (!rst)begin
		p0_filtered<=0;
		p1_filtered<=0;
		p2_filtered<=0;
		p3_filtered<=0;
		q0_filtered<=0;
		q1_filtered<=0;
		q2_filtered<=0;
		q3_filtered<=0;
	end
	else if ((con_bs_reg==1)&&(bs_link==3'd4))begin//
		p0_filtered<=p0_link;
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q0_link;
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
	else if ((con_bs_reg==1)&&(bs_link==3'd3||bs_link==3'd2||bs_link==3'd1))begin//
		p0_filtered<=p0_link;
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q0_link;
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
	else begin
		p0_filtered<=p0_link;
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q0_link;
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
end

`else
always @(posedge clk or negedge rst) begin
	if (!rst)begin
		p0_filtered<=0;
		p1_filtered<=0;
		p2_filtered<=0;
		p3_filtered<=0;
		q0_filtered<=0;
		q1_filtered<=0;
		q2_filtered<=0;
		q3_filtered<=0;
	end
	else if ((con_bs_reg==1)&&(bs_link==3'd4))begin//
		p0_filtered<=p0_s[9:2];
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q0_s[9:2];
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
	else if ((con_bs_reg==1)&&(bs_link==3'd3||bs_link==3'd2||bs_link==3'd1))begin//
		p0_filtered<=p01_w[7:0];
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q01_w[7:0];
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
	else begin
		p0_filtered<=p0_link;
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q0_link;
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
end
`endif



//pipeline3

endmodule
