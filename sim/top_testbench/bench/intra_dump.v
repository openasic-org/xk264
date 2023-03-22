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
// Filename       : intra_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump intra in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_INTRA

integer fp_intra;
integer fp_intra_in;   
integer fp_intra_out;
integer i_intra;

wire [7:0]	 luma_ref_top_left;
wire [31:0]	 luma_ref_top_right;
wire [127:0] luma_ref_top;
wire [127:0] luma_ref_left;
wire [7:0]	 cb_ref_top_left;
wire [63:0]  cb_ref_top;
wire [63:0]  cb_ref_left;
wire [7:0]	 cr_ref_top_left;
wire [63:0]  cr_ref_top;
wire [63:0]  cr_ref_left;
wire [15:0]	 bm_ref_left;
wire [15:0]	 bm_ref_top;

initial begin
	fp_intra     = $fopen("./dump/intra.dat","wb");
	fp_intra_in  = $fopen("./dump/intra_input.dat","wb");
	fp_intra_out = $fopen("./dump/intra_output.dat","wb");
end

assign luma_ref_top = { tb_top.u_top.u_intra_top.u_intra_ref.ref00_t[7:0],	
						tb_top.u_top.u_intra_top.u_intra_ref.ref01_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref02_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref03_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref04_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref05_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref06_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref07_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref08_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref09_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref10_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref11_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref12_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref13_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref14_t[7:0],
						tb_top.u_top.u_intra_top.u_intra_ref.ref15_t[7:0]};

