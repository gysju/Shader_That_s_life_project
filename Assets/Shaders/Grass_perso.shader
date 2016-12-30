Shader "Custom/Grass" 
{
	Properties {
		_GroundTex ("GroundTex", 2D) = "white" {}
		_GrassTex ("GrassTex", 2D) = "white" {}
		[NoScaleOffset]_PerlinTex ("PerlinTex", 2D) = "white" {}

		[Header(Grass)]
		_GrassColor ("GrassColor", Color) = (1,1,1,1)
		_SegmentSize ("Segment size", Range(0.1,1)) = .25
		_SegmentBaseSize ("_Segment base size", Range(0.01,1)) = .25
		_SegmentEndSize ("_Segment end size", Range(0,1)) = .25
		_Inclinaison ("_Inclinaison", Vector) = (0,0,0,0)
		_InclinaisonForce ("_InclinaisonForce", Range(0,1)) = .25

	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		Tags{ "Queue" = "Geometry" }
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows

		#pragma target 5.0

		struct Input 
		{
			float2 uv_GroundTex;
		};

		sampler2D _GroundTex;

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			fixed4 c = tex2D(_GroundTex, IN.uv_GroundTex);
			o.Albedo = c.rgb;
			o.Metallic = 0;
			o.Smoothness = 0;
			o.Alpha = c.a;
		}
		ENDCG
		Pass
		{
			Cull Off
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			#pragma multi_compile_fwdbase 
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			float _SegmentSize;
			float _SegmentBaseSize;
			float _SegmentEndSize;
			float _InclinaisonForce;
			float3 _RandomValue;
			fixed4 _Inclinaison;
			fixed4 _GrassColor;
			sampler2D _GrassTex;
			sampler2D _PerlinTex;

			struct VertInput
			{
				float4 position : POSITION;
				float3 N : NORMAL;
				float3 T : TANGENT;
				float2 texcoord : TEXCOORD0;
			};

			struct GeomInput
			{
				float4 position : POSITION;
				float3 N : NORMAL;
				float3 T : TANGENT;
				float3 B : BINORMAL;
			};

			struct FragInput
			{
				float3 color : COLOR;
				float3 normal	: NORMAL;
				float4 pos : SV_POSITION; //  nom pos obligatoire

				LIGHTING_COORDS(1, 2)
			};

			GeomInput vert(VertInput vertInput)
			{
				_RandomValue = tex2D( _PerlinTex, vertInput.texcoord);
				GeomInput geomInput;

				geomInput.N = normalize(mul(unity_ObjectToWorld, float4(vertInput.N, 0.0f)).xyz);
				geomInput.T = normalize(mul(unity_ObjectToWorld, float4(vertInput.T, 0.0f)).xyz);
				geomInput.B = cross( geomInput.N, geomInput.T);

				geomInput.position = mul(unity_ObjectToWorld, vertInput.position);
				return geomInput;
			}

			void addPoint( float3 pos, float3 norm, float3 col, inout TriangleStream<FragInput> stream)
			{
				FragInput o;

				o.pos = mul(UNITY_MATRIX_VP, float4(pos, 1));
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				o.color = col;
				o.normal = norm;
				stream.Append(o);
			}

			void addGrass(int SegmentNB, float3 posOrigin, float3 normOrigin, triangle GeomInput input[3],inout TriangleStream<FragInput> stream)
			{
				float3 height;
				float size;
				float3 dir = float3 (1,0,0);
				float2 uv = float2(0.0,0.0);
				float3 tex;

				addPoint(posOrigin + dir * _SegmentBaseSize, normOrigin, _GrassColor, stream);
				addPoint(posOrigin - dir * _SegmentBaseSize, normOrigin, _GrassColor, stream);

				_Inclinaison *= _InclinaisonForce;
			
				for(int i = 1; i <= SegmentNB; i++)
				{
					size = lerp( _SegmentBaseSize, _SegmentEndSize, float(i) / float(SegmentNB));
					height = float3 (0, 1, 0) * _SegmentSize * i;
					_GrassColor *= 0.8;
					tex = tex2Dlod(_GrassTex, float4(uv, 0.0f, 0.0f)) * _GrassColor;
					addPoint(posOrigin + ((dir + _Inclinaison.xyz) * size) + height, normOrigin, _GrassColor, stream);
					addPoint(posOrigin - ((dir - _Inclinaison.xyz) * size) + height, normOrigin, _GrassColor, stream);

					_Inclinaison += _Inclinaison;
				}
				stream.RestartStrip();
			}

			[maxvertexcount(24)]
			void geom(triangle GeomInput input[3], inout TriangleStream<FragInput> stream)
			{
				float3 Center = ( input[0].position + input[1].position + input[2].position) / 3.0f;
				float3 norm = ( input[0].N + input[1].N + input[2].N) / 3.0f;

				addGrass(5, Center, norm, input, stream);
				stream.RestartStrip();
			}

			float4 frag (FragInput fragInput) : COLOR
			{
				float atten = LIGHT_ATTENUATION(fragInput);

				float3 normalDirection = normalize(fragInput.normal);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float NdotL = max(0.0, dot(normalDirection, lightDirection));

				float3 color = fragInput.color* (0.1f+NdotL*0.9f*atten);

				return float4(color, 1.0f);
			}
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			Fog{ Mode Off }
			ZWrite On Ztest LEqual Cull Off

			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			float _SegmentSize;
			float _SegmentBaseSize;
			float _SegmentEndSize;
			float _InclinaisonForce;
			float3 _RandomValue;
			fixed4 _Inclinaison;
			fixed4 _GrassColor;
			sampler2D _GrassTex;
			sampler2D _PerlinTex;

			struct VertInput
			{
				float4 position : POSITION;
				float3 N : NORMAL;
				float3 T : TANGENT;
				float2 texcoord : TEXCOORD0;
			};

			struct GeomInput
			{
				float4 position : POSITION;
				float3 N : NORMAL;
				float3 T : TANGENT;
				float3 B : BINORMAL;
			};

			struct FragInput
			{
				V2F_SHADOW_CASTER;
			};

			struct ShadowTrans
			{
				float4 vertex;
			};

			GeomInput vert(VertInput vertInput)
			{
				_RandomValue = tex2D( _PerlinTex, vertInput.texcoord);
				GeomInput geomInput;

				geomInput.N = normalize(mul(unity_ObjectToWorld, float4(vertInput.N, 0.0f)).xyz);
				geomInput.T = normalize(mul(unity_ObjectToWorld, float4(vertInput.T, 0.0f)).xyz);
				geomInput.B = cross( geomInput.N, geomInput.T);

				geomInput.position = mul(unity_ObjectToWorld, vertInput.position);
				return geomInput;
			}

			void addPoint( float3 pos, float3 norm, float3 col, inout TriangleStream<FragInput> stream)
			{
				FragInput o;
				ShadowTrans v;

				o.pos = mul(UNITY_MATRIX_VP, float4(pos, 1)); 
				v.vertex = float4(pos, 1.0f);

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				stream.Append(o);
			} 

			void addGrass(int SegmentNB, float3 posOrigin, float3 normOrigin, triangle GeomInput input[3],inout TriangleStream<FragInput> stream)
			{
				float3 height;
				float size;
				float3 dir = float3 (1,0,0);
				addPoint(posOrigin + dir * _SegmentBaseSize, normOrigin, _GrassColor, stream);
				addPoint(posOrigin - dir * _SegmentBaseSize, normOrigin, _GrassColor, stream);

				_Inclinaison *= _InclinaisonForce;
			
				for(int i = 1; i <= SegmentNB; i++)
				{
					size = lerp( _SegmentBaseSize, _SegmentEndSize, float(i) / float(SegmentNB));
					height = float3 (0, 1, 0) * _SegmentSize * i;
					_GrassColor *= 0.8;

					addPoint(posOrigin + ((dir + _Inclinaison.xyz) * size) + height, normOrigin, _GrassColor, stream);
					addPoint(posOrigin - ((dir - _Inclinaison.xyz) * size) + height, normOrigin, _GrassColor, stream);

					_Inclinaison += _Inclinaison;
				}
				stream.RestartStrip();
			}

			[maxvertexcount(24)]
			void geom(triangle GeomInput input[3], inout TriangleStream<FragInput> stream)
			{
				float3 Center = ( input[0].position + input[1].position + input[2].position) / 3.0f;
				float3 norm = ( input[0].N + input[1].N + input[2].N) / 3.0f;

				addGrass(5, Center, norm, input, stream);
				stream.RestartStrip();
			}

			float4 frag(FragInput fragInput) : COLOR
			{ 
				SHADOW_CASTER_FRAGMENT(fragInput)
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
