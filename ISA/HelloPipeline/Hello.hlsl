float4 VsMain(float4 position : POSITION) : SV_Position
{
	return position;
}

float4 PsMain(float4 position : SV_Position) : SV_Target
{
	return 1.0f;
}