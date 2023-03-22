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
// Filename       : tq_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump TQ in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_TQ

integer fp_tq;
integer fp_tq_in;
integer fp_tq_out;
integer i_tq;

initial begin
	fp_tq  = $fopen("./dump/tq.dat","wb");
    fp_tq_in  = $fopen("./dump/tq_input.dat","wb"); 
    fp_tq_out = $fopen("./dump/tq_output.dat","wb");
end

//--------------------------------------------------------------------------
//	dump TQ variables                                                       
//--------------------------------------------------------------------------
reg  [`BIT_DEPTH-1:0]	tq_y_pre00[0:15], tq_y_pre01[0:15], tq_y_pre02[0:15], tq_y_pre03[0:15], 
						tq_y_pre10[0:15], tq_y_pre11[0:15], tq_y_pre12[0:15], tq_y_pre13[0:15], 
						tq_y_pre20[0:15], tq_y_pre21[0:15], tq_y_pre22[0:15], tq_y_pre23[0:15], 
						tq_y_pre30[0:15], tq_y_pre31[0:15], tq_y_pre32[0:15], tq_y_pre33[0:15]; 

reg  [`BIT_DEPTH-1:0]	tq_y_rec00[0:15], tq_y_rec01[0:15], tq_y_rec02[0:15], tq_y_rec03[0:15], 
						tq_y_rec10[0:15], tq_y_rec11[0:15], tq_y_rec12[0:15], tq_y_rec13[0:15], 
						tq_y_rec20[0:15], tq_y_rec21[0:15], tq_y_rec22[0:15], tq_y_rec23[0:15], 
						tq_y_rec30[0:15], tq_y_rec31[0:15], tq_y_rec32[0:15], tq_y_rec33[0:15]; 

reg  [`BIT_DEPTH  :0]	tq_y_res00[0:15], tq_y_res01[0:15], tq_y_res02[0:15], tq_y_res03[0:15], 
						tq_y_res10[0:15], tq_y_res11[0:15], tq_y_res12[0:15], tq_y_res13[0:15], 
						tq_y_res20[0:15], tq_y_res21[0:15], tq_y_res22[0:15], tq_y_res23[0:15], 
						tq_y_res30[0:15], tq_y_res31[0:15], tq_y_res32[0:15], tq_y_res33[0:15]; 

reg  [`BIT_DEPTH-1:0]	tq_u_pre00[0:3], tq_u_pre01[0:3], tq_u_pre02[0:3], tq_u_pre03[0:3], 
						tq_u_pre10[0:3], tq_u_pre11[0:3], tq_u_pre12[0:3], tq_u_pre13[0:3], 
						tq_u_pre20[0:3], tq_u_pre21[0:3], tq_u_pre22[0:3], tq_u_pre23[0:3], 
						tq_u_pre30[0:3], tq_u_pre31[0:3], tq_u_pre32[0:3], tq_u_pre33[0:3]; 
                                
reg  [`BIT_DEPTH-1:0]	tq_u_rec00[0:3], tq_u_rec01[0:3], tq_u_rec02[0:3], tq_u_rec03[0:3], 
						tq_u_rec10[0:3], tq_u_rec11[0:3], tq_u_rec12[0:3], tq_u_rec13[0:3], 
						tq_u_rec20[0:3], tq_u_rec21[0:3], tq_u_rec22[0:3], tq_u_rec23[0:3], 
						tq_u_rec30[0:3], tq_u_rec31[0:3], tq_u_rec32[0:3], tq_u_rec33[0:3]; 
                                                
reg  [`BIT_DEPTH  :0]	tq_u_res00[0:3], tq_u_res01[0:3], tq_u_res02[0:3], tq_u_res03[0:3], 
						tq_u_res10[0:3], tq_u_res11[0:3], tq_u_res12[0:3], tq_u_res13[0:3], 
						tq_u_res20[0:3], tq_u_res21[0:3], tq_u_res22[0:3], tq_u_res23[0:3], 
						tq_u_res30[0:3], tq_u_res31[0:3], tq_u_res32[0:3], tq_u_res33[0:3];

