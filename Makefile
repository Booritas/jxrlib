## Makefile for building JPEG XR Porting Kit
##
build: all

CC=cc

JXR_VERSION=1.1

DIR_SRC=$(CURDIR)
DIR_SYS=image/sys
DIR_DEC=image/decode
DIR_ENC=image/encode

DIR_GLUE=jxrgluelib
DIR_TEST=jxrtestlib
DIR_EXEC=jxrencoderdecoder

## Are we building shared?
ifneq ($(SHARED),)
PICFLAG=-fPIC
else
PICFLAG=
endif

ifneq ($(BIG_ENDIAN),)
ENDIANFLAG=-D_BIG__ENDIAN_
else
ENDIANFLAG=
endif

ifndef DIR_BUILD
DIR_BUILD=$(CURDIR)/build
endif

ifndef DIR_INSTALL
DIR_INSTALL=/usr
endif

CD=cd
MK_DIR=mkdir -p
CFLAGS=-I. -Icommon/include -I$(DIR_SYS) $(ENDIANFLAG) -D__ANSI__ -DDISABLE_PERF_MEASUREMENT -w $(PICFLAG) -O

SHARED_LIBRARIES=$(DIR_BUILD)/libjxrglue.so $(DIR_BUILD)/libjpegxr.so
STATIC_LIBRARIES=$(DIR_BUILD)/libjxrglue.a $(DIR_BUILD)/libjpegxr.a

ifneq ($(SHARED),)
LIBRARIES=$(SHARED_LIBRARIES)
else
LIBRARIES=$(STATIC_LIBRARIES)
endif

LIBS=-L$(DIR_BUILD) $(shell echo $(LIBRARIES) | sed -e 's%$(DIR_BUILD)/lib\([^ ]*\)\.\(a\|so\)%-l\1%g') -lm

##--------------------------------
##
## Common files
##

SRC_SYS=adapthuff.c image.c strcodec.c strPredQuant.c strTransform.c perfTimerANSI.c
OBJ_SYS=$(patsubst %.c, $(DIR_BUILD)/$(DIR_SYS)/%.o, $(SRC_SYS))
 
$(DIR_BUILD)/$(DIR_SYS)/%.o: $(DIR_SRC)/$(DIR_SYS)/%.c
	$(MK_DIR) $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

##--------------------------------
##
## Decode files
##

SRC_DEC=decode.c postprocess.c segdec.c strdec.c strInvTransform.c strPredQuantDec.c JXRTranscode.c
OBJ_DEC=$(patsubst %.c, $(DIR_BUILD)/$(DIR_DEC)/%.o, $(SRC_DEC))
$(DIR_BUILD)/$(DIR_DEC)/%.o: $(DIR_SRC)/$(DIR_DEC)/%.c
	$(MK_DIR) $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

##--------------------------------
##
## Encode files
##

SRC_ENC=encode.c segenc.c strenc.c strFwdTransform.c strPredQuantEnc.c
OBJ_ENC=$(patsubst %.c, $(DIR_BUILD)/$(DIR_ENC)/%.o, $(SRC_ENC))

$(DIR_BUILD)/$(DIR_ENC)/%.o: $(DIR_SRC)/$(DIR_ENC)/%.c
	$(MK_DIR) $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

##--------------------------------
##
## JPEG XR library
##

$(DIR_BUILD)/libjpegxr.a: $(OBJ_ENC) $(OBJ_DEC) $(OBJ_SYS)
	$(MK_DIR) $(@D)
	ar rvu $@ $(OBJ_ENC) $(OBJ_DEC) $(OBJ_SYS)
	ranlib $@

$(DIR_BUILD)/libjpegxr.so: $(OBJ_ENC) $(OBJ_DEC) $(OBJ_SYS)
	$(MK_DIR) $(@D)
	$(CC) -shared $? -o $@

##--------------------------------
##
## Glue files
##

SRC_GLUE=JXRGlue.c JXRMeta.c JXRGluePFC.c JXRGlueJxr.c
OBJ_GLUE=$(patsubst %.c, $(DIR_BUILD)/$(DIR_GLUE)/%.o, $(SRC_GLUE))

$(DIR_BUILD)/$(DIR_GLUE)/%.o: $(DIR_SRC)/$(DIR_GLUE)/%.c
	$(MK_DIR) $(@D)
	$(CC) $(CFLAGS) -I$(DIR_GLUE) -c $< -o $@

##--------------------------------
##
## Test files
##

SRC_TEST=JXRTest.c JXRTestBmp.c JXRTestHdr.c JXRTestPnm.c JXRTestTif.c JXRTestYUV.c
OBJ_TEST=$(patsubst %.c, $(DIR_BUILD)/$(DIR_TEST)/%.o, $(SRC_TEST))

$(DIR_BUILD)/$(DIR_TEST)/%.o: $(DIR_SRC)/$(DIR_TEST)/%.c
	$(MK_DIR) $(@D)
	$(CC) $(CFLAGS) -I$(DIR_GLUE) -I$(DIR_TEST) -c $< -o $@

##--------------------------------
##
## JPEG XR Glue library
##

$(DIR_BUILD)/libjxrglue.a: $(OBJ_GLUE) $(OBJ_TEST)
	$(MK_DIR) $(@D)
	ar rvu $@ $(OBJ_GLUE) $(OBJ_TEST)
	ranlib $@

$(DIR_BUILD)/libjxrglue.so: $(OBJ_GLUE) $(OBJ_TEST)
	$(MK_DIR) $(@D)
	$(CC) -shared $? -o $@

##--------------------------------
##
## Enc app files
##
ENCAPP=JxrEncApp

$(DIR_BUILD)/$(ENCAPP): $(DIR_SRC)/$(DIR_EXEC)/$(ENCAPP).c $(LIBRARIES)
	$(MK_DIR) $(@D)
	$(CC) $< -o $@ $(CFLAGS) -I$(DIR_GLUE) -I$(DIR_TEST) $(LIBS)

##--------------------------------
##
## Dec app files
##

DECAPP=JxrDecApp

$(DIR_BUILD)/$(DECAPP): $(DIR_SRC)/$(DIR_EXEC)/$(DECAPP).c $(LIBRARIES)
	$(MK_DIR) $(@D)
	$(CC) $< -o $@ $(CFLAGS) -I$(DIR_GLUE) -I$(DIR_TEST) $(LIBS)

##--------------------------------
##
## JPEG XR library
##
all: $(DIR_BUILD)/$(ENCAPP) $(DIR_BUILD)/$(DECAPP) $(LIBRARIES)

clean:
	rm -rf $(DIR_BUILD)/*App $(DIR_BUILD)/*.o $(DIR_BUILD)/libj*.a $(DIR_BUILD)/libj*.so $(DIR_BUILD)/libjxr.pc

$(DIR_BUILD)/libjxr.pc: $(DIR_SRC)/libjxr.pc.in
	@python -c 'import os; d = { "DIR_INSTALL": "$(DIR_INSTALL)", "JXR_VERSION": "$(JXR_VERSION)", "JXR_ENDIAN": "$(ENDIANFLAG)" }; fin = open("$<", "r"); fout = open("$@", "w+"); fout.writelines( [ l % d for l in fin.readlines()])'

install: all $(DIR_BUILD)/libjxr.pc
	install -d $(DIR_INSTALL)/lib/pkgconfig $(DIR_INSTALL)/bin $(DIR_INSTALL)/include/jxrlib  $(DIR_INSTALL)/include/jxrlib $(DIR_INSTALL)/include/jxrlib $(DIR_INSTALL)/include $(DIR_INSTALL)/share/doc/jxr-$(JXR_VERSION)
	install $(LIBRARIES) $(DIR_INSTALL)/lib
	install -m 644 $(DIR_BUILD)/libjxr.pc $(DIR_INSTALL)/lib/pkgconfig
	install $(DIR_BUILD)/$(ENCAPP) $(DIR_BUILD)/$(DECAPP) $(DIR_INSTALL)/bin
	install -m 644 $(DIR_SRC)/common/include/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 $(DIR_SRC)/image/x86/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 $(DIR_SRC)/$(DIR_SYS)/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 $(DIR_SRC)/$(DIR_ENC)/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 $(DIR_SRC)/$(DIR_DEC)/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 $(DIR_SRC)/$(DIR_GLUE)/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 $(DIR_SRC)/$(DIR_TEST)/*.h $(DIR_INSTALL)/include/jxrlib
	install -m 644 doc/* $(DIR_INSTALL)/share/doc/jxr-$(JXR_VERSION)

##
