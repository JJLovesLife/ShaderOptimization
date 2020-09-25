struct VsInput {
	float4 position : POSITION;
	float2 texCoord : TEXCOORD;
};

struct PsInput {
	float4 position : SV_Position;
	float2 texCoord : TEXCOORD;
};

Texture2D g_Tex : register(t0);
SamplerState g_Sampler : register(s0);

PsInput VsMain(VsInput vsIn)
{
	PsInput vsOut;

	vsOut.position = vsIn.position;
	vsOut.texCoord = vsIn.texCoord;

	return vsOut;
}

float4 PsMain(PsInput psIn) : SV_Target
{
	return g_Tex.Sample(g_Sampler, psIn.texCoord);
}