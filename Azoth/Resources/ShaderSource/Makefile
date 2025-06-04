
GLSL_VERTS	= $(shell ls -1 *.vert)
GLSL_FRAGS	= $(shell ls -1 *.frag)
#GLSL_COMPS	= $(shell ls -1 *.comp)

SPIRV_VERTS	= $(GLSL_VERTS:.vert=.vert.spv)
SPIRV_FRAGS	= $(GLSL_FRAGS:.frag=.frag.spv)
SPIRV_COMPS	= $(GLSL_COMPS:.comp=.comp.spv)

GLSL		= $(GLSL_VERTS) $(GLSL_FRAGS) $(GLSL_COMPS)
SPIRV		= $(SPIRV_VERTS) $(SPIRV_FRAGS) $(SPIRV_COMPS)

DST_METAL	= ../Shaders/metal/
METAL_FILES	= $(addprefix $(DST_METAL), $(SPIRV:.spv=.msl))

DST_VULCAN	= ../Shaders/vulcan/

DST_DX		= ../Shaders/directx/
DX_FILES	= $(addprefix $(DST_DX), $(SPIRV:.spv=.dxil))

SHADERCROSS = $(HOME)/bin/shadercross
GLSLC 		= /usr/local/bin/glslc

all: prepare vulcan metal directx

prepare:
	$(MKDIR) $(DST_METAL) $(DST_DX) $(DST_VULCAN)

metal: $(SPIRV) $(METAL_FILES)

vulcan: $(SPIRV) 
	@ $(CP) $(SPIRV) $(DST_VULCAN)
	
directx: $(SPIRV) $(DX_FILES)

clean:
	$(RM) $(SPIRV)


# ----------------------------------------------------------------------------
# Tool definitions

MKDIR		= /bin/mkdir -p
CP			= /bin/cp
RM			= /bin/rm -f


# ----------------------------------------------------------------------------
# Pattern rules for the different types of file

%.vert.spv: %.vert
	$(GLSLC) -fshader-stage=vert $<  -o $@

%.frag.spv: %.frag
	$(GLSLC) -fshader-stage=frag $<  -o $@

%.comp.spv: %.comp
	$(GLSLC) -fshader-stage=comp $<  -o $@

../Shaders/metal/%.msl: %.spv
	$(SHADERCROSS) $< -o $@

../Shaders/directx/%.dxil: %.spv
	$(SHADERCROSS) $< -o $@
	

.SUFFIXES: .vert .spv .msl .dxil