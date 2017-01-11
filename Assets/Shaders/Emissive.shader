Shader "Custom/Emissive" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_EmissiveIntensity ("Emissive intensity", Range(1, 20)) = 1

		_GIAlbedoColor("Color Albedo (GI)", Color) = (1,1,1,1)
		_GIAlbedoTex ("Albedo (GI)", 2D) = "white" {}
	}
	SubShader 
	{
		Pass
		{
			Name "META"
			Tags { "LightMode"="Meta" }
			Cull Off
			
			CGPROGRAM
		
			#include "UnityStandardMeta.cginc"
		
			sampler2D _GIAlbedoTex;
			fixed4 _GIAlbedoColor;
		
			float4 frag_meta2 ( v2f_meta i ): SV_Target 
			{
				FragmentCommonData data = UNITY_SETUP_BRDF_INPUT (i.uv);
				UnityMetaInput o;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
				fixed4 c = tex2D( _GIAlbedoTex, i.uv);
				o.Albedo = fixed3( c.rgb * _GIAlbedoColor.rgb);
				o.Emission = Emission(i.uv.xy);
				return UnityMetaFragment(o);
			}
		
			#pragma vertex vert_meta
			#pragma fragment frag_meta2
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
		
			ENDCG
		}

		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma target 5.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness, _EmissiveIntensity, _Metallic;
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);// * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			o.Emission = _Color * _EmissiveIntensity;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