assign luma_ref_left ={ tb_top.u_top.u_intra_top.u_intra_ref.ref00_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref01_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref02_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref03_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref04_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref05_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref06_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref07_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref08_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref09_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref10_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref11_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref12_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref13_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref14_l[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref15_l[7:0]};
                       
assign cb_ref_top  = {  tb_top.u_top.u_intra_top.u_intra_ref.ref00_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref01_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref02_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref03_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref04_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref05_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref06_t_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref07_t_u[7:0]};

assign cb_ref_left = {  tb_top.u_top.u_intra_top.u_intra_ref.ref00_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref01_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref02_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref03_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref04_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref05_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref06_l_u[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref07_l_u[7:0]};

assign cr_ref_top  = {  tb_top.u_top.u_intra_top.u_intra_ref.ref00_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref01_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref02_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref03_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref04_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref05_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref06_t_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref07_t_v[7:0]};

assign cr_ref_left = {  tb_top.u_top.u_intra_top.u_intra_ref.ref00_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref01_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref02_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref03_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref04_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref05_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref06_l_v[7:0],
                        tb_top.u_top.u_intra_top.u_intra_ref.ref07_l_v[7:0]};
                        
assign bm_ref_top  = {  tb_top.u_top.u_intra_top.u_intra_ref.top_bm[0], 
                        tb_top.u_top.u_intra_top.u_intra_ref.top_bm[1], 
                        tb_top.u_top.u_intra_top.u_intra_ref.top_bm[2], 
                        tb_top.u_top.u_intra_top.u_intra_ref.top_bm[3]};

assign bm_ref_left = {  tb_top.u_top.u_intra_top.u_intra_ref.left_bm[0],
                        tb_top.u_top.u_intra_top.u_intra_ref.left_bm[1],
                        tb_top.u_top.u_intra_top.u_intra_ref.left_bm[2],
                        tb_top.u_top.u_intra_top.u_intra_ref.left_bm[3]};

assign luma_ref_top_left  = tb_top.u_top.u_intra_top.u_intra_ref.ref00_tl[7:0];
assign luma_ref_top_right = {tb_top.u_top.u_intra_top.u_intra_ref.ref00_tr_y_r[7:0],
							 tb_top.u_top.u_intra_top.u_intra_ref.ref01_tr_y_r[7:0],
							 tb_top.u_top.u_intra_top.u_intra_ref.ref02_tr_y_r[7:0],
							 tb_top.u_top.u_intra_top.u_intra_ref.ref03_tr_y_r[7:0]};
assign cb_ref_top_left    = tb_top.u_top.u_intra_top.u_intra_ref.ref00_tl_u[7:0];
assign cr_ref_top_left    = tb_top.u_top.u_intra_top.u_intra_ref.ref00_tl_v[7:0];
                        
//--------------------------------------------------------------------------
//	dump intra variables                                      
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_intra_top.start_i) begin
		#5;
		$fwrite(fp_intra,"\n===== Frame: %d  MB x: %d  y: %d =====\n", 	tb_top.frame_num,    
																		tb_top.u_top.u_intra_top.mb_x[7:0],
																		tb_top.u_top.u_intra_top.mb_y[7:0]);      
		// from top			
		$fdisplay(fp_intra,"$mb_x_total        : %h", tb_top.u_top.u_intra_top.mb_x_total[7:0]);
		$fdisplay(fp_intra,"$intra_flag        : %h", tb_top.u_top.u_intra_top.intra_flag);
		$fdisplay(fp_intra,"$qp                : %h", tb_top.u_top.u_intra_top.qp[5:0]);
		$fdisplay(fp_intra,"$mb_luma           : %h", tb_top.u_top.u_intra_top.mb_luma[2047:0]);
		$fdisplay(fp_intra,"$mb_cb             : %h", tb_top.u_top.u_intra_top.mb_cb[511:0]);
		$fdisplay(fp_intra,"$mb_cr             : %h", tb_top.u_top.u_intra_top.mb_cr[511:0]);
		
		// from intra internal state
		$fdisplay(fp_intra,"$luma_ref_top_left : %h", luma_ref_top_left);
		$fdisplay(fp_intra,"$luma_ref_top_right: %h", luma_ref_top_right);
		$fdisplay(fp_intra,"$luma_ref_top      : %h", luma_ref_top);
		$fdisplay(fp_intra,"$luma_ref_left     : %h", luma_ref_left);
		
		$fdisplay(fp_intra,"$cb_ref_top_left   : %h", cb_ref_top_left);
		$fdisplay(fp_intra,"$cb_ref_top        : %h", cb_ref_top);
		$fdisplay(fp_intra,"$cb_ref_left       : %h", cb_ref_left);
		
		$fdisplay(fp_intra,"$cr_ref_top_left   : %h", cr_ref_top_left);
		$fdisplay(fp_intra,"$cr_ref_top        : %h", cr_ref_top);
		$fdisplay(fp_intra,"$cr_ref_left       : %h", cr_ref_left);
		
		$fdisplay(fp_intra,"$bm_ref_top        : %h", bm_ref_top);
		$fdisplay(fp_intra,"$bm_ref_left       : %h", bm_ref_left);
	end
end

//--------------------------------------------------------------------------
//	dump intra outputs for data check                                                    
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_intra_top.done_o) begin
		$fdisplay(fp_intra_out, "===== Frame: %d  MB x: %d  y: %d =====", tb_top.frame_num,
																	 tb_top.u_top.u_intra_top.mb_x, 
																	 tb_top.u_top.u_intra_top.mb_y);
	
		$fdisplay(fp_intra_out, "$intra_mode        : %h", tb_top.u_top.u_intra_top.intra_mode_o			);
		$fdisplay(fp_intra_out, "$intra4x4_bm       : %h", tb_top.u_top.u_intra_top.i4x4_bm_o[63:0]		);
		$fdisplay(fp_intra_out, "$intra4x4_pm       : %h", tb_top.u_top.u_intra_top.i4x4_pm_o[63:0]		);
		$fdisplay(fp_intra_out, "$intra16x16_mode   : %h", tb_top.u_top.u_intra_top.i16x16_mode_o[1:0]	);
		$fdisplay(fp_intra_out, "$chroma_mode       : %h", tb_top.u_top.u_intra_top.chroma_mode_o[1:0]	);
	end
end     

//--------------------------------------------------------------------------
//	dump intra all inputs for tb_intra
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_intra_top.start_i) begin    
		#5;
		// from top			
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.mb_x[7:0]);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.mb_y[7:0]);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.mb_x_total[7:0]);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.intra_flag);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.qp[5:0]);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.mb_luma[2047:0]);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.mb_cb[511:0]);
		$fdisplay(fp_intra_in, "%h", tb_top.u_top.u_intra_top.mb_cr[511:0]);
		
		// from intra internal state
		$fdisplay(fp_intra_in ,"%h", luma_ref_top_left);
		$fdisplay(fp_intra_in ,"%h", luma_ref_top_right);
		$fdisplay(fp_intra_in ,"%h", luma_ref_top);
		$fdisplay(fp_intra_in ,"%h", luma_ref_left);
		
		$fdisplay(fp_intra_in ,"%h", cb_ref_top_left);
		$fdisplay(fp_intra_in ,"%h", cb_ref_top);
		$fdisplay(fp_intra_in ,"%h", cb_ref_left);
		
		$fdisplay(fp_intra_in ,"%h", cr_ref_top_left);
		$fdisplay(fp_intra_in ,"%h", cr_ref_top);
		$fdisplay(fp_intra_in ,"%h", cr_ref_left);

		$fdisplay(fp_intra_in ,"%h", bm_ref_top);
		$fdisplay(fp_intra_in ,"%h", bm_ref_left);
	end
end
                                   

`endif