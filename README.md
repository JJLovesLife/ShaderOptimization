# Description
This project is a collection of article talking about shader optimization and shader execution in GPU.  
This analysis is mainly based on the compilation result of [RGA](https://github.com/GPUOpen-Tools/radeon_gpu_analyzer).  

# Shader compilation step
1. Shader codes are mainly written with **HLSL**.
2. Use **[dxc](https://github.com/microsoft/DirectXShaderCompiler)** is used to compile HLSL shader into **SPIR-V** shader.
3. RGA is used to compile SPIR-V shader into **RDNA ISA** with **vulkan offline mode** (since I do not have an AMD GPU T_T).

# Shader list
### Version info
dxc version: Vulkan SDK 1.2.148.1  
rga version: 2.3.1.0  

|Directory|Description|
|:-:|-|
|ISA|Collection of shaders focus on the details of ISA implementation.|
