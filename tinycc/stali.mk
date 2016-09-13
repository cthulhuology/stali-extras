ROOT=../../src

include $(ROOT)/config.mk

top_srcdir = .

CFLAGS += -I. -Ilib 
CPPFLAGS +=

CPPFLAGS_P=$(CPPFLAGS) -DCONFIG_TCC_STATIC
CFLAGS_P=$(CFLAGS) -pg -static
LIBS_P=
LDFLAGS_P=$(LDFLAGS)


LIB = libtcc.a
LIBTCC = $(LIB)
LINK_LIBTCC= -static

BIN = tcc

CORE_FILES = tcc.c libtcc.c tccpp.c tccgen.c tccelf.c tccasm.c tccrun.c
CORE_FILES += tcc.h config.h libtcc.h tcctok.h
X86_64_FILES = $(CORE_FILES) x86_64-gen.c i386-asm.c x86_64-asm.h

OBJ = tcc.o libtcc.o tccpp.o tccgen.o tccelf.o tccasm.o tccrun.o x86_64-gen.o i386-asm.o 

CONFIG_x86-64 = yes
NATIVE_DEFINES += -DTCC_TARGET_X86_64

TCCLIBS = $(LIBTCC1) $(LIBTCC) $(LIBTCC_EXTRA)
TCCDOCS = tcc.1

NATIVE_FILES=$(X86_64_FILES)


all: $(LIB) $(OBJ) $(BIN) $(PROGS) $(TCCDOCS)

tcc: tcc.o $(LIBTCC)
	$(CC) -o $@ $^ $(LIBS) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(LINK_LIBTCC)


LIBTCC_OBJ = $(filter-out tcc.o,$(patsubst %.c,%.o,$(filter %.c,$(NATIVE_FILES))))
LIBTCC_INC = $(filter %.h,$(CORE_FILES)) $(filter-out $(CORE_FILES),$(NATIVE_FILES))

$(LIBTCC_OBJ) tcc.o : %.o : %.c $(LIBTCC_INC)
	echo "Building libtcc.a"
	$(CC) -o $@ -c $< $(NATIVE_DEFINES) $(CPPFLAGS) $(CFLAGS)

libtcc.a: $(LIBTCC_OBJ)
	$(AR) rcs $@ $^

libtcc1.a : FORCE $(PROGS)
	$(MAKE) -C lib native

# install
TCC_INCLUDES = stdarg.h stddef.h stdbool.h float.h varargs.h
INSTALL=install
ifdef STRIP_BINARIES
INSTALLBIN=$(INSTALL) -s
else
INSTALLBIN=$(INSTALL)
endif

install-strip: install
	strip $(foreach PROG,$(PROGS),"$(bindir)"/$(PROG))

install: $(PROGS) $(TCCLIBS) $(TCCDOCS)
	mkdir -p "$(bindir)"
	$(INSTALLBIN) -m755 $(PROGS) "$(bindir)"
	cp -P tcc "$(bindir)"
	mkdir -p "$(mandir)/man1"
	-$(INSTALL) -m644 tcc.1 "$(mandir)/man1"
	mkdir -p "$(tccdir)"
	mkdir -p "$(tccdir)/include"
	$(INSTALL) -m644 $(addprefix $(top_srcdir)/include/,$(TCC_INCLUDES)) $(top_srcdir)/tcclib.h "$(tccdir)/include"
	mkdir -p "$(libdir)"
	$(INSTALL) -m644 $(LIBTCC) "$(libdir)"
	mkdir -p "$(includedir)"
	$(INSTALL) -m644 $(top_srcdir)/libtcc.h "$(includedir)"
	mkdir -p "$(tccdir)/x86-64"
	$(INSTALL) -m644 lib/x86_64/libtcc1.a "$(tccdir)/x86-64"

tcc.1: tcc-doc.texi
	-$(top_srcdir)/texi2pod.pl $< tcc.pod
	-pod2man --section=1 --center="Tiny C Compiler" --release=`cat $(top_srcdir)/VERSION` tcc.pod > $@



uninstall:
	rm -fv $(foreach P,$(PROGS),"$(bindir)/$P")
	rm -fv "$(bindir)/tcc"
	rm -fv $(foreach P,$(LIBTCC1),"$(tccdir)/$P")
	rm -fv $(foreach P,$(TCC_INCLUDES),"$(tccdir)/include/$P")
	rm -fv "$(mandir)/man1/tcc.1"
	rm -fv "$(libdir)/$(LIBTCC)" "$(includedir)/libtcc.h"
	rm -rv "$(tccdir)"


clean:
	rm -vf $(PROGS) tcc_p tcc.pod *~ *.o *.a *.so* *.out *.log *.1\
		*.exe a.out tags TAGS libtcc_test tcc


distclean: clean
	rm -vf config.h config.mak config.texi tcc.1 tcc-doc.info tcc-doc.html

tags:
	ctags $(top_srcdir)/*.[ch] $(top_srcdir)/include/*.h $(top_srcdir)/lib/*.[chS]

TAGS:
	ctags -e $(top_srcdir)/*.[ch] $(top_srcdir)/include/*.h $(top_srcdir)/lib/*.[chS]

.PHONY: all clean tar tags TAGS distclean install uninstall FORCE


