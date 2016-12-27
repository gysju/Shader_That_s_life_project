Shader "Exam/Fur"
{
	Properties
	{
		_MainTex ("Base texture", 2D) = "white" {}
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
			#pragma geometry geom
			#pragma hull hull
			#pragma domain domain

			#include "UnityCG.cginc"

			struct VertInput
			{
				float4 position	: POSITION;
				float3 N		: NORMAL;
				float3 T		: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			struct GeomInput
			{
				float4 position	: WORLDPOSITION;
				float3 N		: NORMAL;
				float3 B		: BINORMAL;
				float3 T		: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			struct FragInput
			{
				float3 color	: COLOR;
				float3 normal	: NORMAL;
				float2 uv		: TEXCOORD0;
				float4 position	: SV_POSITION;
				float3 normalGround : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			GeomInput vert(VertInput vertInput)
			{
				GeomInput o;
				return o;
			}

			#ifdef UNITY_CAN_COMPILE_TESSELLATION
			struct OutputPatchConstant
			{
				float edge[3]         : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};
			OutputPatchConstant hullconst(InputPatch<GeomInput, 3> v)
			{
				OutputPatchConstant o;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("hullconst")]
			[outputcontrolpoints(3)]

			GeomInput hull(InputPatch<GeomInput, 3> v, uint id : SV_OutputControlPointID)
			{
				return v[id];
			}

			[domain("tri")]
			GeomInput domain(OutputPatchConstant tessFactors, const OutputPatch<GeomInput, 3> vi, float3 bary : SV_DomainLocation)
			{
				GeomInput v;
				v.position = vi[0].position*bary.x + vi[1].position*bary.y + vi[2].position*bary.z;
				v.N = vi[0].N*bary.x + vi[1].N*bary.y + vi[2].N*bary.z;
				v.B = vi[0].B*bary.x + vi[1].B*bary.y + vi[2].B*bary.z;
				v.T = vi[0].T*bary.x + vi[1].T*bary.y + vi[2].T*bary.z;
				v.uv = vi[0].uv*bary.x + vi[1].uv*bary.y + vi[2].uv*bary.z;

				return v;
			}
			#endif

			void addPoint(float3 pos, float3 norm, float3 normGround, float3 col, float2 uv, inout TriangleStream<FragInput> stream)
			{
				FragInput o;

				o.position = mul(UNITY_MATRIX_VP, float4(pos, 1.0f));
				o.color = col;
				o.normal = norm;
				o.normalGround = normGround;
				o.uv = uv;
				stream.Append(o);
			}

			[maxvertexcount(64)]
			void geom(triangle GeomInput input[3], inout TriangleStream<FragInput> stream)
			{

			}

			fixed4 frag (FragInput i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
