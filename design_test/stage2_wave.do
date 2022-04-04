onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /stage2_tb/DUT/CLOCK_50
add wave -noupdate /stage2_tb/DUT/CPU/CTRL/present_state
add wave -noupdate /stage2_tb/DUT/CPU/ir_out
add wave -noupdate /stage2_tb/DUT/CPU/DA
add wave -noupdate /stage2_tb/DUT/CPU/PC
add wave -noupdate /stage2_tb/DUT/CPU/mem_cmd
add wave -noupdate /stage2_tb/DUT/CPU/mem_addr
add wave -noupdate /stage2_tb/DUT/CPU/lr
add wave -noupdate /stage2_tb/DUT/CPU/execb
add wave -noupdate /stage2_tb/DUT/CPU/pc
add wave -noupdate /stage2_tb/DUT/CPU/sximm8
add wave -noupdate /stage2_tb/DUT/CPU/pc1
add wave -noupdate /stage2_tb/DUT/CPU/pcrel
add wave -noupdate /stage2_tb/DUT/CPU/pctgt
add wave -noupdate /stage2_tb/DUT/CPU/nsel
add wave -noupdate /stage2_tb/DUT/CPU/rsel
add wave -noupdate /stage2_tb/DUT/CPU/tsel
add wave -noupdate /stage2_tb/DUT/CPU/vsel
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1720 ps}
