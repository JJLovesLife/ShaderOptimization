# HelloPipeling
### Shader description
Basic graphics pipeline shader, take into position of vert, draw a white triangle.

---
This is a single vertex shader pass the vertex position from vertex buffer to the pixel shader,
and the pixel shader just fill the pixel with white color.  
From these two shaders, we could have a basis understanding of  
1. how vertex shader extract data from vertex buffer.  
2. how vertex shader output position.  
3. how pixel shader output color.  

### Pixel Shader
The pixel shader's ISA result is much simpler than vertex shader's, hence we'll look at the pixel shader first.  
There are only 5 instructions:
```
  s_inst_prefetch  0x0003
  v_mov_b32     v0, lit(0x3c003c00)
  v_mov_b32     v1, lit(0x3c003c00)
  exp           mrt0, v0, v0, v1, v1 done compr vm
  s_endpgm
```
`s_inst_prefetch` changes the instruction prefetch mode, skip.  
`v_mov_b32` write 4 16-bits floats of 1.0 into packed VGPR v0, v1,
that is the white color but with 16-bits float instead of single precision float.  
Kind of registers usage optimization, I guess.  
`exp` writes the float4 color into the render targt 0.  
`s_endpgm` terminated the shader.  

This plain pixel shader does not worth too much discussion,
we will talk more about pixel shader in later article.  
Now, let's move to the vertex shader.

### Vertex Shader
#### GS 
`type(GS)`  
The first strange things to notice is that the vertex shader is changed into **GS** in hardware.  
IMHO, the GS may not influence the performance as long as the prim count doe not exceed the limit(?)  

#### ID
```
  s_mov_b64     exec, -1
  s_getpc_b64   s[14:15]
  s_inst_prefetch  0x0003
  v_mbcnt_lo_u32_b32  v2, -1, 0
  s_bfe_u32     s0, s3, lit(0x00040018)
  s_bfe_u32     s1, s2, lit(0x00090016)
  s_bfe_u32     s2, s2, lit(0x0009000c)
  v_mbcnt_hi_u32_b32  v2, -1, v2
  v_mad_u32_u24  v2, s0, 64, v2
  s_barrier
```
Those instructions extract some value from packed preset SGPR.  
We'll talk about *s1, s2* later.  
According to the ISA guide, the s0 is the wave in subgroup.
By adding the wave ID in wavefront in v2, we get the wave ID in wavegroup in v2.  
For some reasons, the shader wait for all waves to stop after those opeartions.  

#### GS ALLOC
```
  s_cmp_lt_u32  s0, 1
  s_cbranch_scc0  label_0054
  s_lshl_b32    s0, s1, 12
  s_or_b32      m0, s2, s0
  s_sendmsg     sendmsg(MSG_GS_ALLOC_REQ, GS_OP_NOP, 0)
```
In the first wave in subgroup, the shader request some GS space.  
Accordint to the ISA guide, the s1 register store the *number of primitives*, the s2 register store the number of vertices.  

#### Prim export
```
  v_cmp_gt_u32  vcc, s1, v2
  s_and_saveexec_b64  s[0:1], vcc
  s_cbranch_execz  label_0068
  exp           prim, v0, off, off, off done
```
For waves whose ID within the number of primitives, shader export the primitive data v0.  
However, the exact content of v0 is unknown.  

#### Position export
```
  s_waitcnt     expcnt(0)
  s_mov_b64     exec, s[0:1]
  v_cmp_gt_u32  vcc, s2, v2
  s_and_b64     exec, s[0:1], vcc
  v_add_nc_u32  v0, s11, v5
  s_cbranch_execz  label_00AC
  s_mov_b32     s11, s15
  s_load_dwordx4  s[4:7], s[10:11], null
  v_mov_b32     v1, 0
  s_waitcnt     lgkmcnt(0)
  s_waitcnt_depctr  0xffe3
  tbuffer_load_format_xyzw  v[0:3], v[0:1], s[4:7], 0 idxen offen format:[BUF_FMT_32_32_32_32_FLOAT]
  s_waitcnt     vmcnt(0)
  exp           pos0, v0, v1, v2, v3 done
```
For shaders whose group ID within the number of vertices,
shader loads an address from s[10, 15].  
And from that address, with index of v5 + s11 (exact content also unknown), shader load the position data with format of float4.  
My guess: s11 may be the `BaseVertexLocation` of `DrawIndexedInstanced`; and v5 may the index of each vertex.  

Finally, the shader export the loaded position data to position 0.  

#### Summary
Instead of using VS, RGA chose to use GS.  
GS export primitive data and position from some unknown source.  
PS export the final color and depth.

---
## Command
```
dxc.exe -E VsMain -T vs_6_0 -spirv .\Hello.hlsl -Fo .\Output\out_vert.spv
dxc.exe -E PsMain -T ps_6_0 -spirv .\Hello.hlsl -Fo .\Output\out_frag.spv
rga.exe -s vk-spv-offline -c gfx1010 --O1 --isa .\Output\ --vert .\Output\out_vert.spv --frag .\Output\out_frag.spv
```
