struct PsInput {
	float4 position : SV_Position;
	float4 color : COLOR;
};

PsInput VsMain(float4 position : POSITION, float4 color : COLOR)
{
	PsInput vsOut;

	vsOut.position = position;
	vsOut.color = color;

	return vsOut;
}

float4 PsMain(PsInput psIn) : SV_Target
{
	return psIn.color;
}