Shader "Exam/PostEffect/WaveEffect" 
{
	Properties 
	{
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_WaveSpeed("Speed", Range(0,2)) = 0.5
		_WaveAmplitude("Amplitude", Range(0,1)) = 0.5
		_WaveFrequence("Frequence", Range(0,1)) = 0.5
	}
	Subshader
	{
		Pass
		{
			Tags { "RenderType"="Opaque" }
			LOD 200
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half _WaveSpeed, _WaveAmplitude, _WaveFrequence;

			struct VertInput 
			{
				float4 pos	:	POSITION;
				float2 uv	:	TEXCOORD0;
			};

			struct FragInput
			{
				float4 pos	:	POSITION;
				float2 uv	:	TEXCOORD0;
			};

			FragInput vert ( VertInput IN )
			{
				FragInput o;
				o.pos = mul(UNITY_MATRIX_MVP, IN.pos);
				o.uv = IN.uv;

				return o;
			}

			fixed4 frag( FragInput IN ) : COLOR
			{
				fixed4 o = tex2D(_MainTex, IN.uv + float2(0, sin(IN.pos.x * 0.02 * _WaveFrequence + _Time.y * _WaveSpeed) * 0.1 * _WaveAmplitude));

				return o;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