reg  [`BIT_DEPTH-1:0]	tq_v_pre00[0:3], tq_v_pre01[0:3], tq_v_pre02[0:3], tq_v_pre03[0:3], 
						tq_v_pre10[0:3], tq_v_pre11[0:3], tq_v_pre12[0:3], tq_v_pre13[0:3], 
						tq_v_pre20[0:3], tq_v_pre21[0:3], tq_v_pre22[0:3], tq_v_pre23[0:3], 
						tq_v_pre30[0:3], tq_v_pre31[0:3], tq_v_pre32[0:3], tq_v_pre33[0:3]; 
              
reg  [`BIT_DEPTH-1:0]	tq_v_rec00[0:3], tq_v_rec01[0:3], tq_v_rec02[0:3], tq_v_rec03[0:3], 
						tq_v_rec10[0:3], tq_v_rec11[0:3], tq_v_rec12[0:3], tq_v_rec13[0:3], 
						tq_v_rec20[0:3], tq_v_rec21[0:3], tq_v_rec22[0:3], tq_v_rec23[0:3], 
						tq_v_rec30[0:3], tq_v_rec31[0:3], tq_v_rec32[0:3], tq_v_rec33[0:3]; 
                           
reg  [`BIT_DEPTH  :0]	tq_v_res00[0:3], tq_v_res01[0:3], tq_v_res02[0:3], tq_v_res03[0:3], 
						tq_v_res10[0:3], tq_v_res11[0:3], tq_v_res12[0:3], tq_v_res13[0:3], 
						tq_v_res20[0:3], tq_v_res21[0:3], tq_v_res22[0:3], tq_v_res23[0:3], 
						tq_v_res30[0:3], tq_v_res31[0:3], tq_v_res32[0:3], tq_v_res33[0:3];

always @(posedge clk) begin
	if (tb_top.u_top.u_tq_top.p16x16_en_i) begin
		tq_y_pre00[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre00;
		tq_y_pre10[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre10;
		tq_y_pre20[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre20;
		tq_y_pre30[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre30;
		tq_y_pre01[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre01;  
		tq_y_pre11[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre11;  
		tq_y_pre21[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre21;  
		tq_y_pre31[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre31;  
		tq_y_pre02[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre02;
		tq_y_pre12[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre12;
		tq_y_pre22[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre22;
		tq_y_pre32[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre32;
		tq_y_pre03[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre03;
		tq_y_pre13[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre13;
		tq_y_pre23[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre23;
		tq_y_pre33[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.pre33;
		                                                
		tq_y_res00[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res00;
		tq_y_res10[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res10;
		tq_y_res20[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res20;
		tq_y_res30[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res30;
		tq_y_res01[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res01;
		tq_y_res11[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res11;
		tq_y_res21[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res21;
		tq_y_res31[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res31;
		tq_y_res02[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res02;
		tq_y_res12[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res12;
		tq_y_res22[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res22;
		tq_y_res32[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res32;
		tq_y_res03[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res03;
		tq_y_res13[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res13;
		tq_y_res23[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res23;
		tq_y_res33[tb_top.u_top.u_tq_top.p16x16_num_i] <= tb_top.u_top.u_tq_top.res33;
	end
	
	if (tb_top.u_top.u_tq_top.p16x16_val_o) begin
		tq_y_rec00[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec00;
		tq_y_rec10[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec10;
		tq_y_rec20[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec20;
		tq_y_rec30[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec30;
		tq_y_rec01[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec01;
		tq_y_rec11[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec11;
		tq_y_rec21[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec21;
		tq_y_rec31[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec31;
		tq_y_rec02[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec02;
		tq_y_rec12[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec12;
		tq_y_rec22[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec22;
		tq_y_rec32[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec32;
		tq_y_rec03[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec03;
		tq_y_rec13[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec13;
		tq_y_rec23[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec23;
		tq_y_rec33[tb_top.u_top.u_tq_top.p16x16_num_o] <= tb_top.u_top.u_tq_top.rec33;
	end
	
	if (tb_top.u_top.u_tq_top.chroma_en_i) begin
		if (tb_top.u_top.u_tq_top.chroma_num_i[2:0]<'d4) begin
			tq_u_pre00[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre00;
			tq_u_pre10[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre10;
			tq_u_pre20[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre20;
			tq_u_pre30[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre30;
			tq_u_pre01[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre01;  
			tq_u_pre11[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre11;  
			tq_u_pre21[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre21;  
			tq_u_pre31[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre31;  
			tq_u_pre02[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre02;
			tq_u_pre12[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre12;
			tq_u_pre22[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre22;
			tq_u_pre32[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre32;
			tq_u_pre03[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre03;
			tq_u_pre13[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre13;
			tq_u_pre23[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre23;
			tq_u_pre33[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre33;
			                                                
			tq_u_res00[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res00;
			tq_u_res10[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res10;
			tq_u_res20[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res20;
			tq_u_res30[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res30;
			tq_u_res01[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res01;
			tq_u_res11[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res11;
			tq_u_res21[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res21;
			tq_u_res31[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res31;
			tq_u_res02[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res02;
			tq_u_res12[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res12;
			tq_u_res22[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res22;
			tq_u_res32[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res32;
			tq_u_res03[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res03;
			tq_u_res13[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res13;
			tq_u_res23[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res23;
			tq_u_res33[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res33;
		end
		else begin
			tq_v_pre00[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre00;
			tq_v_pre10[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre10;
			tq_v_pre20[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre20;
			tq_v_pre30[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre30;
			tq_v_pre01[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre01;  
			tq_v_pre11[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre11;  
			tq_v_pre21[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre21;  
			tq_v_pre31[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre31;  
			tq_v_pre02[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre02;
			tq_v_pre12[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre12;
			tq_v_pre22[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre22;
			tq_v_pre32[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre32;
			tq_v_pre03[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre03;
			tq_v_pre13[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre13;
			tq_v_pre23[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre23;
			tq_v_pre33[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.pre33;
			                                                
			tq_v_res00[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res00;
			tq_v_res10[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res10;
			tq_v_res20[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res20;
			tq_v_res30[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res30;
			tq_v_res01[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res01;
			tq_v_res11[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res11;
			tq_v_res21[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res21;
			tq_v_res31[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res31;
			tq_v_res02[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res02;
			tq_v_res12[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res12;
			tq_v_res22[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res22;
			tq_v_res32[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res32;
			tq_v_res03[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res03;
			tq_v_res13[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res13;
			tq_v_res23[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res23;
			tq_v_res33[tb_top.u_top.u_tq_top.chroma_num_i[1:0]] <= tb_top.u_top.u_tq_top.res33;
		end
	end	
	
	if (tb_top.u_top.u_tq_top.cb_val_o) begin
		tq_u_rec00[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec00;
		tq_u_rec10[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec10;
		tq_u_rec20[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec20;
		tq_u_rec30[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec30;
		tq_u_rec01[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec01;
		tq_u_rec11[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec11;
		tq_u_rec21[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec21;
		tq_u_rec31[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec31;
		tq_u_rec02[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec02;
		tq_u_rec12[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec12;
		tq_u_rec22[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec22;
		tq_u_rec32[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec32;
		tq_u_rec03[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec03;
		tq_u_rec13[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec13;
		tq_u_rec23[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec23;
		tq_u_rec33[tb_top.u_top.u_tq_top.cb_num_o] <= tb_top.u_top.u_tq_top.rec33;		
	end
	
	if (tb_top.u_top.u_tq_top.cr_val_o) begin
		tq_v_rec00[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec00;
		tq_v_rec10[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec10;
		tq_v_rec20[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec20;
		tq_v_rec30[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec30;
		tq_v_rec01[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec01;
		tq_v_rec11[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec11;
		tq_v_rec21[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec21;
		tq_v_rec31[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec31;
		tq_v_rec02[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec02;
		tq_v_rec12[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec12;
		tq_v_rec22[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec22;
		tq_v_rec32[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec32;
		tq_v_rec03[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec03;
		tq_v_rec13[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec13;
		tq_v_rec23[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec23;
		tq_v_rec33[tb_top.u_top.u_tq_top.cr_num_o] <= tb_top.u_top.u_tq_top.rec33;	
	end	
end

// dump inter frame tq
always @(posedge clk) begin
	if (tb_top.u_top.u_top_ctrl.mc_done_i) begin		
		$fdisplay(fp_tq,"===== Frame: %d  MB x: %d  y: %d =====", tb_top.frame_num,
																	tb_top.u_top.u_mc.sysif_cmb_x_i[7:0],
																	tb_top.u_top.u_mc.sysif_cmb_y_i[7:0]);							
		// print y_pre
		$fdisplay(fp_tq, "$y_pre");
		for (i_tq=0; i_tq<16; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq, 
									tq_y_pre00[i_tq], tq_y_pre01[i_tq], tq_y_pre02[i_tq], tq_y_pre03[i_tq],
		                        	tq_y_pre10[i_tq], tq_y_pre11[i_tq], tq_y_pre12[i_tq], tq_y_pre13[i_tq],
		                        	tq_y_pre20[i_tq], tq_y_pre21[i_tq], tq_y_pre22[i_tq], tq_y_pre23[i_tq],
		                        	tq_y_pre30[i_tq], tq_y_pre31[i_tq], tq_y_pre32[i_tq], tq_y_pre33[i_tq]);		
		end
		// print y_res
		$fdisplay(fp_tq, "$y_res");
		for (i_tq=0; i_tq<16; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq,
									tq_y_res00[i_tq], tq_y_res01[i_tq], tq_y_res02[i_tq], tq_y_res03[i_tq],
		                        	tq_y_res10[i_tq], tq_y_res11[i_tq], tq_y_res12[i_tq], tq_y_res13[i_tq],
		                        	tq_y_res20[i_tq], tq_y_res21[i_tq], tq_y_res22[i_tq], tq_y_res23[i_tq],
		                        	tq_y_res30[i_tq], tq_y_res31[i_tq], tq_y_res32[i_tq], tq_y_res33[i_tq]);		
		end
		// print y_rec
		$fdisplay(fp_tq, "$y_rec");
		for (i_tq=0; i_tq<16; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq,
									tq_y_rec00[i_tq], tq_y_rec01[i_tq], tq_y_rec02[i_tq], tq_y_rec03[i_tq],
		                        	tq_y_rec10[i_tq], tq_y_rec11[i_tq], tq_y_rec12[i_tq], tq_y_rec13[i_tq],
		                        	tq_y_rec20[i_tq], tq_y_rec21[i_tq], tq_y_rec22[i_tq], tq_y_rec23[i_tq],
		                        	tq_y_rec30[i_tq], tq_y_rec31[i_tq], tq_y_rec32[i_tq], tq_y_rec33[i_tq]);		
		end
		// print u_pre
		$fdisplay(fp_tq, "$u_pre");
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq, 
									tq_u_pre00[i_tq], tq_u_pre01[i_tq], tq_u_pre02[i_tq], tq_u_pre03[i_tq],
		                        	tq_u_pre10[i_tq], tq_u_pre11[i_tq], tq_u_pre12[i_tq], tq_u_pre13[i_tq],
		                        	tq_u_pre20[i_tq], tq_u_pre21[i_tq], tq_u_pre22[i_tq], tq_u_pre23[i_tq],
		                        	tq_u_pre30[i_tq], tq_u_pre31[i_tq], tq_u_pre32[i_tq], tq_u_pre33[i_tq]);		
		end
		// print y_res
		$fdisplay(fp_tq, "$u_res");
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq,
									tq_u_res00[i_tq], tq_u_res01[i_tq], tq_u_res02[i_tq], tq_u_res03[i_tq],
		                        	tq_u_res10[i_tq], tq_u_res11[i_tq], tq_u_res12[i_tq], tq_u_res13[i_tq],
		                        	tq_u_res20[i_tq], tq_u_res21[i_tq], tq_u_res22[i_tq], tq_u_res23[i_tq],
		                        	tq_u_res30[i_tq], tq_u_res31[i_tq], tq_u_res32[i_tq], tq_u_res33[i_tq]);		
		end
		// print y_rec
		$fdisplay(fp_tq, "$u_rec");
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq,
									tq_u_rec00[i_tq], tq_u_rec01[i_tq], tq_u_rec02[i_tq], tq_u_rec03[i_tq],
		                        	tq_u_rec10[i_tq], tq_u_rec11[i_tq], tq_u_rec12[i_tq], tq_u_rec13[i_tq],
		                        	tq_u_rec20[i_tq], tq_u_rec21[i_tq], tq_u_rec22[i_tq], tq_u_rec23[i_tq],
		                        	tq_u_rec30[i_tq], tq_u_rec31[i_tq], tq_u_rec32[i_tq], tq_u_rec33[i_tq]);		
		end
		// print v_pre
		$fdisplay(fp_tq, "$v_pre");
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq, 
									tq_v_pre00[i_tq], tq_v_pre01[i_tq], tq_v_pre02[i_tq], tq_v_pre03[i_tq],
		                        	tq_v_pre10[i_tq], tq_v_pre11[i_tq], tq_v_pre12[i_tq], tq_v_pre13[i_tq],
		                        	tq_v_pre20[i_tq], tq_v_pre21[i_tq], tq_v_pre22[i_tq], tq_v_pre23[i_tq],
		                        	tq_v_pre30[i_tq], tq_v_pre31[i_tq], tq_v_pre32[i_tq], tq_v_pre33[i_tq]);		
		end
		// print v_res
		$fdisplay(fp_tq, "$v_res");
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq,
									tq_v_res00[i_tq], tq_v_res01[i_tq], tq_v_res02[i_tq], tq_v_res03[i_tq],
		                        	tq_v_res10[i_tq], tq_v_res11[i_tq], tq_v_res12[i_tq], tq_v_res13[i_tq],
		                        	tq_v_res20[i_tq], tq_v_res21[i_tq], tq_v_res22[i_tq], tq_v_res23[i_tq],
		                        	tq_v_res30[i_tq], tq_v_res31[i_tq], tq_v_res32[i_tq], tq_v_res33[i_tq]);		
		end
		// print v_rec
		$fdisplay(fp_tq, "$v_rec");
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq, "%2d: %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", i_tq,
									tq_v_rec00[i_tq], tq_v_rec01[i_tq], tq_v_rec02[i_tq], tq_v_rec03[i_tq],
		                        	tq_v_rec10[i_tq], tq_v_rec11[i_tq], tq_v_rec12[i_tq], tq_v_rec13[i_tq],
		                        	tq_v_rec20[i_tq], tq_v_rec21[i_tq], tq_v_rec22[i_tq], tq_v_rec23[i_tq],
		                        	tq_v_rec30[i_tq], tq_v_rec31[i_tq], tq_v_rec32[i_tq], tq_v_rec33[i_tq]);		
		end
	end
end

//--------------------------------------------------------------------------
//	dump TQ outputs for data check                                       
//--------------------------------------------------------------------------
// dump inter frame tq
always @(posedge tb_top.u_top.u_top_ctrl.mc_done_i /*or posedge tb_top.u_top.u_top_ctrl.intra_done_i*/) begin
	if (tb_top.u_top.sys_intra_flag) 
		$fwrite(fp_tq_out,"===== Frame: %d  MB x: %d  y: %d =====\n", 	tb_top.frame_num, 
																	tb_top.u_top.u_intra_top.mb_x, 
																	tb_top.u_top.u_intra_top.mb_y);
	else 
		$fwrite(fp_tq_out,"===== Frame: %d  MB x: %d  y: %d =====\n", 	tb_top.frame_num, 
																	tb_top.u_top.u_mc.sysif_cmb_x_i, 
																	tb_top.u_top.u_mc.sysif_cmb_y_i);										
	
	// dump non_zero
	$fwrite(fp_tq_out,"$non_zero_luma  : %h \n", tb_top.u_top.u_tq_top.non_zero_flag4x4[15:0]);
	$fwrite(fp_tq_out,"$non_zero_cb    : %h \n", tb_top.u_top.u_tq_top.non_zero_flag_cb[3:0]);
	$fwrite(fp_tq_out,"$non_zero_cr    : %h \n", tb_top.u_top.u_tq_top.non_zero_flag_cr[3:0]);
	
	// dump cbp
	$fwrite(fp_tq_out,"$cbp_luma       : %h \n", tb_top.u_top.u_tq_top.cbp_luma[3:0]);
	$fwrite(fp_tq_out,"$cbp_chroma     : %h \n", tb_top.u_top.u_tq_top.cbp_chroma[1:0]);
	
	// dump luma ac(address: 0~15), chroma ac(address: 16~23)
	$fwrite(fp_tq_out,"$ac/dc \n");
	for (i_tq=0; i_tq<32; i_tq=i_tq+1) begin	
		$fwrite(fp_tq_out, "%2d: %h \n", i_tq, tb_top.u_top.u_tq_top.u_coeff_ram_256x64.ram_2p_256x64.mem_array[tb_top.u_top.u_tq_top.mem_sel*32+i_tq]);
	end
	
	// dump luma ac(address: 0~15), chroma ac(address: 16~23)
	$fwrite(fp_tq_out,"$rec \n");
	for (i_tq=0; i_tq<24; i_tq=i_tq+1) begin
		if (tb_top.u_top.u_tq_top.mem_sel)
			$fwrite(fp_tq_out, "%2d: %h \n", i_tq, tb_top.u_top.u_tq_top.u_rec_ram_128x24_0.rf_2p_128x24.mem_array[i_tq]);
		else
			$fwrite(fp_tq_out, "%2d: %h \n", i_tq, tb_top.u_top.u_tq_top.u_rec_ram_128x24_1.rf_2p_128x24.mem_array[i_tq]);
	end
end

//--------------------------------------------------------------------------
//	dump TQ all inputs for tb_intra                                      
//--------------------------------------------------------------------------  
// dump inter frame tq
always @(posedge clk) begin
	if (tb_top.u_top.u_top_ctrl.mc_done_i) begin
		$fdisplay(fp_tq_in,"%h", tb_top.u_top.u_mc.sysif_cmb_x_i);
		$fdisplay(fp_tq_in,"%h", tb_top.u_top.u_mc.sysif_cmb_y_i);
		$fdisplay(fp_tq_in,"%h", tb_top.u_top.u_tq_top.qp[5:0]);
		// print y_pre
		for (i_tq=0; i_tq<16; i_tq=i_tq+1) begin
			$fdisplay(fp_tq_in, "%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h", 
									tq_y_pre00[i_tq], tq_y_pre01[i_tq], tq_y_pre02[i_tq], tq_y_pre03[i_tq],
		                        	tq_y_pre10[i_tq], tq_y_pre11[i_tq], tq_y_pre12[i_tq], tq_y_pre13[i_tq],
		                        	tq_y_pre20[i_tq], tq_y_pre21[i_tq], tq_y_pre22[i_tq], tq_y_pre23[i_tq],
		                        	tq_y_pre30[i_tq], tq_y_pre31[i_tq], tq_y_pre32[i_tq], tq_y_pre33[i_tq]);		
		end
		// print y_res
		for (i_tq=0; i_tq<16; i_tq=i_tq+1) begin
			$fdisplay(fp_tq_in, "%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h",
									tq_y_res00[i_tq], tq_y_res01[i_tq], tq_y_res02[i_tq], tq_y_res03[i_tq],
		                        	tq_y_res10[i_tq], tq_y_res11[i_tq], tq_y_res12[i_tq], tq_y_res13[i_tq],
		                        	tq_y_res20[i_tq], tq_y_res21[i_tq], tq_y_res22[i_tq], tq_y_res23[i_tq],
		                        	tq_y_res30[i_tq], tq_y_res31[i_tq], tq_y_res32[i_tq], tq_y_res33[i_tq]);		
		end
		
		// print u_pre
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq_in, "%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h",
									tq_u_pre00[i_tq], tq_u_pre01[i_tq], tq_u_pre02[i_tq], tq_u_pre03[i_tq],
		                        	tq_u_pre10[i_tq], tq_u_pre11[i_tq], tq_u_pre12[i_tq], tq_u_pre13[i_tq],
		                        	tq_u_pre20[i_tq], tq_u_pre21[i_tq], tq_u_pre22[i_tq], tq_u_pre23[i_tq],
		                        	tq_u_pre30[i_tq], tq_u_pre31[i_tq], tq_u_pre32[i_tq], tq_u_pre33[i_tq]);		
		end
		// print u_res
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq_in, "%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h",
									tq_u_res00[i_tq], tq_u_res01[i_tq], tq_u_res02[i_tq], tq_u_res03[i_tq],
		                        	tq_u_res10[i_tq], tq_u_res11[i_tq], tq_u_res12[i_tq], tq_u_res13[i_tq],
		                        	tq_u_res20[i_tq], tq_u_res21[i_tq], tq_u_res22[i_tq], tq_u_res23[i_tq],
		                        	tq_u_res30[i_tq], tq_u_res31[i_tq], tq_u_res32[i_tq], tq_u_res33[i_tq]);		
		end
		
		// print v_pre
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq_in, "%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h", 
									tq_v_pre00[i_tq], tq_v_pre01[i_tq], tq_v_pre02[i_tq], tq_v_pre03[i_tq],
		                        	tq_v_pre10[i_tq], tq_v_pre11[i_tq], tq_v_pre12[i_tq], tq_v_pre13[i_tq],
		                        	tq_v_pre20[i_tq], tq_v_pre21[i_tq], tq_v_pre22[i_tq], tq_v_pre23[i_tq],
		                        	tq_v_pre30[i_tq], tq_v_pre31[i_tq], tq_v_pre32[i_tq], tq_v_pre33[i_tq]);		
		end
		// print v_res
		for (i_tq=0; i_tq<4; i_tq=i_tq+1) begin
			$fdisplay(fp_tq_in, "%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h\n%h",
									tq_v_res00[i_tq], tq_v_res01[i_tq], tq_v_res02[i_tq], tq_v_res03[i_tq],
		                        	tq_v_res10[i_tq], tq_v_res11[i_tq], tq_v_res12[i_tq], tq_v_res13[i_tq],
		                        	tq_v_res20[i_tq], tq_v_res21[i_tq], tq_v_res22[i_tq], tq_v_res23[i_tq],
		                        	tq_v_res30[i_tq], tq_v_res31[i_tq], tq_v_res32[i_tq], tq_v_res33[i_tq]);		
		end
	end
end

`endif
