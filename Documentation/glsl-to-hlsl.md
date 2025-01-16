
Instead, convert to SPV and run shadercross on the SPV file:

glslc -fshader-stage=frag shader.frag  -o shader.frag.spv
shadercross shader.frag.spv -o shader_fs.msl