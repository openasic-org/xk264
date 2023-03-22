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
// Filename       : db_filter.v
// Author         : shen weiwei
// Created        : 2012-05-05
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
//------------------------------------------------------------------- 

module db_filter ( clk,
					 rst, 
					 
					 bs_luma,
					 bs_chroma_1, 
					 bs_chroma_2, 
					 
                     qp1_i, qp2_i,
					 select,
					 
					 p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i,
                     p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i,
                     p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i,
                     p3_4_i, p2_4_i, p1_4_i, p0_4_i, q0_4_i, q1_4_i, q2_4_i, q3_4_i,
					 
					 p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o,
                     p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o,
                     p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o,
                     p3_4_o, p2_4_o, p1_4_o, p0_4_o, q0_4_o, q1_4_o, q2_4_o, q3_4_o
                    
                    );
					  
input clk;
input rst;

input [2:0] bs_luma;
input [2:0] bs_chroma_1;
input [2:0] bs_chroma_2;

input [5:0] qp1_i, qp2_i;
input select;                 //0 for luma, 1 for chroma

input [7:0] p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i;
input [7:0] p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i;
input [7:0] p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i;
input [7:0] p3_4_i, p2_4_i, p1_4_i, p0_4_i, q0_4_i, q1_4_i, q2_4_i, q3_4_i;
					  
output [7:0] p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o;
output [7:0] p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o;
output [7:0] p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o;
output [7:0] p3_4_o, p2_4_o, p1_4_o, p0_4_o, q0_4_o, q1_4_o, q2_4_o, q3_4_o;


wire [7:0] p3_filtered_l1, p2_filtered_l1, p1_filtered_l1, p0_filtered_l1, q0_filtered_l1, q1_filtered_l1, q2_filtered_l1, q3_filtered_l1;
wire [7:0] p3_filtered_l2, p2_filtered_l2, p1_filtered_l2, p0_filtered_l2, q0_filtered_l2, q1_filtered_l2, q2_filtered_l2, q3_filtered_l2;
wire [7:0] p3_filtered_l3, p2_filtered_l3, p1_filtered_l3, p0_filtered_l3, q0_filtered_l3, q1_filtered_l3, q2_filtered_l3, q3_filtered_l3;
wire [7:0] p3_filtered_l4, p2_filtered_l4, p1_filtered_l4, p0_filtered_l4, q0_filtered_l4, q1_filtered_l4, q2_filtered_l4, q3_filtered_l4;

luma_pipeline luma1 ( .clk(clk), 
					  .rst(rst), 
					  .bs(bs_luma), 
                      .qp1_i(qp1_i), .qp2_i(qp2_i),
                      .p0_i(p0_1_i), .p1_i(p1_1_i), .p2_i(p2_1_i), .p3_i(p3_1_i), 
					  .q0_i(q0_1_i), .q1_i(q1_1_i), .q2_i(q2_1_i), .q3_i(q3_1_i), 
                      .p0_filtered(p0_filtered_l1), .p1_filtered(p1_filtered_l1), .p2_filtered(p2_filtered_l1), .p3_filtered(p3_filtered_l1), 
					  .q0_filtered(q0_filtered_l1), .q1_filtered(q1_filtered_l1), .q2_filtered(q2_filtered_l1), .q3_filtered(q3_filtered_l1)
                     );

luma_pipeline luma2 ( .clk(clk), 
					  .rst(rst), 
					  .bs(bs_luma), 
                      .qp1_i(qp1_i), .qp2_i(qp2_i),
                      .p0_i(p0_2_i), .p1_i(p1_2_i), .p2_i(p2_2_i), .p3_i(p3_2_i), 
					  .q0_i(q0_2_i), .q1_i(q1_2_i), .q2_i(q2_2_i), .q3_i(q3_2_i), 
                      .p0_filtered(p0_filtered_l2), .p1_filtered(p1_filtered_l2), .p2_filtered(p2_filtered_l2), .p3_filtered(p3_filtered_l2), 
					  .q0_filtered(q0_filtered_l2), .q1_filtered(q1_filtered_l2), .q2_filtered(q2_filtered_l2), .q3_filtered(q3_filtered_l2)
                     );

