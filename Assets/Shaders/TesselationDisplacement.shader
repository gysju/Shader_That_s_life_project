Shader "Custom/TesselationDisplacement"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpTex ("Normal", 2D) = "bump" {}
		_DisplaceTex ("Displace ", 2D) = "black" {}
		_DisplacementIntensity("Displacement intensity", Range(0, 3.0)) = 1.0
		_Tesselation("Tesselation", Range(0.1, 15)) = 2
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" 
		"LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain

			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"


			sampler2D _MainTex, _BumpTex, _DisplaceTex;
			float4 _MainTex_ST, _BumpTex_ST, _DisplaceTex_ST;
			float _DisplacementIntensity, _Tesselation;

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct HullInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float3 binormal : BINORMAL;
				float2 uv : TEXCOORD0;
			};

			struct DomaineInput
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float3 binormal : BINORMAL;
				float2 uv : TEXCOORD0;
			};

			struct PixelInput
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float3 binormal : BINORMAL;
				float2 uv : TEXCOORD0;
			};

			struct HullConstantOutput
			{
				float TessFactor[3] : SV_TESSFACTOR;
				float InsideTessFactor : SV_INSIDETESSFACTOR;
			};

			HullInput vert( VertexInput v)
			{
				HullInput o;

				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0f));
				o.normal = mul((float3x3)unity_ObjectToWorld, v.normal.xyz);
				o.tangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz); 
				o.binormal = normalize(cross(o.normal, o.tangent));
				o.uv = v.uv;
				return o;
			}

			HullConstantOutput hullConstant( InputPatch<HullInput, 3> i)
			{
				HullConstantOutput o;

				o.InsideTessFactor = o.TessFactor[0] = o.TessFactor[1] = o.TessFactor[2] = _Tesselation;

				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("hullConstant")]
			[outputcontrolpoints(3)]
			DomaineInput hull( InputPatch<HullInput, 3> i, uint uCPID : SV_OutputControlPointID )
			{
				DomaineInput o;

				o.vertex = i[uCPID].vertex;
				o.normal = i[uCPID].normal;
				o.tangent = i[uCPID].tangent;
				o.binormal = i[uCPID].binormal;
				o.uv = i[uCPID].uv;

				return o;
			}

			[domain("tri")]
			PixelInput domain( HullConstantOutput contantData, const OutputPatch<DomaineInput, 3> i, float3 bary : SV_DomainLocation)
			{
				PixelInput o;

				float3 position = bary.x * i[0].vertex + bary.y * i[1].vertex + bary.z * i[2].vertex;
				float3 normal = bary.x * i[0].normal + bary.y * i[1].normal + bary.z * i[2].normal;
				float3 binormal = bary.x * i[0].binormal + bary.y * i[1].binormal + bary.z * i[2].binormal;
				float3 tangent = bary.x * i[0].tangent + bary.y * i[1].tangent + bary.z * i[2].tangent;
				float2 uv = bary.x * i[0].uv + bary.y * i[1].uv + bary.z * i[2].uv;

				float displace = tex2Dlod(_DisplaceTex, float4(uv, 0.0f, 0.0f)).g;


				position += normal * displace * _DisplacementIntensity;
				o.vertex = mul(UNITY_MATRIX_VP, float4(position, 1.0f));
				o.normal = normalize(normal);
				o.binormal = normalize(binormal);
				o.tangent = normalize(tangent);
				o.uv = uv;

				return o;
			}

			float4 frag( PixelInput i ) : SV_Target
			{
				float4 albedo = tex2D(_MainTex, i.uv);
				float3 normal = UnpackNormal(tex2D(_BumpTex, i.uv));

				float3 worldNormal = normal.x * i.tangent + normal.y * i.binormal + normal.z * i.normal;
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz); 
				float intensity = max(0.0f, dot(worldNormal, lightDirection));


				return albedo * intensity;
			}
			ENDCG
		}
	}
}
