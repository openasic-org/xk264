//--------------------------------------------
//			Include Dir
//--------------------------------------------
+incdir+./
+incdir+../../rtl/

//--------------------------------------------
//			Memory Model
//--------------------------------------------
../../lib/behave/mem/rom_1p.v
../../lib/behave/mem/rf_1p.v
../../lib/behave/mem/rf_2p.v
../../lib/behave/mem/ram_1p.v
../../lib/behave/mem/ram_2p.v

//--------------------------------------------
//			Memory Instance
//--------------------------------------------
../../rtl/mem/fme_ram_2p_160x128.v

../../rtl/mem/intra_ram_2p_16x120.v 
../../rtl/mem/intra_ram_2p_128x120.v

../../rtl/mem/tq_ram_2p_128x32.v
../../rtl/mem/tq_ram_2p_128x24.v
../../rtl/mem/tq_ram_dp_256x64.v

../../rtl/mem/mv_ram_1p_16x480.v
../../rtl/mem/mvd_ram_2p_18x32.v

../../rtl/mem/cavlc_ram_2p_36x120.v

../../rtl/mem/db_ram_1p_128x8.v
../../rtl/mem/db_ram_1p_28x480.v

../../rtl/mem/fetch_ram_dp_128x48.v
../../rtl/mem/fetch_ram_2p_64x144.v
../../rtl/mem/fetch_ram_2p_128x16.v
../../rtl/mem/fetch_ram_2p_128x64.v

//--------------------------------------------
//			IME
//--------------------------------------------
../../rtl/ime/ime_abs.v
../../rtl/ime/ime_cost4x4.v
../../rtl/ime/ime_costx16.v
../../rtl/ime/ime_costx8.v
../../rtl/ime/ime_min_cost.v
../../rtl/ime/ime_mux.v
../../rtl/ime/ime_mv_cost.v
../../rtl/ime/ime_sad4x4.v
../../rtl/ime/ime_sad4x4_pe.v
../../rtl/ime/ime_sad_top.v
../../rtl/ime/ime_sad_x16.v
../../rtl/ime/ime_sad_x8.v
../../rtl/ime/ime_ctrl.v
../../rtl/ime/ime_top.v

//--------------------------------------------
//			FME
//--------------------------------------------
../../rtl/fme/fme_best_candidate.v
../../rtl/fme/fme_ctrl.v
../../rtl/fme/fme_datapath.v
../../rtl/fme/fme_fetch.v
../../rtl/fme/fme_interpolator_4pel.v
../../rtl/fme/fme_load.v
../../rtl/fme/fme_ram.v
../../rtl/fme/fme_satd_gen_4x4.v
../../rtl/fme/fme_satd_gen_double4xn.v
../../rtl/fme/fme_top.v

//--------------------------------------------
//			MC
//--------------------------------------------
../../rtl/mc/mc_chroma.v
../../rtl/mc/mc_chroma_ip_2pel.v
../../rtl/mc/mc_chroma_top.v
../../rtl/mc/mc_core.v
../../rtl/mc/mc_ip_4pel.v
../../rtl/mc/mc_luma.v
../../rtl/mc/mc_luma_top.v
../../rtl/mc/mc_top.v

//--------------------------------------------
//			INTRA
//--------------------------------------------
../../rtl/intra/intra_16x16_chroma_ctrl.v    
../../rtl/intra/intra_16x16_chroma_dc.v      
../../rtl/intra/intra_16x16_chroma_pe.v      
../../rtl/intra/intra_16x16_chroma_plane.v   
../../rtl/intra/intra_16x16_chroma_top.v     
../../rtl/intra/intra_4x4_ctrl.v             
../../rtl/intra/intra_4x4_pe.v               
../../rtl/intra/intra_4x4_pred_mode_gen.v    
../../rtl/intra/intra_4x4_top.v              
../../rtl/intra/intra_hadamard4x4.v   
../../rtl/intra/intra_lambda.v       
../../rtl/intra/intra_ref.v                  
../../rtl/intra/intra_top.v                  

