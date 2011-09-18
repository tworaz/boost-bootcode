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

#ifndef _ATAG_H_
#define _ATAG_H_

/*
 * ATAG list is used by the bootloader to pass kernel some initial
 * configuration hints along with startup arguments.
 *
 *            ATAG entry:
 * 0x0 +-----------------------+
 *     |       TAG Size        |
 * 0x4 +-----------------------+
 *     |       TAG ID          |
 * 0x8 +-----------------------+
 *     |                       |
 *     |      TAG Size - 2     |
 *     |      words of data    |
 *     |                       |
 *     +-----------------------+
 */

/* Empty tag used to end the list */
#define ATAG_NONE		0x00000000
#define ATAG_NONE_SIZE		2

/* Start tag used to begin the list */
#define ATAG_CORE		0x54410001
#define ATAG_CORE_SIZE		5 /* Size of 2 is also possible */

/* Tag used to describe physical area of memory */
#define ATAG_MEM		0x54410002
#define ATAG_MEM_SIZE		4

/* Tag describing physical location of ramdisk image */
#define ATAG_INITRD2		0x54420005
#define ATAG_INITRD2_SIZE	4

/* Tag used to pass command line arguments to the kernel */
#define ATAG_CMDLINE		0x54410009
#define ATAG_CMDLINE_SIZE(cl)	(2 + ((cl + 3) / 4))

#endif /* !_ATAG_H_ */
