Shader "Exam/Toon" {
	Properties {
		_MatColor ("MatColor", Color) = (1,1,1,1)
		_Gloss ("Glossiness",Range (0,1)) = .5
		_OutlineColor ("OutlineColor", Color) = (0,0,0,1)
		_OutlineThickness ("OutlineThickness", Range (0,.1)) = .05

		[Header(Helper)]
		_VerticalSize ("Size", Range(0,1)) = 1

	}
	SubShader {
		
		Pass {
			Cull front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			half3 _OutlineColor;
			half _OutlineThickness;

			struct appData{
				float4 pos		: POSITION;
				half3 normal	: NORMAL;
			};

			struct v2f {
				float4 pos		: SV_POSITION;
			};

			v2f vert ( appData v) {
				v2f o;
				v.pos += half4(v.normal, 0) * _OutlineThickness;
				o.pos = mul ( UNITY_MATRIX_MVP, v.pos);
				return o;
			}
			half4 frag(v2f i)	:	COLOR {
				half4 o;
				o.rgb = _OutlineColor;
				o.a = 1;

				return o;
			}
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			half3 _MatColor, _SunDir, _SunColor, _Ambient;
			half _Gloss;

			struct appData{
				float4 pos		: Position;
				half3 normal	: NORMAL;
			};

			struct v2f {
				float4 pos		: SV_POSITION;
				half3 N			: ATTR0;
				float3 wPos		: ATTR1;
			};

			v2f vert(appData v){
				v2f o;
				o.pos = mul (UNITY_MATRIX_MVP, v.pos);
				o.N = mul (unity_ObjectToWorld, half4(v.normal, 0)).xyz;
				o.wPos = mul (unity_ObjectToWorld, v.pos).xyz;
				
				return o;
			}

			half4 frag(v2f i)	: COLOR {
				half4 o;
				half3 N = normalize(i.N);
				half3 L = -_SunDir;
				half3 V = normalize(_WorldSpaceCameraPos - i.wPos);
				half3 H = normalize(V+L);
				half NdotL = dot (N,L);
				half NdotH = dot(N,H);
				half e = exp2(_Gloss*12);

				half diffuse = smoothstep(-0.5,0.5,NdotL);

				half specular = smoothstep(0,0.5, pow(NdotH, e)) * diffuse;

				o.rgb = _MatColor * (_SunColor * (diffuse + specular) + _Ambient );
				o.a = 1;
				return o;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
