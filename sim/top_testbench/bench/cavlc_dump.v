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
// Filename       : cavlc_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump cavlc in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_CAVLC

integer fp_cavlc ;
integer fp_cavlc_in;   
integer fp_cavlc_out;
integer i_cavlc;
integer cnt_cavlc;
reg [67:0] reg_cavlc;

initial begin
    fp_cavlc = $fopen("./dump/cavlc.dat","wb");
    fp_cavlc_in  = $fopen("./dump/cavlc_input.dat","wb");
    fp_cavlc_out = $fopen("./dump/cavlc_output.dat","wb");
end

//--------------------------------------------------------------------------
//	dump cavlc variables                                      
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_cavlc_top.start) begin
		#5;
		$fwrite(fp_cavlc,"\n===== Frame: %d  MB x: %d  y: %d =====\n", 	tb_top.frame_num,          
																	tb_top.u_top.u_cavlc_top.mb_x, 
																	tb_top.u_top.u_cavlc_top.mb_y);		
		// top level 
		$fdisplay(fp_cavlc,"$intra_flag            : %h", tb_top.u_top.intra_flag       		 );
		$fdisplay(fp_cavlc,"$qp                    : %h", tb_top.u_top.ec_qp                	 );
		// from tq
		$fdisplay(fp_cavlc,"$tq_cbp                : %h", tb_top.u_top.tq_cbp[8:0]               );
		// from intra                                               	       
		$fdisplay(fp_cavlc,"$intra_mb_type_info    : %h", tb_top.u_top.intra_mb_type_info        );
		$fdisplay(fp_cavlc,"$intra_chroma_mode     : %h", tb_top.u_top.intra_chroma_mode[1:0]    );
		$fdisplay(fp_cavlc,"$intra_16x16_mode      : %h", tb_top.u_top.intra_16x16_mode[1:0]     );
		$fdisplay(fp_cavlc,"$intra_4x4_bm          : %h", tb_top.u_top.intra_4x4_bm[63:0]        );
		$fdisplay(fp_cavlc,"$intra_4x4_pm          : %h", tb_top.u_top.intra_4x4_pm[63:0]        );
		// from inter
		$fdisplay(fp_cavlc,"$inter_mb_type_info    : %h", tb_top.u_top.mc_mb_type_info[1:0]   );
		$fdisplay(fp_cavlc,"$inter_sub_partition   : %h", tb_top.u_top.mc_sub_partition[7:0]  );	
		// from ac mem
		$fdisplay(fp_cavlc,"$ac");
		for (i_cavlc=0; i_cavlc<32; i_cavlc=i_cavlc+1)
			$fdisplay(fp_cavlc,"%2d: %h", i_cavlc, tb_top.u_top.u_tq_top.u_coeff_ram_256x64.ram_2p_256x64.mem_array[i_cavlc+(!tb_top.u_top.u_tq_top.mem_sel)*32]);		
		// from mvd mem
		$fdisplay(fp_cavlc,"$mvd");
		for (i_cavlc=0; i_cavlc<16; i_cavlc=i_cavlc+1)
			$fdisplay(fp_cavlc,"%2d: %h", i_cavlc, tb_top.u_top.u_mvd_cmp.u_mvd_ram.rf_2p_18x32.mem_array[i_cavlc+(!tb_top.u_top.u_mvd_cmp.mem_sel)*16]);			
	end	
end


//--------------------------------------------------------------------------
//	dump cavlc outputs for data check                                                    
//--------------------------------------------------------------------------
always @(posedge clk) begin                                                                        
	if (tb_top.u_top.u_cavlc_top.start) begin                                                      
		$fwrite(fp_cavlc_out,"\n===== Frame: %d  MB x: %d  y: %d =====\n", 	tb_top.frame_num,          
																	tb_top.u_top.u_cavlc_top.mb_x, 
																	tb_top.u_top.u_cavlc_top.mb_y);
		$fwrite(fp_cavlc_out, "$bs\n");
		cnt_cavlc = 0;
	end
	
	if (tb_top.u_top.u_bs_buf.cavlc_we) begin
		reg_cavlc = tb_top.u_top.u_bs_buf.cavlc_bit;
		for (i_cavlc=0; i_cavlc<tb_top.u_top.u_bs_buf.cavlc_inc; i_cavlc=i_cavlc+1) begin
			$fwrite(fp_cavlc_out,"%2h ", reg_cavlc[67:60]);
			reg_cavlc = {reg_cavlc[59:0], 8'b0};
			cnt_cavlc = cnt_cavlc + 1;
			
			if (cnt_cavlc%16==0) 
				$fwrite(fp_cavlc_out,"\n");
		end
	end
end

//--------------------------------------------------------------------------
//	dump cavlc all inputs for tb_cavlc
//-------------------------------------------------------------------------- 
always @(posedge clk) begin
	if (tb_top.u_top.u_cavlc_top.start) begin
		#5;
		// top level 
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.u_cavlc_top.mb_x[6:0]     );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.u_cavlc_top.mb_y[6:0]     );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.intra_flag                );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.ec_qp                	   );
		// from tq
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.tq_cbp[8:0]               );	
		// from intra                                                  	       
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.intra_mb_type_info        );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.intra_chroma_mode[1:0]    );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.intra_16x16_mode[1:0]     );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.intra_4x4_bm[63:0]        );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.intra_4x4_pm[63:0]        );
		// from inter
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.mc_mb_type_info[1:0]   );
		$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.mc_sub_partition[7:0]  );	
		// from ac mem
		for (i_cavlc=0; i_cavlc<32; i_cavlc=i_cavlc+1)
			$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.u_tq_top.u_coeff_ram_256x64.ram_2p_256x64.mem_array[(!tb_top.u_top.u_tq_top.mem_sel)*32+i_cavlc]);			
		// from mvd mem
		for (i_cavlc=0; i_cavlc<16; i_cavlc=i_cavlc+1)
			$fdisplay(fp_cavlc_in,"%h", tb_top.u_top.u_mvd_cmp.u_mvd_ram.rf_2p_18x32.mem_array[i_cavlc+(!tb_top.u_top.u_mvd_cmp.mem_sel)*16]);
	end
end

`endif