RWTexture2D<float4> g_Tex;
RWTexture2D<uint> g_Transparent;

groupshared bool s_tranparentExist;

[numthreads(64, 1, 1)]
void CsMain(uint2 dUv : SV_DispatchThreadID, uint2 gUv : SV_GroupID, uint gIdx : SV_GroupThreadID) {
	if (gIdx == 0) {
		s_tranparentExist = false;
	}
	GroupMemoryBarrierWithGroupSync();

	if (g_Tex[dUv].a != 1.0f) {
		s_tranparentExist = true;
	}
	GroupMemoryBarrierWithGroupSync();

	if (s_tranparentExist && gIdx == 0) {
		g_Transparent[gUv] = 1;
	}
}
