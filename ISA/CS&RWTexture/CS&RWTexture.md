# CS & RWTexture
### Shader description
Use compute shader to write texture partly (not all component).  

---
### Compute shader
#### SV_DispatchThreadID
In HLSL:
```
[numthreads(16, 8, 1)]
```
In ISA:
```
  s_and_b32     s0, s5, lit(0x00ffffff)
  v_mad_u32_u24  v2, s3, 16, v0
  v_mad_u32_u24  v1, s4, 8, v1
```
According to the ISA guide and the instruction, it is clear that `s3, s4, s5` is the `SV_GroupID`.  

Notice, instead of the full 32-bits uint, the least 24-bits is used.  
IMHO, I believe there are two reasons:  

1. 24-bits integer operations are faster than 32-bits.
And it is possible to reuse the float operation hardware(significand precision is 24 bits).  
2. In [XGL](https://github.com/GPUOpen-Drivers/xgl), the maximum number of one dimension of dispatch command is **65535**, which is in range of 24-bits.  

After the multiplication(not sure why it isn't optimized to shift), `v2, v1, s0` contain the `SV_DispatchThreadID`.  

##### Comments
Will manuallay compute the `SV_DispatchThreadID` be faster? I'm  not sure.  
In manually computed version, compiler is able to optimise the multiplication into shift. and the `s_and_b32` instruction is skipped.  
But I'm using the offline compiler, I'm not sure whether it will be better in the driver mode. More information is needed.

#### RWTexture
```
  image_load    v[3:4], [v2,v1], s[4:11] dmask:0x5 dim:SQ_RSRC_IMG_2D
  s_waitcnt     vmcnt(0)
  v_mov_b32     v5, v4
  v_mov_b32     v4, s0
  image_store   v[3:6], [v2,v1], s[4:11] dmask:0xf dim:SQ_RSRC_IMG_2D unorm glc
```
The `image_store` is used to write data into texture.  
This instruction takes into one T# and an unorm coordinate.  
Note, according to the ISA guide, write instruction will override all the components.
However we only write to the `y` component of `uint3` in sample HLSL code,
therefore we have to read other components first, then combine all the components before writing.  
That's why the result ISA will contain one `image_load` instruction.  

##### Comments
For better performance, we should write all components instead of some of them.  
The situation for NVIDIA is still unclear.

---
## Command
```
dxc.exe -E CsMain -T cs_6_0 -spirv .\RWTexture.hlsl -Fo .\Output\out_comp.spv
rga.exe -s vk-spv-offline -c gfx1010 --O1 --isa .\Output\ --comp .\Output\out_comp.spv
```