luma_pipeline luma3 ( .clk(clk), 
					  .rst(rst), 
					  .bs(bs_luma), 
                      .qp1_i(qp1_i), .qp2_i(qp2_i),
                      .p0_i(p0_3_i), .p1_i(p1_3_i), .p2_i(p2_3_i), .p3_i(p3_3_i), 
					  .q0_i(q0_3_i), .q1_i(q1_3_i), .q2_i(q2_3_i), .q3_i(q3_3_i), 
                      .p0_filtered(p0_filtered_l3), .p1_filtered(p1_filtered_l3), .p2_filtered(p2_filtered_l3), .p3_filtered(p3_filtered_l3), 
					  .q0_filtered(q0_filtered_l3), .q1_filtered(q1_filtered_l3), .q2_filtered(q2_filtered_l3), .q3_filtered(q3_filtered_l3)
                     );

luma_pipeline luma4 ( .clk(clk), 
					  .rst(rst), 
					  .bs(bs_luma), 
                      .qp1_i(qp1_i), .qp2_i(qp2_i),
                      .p0_i(p0_4_i), .p1_i(p1_4_i), .p2_i(p2_4_i), .p3_i(p3_4_i), 
					  .q0_i(q0_4_i), .q1_i(q1_4_i), .q2_i(q2_4_i), .q3_i(q3_4_i), 
                      .p0_filtered(p0_filtered_l4), .p1_filtered(p1_filtered_l4), .p2_filtered(p2_filtered_l4), .p3_filtered(p3_filtered_l4), 
					  .q0_filtered(q0_filtered_l4), .q1_filtered(q1_filtered_l4), .q2_filtered(q2_filtered_l4), .q3_filtered(q3_filtered_l4)
                     );

					 
					 
wire [7:0] p3_filtered_c1, p2_filtered_c1, p1_filtered_c1, p0_filtered_c1, q0_filtered_c1, q1_filtered_c1, q2_filtered_c1, q3_filtered_c1;
wire [7:0] p3_filtered_c2, p2_filtered_c2, p1_filtered_c2, p0_filtered_c2, q0_filtered_c2, q1_filtered_c2, q2_filtered_c2, q3_filtered_c2;
wire [7:0] p3_filtered_c3, p2_filtered_c3, p1_filtered_c3, p0_filtered_c3, q0_filtered_c3, q1_filtered_c3, q2_filtered_c3, q3_filtered_c3;
wire [7:0] p3_filtered_c4, p2_filtered_c4, p1_filtered_c4, p0_filtered_c4, q0_filtered_c4, q1_filtered_c4, q2_filtered_c4, q3_filtered_c4;


chroma_pipeline chroma1 ( .clk(clk), 
						  .rst(rst), 
                          .bs(bs_chroma_1), 
                          .qp1_i(qp1_i), .qp2_i(qp2_i),
                          .p0_i(p0_1_i), .p1_i(p1_1_i), .p2_i(p2_1_i), .p3_i(p3_1_i),
						  .q0_i(q0_1_i), .q1_i(q1_1_i), .q2_i(q2_1_i), .q3_i(q3_1_i),
                          .p0_filtered(p0_filtered_c1), .p1_filtered(p1_filtered_c1), .p2_filtered(p2_filtered_c1), .p3_filtered(p3_filtered_c1), 
                          .q0_filtered(q0_filtered_c1), .q1_filtered(q1_filtered_c1), .q2_filtered(q2_filtered_c1), .q3_filtered(q3_filtered_c1)
						 );

chroma_pipeline chroma2 ( .clk(clk), 
						  .rst(rst), 
                          .bs(bs_chroma_1), 
                          .qp1_i(qp1_i), .qp2_i(qp2_i),
                          .p0_i(p0_2_i), .p1_i(p1_2_i), .p2_i(p2_2_i), .p3_i(p3_2_i),
						  .q0_i(q0_2_i), .q1_i(q1_2_i), .q2_i(q2_2_i), .q3_i(q3_2_i),
                          .p0_filtered(p0_filtered_c2), .p1_filtered(p1_filtered_c2), .p2_filtered(p2_filtered_c2), .p3_filtered(p3_filtered_c2), 
                          .q0_filtered(q0_filtered_c2), .q1_filtered(q1_filtered_c2), .q2_filtered(q2_filtered_c2), .q3_filtered(q3_filtered_c2)
						 );

chroma_pipeline chroma3 ( .clk(clk), 
						  .rst(rst), 
                          .bs(bs_chroma_2), 
                          .qp1_i(qp1_i), .qp2_i(qp2_i),
                          .p0_i(p0_3_i), .p1_i(p1_3_i), .p2_i(p2_3_i), .p3_i(p3_3_i),
						  .q0_i(q0_3_i), .q1_i(q1_3_i), .q2_i(q2_3_i), .q3_i(q3_3_i),
                          .p0_filtered(p0_filtered_c3), .p1_filtered(p1_filtered_c3), .p2_filtered(p2_filtered_c3), .p3_filtered(p3_filtered_c3), 
                          .q0_filtered(q0_filtered_c3), .q1_filtered(q1_filtered_c3), .q2_filtered(q2_filtered_c3), .q3_filtered(q3_filtered_c3)
						 );

