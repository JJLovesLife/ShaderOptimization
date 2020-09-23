# Attribute Interpolation
### Shader description
VS take position and color as inputs.  
PS outputs the interpolated color.

---
First look at how attribute is interpolated in pixel shader.  

### Vertex Shader
The VS is almost identical to the one in HelloPipeline,
except the instructions load and output the vertex data,
since we load another color data this time.
```
  s_mov_b32     s2, s10
  s_mov_b32     s3, s15
  s_load_dwordx8  s[12:19], s[2:3], null
```
load two addresses from the same address store in s[10, 15].

```
  tbuffer_load_format_xyzw  v[2:5], v[0:1], s[12:15], 0 idxen offen format:[BUF_FMT_32_32_32_32_FLOAT]
  tbuffer_load_format_xyzw  v[6:9], v[0:1], s[16:19], 0 idxen offen format:[BUF_FMT_32_32_32_32_FLOAT]
  s_waitcnt     vmcnt(1)
  exp           pos0, v2, v3, v4, v5 done
  s_waitcnt     vmcnt(0)
  exp           param0, v6, v7, v8, v9
```
This time we output not only the position data, but also the param0, which is the color attribute.

### Pixel Shader
#### Interpolation
```
  s_mov_b32     m0, s2
  v_interp_p1_f32  v2, v0, attr0.x
  v_interp_p1_f32  v3, v0, attr0.y
  v_interp_p1_f32  v4, v0, attr0.z
  v_interp_p1_f32  v0, v0, attr0.w
  v_interp_p2_f32  v2, v1, attr0.x
  v_interp_p2_f32  v3, v1, attr0.y
  v_interp_p2_f32  v4, v1, attr0.z
  v_interp_p2_f32  v0, v1, attr0.w
  v_cvt_pkrtz_f16_f32  v2, v2, v3
  v_cvt_pkrtz_f16_f32  v3, v4, v0
  exp           mrt0, v2, v2, v3, v3 done compr vm
```
First, write the m0 SGPR, which contain the offset of where parameters store and
new_prim_mask(indicate a new primitive begins, the exact usage is still unkown).

For homogeneous interpolated attribute, the result can be calculated with equation `P0 + P10 * I + P20 * J`,  
where `I` and `J` are the barycentric coordinates, and `P0, P10, P20` are determined per parameter.

`v_interp_p1_f32` does the first fma operation `P0 + P10 * I`.  
`v_interp_p2_f32` does the second fma operation `(..) + P20 * J`.  
For the four components of color, the previous two instructions are executed to get the correct interpolated result.  

`v_cvt_pkrtz_f16_f32` pack the four float components into two packed FP16 in order to export with compress.  


#### Summary
Parameter interpolations are done by equation `P0 + P10 * I + P20 * J`.  
Barycentric coordinates `I` and `J` are shared across all parameters.  
`P0, P10, P20` are calculated for each parameters in rasterization stage(IMHO).  

---
## Command
```
dxc.exe -E VsMain -T vs_6_0 -spirv .\Interpolation.hlsl -Fo .\Output\out_vert.spv
dxc.exe -E PsMain -T ps_6_0 -spirv .\Interpolation.hlsl -Fo .\Output\out_frag.spv
rga.exe -s vk-spv-offline -c gfx1010 --O1 --isa .\Output\ --vert .\Output\out_vert.spv --frag .\Output\out_frag.spv
```
