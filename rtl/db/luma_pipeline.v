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
// Filename       : luma_pipeline.v
// Author         : shen weiwei
// Created        : 2011-01-07
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
//-------------------------------------------------------------------

module luma_pipeline ( clk, rst, bs, 
                           qp1_i, qp2_i,
                           p0_i, p1_i, p2_i, p3_i, q0_i, q1_i, q2_i,q3_i,
                           p0_filtered, p1_filtered, p2_filtered, p3_filtered, q0_filtered, q1_filtered, q2_filtered, q3_filtered
                          );
                       

  
input clk;
input rst;
input [2:0] bs;
input [7:0] p0_i, p1_i, p2_i, p3_i, q0_i, q1_i, q2_i,q3_i;

input [5:0] qp1_i;
input [5:0] qp2_i;

output [7:0] p0_filtered, p1_filtered, p2_filtered, p3_filtered, q0_filtered, q1_filtered, q2_filtered, q3_filtered;





//pipeline 1
wire [6:0] qpav1;
assign qpav1=qp1_i+qp2_i+ 7'd1;
wire [5:0] qpav;
assign qpav=qpav1[6:1];

wire [5:0] indexA;
wire [5:0] indexB;
assign indexA=(qpav<=0)?6'd0:((qpav>=6'd51)?6'd51:qpav);
assign indexB=(qpav<=0)?6'd0:((qpav>=6'd51)?6'd51:qpav);

reg [5:0] indexA_reg;
always @(posedge clk or negedge rst) begin
	if(!rst) 
		indexA_reg<=0;
	else
		indexA_reg<=indexA;
end

wire [7:0] alpha;
wire [4:0] beta;
rom_alpha alpha1 ( .address_i(indexA),.q_o(alpha));
rom_beta beta1( .address_i(indexB), .q_o(beta) );

