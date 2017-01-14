Shader "Custom/Lava" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_Normal ("Normal map", 2D) = "bump" {}
		_Mask ("Tunnel mask", 2D) = "white" {}

		[header(Crack)]
		_Crack ("Crack", 2D) = "black" {}
		_CrackLowColor("Crack low color", Color) = (1,1,1,1)
		_CrackHighColor("Crack high color", Color) = (1,1,1,1)

		_CrackLowIntensity ("low emissive intensity", Range(0,5)) = 0
		_CrackHighIntensity ("High emissive intensity", Range(0,5)) = 0

		_EmissionMask ("Emission mask", 2D) = "black" {}

		[header(tesselation)]

		_Tessalation("Tesselation", Range(1, 100)) = 1
		_Height ("HeightMap", 2D) = "black" {}
		_CrackDisplacement("Crack Displacement", Range(-0.3, 0)) = 0
		_Displacement("Displacement", Range(0, 1)) = 0

		[header(test)]
		_PanIntensity("pan intensity", Range(0,1)) = 0.1
		_EmissionMaskPanIntensity("emission pan intensity", Range(0,1)) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tess
		#pragma target 5.0

		sampler2D _MainTex, _Normal, _Crack, _EmissionMask, _Height, _Mask;
		float4 _CrackLowColor, _CrackHighColor;
		float _EmissionMaskPanIntensity, _CrackLowIntensity, _CrackHighIntensity, _Tessalation, _Displacement, _CrackDisplacement, _PanIntensity;

		struct Input {
			float2 uv_MainTex;
			float2 uv_TunnelMask;
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
			fixed emissionMask = tex2D( _EmissionMask, IN.uv_Crack - float2((_Time.y * _PanIntensity) + ( _Time.y * _EmissionMaskPanIntensity ), 0)) * 0.5;
			fixed tunnelMask = tex2D ( _Mask, IN.uv_TunnelMask);

			float4 finalColor = lerp(_CrackLowColor, _CrackHighColor, emissionMask);

			o.Albedo = c.rgb + crack * finalColor;
			o.Albedo *= tunnelMask;
			o.Metallic = 0;
			o.Smoothness = crack;
			o.Alpha = c.a;
			o.Emission = finalColor * crack * lerp(_CrackLowIntensity, _CrackHighIntensity, emissionMask) * tunnelMask;
			o.Normal = N;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
