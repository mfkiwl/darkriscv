	.file	"io.c"
	.option nopic
	.text
	.align	2
	.globl	board_name
	.type	board_name, @function
board_name:
	beqz	a0,.L3
	li	a5,1
	beq	a0,a5,.L4
	li	a5,2
	beq	a0,a5,.L5
	li	a5,3
	beq	a0,a5,.L6
	li	a5,4
	beq	a0,a5,.L7
	li	a5,5
	beq	a0,a5,.L8
	li	a5,6
	beq	a0,a5,.L9
	li	a5,7
	beq	a0,a5,.L10
	li	a5,8
	beq	a0,a5,.L11
	li	a5,9
	beq	a0,a5,.L12
	lui	a0,%hi(.LC10)
	addi	a0,a0,%lo(.LC10)
	ret
.L3:
	lui	a0,%hi(.LC2)
	addi	a0,a0,%lo(.LC2)
	ret
.L4:
	lui	a0,%hi(.LC3)
	addi	a0,a0,%lo(.LC3)
	ret
.L5:
	lui	a0,%hi(.LC4)
	addi	a0,a0,%lo(.LC4)
	ret
.L6:
	lui	a0,%hi(.LC5)
	addi	a0,a0,%lo(.LC5)
	ret
.L7:
	lui	a0,%hi(.LC6)
	addi	a0,a0,%lo(.LC6)
	ret
.L8:
	lui	a0,%hi(.LC7)
	addi	a0,a0,%lo(.LC7)
	ret
.L9:
	lui	a0,%hi(.LC8)
	addi	a0,a0,%lo(.LC8)
	ret
.L10:
	lui	a0,%hi(.LC1)
	addi	a0,a0,%lo(.LC1)
	ret
.L11:
	lui	a0,%hi(.LC9)
	addi	a0,a0,%lo(.LC9)
	ret
.L12:
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	ret
	.size	board_name, .-board_name
	.globl	utimers
	.globl	threads
	.comm	io,16,4
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"qmtech artix7 a35"
	.zero	2
.LC1:
	.string	"digilent spartan3 s200"
	.zero	1
.LC2:
	.string	"simulation only"
.LC3:
	.string	"avnet microboard lx9"
	.zero	3
.LC4:
	.string	"xilinx ac701 a200"
	.zero	2
.LC5:
	.string	"qmtech sdram lx16"
	.zero	2
.LC6:
	.string	"qmtech spartan7 s15"
.LC7:
	.string	"lattice brevia2 lxp2"
	.zero	3
.LC8:
	.string	"piswords rs485 lx9"
	.zero	1
.LC9:
	.string	"aliexpress hpc/40gbe k420"
	.zero	2
.LC10:
	.string	"unknown"
	.section	.sbss,"aw",@nobits
	.align	2
	.type	utimers, @object
	.size	utimers, 4
utimers:
	.zero	4
	.type	threads, @object
	.size	threads, 4
threads:
	.zero	4
	.ident	"GCC: (GNU) 9.0.0 20180818 (experimental)"
