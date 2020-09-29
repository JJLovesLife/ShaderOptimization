RWTexture2D<uint3> g_Tex;

[numthreads(16, 8, 1)]
void CsMain(uint3 id : SV_DispatchThreadID) {
	g_Tex[id.xy].y = id.z;
}
