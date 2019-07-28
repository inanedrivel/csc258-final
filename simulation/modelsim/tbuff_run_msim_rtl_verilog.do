transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/re4/git/258/vga-c3 {/home/re4/git/258/vga-c3/vga_render.v}
vlog -vlog01compat -work work +incdir+/home/re4/git/258/vga-c3 {/home/re4/git/258/vga-c3/vga_controller.v}
vlog -vlog01compat -work work +incdir+/home/re4/git/258/vga-c3 {/home/re4/git/258/vga-c3/memory_controller.v}
vlog -vlog01compat -work work +incdir+/home/re4/git/258/vga-c3 {/home/re4/git/258/vga-c3/main.v}
vlog -vlog01compat -work work +incdir+/home/re4/git/258/vga-c3 {/home/re4/git/258/vga-c3/char_rom.v}

