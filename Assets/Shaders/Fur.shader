Shader "Exam/Fur"
{
	Properties
	{
		[Header(Base)]
		_MainTex("MainTex", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0
		_Color ("BaseColor", Color) = (1,1,1,1)

		[Header(Fur)]
		_FurLength ( "length ", Range(0,0.5)) = 0.5
		_FurLengthRandomIntensity ( "Fur Length Random Intensity", Range(0,1)) = 0
		_FurLowSize ( "Low size ", Range(0,0.25)) = 0.5
		_FurHighSize ( "High size ", Range(0,0.25)) = 0.5
		_LowCurlIntensity ("Low curl Intensity", Range(0,1)) = 0
		_HighCurlIntensity ("High curl Intensity", Range(0,1)) = 1
		_LowColor ("LowColor", Color) = (1,1,1,1)
		_HighColor ("HighColor", Color) = (1,1,1,1)

		[Header(Helper)]
		_RandomTex("RandomTex", 2D) = "black" {}

		[Header(Tesselation and deisplacement)]
		_Tesselation("Tesselation", Range(0,10)) = 0
		_DisplaceMap("Displace map", 2D) = "Black" {}
		_TesselationIntensity("Tesselation Intensity", Range(0,1)) = 0.1
	}
	SubShader
	{
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma target 5.0

		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;
		};

		half _Glossiness;
		fixed4 _Color;

		// first pass
		void surf(Input IN, inout SurfaceOutputStandard o )
		{
			fixed4 c = _Color * tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Metallic = 0.0f;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG

		// seconde pass
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma target 5.0

			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma domain domain
			#pragma hull hull

			#pragma multi_compile_fwdbase 
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			float _FurLowSize, _FurHighSize, _FurLength, _LowCurlIntensity, _HighCurlIntensity, _Tesselation, _FurLengthRandomIntensity, _TesselationIntensity;
			float4 _LowColor, _HighColor;
			sampler2D _RandomTex, _DisplaceMap;

			struct VertInput
			{
				float4 position : POSITION;
				float3 normal	: NORMAL;
				float3 tangent	: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			struct GeomInput
			{
				float4 position : POSITION;
				float3 normal	: NORMAL;
				float3 tangent	: TANGENT;
				float3 binormal	: BINORMAL;	
				float2 uv		: TEXCOORD0;
			};

			struct FragInput
			{
				float4 position	: SV_POSITION;
				float4 color	: COLOR;
				float3 normal	: NORMAL;
			};

			GeomInput vert( VertInput IN )
			{
				GeomInput o;

				o.position = mul( unity_ObjectToWorld, IN.position);
				o.normal = normalize(mul( unity_ObjectToWorld, float4( IN.normal, 0.0f)).xyz);
				o.tangent = normalize(mul( unity_ObjectToWorld, float4 ( IN.tangent, 0.0f)).xyz);
				o.binormal = cross(o.normal, o.tangent);
				o.uv = IN.uv;
				return o;
			}

			#ifdef UNITY_CAN_COMPILE_TESSELLATION

			struct OutputPatchConstant
			{
				float edge[3]	: SV_TessFactor;
				float inside	: SV_InsideTessFactor;
			};

			OutputPatchConstant hullconst( InputPatch<GeomInput, 3> v)
			{
				OutputPatchConstant o;
				o.edge[0] = o.edge[1] = o.edge[2] = o.inside = _Tesselation;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("hullconst")]
			[outputcontrolpoints(3)]

			GeomInput hull( InputPatch<GeomInput, 3> v, uint id : SV_OutputControlPointID )
			{
				return v[id];
			}

			[domain("tri")]
			GeomInput domain( OutputPatchConstant tessFactors, const OutputPatch<GeomInput, 3> vi, float3 bary : SV_DomainLocation)
			{
				GeomInput o;

				float3 position = vi[0].position*bary.x + vi[1].position*bary.y + vi[2].position*bary.z;
				float3 normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
				float3 binormal = vi[0].binormal*bary.x + vi[1].binormal*bary.y + vi[2].binormal*bary.z;
				float3 tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
				float2 uv = vi[0].uv*bary.x + vi[1].uv*bary.y + vi[2].uv*bary.z;

				float displace = tex2Dlod(_DisplaceMap, float4(uv, 0.0f, 0.0f)).g * _TesselationIntensity;

				o.position = float4(position, 0.0f) + float4(normal, 0.0f) * displace;
				o.normal = normalize(normal);
				o.binormal = normalize(binormal);
				o.tangent = normalize(tangent);
				o.uv = uv;

				return o;
			}

			#endif
			void addPoint( float3 pos, float3 norm, float4 col, inout TriangleStream<FragInput> stream)
			{
				FragInput o;

				o.position = mul(UNITY_MATRIX_VP, float4(pos, 1.0f));
				o.color = col;
				o.normal = norm;
				stream.Append(o);
			}

			void addFur( float3 pos, float3 dir, float3 tang, float3 bin, float2 uv, triangle GeomInput input[3], inout TriangleStream<FragInput> stream)
			{
				const float segmentCount = 8.0f;
				float relativePosStep = 1.0f / segmentCount;
				float3 RandomRGB = tex2Dlod(_RandomTex, float4(uv, 0, 0)) * 2.0f - float3(1.0f,1.0f,1.0f);

				float3 rootPos = pos;
				float3 orientation = normalize(sin(RandomRGB.r * 6.28 ) * tang + cos(RandomRGB.r * 6.28) * bin); // remplaceras quand j'aurais mis le random
				float3 furAngleCurve = 0.0f;
				float3 furCurveDir = cross(orientation, dir);

				addPoint( rootPos + (orientation  * _FurLowSize), dir, _LowColor, stream);
				addPoint( rootPos - (orientation  * _FurLowSize), dir, _LowColor, stream);

				for( float relativePos = relativePosStep; relativePos < 1.0f; relativePos += relativePosStep)
				{
					float furSize = lerp( _FurLowSize, _FurHighSize, relativePos);
					float4 col = lerp(_LowColor, _HighColor, relativePos);
					float3 growDir = (cos(furAngleCurve) * dir + sin( furAngleCurve ) * furCurveDir);
					furAngleCurve += lerp(_LowCurlIntensity, _HighCurlIntensity, relativePos);

					rootPos += growDir * _FurLength/ segmentCount;

					addPoint( rootPos + orientation  * furSize, dir, col, stream);
					addPoint( rootPos - orientation  * furSize, dir, col, stream);
				}
			}

			[maxvertexcount(24)]
			void geom( triangle GeomInput IN[3], inout TriangleStream<FragInput> stream )
			{
				float3 center = ( IN[0].position + IN[1].position + IN[2].position) / 3.0f;
				float3 norm = ( IN[0].normal + IN[1].normal + IN[2].normal) / 3.0f;
				float3 tang = ( IN[0].binormal + IN[1].binormal + IN[2].binormal) / 3.0f;
				float3 bin = ( IN[0].tangent + IN[1].tangent + IN[2].tangent) / 3.0f;
				float2 uv = ( IN[0].uv + IN[1].uv + IN[2].uv) / 3.0f;

				addFur( center, norm, tang, bin, uv, IN, stream);
				stream.RestartStrip();
			}

			float4 frag( FragInput IN ) : COLOR
			{
				float4 o;
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float NdotL = saturate((dot(IN.normal, lightDir)));

				o.rgb = IN.color * NdotL;
				o.a = 1;
				return o;
			}
			ENDCG
		}
	}
}
