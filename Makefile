AS := ca65
CC := cl65
C1541 := c1541
X128 := x128

ifdef CC65_HOME
	AS := $(CC65_HOME)/bin/$(AS)
	CC := $(CC65_HOME)/bin/$(CC)
endif

ifdef VICE_HOME
	C1541 := $(VICE_HOME)/$(C1541)
	X128 := $(VICE_HOME)/$(X128)
endif

.PHONY: all clean check zap

ASFLAGS = --create-dep $(@:.o=.dep)

all: bootsect.128 testboot
clean:
	rm -rf *.o test.d64 bootsect.128 testboot
zap: clean
	rm -rf *.dep

check: test.d64
	$(X128) -debugcart -limitcycles 10000000 -sounddev dummy -silent -console -8 $+

test.d64: testboot bootsect.128
	$(C1541) -format test,xx d64 test.d64 \
		-write testboot \
		-bwrite bootsect.128 1 0

bootsect.128: LDFLAGS += -C linker.cfg
bootsect.128: bootsect.128.o autostart64.o

testboot: LDFLAGS += -t c64 -C c64-asm.cfg -u __EXEHDR__
testboot: testboot.o

-include *.dep
