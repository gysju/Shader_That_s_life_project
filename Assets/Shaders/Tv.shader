Shader "Exam/Tv" {
	Properties {
		_MainTex ("MainTex", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_Tesselation("Tesselation", Range(1,100)) = 1

		[Header(Effect)]
		_LookAt ("LookAt", 2D) = "black" {}
		_DisplacementIntensity ("Displacement Intensity", Range( 0, 1)) = 0
		[Space(10)]
		_TimeSpeedVertical ("Time speed for ligne UV Decal ", Range( 0, .5)) = 0
		_TimeSpeedHorizontal ("Time speed for ligne UV Decal ", Range( 0, .5)) = 0
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tess
		#pragma target 5.0

		sampler2D _MainTex, _LookAt;
		float _Tesselation, _TimeSpeedVertical, _TimeSpeedHorizontal, _DisplacementIntensity;

		struct Input {
			float2 uv_MainTex;
			float2 uv_LookAt;
		};

		fixed4 _Color;

		void vert( inout appdata_full v)
		{
			float bump = tex2Dlod( _MainTex, v.texcoord).a;
			v.vertex.xyz += v.normal * bump * _DisplacementIntensity;
		}

		float4 tess()
		{
			return _Tesselation;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float background = tex2D( _LookAt, float2( IN.uv_LookAt.y + _Time.y * _TimeSpeedVertical, IN.uv_LookAt.x )).b;
			float lookAt_g = tex2D( _LookAt, IN.uv_LookAt * 0.0001 + float2(_Time.y * _TimeSpeedHorizontal, 0.0f)).g;
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex + float2( 0, lookAt_g)) * _Color;
			o.Albedo = saturate (c.rgb + (background * 0.1));
			o.Metallic = 0;
			o.Smoothness = 0;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
