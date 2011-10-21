##
# Copyright (c) 2011 Peter Tworek
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the author nor the names of any co-contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

-include Makefile.config

BIN = bcode

CROSS ?= arm-none-eabi-

ifeq ($(RAMDISK), yes)
	KERNEL_CMDLINE ?= "root=/dev/ram rw console=tty0 init=/sbin/init verbose"
else
	KERNEL_CMDLINE ?= "root=/dev/sda2 rw console=tty0 init=/sbin/init quiet"
endif
CPPFLAGS += -DKERNEL_CMDLINE=\"$(KERNEL_CMDLINE)\" -DCMDLINE_LEN=$(shell expr length $(KERNEL_CMDLINE))

CPP     := $(CROSS)cpp
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJDUMP := $(CROSS)objdump
OBJCOPY := $(CROSS)objcopy

LDFLAGS = -T $(LDSCRIPT)

LDSCRIPT = bootcode.ld
SOURCES  = bootcode.S

OBJS = ${SOURCES:.S=.o}

$(BIN): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(BIN).elf
	$(OBJDUMP) $(BIN).elf --disassemble-all > $(BIN).lst
	$(OBJCOPY) -O binary -R .note -R .comment -S $(BIN).elf $@
	$(OBJDUMP) -D $@ -b binary -m arm -EL > $(BIN)-out.lst

%.o: %.S
	$(CPP) $(ACPPFLAGS) $(CPPFLAGS) $< $*.tmp
	$(AS) $(ASFLAGS) $(OUTPUT_OPTION) $*.tmp
	$(RM)  $*.tmp

clean:
	rm -f $(OBJS) $(BIN) *.elf *.bin *.lst *.tmp

.PHONY = clean all
