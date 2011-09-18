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

BIN = bootcode

CROSS ?= arm-none-eabi

CPP     := $(CROSS)-cpp
AS      := $(CROSS)-as
LD      := $(CROSS)-ld
OBJDUMP := $(CROSS)-objdump
OBJCOPY := $(CROSS)-objcopy

LDFLAGS = -T $(LDSCRIPT)

LDSCRIPT = $(BIN).ld
SOURCES  = $(BIN).S

OBJS = ${SOURCES:.S=.o}

$(BIN): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(BIN).elf
	$(OBJDUMP) $(BIN).elf --disassemble-all > $(BIN).lst
	$(OBJCOPY) -O binary -R .note -R .comment -S $(BIN).elf $@
	$(OBJDUMP) -D $@ -b binary -m arm -EL > bootcode-out.lst

%.o: %.S
	$(CPP) $(ACPPFLAGS) $(CPPFLAGS) $< $*.tmp
	$(AS) $(ASFLAGS) $(OUTPUT_OPTION) $*.tmp
	$(RM)  $*.tmp

clean:
	rm -f $(OBJS) $(BIN) *.elf *.bin *.lst

.PHONY = clean all
