/*-
 * Copyright (c) 2011 Peter Tworek
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the author nor the names of any co-contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * bootcode.S - glue code for starting Linux kernel on Psion/Teklogix NetBook Pro.
 */

#include "atag.h"
#include "config.h"

#define ENTRY(x) .align 0; .globl x; x:

	.section ".text"

#define PRINT_CHAR(c) \
	mov	ip, #(c);\
	strb	ip, [r10]

#define PRINT_NEW_LINE \
	PRINT_CHAR(10) ; \
	PRINT_CHAR(13)

#define PRINT_BYTE \
	cmp	r1, #10 ; \
	addcc	r1, r1, #48 ; \
	addcs	r1, r1, #55 ; \
	mov	r3, #0x80000 ; \
	1: \
	ldrb	r2, [r10, #20] ; \
	subs	r3, r3, #1 ; \
	bmi	2f ; \
	tst	r2, #0x40 ; \
	bne	1b ; \
	2: \
	strb	r1, [r10]

image_start:
	.skip 7*4

/*
 * Printing register value on the serial console in hexdecimal format.
 * r0 - value to print
 * NOTE: r10 shound be set to base address of XScale UART port.
 */
 ENTRY(print_hex)
	lsr	r1, r0, #28
	PRINT_BYTE

	lsr	r1, r0, #24
	and	r1, r1, #15
	PRINT_BYTE

	lsr	r1, r0, #20
	and	r1, r1, #15
	PRINT_BYTE

	lsr	r1, r0, #16
	and	r1, r1, #15
	PRINT_BYTE

	lsr	r1, r0, #12
	and	r1, r1, #15
	PRINT_BYTE

	lsr	r1, r0, #8
	and	r1, r1, #15
	PRINT_BYTE

	lsr	r1, r0, #4
	and	r1, r1, #15
	PRINT_BYTE

	and	r1, r0, #15
	PRINT_BYTE

	mov	pc, lr

/*
 * Main entry point.
 * lr - kernel entry address.
 */
 ENTRY(start)
	/* r10 = UART base addr (0x40100000) */
	mov	r10, #0x40000000
	orr	r10, r10, #0x00100000

	mov	r0, #0x13	/* Supervisor mode */
	orr	r0, r0, #0xc0	/* Disable interrupts */
	msr	CPSR_c, r0

	PRINT_CHAR('L')

	/*
	 * Initialize 64kb dcache from known and valid data.
	 */
	bic	r0, pc, #0x1F
	add	r1, r0, #0x10000
1:	ldr	r2, [r0], #32
	cmp	r0, r1
	bcc	1b		/* Branch to 1 if r1 > r0 */

	mov	r0, #0
	mcr	p15, 0, r0, c7, c10, 4	/* Drain Write (& Fill) Buffer */
	mcr	p15, 0, r0, c7, c7, 0	/* Invalidate I&D cache & BTB */

	/*
	 * Disable dcache, alignment fault & MMU
	 * TODO: Shouldn't this be 0x5, or 0x07?
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #15
	mcr	p15, 0, r0, c1, c0, 0

	/* Print image load address */
	mov	r0, lr
	mov	r13, lr
	bl	print_hex

	PRINT_CHAR('-')

	/* Print current address */
	mov	r0, pc
	bl	print_hex

	PRINT_CHAR('-')

	/* Calculate kernel load address */
	adr	r13, start
	ldr	r2, cfg_start_addr
	sub	r13, r13, r2
	mov	r0, r13
	bl	print_hex

	PRINT_CHAR(' ')
	PRINT_CHAR('p')

	/* Print CP15 ARM Control register */
	mrc	p15, 0, r0, c1, c0, 0
	bl	print_hex

	PRINT_CHAR(' ')

	/*
	 * Calculate some usefull addresses.
	 */
	mov	lr, r13
	sub	r7, lr, #4		/* r7  = image load addr */
	mov	r8, lr			/* r8  = kernel load addr */
	adr	r9, image_start		/* r9  = kernel end addr */
	mov	r13, lr			/* r13 = kernel load addr */

	/* WTF ??? */
	mov	r0, #80	/* 'P' */
	strb	r0, [ip]

	/* Print image load addr. */
	mov	r0, r7
	bl	print_hex

	PRINT_NEW_LINE

	/* WTF ??? */
	mov	r0, #65 /* 'A' */
	strb	r0, [ip]

	/* Print kernel load addr. */
	mov	r0, r8
	bl	print_hex

	PRINT_NEW_LINE

	/* WTF ??? */
	mov	r0, #70 /* 'F' */
	strb	r0, [ip]

	/* Print kernel end addr */
	mov	r0, r9
	bl	print_hex

	PRINT_NEW_LINE

	/*
	 * Copy kernel to image load addr for each 512kb
	 * copied diplay dot on the serial console.
	 */
	mov	lr, r13
1:	add	ip, r8, #0x80000
2:	ldm	r8!, {r0, r1, r2, r3}
	stmia	r7!, {r0, r1, r2, r3}
	cmp	r8, ip
	cmpcc	r8, r9
	bcc	2b
	PRINT_CHAR('.')
	cmp	r8, r9
	bcc	1b

	PRINT_NEW_LINE

	/*
	 * Setup ATAG list in memory.
	 */
	mov	r0, #MEMORY_START
	ldr	r0, [r0, #244] /* Probably some structure holding hw info/specs */
	str	r0, atag_mem_size
	mov	r0, #0
	ldr	r1, root_type
	sub	r2, lr, #4	/* r2 = image load addr */
	sub	r2, r2, #0x8000
	add	r2, r2, #0x100	/* r2 = atag list start */
	mov	r7, r2		/* r7 = atag list start */
	adr	r8, atag_start
	adr	r9, atag_end

	PRINT_CHAR('P')

	/*
	 * Copy ATAG list into place.
	 */
1:	ldr	r11, [r8], #4
	str	r11, [r7], #4
	cmp	r8, r9
	bcc	1b

	PRINT_CHAR('s')

	/*
	 * Set both memory and run mode frequency multipliers to 2.
	 */
	ldr	r3, pxa_clkman_base
	ldr	r4, [r3]
	bic	r4, r4, #0x3e0
	orr	r4, r4, #0x240
	str	r4, [r3]

	/*
	 * Start frequency change sequence and enter tubo mode.
	 */
	mov	r4, #3
	mcr	p14, 0, r4, c6, c0, 0

	PRINT_CHAR('i')

	/*
	 * Copy initrd into it's final destination.
	 */
	ldr	r4, atag_initrd2_start
	adr	r5, initrd_code_start
	ldr	r6, cfg_initrd_end
	ldr	r7, cfg_initrd_start
	sub	r6, r6, r7	/* r6 = real initrd size */
	add	r6, r6, r5	/* r6 = real initrd end */
1:	ldm	r5!, {r7, r8, r9, r13}
	stmia	r4!, {r7, r8, r9, r13}
	cmp	r5, r6
	bcc	1b

	PRINT_CHAR('G')

	/*
	 * Execute the actual kernel! :)
	 * NOTE: r2 must point to ATAG list start.
	 */
	sub	pc, lr, #4

	/* Data section */
root_type:		.word	0x000001f7

/*
 * ATAG list template.
 */
atag_start:
atag_core:		.word	ATAG_CORE_SIZE
			.word	ATAG_CORE
			.word	0x00000001	/* flags */
			.word	PAGE_SIZE	/* pagesize */
			.word	0x00000000	/* rootdev */
atag_mem:		.word	ATAG_MEM_SIZE
			.word	ATAG_MEM
atag_mem_size:		.word	MEMORY_SIZE
atag_mem_start:		.word	MEMORY_START
atag_initrd2:		.word	ATAG_INITRD2_SIZE
			.word	ATAG_INITRD2
atag_initrd2_start:	.word	INITRD_LOAD_ADDR
atag_initrd2_size:	.word	INITRD_DEF_SIZE
atag_cmdline:		.word	0x00000010
			.word	ATAG_CMDLINE
			.word	0x746f6f72
			.word	0x65642f3d
			.word	0x61722f76
			.word	0x7772206d
			.word	0x6e6f6320
			.word	0x656c6f73
			.word	0x7974743d
			.word	0x2c304153
			.word	0x32353131
			.word	0x69203030
			.word	0x3d74696e
			.word	0x6e696c2f
			.word	0x63727875
			.word	0x00000000
			.word	0x00000000
			.word	0x00000000
atag_end:

/*
 * Configuration data
 */
cfg_start_addr:		.word	0x0025f4b8 /* last instr of print_hex */
pxa_clkman_base:	.word	PXA_CLKMAN_BASE
cfg_initrd_end:		.word	0x00a5f740
cfg_initrd_start:	.word	0x0025f740

/*
 * Initrd/ramdisk should start straight here
 */
initrd_code_start:
