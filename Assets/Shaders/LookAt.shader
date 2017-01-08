// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/22_Tp_LookAt" {
	Properties {
		_ColorTex ("Albedo (RGBA)", 2D) = "white" {}
		_LookUpTex ("LookUp (RGBA)", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert						
			#pragma fragment frag					
			#pragma target 5.0						

			sampler2D _ColorTex;
			sampler2D _LookUpTex;

			struct appData							
			{
				float4 pos	: POSITION;				
				float3 normal : NORMAL;				
				float2 texcoord : TEXCOORD0; 
			};
            
			struct v2f								
			{
				float4 pos	: SV_POSITION;
				float3 normal	: ATTR0;			
				float3 wPos		: ATTR1;			
				float2 UV		: ATTR2;
			};
            
			v2f vert(appData v)						
			{
				v2f o;
				o.UV = v.texcoord;
				o.pos =    mul (UNITY_MATRIX_MVP, v.pos);				
				o.normal = mul(unity_ObjectToWorld,float4(v.normal,0).xyz);	
				o.wPos =   mul(unity_ObjectToWorld, v.pos).xyz;				

				return o;
			}

			float4 frag(v2f i) : COLOR					
			{
				half4 o;
				half3 Lookup = tex2D(_LookUpTex, _Time.x ) * 2 - 1;	
				half3 LookupTex = tex2D(_LookUpTex, (i.UV * (50.0) + _Time.y * 4).y );			
				half3 MainTex = tex2D(_ColorTex,i.UV + half2(Lookup.g,Lookup.r)).rgb;

				o.rgb = MainTex * half3(LookupTex.r,LookupTex.r,LookupTex.r) * 2.0f;
				o.a = 1;
				return o;						
			}
			ENDCG
		}
	}
}