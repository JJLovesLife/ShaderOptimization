# Basic Texture
### Shader description
PS uses interpolated texture coordinate to sample a texture.  

---
First look at how texture sample works.

### Pixel Shader
#### Quad execute
```
  s_mov_b64     s[12:13], exec
  s_wqm_b64     exec, exec
```
We know that texture sample works with a quad mode since it needs the derivative.  
`s_wqrm_b64` expand the execute mask to the quad execute mask.  

#### Texture sample
```
image_sample  v[0:3], [v2,v0], s[4:11], s[0:3] dmask:0xf dim:SQ_RSRC_IMG_2D
```
Tha texture sample instruction takes into a **T#(image resource constant) and a S#(sampler constant)**.  
Then the texture cache sample the texture descripted by T#, in the way descripted by S#, at address provided by SGPR.

```
  s_load_dwordx8  s[4:11], s[0:1], null
  s_load_dwordx4  s[0:3], s[0:1], 0x000020
```
T# and S# are loaded from memory with scalar memory operations.

##### Format, layout etc
The sample instruction descripted the component and dimension wanted.  
The T# provided *the resource view*, which contains format, dimension etc of the resource view.  
The S# provided some rules applied when sampling the image.  

---
## Command
```
dxc.exe -E VsMain -T vs_6_0 -spirv .\Texture.hlsl -Fo .\Output\out_vert.spv
dxc.exe -E PsMain -T ps_6_0 -spirv .\Texture.hlsl -Fo .\Output\out_frag.spv
rga.exe -s vk-spv-offline -c gfx1010 --O1 --isa .\Output\ --vert .\Output\out_vert.spv --frag .\Output\out_frag.spv
```
