vlib ./work
vmap work work
vlog -f ./vlog.args
vsim -l sim_top.log  +nospecify work.tb_top
run -all
