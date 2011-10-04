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

#define ENTRY(x) .align 4; .globl x; x:

#define PRINT_CHAR(c) \
	mov	ip, #(c);\
	strb	ip, [r10]

#define PRINT_NEW_LINE \
	PRINT_CHAR(10) ; \
	PRINT_CHAR(13)


.section ".text"

/*
 * Bootcode image header. All values besides magic number
 * have to be set during image creation.
 */
bcode_hdr_magic:	.word	BCODE_HDR_MAGIC
bcode_offset:		.word	0x00000000
ramdisk_size:		.word	0x00000000
			.word	0x00000000 /* Unused */

/*
 * Main entry point.
 * lr - kernel entry address.
 */
ENTRY(start)
	/* UART base addr */
	ldr	r10, pxa_uart_base

	mov	r0, #0x13	/* Supervisor mode */
	orr	r0, r0, #0xc0	/* Disable interrupts */
	msr	CPSR_c, r0

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

	/* Save link register value */
	mov	r13, lr

	/* Print welcome string */
	adr	r0, welcome_str
	bl	print_string

	/* Print kernel load address */
	adr	r0, img_load_str
	bl	print_string
	sub	r0, r13, #4
	bl	print_hex
	PRINT_NEW_LINE

#if notused
	/* Print CP15 ARM Control register */
	adr	r0, arm_ctrl_str
	bl	print_string
	mrc	p15, 0, r0, c1, c0, 0
	bl	print_hex
	PRINT_NEW_LINE
#endif

	/*
	 * Calculate some usefull addresses.
	 */
	mov	lr, r13
	sub	r7, lr, #4		/* r7 = image load addr */
	add	r8, lr, #12		/* r8 = kernel load addr */
	adr	r9, bcode_hdr_magic	/* r9 = kernel end addr */
	mov	r13, lr			/* r13 = kernel load addr */

	/* Print next action description */
	adr	r0, kernel_copy_from_str
	bl	print_string
	mov	r0, r8
	bl	print_hex
	adr	r0, kernel_copy_to_str
	bl	print_string
	mov	r0, r7
	bl	print_hex
	PRINT_NEW_LINE

	/*
	 * Copy kernel image to it's runtime destination.
	 */
1:	add	ip, r8, #0x20000
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
	 * Extract some HW params from BooSt.
	 */
#if notused
	mov	r0, #MEMORY_START
	ldr	r0, [r0, #244] /* Probably some structure holding hw info/specs */
	str	r0, atag_mem_size
	mov	r0, #0
#endif

	/*
	 * Configure ramdisk size ATAG.
	 */
	ldr	r1, ramdisk_size
	adr	r0, atag_initrd2_size
	str	r1, [r0]

	/*
	 * Setup ATAG list in memory.
	 */
	sub	r2, r13, #4	/* r2 = image load addr */
	sub	r2, r2, #0x8000
	add	r2, r2, #0x100	/* r2 = atag list start */
	mov	r7, r2		/* r7 = atag list start */
	adr	r8, atag_start
	adr	r9, atag_end

	/*
	 * Copy ATAG list into place.
	 */
1:	ldr	r11, [r8], #4
	str	r11, [r7], #4
	cmp	r8, r9
	bcc	1b

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

	/* Restore link register */
	mov	lr, r13

	/*
	 * Copy initrd into it's final destination.
	 */
	ldr	r4, atag_initrd2_start
	adr	r5, initrd_code_start
	ldr	r6, ramdisk_size
	add	r6, r5, r6
1:	ldm	r5!, {r7, r8, r9, r13}
	stmia	r4!, {r7, r8, r9, r13}
	cmp	r5, r6
	bcc	1b

	/* Set proper macine type. */
	ldr	r1, mach_type
	mov	r0, #0

	/*
	 * Execute the actual kernel! :)
	 * NOTE:
	 * - r2 must hold to ATAG list start addr.
	 */

	sub	pc, lr, #4

/*
 * Print unsigned value on the serial console in hexdecimal format.
 * r0 - value to print
 * NOTE: r10 shound be set to base address of XScale UART port.
 */
ENTRY(print_hex)

#define PRINT_BYTE \
	cmp	r1, #10 ; \
	addcc	r1, r1, #48 ; \
	addcs	r1, r1, #55 ; \
	mov	r3, #0x80000 ; \
	1: \
	ldrb	r2, [r10, #14] ; \
	subs	r3, r3, #1 ; \
	bmi	2f ; \
	tst	r2, #0x20 ; \
	bne	1b ; \
	2: \
	strb	r1, [r10]

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

#undef PRINT_BYTE

	mov	pc, lr

/*
 * Print NULL terminated ascii string on the serial console.
 * r0 - memory address where the string is located.
 */
ENTRY(print_string)
	ldrb	r1, [r0], #1
	cmp	r1, #0
	beq	3f

	mov	r3, #0x80000
1:	ldrb	r2, [r10, #14]
	subs	r3, r3, #1
	bmi	2f
	tst	r2, #0x20
	bne	1b
2:	strb	r1, [r10]
	b	print_string
3:
	mov	pc, lr

/*
 * Some constants.
 */
mach_type:		.word	NETBOOKPRO_MACH_TYPE
pxa_clkman_base:	.word	PXA_CLKMAN_BASE
pxa_uart_base:		.word	PXA_UART_BASE

welcome_str:		.asciz	BCODE_VERSION_STR
.align 4,0
img_load_str:		.asciz	"Boot image load addr: 0x"
.align 4,0
arm_ctrl_str:		.asciz	"ARM CP15 Control reg value: 0x"
.align 4,0
kernel_copy_from_str:	.asciz	"Copying kernel image from 0x"
.align 4,0
kernel_copy_to_str:	.asciz	" to 0x"


.align 4, 0
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
atag_initrd2_size:	.word	0

atag_cmdline:		.word	15  /* (((cmdlen + 3) / 4) + 2) */
			.word	ATAG_CMDLINE
			.asciz	"root=/dev/ram rw console=tty0 init=/linuxrc verbose"
/* ATAG_NONE */
			.word	0x00000000
			.word	0x00000000
.align 4, 0
atag_end:

/*
 * Initrd/ramdisk should start straight here
 */
initrd_code_start:
