# (C)2004-2008 SourceMod Development Team
# Makefile written by David "BAILOPAN" Anderson

SMSDK ?= ../_SDK_PLATFORM/sourcemod
SRCDS_BASE ?= ../_SDK_PLATFORM/srcds
MMSOURCE ?= ../_SDK_PLATFORM/mmsource
HL2SDK_L4D2 ?= ../_SDK_PLATFORM/hl2sdk-l4d2


#####################################
### EDIT BELOW FOR OTHER PROJECTS ###
#####################################

PROJECT = connecthook

OBJECTS = sdk/smsdk_ext.cpp extension.cpp util.cpp CDetour/detours.cpp asm/asm.c

##############################################
### CONFIGURE ANY OTHER FLAGS/OPTIONS HERE ###
##############################################

C_OPT_FLAGS = -DNDEBUG -O2 -funroll-loops -pipe -fno-strict-aliasing
C_DEBUG_FLAGS = -D_DEBUG -DDEBUG -g -ggdb3
C_GCC4_FLAGS = -fvisibility=hidden
CPP_GCC4_FLAGS = -fvisibility-inlines-hidden
CPP = gcc


HL2SDK = $(HL2SDK_L4D2)
HL2PUB = $(HL2SDK)/public
HL2LIB = $(HL2SDK)/lib/linux
CFLAGS += -DSOURCE_ENGINE=6
METAMOD = $(MMSOURCE)/core
SRCDS = $(SRCDS_BASE)/left4dead2
INCLUDE += -I$(HL2SDK)/public/game/server
VSTDLIB = libvstdlib_srv.so
TIER0 = libtier0_srv.so
LIBDIR = $(HL2LIB)
BINARY = $(PROJECT).ext.2.l4d2.so

LINK_HL2 = $(HL2LIB)/tier1_i486.a $(VSTDLIB) $(TIER0)

LINK += $(LINK_HL2)

INCLUDE += -I. -I.. -Isdk -I$(HL2PUB) -I$(HL2PUB)/engine -I$(HL2PUB)/steam -I$(HL2PUB)/mathlib -I$(HL2PUB)/tier0 \
	-I$(HL2PUB)/tier1 -I$(METAMOD) -I$(METAMOD)/sourcehook -I$(SMSDK)/public -I$(SMSDK)/public/extensions \
	-I$(SMSDK)/public/sourcepawn

CFLAGS += -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_ORANGEBOXVALVE=4 -DSE_LEFT4DEAD=5 -DSE_LEFT4DEAD2=6

LINK += -static-libgcc

CFLAGS += -D_LINUX -Dstricmp=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -Dstrnicmp=strncasecmp \
	-D_snprintf=snprintf -D_vsnprintf=vsnprintf -D_alloca=alloca -Dstrcmpi=strcasecmp -Wall -Werror -Wno-switch \
	-Wno-unused -mfpmath=sse -msse -DSOURCEMOD_BUILD -DHAVE_STDINT_H -m32
CPPFLAGS += -Wno-non-virtual-dtor -fno-exceptions -fno-rtti

################################################
### DO NOT EDIT BELOW HERE FOR MOST PROJECTS ###
################################################

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS += $(C_DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS += $(C_OPT_FLAGS)
endif

BIN_DIR := $(BIN_DIR)

GCC_VERSION := $(shell $(CPP) -dumpversion >&1 | cut -b1)
ifeq "$(GCC_VERSION)" "4"
	CFLAGS += $(C_GCC4_FLAGS)
	CPPFLAGS += $(CPP_GCC4_FLAGS)
endif

OBJ_LINUX := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

all:
	mkdir -p $(BIN_DIR)/sdk
	mkdir -p $(BIN_DIR)/CDetour
	mkdir -p $(BIN_DIR)/asm
	ln -sf $(LIBDIR)/$(VSTDLIB) $(VSTDLIB)
	ln -sf $(LIBDIR)/$(TIER0) $(TIER0)
	$(MAKE) -f Makefile extension


extension: $(OBJ_LINUX)
	$(CPP) $(INCLUDE) $(OBJ_LINUX) $(LINK) -m32 -shared -ldl -lm -o$(BIN_DIR)/$(BINARY)

debug:
	$(MAKE) -f Makefile all DEBUG=true

default: all

clean:
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/sdk/*.o
	rm -rf $(BIN_DIR)/$(BINARY)
