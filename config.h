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

#ifndef _CONFIG_H_
#define _CONFIG_H_

/* Bootcode version number. */
#define BCODE_VERSION		1
#define BCODE_VERSION_STR	"Psion Teklogix NetBook Pro open bootcode v1\n\r"

/* Bootcode header magic number */
#define BCODE_HDR_MAGIC		((0xBC0DE << 12) | (BCODE_VERSION))

/* Addresses of some PXA255 peripherials */
#define PXA_UART_BASE		0x40100000
#define PXA_CLKMAN_BASE		0x41300000

/* Must be the same as in arch/arm/tools/mach-types */
#define NETBOOKPRO_MACH_TYPE	503

/* Default page size. Used by ATAG_CORE. */
#define PAGE_SIZE		4096

/* Default memory configuration for ATAG_MEM */
#define MEMORY_START		0xa0000000
#define MEMORY_SIZE		(128 * 1024 * 1024)

/* Physical location of ramdisk in memory. */
#define INITRD_LOAD_ADDR	0xa2000000

#endif /* !_CONFIG_H_ */