wire [8:0] con_1;
wire [8:0] con_2;
wire [8:0] con_3;
assign con_1=p0_i-q0_i;
assign con_2=p1_i-p0_i;
assign con_3=q1_i-q0_i;
wire [8:0] con_1_1;
wire [8:0] con_2_1;
wire [8:0] con_3_1;
assign con_1_1=(con_1[8]==0)?con_1:(~con_1+8'd1);
assign con_2_1=(con_2[8]==0)?con_2:(~con_2+8'd1);
assign con_3_1=(con_3[8]==0)?con_3:(~con_3+8'd1);
wire con_1_2;
wire con_2_2;
wire con_3_2;
assign con_1_2=(con_1_1<alpha)?1'b1:1'b0;
assign con_2_2=(con_2_1<beta) ?1'b1:1'b0;
assign con_3_2=(con_3_1<beta) ?1'b1:1'b0;


wire con_bs;//!!
assign con_bs=con_1_2&con_2_2&con_3_2;//!!!

reg con_bs_reg;//!!!
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		con_bs_reg<=0;
	end
	else begin
		con_bs_reg<=con_bs;
	end	
end

reg [2:0] bs_link;//!!!
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		bs_link<=0;
	end
	else begin
		bs_link<=bs;
	end	
end




wire [8:0] con_w_1;
wire [8:0] con_w_2;
assign con_w_1=p2_i-p0_i;
assign con_w_2=q2_i-q0_i;
wire [8:0] con_w_1_1;
wire [8:0] con_w_2_1;
assign con_w_1_1=(con_w_1[8]==0)?con_w_1:(~con_w_1+9'd1);
assign con_w_2_1=(con_w_2[8]==0)?con_w_2:(~con_w_2+9'd1);
wire ap_w;
wire aq_w;
assign ap_w=(con_w_1_1<beta)?1'b1:1'b0;
assign aq_w=(con_w_2_1<beta)?1'b1:1'b0;

reg ap_w_reg;
reg aq_w_reg;
always @( posedge clk or negedge rst) begin
	if(!rst) begin
		ap_w_reg<=0;
		aq_w_reg<=0;
	end
	else begin
		ap_w_reg<=ap_w;
		aq_w_reg<=aq_w;
	end
end

wire [5:0]        alpha_2;
assign            alpha_2=alpha[7:2];
wire [6:0]        alpha_2_1;
assign            alpha_2_1=alpha_2+2'd2;
wire              con_s;
assign            con_s=(con_1_1<alpha_2_1)?1'b1:1'b0;
wire              ap_s;
wire              aq_s;
assign            ap_s=(ap_w&con_s);
assign            aq_s=(aq_w&con_s);

reg ap_s_reg;
reg aq_s_reg;

always @( posedge clk or negedge rst) begin
	if(!rst) begin
		ap_s_reg<=0;
		aq_s_reg<=0;
	end
	else begin
		ap_s_reg<=ap_s;
		aq_s_reg<=aq_s;
	end
end


wire signed [8:0]        p0_i_1;
wire signed [8:0]        p1_i_1;
wire signed [8:0]        q0_i_1;
wire signed [8:0]        q1_i_1;
assign                   p0_i_1={1'b0,p0_i};
assign                   p1_i_1={1'b0,p1_i};
assign                   q0_i_1={1'b0,q0_i};
assign                   q1_i_1={1'b0,q1_i};
wire signed [10:0]       con_s_1;
assign                   con_s_1=(q0_i_1-p0_i_1)<<2;
wire signed [9:0]        con_s_2;
assign                   con_s_2=p1_i_1-q1_i_1+10'sb0000000100;
wire signed [11:0]       con_s_3;
assign                   con_s_3=con_s_1+con_s_2;
wire signed [8:0]        con_s_tc;
assign                   con_s_tc=con_s_3[11:3];

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





//con_1_reg, con_2_reg,  con_3_reg, bs_o,ap_w_reg, aq_w_reg,ap_s_reg,aq_s_reg,con_s_tc_reg,indexA_reg
//bs_o,bs_o,ap_w_reg, aq_w_reg,ap_s_reg,aq_s_reg,con_s_tc_reg,indexA_reg



//pipeline 2

//w
wire [4:0]       tc0;

rom_clip clip1(.address_i(({bs_link[2:0],indexA_reg[5:0]})), .q_o(tc0));//!!!

wire signed [5:0]        tc0_1={1'b0,tc0[4:0]};

wire signed [5:0]        tc;
assign                   tc=tc0_1+ap_w_reg+aq_w_reg;

wire signed [5:0]        dif;
wire signed [8:0]        dif_w; 
assign                   dif_w=(con_s_tc_reg<(-tc))?(-tc):((con_s_tc_reg>tc)?tc:con_s_tc_reg);
assign                   dif = dif_w[5:0] ;

wire signed [8:0]        p0_w;
assign                   p0_w={1'b0,p0_link[7:0]};
wire signed [8:0]        q0_w;
assign                   q0_w={1'b0,q0_link[7:0]};

wire signed [9:0]        p0dif;
assign                   p0dif=p0_w+dif;

wire signed [9:0]        q0dif;
assign                   q0dif=q0_w-dif;

wire signed [8:0]        p01_w;
assign                   p01_w=(p0dif<0)?9'sd0:((p0dif>9'sb011111111)?9'sb011111111:p0dif[8:0]);
wire signed [8:0]        q01_w;
assign                   q01_w=(q0dif<0)?9'sd0:((q0dif>9'sb011111111)?9'sb011111111:q0dif[8:0]);

//p11
wire signed [9:0]        p11_w_1;
assign                   p11_w_1=p0_w+q0_w+2'sb01;

wire signed [8:0]        p11_w_2;
assign                   p11_w_2=p11_w_1[9:1];

wire signed [9:0]        p1_w;
assign                   p1_w={1'b0,p1_link[7:0],1'b0};

wire signed [8:0]        p1_w_1;
assign                   p1_w_1={1'b0,p1_link[7:0]};

wire signed [8:0]        p2_w;
assign                   p2_w={1'b0,p2_link[7:0]};

wire signed [9:0]        p11db;
assign                   p11db=p2_w+p11_w_2-p1_w;

wire signed [8:0]        p11db_1;
assign                   p11db_1=p11db[9:1];

wire signed [8:0]        p11db_2;
assign                   p11db_2=(p11db_1<(-tc0_1))?(-tc0_1):((p11db_1>tc0_1)?tc0_1:p11db_1);

wire signed [8:0]        p11db_3;
assign                   p11db_3= p1_w_1+p11db_2;

//q11
wire signed [9:0]        q1_w;
assign                   q1_w={1'b0,q1_link[7:0],1'b0};

wire signed [8:0]        q1_w_1;
assign                   q1_w_1={1'b0,q1_link[7:0]};

wire signed [8:0]        q2_w;
assign                   q2_w={1'b0,q2_link[7:0]};

wire signed [9:0]        q11db;
assign                   q11db=q2_w+p11_w_2-q1_w;

wire signed [8:0]        q11db_1;
assign                   q11db_1=q11db[9:1];

wire signed [8:0]        q11db_2;
assign                   q11db_2=(q11db_1<(-tc0_1))?(-tc0_1):((q11db_1>tc0_1)?tc0_1:q11db_1);

wire signed [8:0]        q11db_3;
assign                   q11db_3= q1_w_1+q11db_2;


//

reg [7:0] p11_w;
always @* begin
	if((bs_link==3'd3||bs_link==3'd2||bs_link==3'd1)&&(ap_w_reg==1)) begin
		p11_w=p11db_3[7:0];
	end
	else begin
		p11_w=p1_link;
	end
end

reg [7:0] q11_w;
always @* begin
	if((bs_link==3'd3||bs_link==3'd2||bs_link==3'd1)&&(aq_w_reg==1)) begin
		q11_w=q11db_3[7:0];
	end
	else begin
		q11_w=q1_link;///////////////////////////////����
	end
end





//s

reg [10:0] p01_s;
reg [9:0] p11_s;
reg [10:0] p21_s;
always @* begin
	if((bs_link==3'd4)&&(ap_s_reg==1)) begin
		p01_s={3'b000,p2_link[7:0]}+{2'b00,p1_link[7:0],1'b0}+{2'b00,p0_link[7:0],1'b0}+{2'b00,q0_link[7:0],1'b0}+{3'b000,q1_link[7:0]}+11'd4;
		p11_s={2'b00,p2_link[7:0]}+{2'b00,p1_link[7:0]}+{2'b00,p0_link[7:0]}+{2'b00,q0_link[7:0]}+10'd2;
		p21_s={2'b00,p3_link[7:0],1'b0}+{2'b00,p2_link[7:0],1'b0}+{3'b000,p2_link[7:0]}+{3'b000,p1_link[7:0]}+{3'b000,p0_link[7:0]}+{3'b000,q0_link[7:0]}+11'd4;
	end
	else if((bs_link==3'd4)&&(ap_s_reg==0))begin
		p01_s={1'b0,p1_link[7:0],2'b00}+{2'b00,p0_link[7:0],1'b0}+{2'b00,q1_link[7:0],1'b0}+11'd4;
		p11_s={p1_link[7:0],2'b00};
		p21_s={p2_link[7:0],3'b000};
	end
	else begin
		p01_s={p0_link[7:0],3'b000};
		p11_s={p1_link[7:0],2'b00};
		p21_s={p2_link[7:0],3'b000};
	end
end

reg [10:0] q01_s;
reg [9:0] q11_s;
reg [10:0] q21_s;
always @* begin
	if((bs_link==3'd4)&&(aq_s_reg==1)) begin
		q01_s={3'b000,p1_link[7:0]}+{2'b00,p0_link[7:0],1'b0}+{2'b00,q0_link[7:0],1'b0}+{2'b00,q1_link[7:0],1'b0}+{3'b000,q2_link[7:0]}+11'd4;
		q11_s={2'b00,q2_link[7:0]}+{2'b00,q1_link[7:0]}+{2'b00,q0_link[7:0]}+{2'b00,p0_link[7:0]}+10'd2;
		q21_s={2'b00,q3_link[7:0],1'b0}+{2'b00,q2_link[7:0],1'b0}+{3'b000,q2_link[7:0]}+{3'b000,q1_link[7:0]}+{3'b000,q0_link[7:0]}+{3'b000,p0_link[7:0]}+11'd4;
	end
	else if((bs_link==3'd4)&&(aq_s_reg==0))begin
		q01_s={1'b0,q1_link[7:0],2'b00}+{2'b00,q0_link[7:0],1'b0}+{2'b00,p1_link[7:0],1'b0}+11'd4;
		q11_s={q1_link[7:0],2'b00};
		q21_s={q2_link[7:0],3'b000};
	end
	else begin
		q01_s={q0_link[7:0],3'b000};
		q11_s={q1_link[7:0],2'b00};
		q21_s={q2_link[7:0],3'b000};
	end
end


//
reg [7:0]                    p0_filtered;
reg [7:0]                    p1_filtered;
reg [7:0]                    p2_filtered;
reg [7:0]                    p3_filtered;
reg [7:0]                    q0_filtered;
reg [7:0]                    q1_filtered;
reg [7:0]                    q2_filtered;
reg [7:0]                    q3_filtered;

`ifdef DB_BYPASS
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		p0_filtered<=0;
		p1_filtered<=0;
		p2_filtered<=0;
		p3_filtered<=0;
		q0_filtered<=0;
		q1_filtered<=0;
		q2_filtered<=0;
		q3_filtered<=0;
	end
	else if((con_bs_reg==1)&&(bs_link==3'd4))begin
		p0_filtered<=p0_link;
		p1_filtered<=p1_link;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q0_link;
		q1_filtered<=q1_link;
		q2_filtered<=q2_link;
		q3_filtered<=q3_link;
	end
	else if ((con_bs_reg==1)&&(bs_link==3'd3||bs_link==3'd2||bs_link==3'd1))begin
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
	if(!rst) begin
		p0_filtered<=0;
		p1_filtered<=0;
		p2_filtered<=0;
		p3_filtered<=0;
		q0_filtered<=0;
		q1_filtered<=0;
		q2_filtered<=0;
		q3_filtered<=0;
	end
	else if((con_bs_reg==1)&&(bs_link==3'd4))begin
		p0_filtered<=p01_s[10:3];
		p1_filtered<=p11_s[9:2];
		p2_filtered<=p21_s[10:3];
		p3_filtered<=p3_link;
		q0_filtered<=q01_s[10:3];
		q1_filtered<=q11_s[9:2];
		q2_filtered<=q21_s[10:3];
		q3_filtered<=q3_link;
	end
	else if ((con_bs_reg==1)&&(bs_link==3'd3||bs_link==3'd2||bs_link==3'd1))begin
		p0_filtered<=p01_w[7:0];
		p1_filtered<=p11_w;
		p2_filtered<=p2_link;
		p3_filtered<=p3_link;
		q0_filtered<=q01_w[7:0];
		q1_filtered<=q11_w;
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



















endmodule