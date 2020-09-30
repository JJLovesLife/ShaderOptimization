# Group Shared
### Shader description
Use group shared memory to store some data, and read it back for ouput.

---
### Compute shader
Basically, there are two things that worth discussing.  

1. What will `GroupMemoryBarrierWithGroupSync` do?  
2. Where will `groupshared` map to?

#### GroupMemoryBarrierWithGroupSync
Actually, this function does not map to any particulay instruction,  
as long as the group size with 64 waves.  
That's pretty straightforward since one wavefront contains 64 waves,
and waves in the same wavefront execute simultaneously.  

However, when group size exceeded 64, waves will split into multi wavefronts.  
That's where `s_barrier` comes in. This instruction will synchronize all waves within the same group.  

#### groupshared
It won't be surprised that groupshared is implemented by LDS.  
```
  ds_write_b32  v2, v2

  ds_read_b32   v0, v0
```
These two instructions are used to read and write to the LDS memory.

##### Comments
For shader code like this:
```
  if (gIdx == 0) {
    s_tranparentExist = false;
  }
```
should we write to LDS in only one wave?  
The advantage is we only need to write to LDS once.  

But the advantage of write to LDS in all waves is that
we can reduce one branch.  

Also I mean, can hardware optimizes writing to the same LDS location?  
If it's possible, writing in all waves won't take more time to execute.  

However, if my understanding is correct, you will have to execute the write instruction
twice, one for the lower 32 waves, the other for the higher 32 waves.
That takes one more cycle too.  

Besides, if group size exceeded the 64 limits,
you will have to write to the LDS in more than one wavefronts.  
But for most cases, group size is withn 64 waves, so that's not a big problem.  

In short, my humble opinion, based on the current infomation, write in only one wave is a better pratice.  

---
## Command
```
dxc.exe -E CsMain -T cs_6_0 -spirv .\GroupShared.hlsl -Fo .\Output\out_comp.spv
rga.exe -s vk-spv-offline -c gfx1010 --O1 --isa .\Output\ --comp .\Output\out_comp.spv
```
