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
// Filename       : mc_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump mc in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_MC

integer fp_mc;
integer fp_mc_in;
integer fp_mc_out;
integer i_mc;

initial begin
	fp_mc  	  = $fopen("./dump/mc.dat","wb");
	fp_mc_in  = $fopen("./dump/mc_input.dat","wb"); 
    fp_mc_out = $fopen("./dump/mc_output.dat","wb");
end

//--------------------------------------------------------------------------
//	dump MC variables                                                       
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_mc.sysif_start_mc_i) begin
		$fdisplay(fp_mc,"===== Frame: %d  MB x: %d  y: %d =====", tb_top.frame_num, 
																tb_top.u_top.u_mc.sysif_cmb_x_i[7:0], 
																tb_top.u_top.u_mc.sysif_cmb_y_i[7:0]);
		$fdisplay(fp_mc, "$qp            : %h", tb_top.u_top.qp_r1[5:0]);          			
		$fdisplay(fp_mc, "$mb_type       : %h", tb_top.u_top.u_mc.fmeif_mb_type_info_i[14:0]);
		$fdisplay(fp_mc, "$fmv           : %h", tb_top.u_top.u_mc.fmeif_fmv_i[255:0]);
		$fdisplay(fp_mc, "$imv           : %h", tb_top.u_top.u_mc.fmeif_imv_i[191:0]);
		#5; // luma/cb/cr not registed in mc, but use it from cur_mb module
		$fdisplay(fp_mc, "$cmb_luma      : %h", tb_top.u_top.u_mc.sysif_cmb_luma_i[2047:0]);
		$fdisplay(fp_mc, "$cmb_cb        : %h", tb_top.u_top.u_mc.sysif_cmb_cb_i[511:0]);
		$fdisplay(fp_mc, "$cmb_cr        : %h", tb_top.u_top.u_mc.sysif_cmb_cr_i[511:0]);		
		
		$fdisplay(fp_mc, "$luma from fme :");		
		for (i_mc=0; i_mc<128; i_mc=i_mc+1'b1) begin
			$fdisplay(fp_mc, "%3d: %h", i_mc, tb_top.u_top.u_fme.fme_ram.u_fme_ram.ram_2p_160x128.mem_array[i_mc]);		
		end
		
		$fdisplay(fp_mc, "$chroma from fetch :");
	 	for (i_mc=0; i_mc<144; i_mc=i_mc+1'b1) begin
			$fdisplay(fp_mc, "%3d: %h", i_mc,
			{tb_top.u_top.u_fetch_chroma.left_bank0.rf_2p_64x144.mem_array[i_mc],
			 tb_top.u_top.u_fetch_chroma.right_bank0.rf_2p_64x144.mem_array[i_mc]});
		end
	end
end

//--------------------------------------------------------------------------
//	dump MC outputs for data check                                       
//--------------------------------------------------------------------------
reg [16*(`BIT_DEPTH-1)-1:0] pre_array[0:23];
reg [16*(`BIT_DEPTH)-1  :0] res_array[0:23];

always @(posedge clk) begin
	if (tb_top.u_top.u_mc.tq_p16x16_en_o) begin
		pre_array[tb_top.u_top.u_mc.tq_p16x16_num_o[3:0]] <=	
								   {tb_top.u_top.u_mc.pre00, 
									tb_top.u_top.u_mc.pre01,
									tb_top.u_top.u_mc.pre02,
									tb_top.u_top.u_mc.pre03,
									tb_top.u_top.u_mc.pre10,
									tb_top.u_top.u_mc.pre11,
									tb_top.u_top.u_mc.pre12,
									tb_top.u_top.u_mc.pre13,
									tb_top.u_top.u_mc.pre20,
									tb_top.u_top.u_mc.pre21,
									tb_top.u_top.u_mc.pre22,
									tb_top.u_top.u_mc.pre23,
									tb_top.u_top.u_mc.pre30,
									tb_top.u_top.u_mc.pre31,
									tb_top.u_top.u_mc.pre32,
									tb_top.u_top.u_mc.pre33
									};
	    res_array[tb_top.u_top.u_mc.tq_p16x16_num_o[3:0]] <=	
	    						   {tb_top.u_top.u_mc.res00, 
									tb_top.u_top.u_mc.res01,
									tb_top.u_top.u_mc.res02,
									tb_top.u_top.u_mc.res03,
									tb_top.u_top.u_mc.res10,
									tb_top.u_top.u_mc.res11,
									tb_top.u_top.u_mc.res12,
									tb_top.u_top.u_mc.res13,
									tb_top.u_top.u_mc.res20,
									tb_top.u_top.u_mc.res21,
									tb_top.u_top.u_mc.res22,
									tb_top.u_top.u_mc.res23,
									tb_top.u_top.u_mc.res30,
									tb_top.u_top.u_mc.res31,
									tb_top.u_top.u_mc.res32,
									tb_top.u_top.u_mc.res33
									};							 
	end
	
	if (tb_top.u_top.u_mc.tq_chroma_en_o) begin
		pre_array[tb_top.u_top.u_mc.tq_chroma_num_o[2:0]+'d16] <=
									{tb_top.u_top.u_mc.pre00, 
									tb_top.u_top.u_mc.pre01,
									tb_top.u_top.u_mc.pre02,
									tb_top.u_top.u_mc.pre03,
									tb_top.u_top.u_mc.pre10,
									tb_top.u_top.u_mc.pre11,
									tb_top.u_top.u_mc.pre12,
									tb_top.u_top.u_mc.pre13,
									tb_top.u_top.u_mc.pre20,
									tb_top.u_top.u_mc.pre21,
									tb_top.u_top.u_mc.pre22,
									tb_top.u_top.u_mc.pre23,
									tb_top.u_top.u_mc.pre30,
									tb_top.u_top.u_mc.pre31,
									tb_top.u_top.u_mc.pre32,
									tb_top.u_top.u_mc.pre33
									};
	    res_array[tb_top.u_top.u_mc.tq_chroma_num_o[2:0]+'d16] <=
	    							{tb_top.u_top.u_mc.res00, 
									tb_top.u_top.u_mc.res01,
									tb_top.u_top.u_mc.res02,
									tb_top.u_top.u_mc.res03,
									tb_top.u_top.u_mc.res10,
									tb_top.u_top.u_mc.res11,
									tb_top.u_top.u_mc.res12,
									tb_top.u_top.u_mc.res13,
									tb_top.u_top.u_mc.res20,
									tb_top.u_top.u_mc.res21,
									tb_top.u_top.u_mc.res22,
									tb_top.u_top.u_mc.res23,
									tb_top.u_top.u_mc.res30,
									tb_top.u_top.u_mc.res31,
									tb_top.u_top.u_mc.res32,
									tb_top.u_top.u_mc.res33
									};							 
	end 
end

always @(posedge clk) begin
	if (tb_top.u_top.u_mc.sysif_done_mc_o) begin
		$fdisplay(fp_mc_out,"===== Frame: %d  MB x: %d  y: %d =====", tb_top.frame_num, 
																tb_top.u_top.u_mc.sysif_cmb_x_i[7:0], 
																tb_top.u_top.u_mc.sysif_cmb_y_i[7:0]);	
		$fdisplay(fp_mc_out, "$ mc pre:");
		for (i_mc = 0; i_mc<'d24; i_mc=i_mc+1'b1) begin 
			$fdisplay(fp_mc_out, "%2d:%h", i_mc, pre_array[i_mc]);
		end
		
		$fdisplay(fp_mc_out, "$ mc res:");
		for (i_mc = 0; i_mc<'d24; i_mc=i_mc+1'b1) begin 
			$fdisplay(fp_mc_out, "%2d:%h", i_mc, res_array[i_mc]);
		end
	end
end

//--------------------------------------------------------------------------
//	dump MC all inputs for tb_intra                                      
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_mc.sysif_start_mc_i) begin
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.sysif_cmb_x_i[7:0]);
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.sysif_cmb_y_i[7:0]);
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.qp_r1[5:0]);		
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.fmeif_mb_type_info_i[14:0]);
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.fmeif_fmv_i[255:0]);
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.fmeif_imv_i[191:0]);
		#5; // luma/cb/cr not registed in mc, but use it from cur_mb module
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.sysif_cmb_luma_i[2047:0]);
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.sysif_cmb_cb_i[511:0]);
		$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_mc.sysif_cmb_cr_i[511:0]);	
			
		for (i_mc=0; i_mc<128; i_mc=i_mc+1'b1) begin
			$fdisplay(fp_mc_in, "%h", tb_top.u_top.u_fme.fme_ram.u_fme_ram.ram_2p_160x128.mem_array[i_mc]);		
		end
		
	 	for (i_mc=0; i_mc<144; i_mc=i_mc+1'b1) begin
			$fdisplay(fp_mc_in, "%h",
			{tb_top.u_top.u_fetch_chroma.left_bank0.rf_2p_64x144.mem_array[i_mc],
			tb_top.u_top.u_fetch_chroma.right_bank0.rf_2p_64x144.mem_array[i_mc]});
		end
	end
end                                      

`endif