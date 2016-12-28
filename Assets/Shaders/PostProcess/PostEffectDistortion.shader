Shader "Exam/PostEffect/DistortionEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Aberations("Aberation", Range(-0.5, 0.5)) = 0.0
		_AberationsDir("AberationsDir", Vector) = (1,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float2 _AberationsDir;
			float _Aberations;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				fixed4 col = float4 (0.0f, tex2D(_MainTex, i.uv).g, 0.0f, 1.0f);
				float2 dir = normalize (_AberationsDir) * _Aberations;
				col.r = tex2D(_MainTex, i.uv + dir).r;
				col.b = tex2D(_MainTex, i.uv + (dir * 0.5)).b;

				return col;
			}
			ENDCG
		}
	}
}
