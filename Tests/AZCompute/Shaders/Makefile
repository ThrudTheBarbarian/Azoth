
HLSL_VERTS	= $(wildcard *.vert)
HLSL_FRAGS	= $(wildcard *.frag)
HLSL_COMPS	= $(wildcard *.comp)

SPIRV_VERTS	= $(HLSL_VERTS:.vert=.vert.spv)
SPIRV_FRAGS	= $(HLSL_FRAGS:.frag=.frag.spv)
SPIRV_COMPS	= $(HLSL_COMPS:.comp=.comp.spv)

GLSL		= $(HLSL_VERTS) $(HLSL_FRAGS) $(HLSL_COMPS)
SPIRV		= $(SPIRV_VERTS) $(SPIRV_FRAGS) $(SPIRV_COMPS)

DST_METAL	= ../Resources/Shaders/metal/
METAL_FILES	= $(addprefix $(DST_METAL), $(SPIRV:.spv=.msl))

DST_VULCAN	= ../Resources/Shaders/vulcan/

DST_DX		= ../Resources/Shaders/directx/
DX_FILES	= $(addprefix $(DST_DX), $(SPIRV:.spv=.dxil))

SHADERCROSS = $(HOME)/bin/shadercross
GLSLC		= /usr/local/bin/glslc

all: vulcan metal directx
	make clean
		
vulcan: $(SPIRV) 
	cp $(SPIRV) $(DST_VULCAN)

metal: $(SPIRV) $(METAL_FILES)
	
directx: $(SPIRV) $(DX_FILES)

clean:
	rm -f $(SPIRV)


# ----------------------------------------------------------------------------
# Pattern rules for the different types of file

%.vert.spv: %.vert
	$(GLSLC) -x hlsl -fshader-stage=vert $<  -o $@

%.frag.spv: %.frag
	$(GLSLC) -x hlsl -fshader-stage=frag $<  -o $@

%.comp.spv: %.comp
	$(GLSLC) -x hlsl -fshader-stage=comp $<  -o $@

../Resources/Shaders/metal/%.msl: %.spv
	$(SHADERCROSS) $< -o $@

../Resources/Shaders/directx/%.dxil: %.spv
	$(SHADERCROSS) $< -o $@
	

.SUFFIXES: .vert .spv .msl .dxil