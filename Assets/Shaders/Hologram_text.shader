Shader "Exam/Hologram_text" {
	Properties {
		_MainTex("Main Texture", 2D) = "black" {}
		_NoiseTex("Noise Texture", 2D) = "black" {}
		_EmissiveColor ("Emissive color", Color) = (1,1,1,1)
		_VerticalValue ("vertical value", Range(0,1)) = 1.0
		_VerticalSize ("vertical Size", float) = 2.0
		_StripeColor ("Stripe color", Color) = (1,1,1,1)
		_StripeSize ("Stripe Size ( normalize )", Range( 0.0, 0.5)) = 0.1

		_EmissiveIntensity ("Emissive intensity", Range(1,5)) = 1.0
	}
	SubShader 
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200

		Cull Off
		Zwrite Off
		Blend One One
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows alpha:fade
		#pragma target 5.0

		sampler2D _MainTex, _NoiseTex;
		fixed4 _EmissiveColor, _StripeColor;
		float _VerticalValue, _VerticalSize, _StripeSize, _EmissiveIntensity;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_NoiseTex;
			float3 worldPos;
		};

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			float mainTex = tex2D( _MainTex, IN.uv_MainTex).r;
			float4 Noise = tex2D( _NoiseTex, float2(IN.uv_NoiseTex.y,IN.uv_NoiseTex.x) * (50.0) + _Time.y * 4);
			Noise.gb *= 2.0f;
			Noise.gb -= 1.0f;

			float3 localPos = IN.worldPos - mul( unity_ObjectToWorld, float4(0,0,0,1)).xyz;
			localPos.y += _VerticalSize * 0.5;

			float height = _VerticalSize * _VerticalValue + _StripeSize;
			if (localPos.y > height || height == 0)
				discard;

			height = _VerticalSize *  _VerticalValue;
			if (localPos.y > height)
				o.Emission = _StripeColor.rgb * _EmissiveIntensity * Noise.g;
			else
				o.Emission = (_EmissiveColor.rgb + mainTex) * _EmissiveIntensity * Noise.r;
			o.Alpha = Noise.g * mainTex.r;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
