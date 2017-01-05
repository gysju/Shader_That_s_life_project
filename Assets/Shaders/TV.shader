Shader "Exam/TV"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}

		_Tesselation("Tesselation", Range(1,10)) = 0

		[Header(Effect)]
		_LookAt ("LookAt", 2D) = "black" {}
		_TimeSpeedXDisplacement ("Time speed for displacement in X", Range( 0, 1)) = 0
		_XDisplacementIntensity ("Displacement Intensity in X", Range(0,0.5)) = 0
		[Space(10)]
		_TimeSpeedZDisplacement ("Time speed for displacement in Z", Range( 0, 1)) = 0
		_ZDisplacementIntensity ("Displacement Intensity in Z", Range(0,0.5)) = 0
		[Space(10)]
		_TimeSpeedVertical ("Time speed for Vertical UV Decal ", Range( 0, 1)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM

			#pragma target 5.0

			#pragma vertex vert
			#pragma fragment frag
			#pragma domain domain
			#pragma hull hull

			#pragma multi_compile_fwdbase 

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex, _LookAt;
			float4 _MainTex_ST, _LookAt_ST;
			float _XDisplacementIntensity, _ZDisplacementIntensity, _Tesselation, _TimeSpeedXDisplacement, _TimeSpeedZDisplacement, _TimeSpeedVertical;

			struct VertInput
			{
				float4 pos 		: POSITION;
				float3 normal 	: NORMAL;
				float3 tangent 	: TANGENT;
				float2 uv 		: TEXCOORD0;
			};

			struct HullInput
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float3 binormal : BINORMAL;
				float2 uv : TEXCOORD0;
			};

			struct DomaineInput
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float3 binormal : BINORMAL;
				float2 uv : TEXCOORD0;
			};

			struct PixelInput
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float3 binormal : BINORMAL;
				float2 uv : TEXCOORD0;
			};

			struct OutputPatchConstant
			{
				float edge[3]	: SV_TessFactor;
				float inside	: SV_InsideTessFactor;
			};

			
			HullInput vert (VertInput IN)
			{
				HullInput o;
				o.pos = mul( unity_ObjectToWorld, IN.pos);
				o.normal = normalize( mul( unity_ObjectToWorld, float4( IN.normal, 0)).xyz);
				o.tangent = normalize( mul( unity_ObjectToWorld, float4( IN.tangent, 0)).xyz);
				o.binormal = cross( o.normal, o.tangent );
				o.uv = IN.uv;
				return o;
			}


			OutputPatchConstant hullconst( InputPatch<DomaineInput, 3> v)
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

			DomaineInput hull( InputPatch<DomaineInput, 3> v, uint id : SV_OutputControlPointID )
			{
				DomaineInput o;

				o.pos = v[id].pos;
				o.normal = v[id].normal;
				o.tangent = v[id].tangent;
				o.binormal = v[id].binormal;
				o.uv = v[id].uv;

				return o;
			}

			[domain("tri")]
			PixelInput domain( OutputPatchConstant tessFactors, const OutputPatch<DomaineInput, 3> i, float3 bary : SV_DomainLocation)
			{
				PixelInput o;

				float3 position = bary.x * i[0].pos + bary.y * i[1].pos + bary.z * i[2].pos;
				float3 normal = bary.x * i[0].normal + bary.y * i[1].normal + bary.z * i[2].normal;
				float3 binormal = bary.x * i[0].binormal + bary.y * i[1].binormal + bary.z * i[2].binormal;
				float3 tangent = bary.x * i[0].tangent + bary.y * i[1].tangent + bary.z * i[2].tangent;
				float2 uv = bary.x * i[0].uv + bary.y * i[1].uv + bary.z * i[2].uv;

				float displace = tex2Dlod(_MainTex, float4( uv, 0.0f, 0.0f)).a;

				float lookAtX = tex2Dlod( _LookAt, float4( uv * 0.01 + float2( _Time.y * _TimeSpeedZDisplacement, 0.0f), 0.0f, 0.0f)).a;
				float lookAtZ = tex2Dlod( _LookAt, float4( uv * 0.01 + float2( _Time.y * _TimeSpeedXDisplacement, 0.0f), 0.0f, 0.0f)).b * 2.0f - 1.0f;

				position += normal * displace * _ZDisplacementIntensity * lookAtZ;
				position += tangent * displace * _XDisplacementIntensity * lookAtX;

				o.pos = mul(UNITY_MATRIX_VP, float4(position, 1.0f));
				o.normal = normalize(normal);
				o.binormal = normalize(binormal);
				o.tangent = normalize(tangent);
				o.uv = uv;

				return o;
			}

			float4 frag (PixelInput IN) : SV_Target
			{
				float background = tex2D( _LookAt, IN.uv * _LookAt_ST.xy + _LookAt_ST.wz).b;
				float horizontal = tex2D( _LookAt, IN.uv * 0.001 + float2(_Time.y * _TimeSpeedVertical,  0.0f)).b * 2.0f - 1.0f;
				float vertical = tex2D( _LookAt, IN.uv * 0.001 + float2(_Time.y * _TimeSpeedVertical,  0.0f)).r * 2.0f - 1.0f;
				float4 col = tex2D(_MainTex, IN.uv + float2( horizontal , vertical));
				col.a = 1;

				return float4(background, background, background, background);
			}
			ENDCG
		}
	}
}