chroma_pipeline chroma4 ( .clk(clk), 
						  .rst(rst), 
                          .bs(bs_chroma_2), 
                          .qp1_i(qp1_i), .qp2_i(qp2_i),
                          .p0_i(p0_4_i), .p1_i(p1_4_i), .p2_i(p2_4_i), .p3_i(p3_4_i),
						  .q0_i(q0_4_i), .q1_i(q1_4_i), .q2_i(q2_4_i), .q3_i(q3_4_i),
                          .p0_filtered(p0_filtered_c4), .p1_filtered(p1_filtered_c4), .p2_filtered(p2_filtered_c4), .p3_filtered(p3_filtered_c4), 
                          .q0_filtered(q0_filtered_c4), .q1_filtered(q1_filtered_c4), .q2_filtered(q2_filtered_c4), .q3_filtered(q3_filtered_c4)
						 );

						 
						 
reg [7:0] p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o;
reg [7:0] p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o;
reg [7:0] p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o;
reg [7:0] p3_4_o, p2_4_o, p1_4_o, p0_4_o, q0_4_o, q1_4_o, q2_4_o, q3_4_o;						 

always@(*)begin
	case(select)
		1'b0:begin
			p3_1_o <= p3_filtered_l1; p2_1_o <= p2_filtered_l1; p1_1_o <= p1_filtered_l1; p0_1_o <= p0_filtered_l1; 
			p3_2_o <= p3_filtered_l2; p2_2_o <= p2_filtered_l2; p1_2_o <= p1_filtered_l2; p0_2_o <= p0_filtered_l2; 
			p3_3_o <= p3_filtered_l3; p2_3_o <= p2_filtered_l3; p1_3_o <= p1_filtered_l3; p0_3_o <= p0_filtered_l3; 
			p3_4_o <= p3_filtered_l4; p2_4_o <= p2_filtered_l4; p1_4_o <= p1_filtered_l4; p0_4_o <= p0_filtered_l4; 
			
			q0_1_o <= q0_filtered_l1; q1_1_o <= q1_filtered_l1; q2_1_o <= q2_filtered_l1; q3_1_o <= q3_filtered_l1; 
			q0_2_o <= q0_filtered_l2; q1_2_o <= q1_filtered_l2; q2_2_o <= q2_filtered_l2; q3_2_o <= q3_filtered_l2; 
			q0_3_o <= q0_filtered_l3; q1_3_o <= q1_filtered_l3; q2_3_o <= q2_filtered_l3; q3_3_o <= q3_filtered_l3; 
			q0_4_o <= q0_filtered_l4; q1_4_o <= q1_filtered_l4; q2_4_o <= q2_filtered_l4; q3_4_o <= q3_filtered_l4; 			
		end
		1'b1:begin
			p3_1_o <= p3_filtered_c1; p2_1_o <= p2_filtered_c1; p1_1_o <= p1_filtered_c1; p0_1_o <= p0_filtered_c1; 
			p3_2_o <= p3_filtered_c2; p2_2_o <= p2_filtered_c2; p1_2_o <= p1_filtered_c2; p0_2_o <= p0_filtered_c2; 
			p3_3_o <= p3_filtered_c3; p2_3_o <= p2_filtered_c3; p1_3_o <= p1_filtered_c3; p0_3_o <= p0_filtered_c3; 
			p3_4_o <= p3_filtered_c4; p2_4_o <= p2_filtered_c4; p1_4_o <= p1_filtered_c4; p0_4_o <= p0_filtered_c4;
			
			q0_1_o <= q0_filtered_c1; q1_1_o <= q1_filtered_c1; q2_1_o <= q2_filtered_c1; q3_1_o <= q3_filtered_c1;
			q0_2_o <= q0_filtered_c2; q1_2_o <= q1_filtered_c2; q2_2_o <= q2_filtered_c2; q3_2_o <= q3_filtered_c2;
			q0_3_o <= q0_filtered_c3; q1_3_o <= q1_filtered_c3; q2_3_o <= q2_filtered_c3; q3_3_o <= q3_filtered_c3;
			q0_4_o <= q0_filtered_c4; q1_4_o <= q1_filtered_c4; q2_4_o <= q2_filtered_c4; q3_4_o <= q3_filtered_c4;
		end 
	endcase
end
	

	
					  
endmodule
