Shader "Custom/Lava" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_Normal ("Normal map", 2D) = "bump" {}
		[header(Crack)]
		_Crack ("Crack", 2D) = "black" {}
		_CrackLowColor("Crack low color", Color) = (1,1,1,1)
		_CrackHighColor("Crack high color", Color) = (1,1,1,1)

		_CrackLowIntensity ("low emissive intensity", Range(0,5)) = 0
		_CrackHighIntensity ("High emissive intensity", Range(0,5)) = 0

		_Effect ("Effect", 2D) = "black" {}

		_PanIntensity("pan intensity", Range(0,1)) = 0.1

		[header(tesselation)]

		_Tessalation("Tesselation", Range(1, 100)) = 1
		_Height ("HeightMap", 2D) = "black" {}
		_CrackDisplacement("Crack Displacement", Range(-0.3, 0)) = 0
		_Displacement("Displacement", Range(0, 1)) = 0

		[header(test)]
		_SpeedSpan("Speed test", Range(0,1)) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tess
		#pragma target 5.0

		sampler2D _MainTex, _Normal, _Crack, _Effect, _Height;
		float4 _CrackLowColor, _CrackHighColor;
		float _SpeedSpan, _CrackLowIntensity, _CrackHighIntensity, _Tessalation, _Displacement, _CrackDisplacement, _PanIntensity;

		struct Input {
			float2 uv_MainTex;
			float2 uv_Crack;
		};

		float4 tess()
		{
			return _Tessalation;
		}

		void vert( inout appdata_full v )
		{
			float crack = tex2Dlod( _Crack, float4( v.texcoord.xy - float2( _Time.y * _PanIntensity, 0), 0, 0)).g * _CrackDisplacement;
			float height = tex2Dlod ( _Height, float4( v.texcoord.xy - float2( _Time.y * _PanIntensity, 0) , 0, 0)).g * _Displacement;
			v.vertex.xyz += v.normal * height;
			v.vertex.xyz += v.normal * crack;

		}
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			fixed4 c = tex2D ( _MainTex, IN.uv_MainTex - float2( _Time.y * _PanIntensity, 0));
			fixed3 N = UnpackNormal(tex2D ( _Normal, IN.uv_MainTex - float2( _Time.y * _PanIntensity, 0) )); 
			fixed crack = tex2D( _Crack, IN.uv_Crack - float2( _Time.y * _PanIntensity, 0));
			fixed effect = tex2D( _Effect, IN.uv_Crack - float2((_Time.y * _PanIntensity) + ( _Time.y * _SpeedSpan ), 0)) * 0.5;

			float4 finalColor = lerp(_CrackLowColor, _CrackHighColor, effect);

			o.Albedo = c.rgb + crack * finalColor;
			o.Metallic = 0;
			o.Smoothness = crack;
			o.Alpha = c.a;
			o.Emission = finalColor * crack * lerp(_CrackLowIntensity, _CrackHighIntensity, effect);
			o.Normal = N;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
