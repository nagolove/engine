# GNU Make project makefile autogenerated by Premake

ifndef config
  config=debug
endif

ifndef verbose
  SILENT = @
endif

.PHONY: clean prebuild prelink

ifeq ($(config),debug)
  RESCOMP = windres
  TARGETDIR = .
  TARGET = $(TARGETDIR)/messenger2.so
  OBJDIR = obj/Debug/messenger2
  DEFINES += -DDEBUG
  INCLUDES += -I/usr/include/luajit-2.1 -I../../projects/Chipmunk2D/include -I../lua_capi -I/usr/include/SDL2
  FORCE_INCLUDE +=
  ALL_CPPFLAGS += $(CPPFLAGS) -MMD -MP $(DEFINES) $(INCLUDES)
  ALL_CFLAGS += $(CFLAGS) $(ALL_CPPFLAGS) -fPIC -g -ggdb3 -fPIC -Wall -Werror -Wno-strict-aliasing -D_REENTRANT
  ALL_CXXFLAGS += $(CXXFLAGS) $(ALL_CPPFLAGS) -fPIC -g -ggdb3 -fPIC -Wall -Werror -Wno-strict-aliasing -D_REENTRANT
  ALL_RESFLAGS += $(RESFLAGS) $(DEFINES) $(INCLUDES)
  LIBS += -llua5.1 -lchipmunk -lmem_guard -llua_tools -lpthread -lSDL2
  LDDEPS +=
  ALL_LDFLAGS += $(LDFLAGS) -L../../projects/Chipmunk2D/src -L../c_guard -L../lua_capi -shared -Wl,-soname=messenger2.so
  LINKCMD = $(CC) -o "$@" $(OBJECTS) $(RESOURCES) $(ALL_LDFLAGS) $(LIBS)
  define PREBUILDCMDS
  endef
  define PRELINKCMDS
  endef
  define POSTBUILDCMDS
  endef
all: prebuild prelink $(TARGET)
	@:

endif

ifeq ($(config),release)
  RESCOMP = windres
  TARGETDIR = .
  TARGET = $(TARGETDIR)/messenger2.so
  OBJDIR = obj/Release/messenger2
  DEFINES += -DNDEBUG
  INCLUDES += -I/usr/include/luajit-2.1 -I../../projects/Chipmunk2D/include -I../lua_capi -I/usr/include/SDL2
  FORCE_INCLUDE +=
  ALL_CPPFLAGS += $(CPPFLAGS) -MMD -MP $(DEFINES) $(INCLUDES)
  ALL_CFLAGS += $(CFLAGS) $(ALL_CPPFLAGS) -O2 -fPIC -ggdb3 -fPIC -Wall -Werror -Wno-strict-aliasing -D_REENTRANT
  ALL_CXXFLAGS += $(CXXFLAGS) $(ALL_CPPFLAGS) -O2 -fPIC -ggdb3 -fPIC -Wall -Werror -Wno-strict-aliasing -D_REENTRANT
  ALL_RESFLAGS += $(RESFLAGS) $(DEFINES) $(INCLUDES)
  LIBS += -llua5.1 -lchipmunk -lmem_guard -llua_tools -lpthread -lSDL2
  LDDEPS +=
  ALL_LDFLAGS += $(LDFLAGS) -L../../projects/Chipmunk2D/src -L../c_guard -L../lua_capi -shared -Wl,-soname=messenger2.so -s
  LINKCMD = $(CC) -o "$@" $(OBJECTS) $(RESOURCES) $(ALL_LDFLAGS) $(LIBS)
  define PREBUILDCMDS
  endef
  define PRELINKCMDS
  endef
  define POSTBUILDCMDS
  endef
all: prebuild prelink $(TARGET)
	@:

endif

OBJECTS := \
	$(OBJDIR)/messenger2.o \

RESOURCES := \

CUSTOMFILES := \

SHELLTYPE := posix
ifeq (.exe,$(findstring .exe,$(ComSpec)))
	SHELLTYPE := msdos
endif

$(TARGET): $(GCH) ${CUSTOMFILES} $(OBJECTS) $(LDDEPS) $(RESOURCES) | $(TARGETDIR)
	@echo Linking messenger2
	$(SILENT) $(LINKCMD)
	$(POSTBUILDCMDS)

$(CUSTOMFILES): | $(OBJDIR)

$(TARGETDIR):
	@echo Creating $(TARGETDIR)
ifeq (posix,$(SHELLTYPE))
	$(SILENT) mkdir -p $(TARGETDIR)
else
	$(SILENT) mkdir $(subst /,\\,$(TARGETDIR))
endif

$(OBJDIR):
	@echo Creating $(OBJDIR)
ifeq (posix,$(SHELLTYPE))
	$(SILENT) mkdir -p $(OBJDIR)
else
	$(SILENT) mkdir $(subst /,\\,$(OBJDIR))
endif

clean:
	@echo Cleaning messenger2
ifeq (posix,$(SHELLTYPE))
	$(SILENT) rm -f  $(TARGET)
	$(SILENT) rm -rf $(OBJDIR)
else
	$(SILENT) if exist $(subst /,\\,$(TARGET)) del $(subst /,\\,$(TARGET))
	$(SILENT) if exist $(subst /,\\,$(OBJDIR)) rmdir /s /q $(subst /,\\,$(OBJDIR))
endif

prebuild:
	$(PREBUILDCMDS)

prelink:
	$(PRELINKCMDS)

ifneq (,$(PCH))
$(OBJECTS): $(GCH) $(PCH) | $(OBJDIR)
$(GCH): $(PCH) | $(OBJDIR)
	@echo $(notdir $<)
	$(SILENT) $(CC) -x c-header $(ALL_CFLAGS) -o "$@" -MF "$(@:%.gch=%.d)" -c "$<"
else
$(OBJECTS): | $(OBJDIR)
endif

$(OBJDIR)/messenger2.o: messenger2.c
	@echo $(notdir $<)
	$(SILENT) $(CC) $(ALL_CFLAGS) $(FORCE_INCLUDE) -o "$@" -MF "$(@:%.o=%.d)" -c "$<"

-include $(OBJECTS:%.o=%.d)
ifneq (,$(PCH))
  -include $(OBJDIR)/$(notdir $(PCH)).d
endif