//--------------------------------------------
//			TQ                             
//--------------------------------------------
../../rtl/tq/tq_add_idct_pre.v  
../../rtl/tq/tq_dct4x4.v        
../../rtl/tq/tq_dequant2x2_dc.v 
../../rtl/tq/tq_dequant4x4.v    
../../rtl/tq/tq_dequant4x4_dc.v 
../../rtl/tq/tq_div6_l.v
../../rtl/tq/tq_div6_c.v
../../rtl/tq/tq_ht2x2.v         
../../rtl/tq/tq_ht4x4.v         
../../rtl/tq/tq_idct4x4.v       
../../rtl/tq/tq_iht2x2.v        
../../rtl/tq/tq_iht4x4.v        
../../rtl/tq/tq_mod6_l.v 
../../rtl/tq/tq_mod6_c.v 
../../rtl/tq/tq_quant2x2_dc.v   
../../rtl/tq/tq_quant4x4.v      
../../rtl/tq/tq_quant4x4_dc.v   
../../rtl/tq/tq_top.v      
     
//--------------------------------------------
//			CAVLC
//--------------------------------------------
../../rtl/cavlc/BitStream_packer.v
../../rtl/cavlc/cbp_enc.v
../../rtl/cavlc/Coeff_Sign_packer.v
../../rtl/cavlc/Coeff_token_enc.v
../../rtl/cavlc/Coeff_token_vlc0.v
../../rtl/cavlc/Coeff_token_vlc1.v
../../rtl/cavlc/Coeff_token_vlc2.v
../../rtl/cavlc/Coeff_token_vlc_chromaDC.v
../../rtl/cavlc/control_fsm.v
../../rtl/cavlc/LevelCodeGen.v
../../rtl/cavlc/level_bit_packer.v
../../rtl/cavlc/level_enc.v
../../rtl/cavlc/level_run_buf.v
../../rtl/cavlc/MB_header_enc.v
../../rtl/cavlc/Delta_qp_enc.v
../../rtl/cavlc/MB_header_packer.v
../../rtl/cavlc/NC_compute.v
../../rtl/cavlc/regLevel_buf.v
../../rtl/cavlc/regRun_buf.v
../../rtl/cavlc/run_enc.v
../../rtl/cavlc/Run_tab.v
../../rtl/cavlc/TotalCoefZero.v
../../rtl/cavlc/TotalZeros_enc.v
../../rtl/cavlc/TotalZeros_tab.v
../../rtl/cavlc/TrailingOne.v
../../rtl/cavlc/Zeros_Run_packer.v
../../rtl/cavlc/cavlc_top.v

//--------------------------------------------
//			DB
//--------------------------------------------
../../rtl/db/bs.v
../../rtl/db/chroma_pipeline.v
../../rtl/db/luma_pipeline.v
../../rtl/db/db_control.v
../../rtl/db/db_filter.v
../../rtl/db/rom_alpha.v
../../rtl/db/rom_beta.v
../../rtl/db/rom_clip.v
../../rtl/db/db_top.v

//--------------------------------------------
//			Fetch
//--------------------------------------------
../../rtl/fetch/fetch_luma.v
../../rtl/fetch/fetch_chroma.v
../../rtl/fetch/fetch_ime.v
../../rtl/fetch/fetch_fme.v
../../rtl/fetch/fetch.v
../../rtl/fetch/fetch_db.v

//--------------------------------------------
//			TOP
//--------------------------------------------
../../rtl/top/mvd_cmp.v
../../rtl/top/bs_buf.v
../../rtl/top/cur_mb.v
../../rtl/top/mem_arbiter.v
../../rtl/top/top_ctrl.v
../../rtl/top/top.v

//--------------------------------------------
//			Test Bench
//--------------------------------------------
./tb_top.v
