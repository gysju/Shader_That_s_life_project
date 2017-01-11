﻿Shader "Exam/Geometry" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_RandomTex ("Random", 2D) = "white" {}

		_HexaSize ("Hexa size", Range (0.01, 0.05)) = 0.025
		_HexaHeight ("Hexa height", Range (0.01, 1)) = 0.2
		_HexaRandomHeight ("Hexa random height intensity ", Range (0, 2)) = 0

		_Tesselation ("Tesselation", Range(1, 10)) = 1

	}
	
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma target 5.0
		
		sampler2D _MainTex;
		
		struct Input 
		{
			float2 uv_MainTex;
		};

		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
		}
		ENDCG
		
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

			#include "UnityCG.cginc"

			sampler2D _MainTex, _RandomTex;
			float4 _RandomTex_ST;
			float _HexaSize, _HexaHeight, _Tesselation, _HexaRandomHeight;

			struct VertInput
			{
				float4 pos 		: POSITION;
				float3 normal	: NORMAL;
				float3 tangent	: TANGENT;
				float2 uv		: TEXCOORD0;
			};
			
			struct GeomInput
			{
				float4 pos 		: POSITION;
				float3 normal	: NORMAL;
				float3 binormal	: BINORMAL;
				float3 tangent	: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			struct FragInput
			{
				float4 pos		: SV_POSITION;
				float3 normal	: NORMAL;
				float3 color	: COLOR;
			};
			
			GeomInput vert(VertInput IN)
			{
				GeomInput geomInput;

				geomInput.pos = mul(unity_ObjectToWorld, IN.pos);
				geomInput.normal = normalize(mul(unity_ObjectToWorld, float4(IN.normal, 0.0f)).xyz);
				geomInput.tangent = normalize(mul(unity_ObjectToWorld, float4(IN.tangent, 0.0f)).xyz);
				geomInput.binormal = cross(geomInput.normal, geomInput.tangent);
				geomInput.uv = IN.uv;
				return geomInput;
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

				float3 pos = vi[0].pos*bary.x + vi[1].pos*bary.y + vi[2].pos*bary.z;
				float3 normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
				float3 binormal = vi[0].binormal*bary.x + vi[1].binormal*bary.y + vi[2].binormal*bary.z;
				float3 tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
				float2 uv = vi[0].uv*bary.x + vi[1].uv*bary.y + vi[2].uv*bary.z;


				o.pos = float4(pos, 0.0f);
				o.normal = normalize(normal);
				o.binormal = normalize(binormal);
				o.tangent = normalize(tangent);
				o.uv = uv;

				return o;
			}

			#endif

			void addPoint(float3 pos, float3 norm, float3 col, inout TriangleStream<FragInput> stream)
			{
				FragInput o;
			
				o.pos = mul(UNITY_MATRIX_VP, float4(pos, 1.0f));
				o.normal = norm;
				o.color = col;
				
				stream.Append(o);
			}

			void addGeom( float3 pos, float3 norm, float3 tang, float3 bin, float2 uv, inout TriangleStream<FragInput> stream)
			{
				float4 colorMainTex = tex2Dlod (_MainTex, float4(uv, 0,0));
				float3 RandomRGB = tex2Dlod(_RandomTex, float4(uv * _RandomTex_ST.xy + _RandomTex_ST.wz, 0, 0)) * 2.0f - float3(1.0f,1.0f,1.0f);
				float GeomLength = _HexaHeight + RandomRGB.g * _HexaRandomHeight;

				//left
				addPoint ( pos - _HexaSize * tang, norm, colorMainTex, stream);
				addPoint ( pos - _HexaSize * tang + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // gauche

				//up
				addPoint ( pos + _HexaSize * bin, norm, float4(0.3,0.3,0.3,1), stream);
				addPoint ( pos + _HexaSize * bin + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // haut gauche

				// right
				addPoint ( pos + _HexaSize * tang, norm, float4(0.3,0.3,0.3,1), stream);
				addPoint ( pos + _HexaSize * tang + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // droite

				// down
				addPoint ( pos - _HexaSize * bin, norm, float4(0.3,0.3,0.3,1), stream);
				addPoint ( pos - _HexaSize * bin + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // haut gauche

				//left
				addPoint ( pos - _HexaSize * tang, norm, float4(0.3,0.3,0.3,1), stream);
				addPoint ( pos - _HexaSize * tang + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // gauche

				//cover

				addPoint ( pos + _HexaSize * bin + float3( 0, GeomLength, 0), norm,  colorMainTex, stream); // haut gauche
				addPoint ( pos + _HexaSize * tang + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // droite
				addPoint ( pos - _HexaSize * bin + float3( 0, GeomLength, 0), norm,  colorMainTex, stream); // haut gauche
				addPoint ( pos - _HexaSize * tang + float3( 0, GeomLength, 0), norm, colorMainTex, stream); // droite
			}

			[maxvertexcount(24)]
			void geom(triangle GeomInput IN[3], inout TriangleStream<FragInput> stream)
			{
				float3 center = ( IN[0].pos + IN[1].pos + IN[2].pos) / 3.0f;
				float3 norm = ( IN[0].normal + IN[1].normal + IN[2].normal) / 3.0f;
				float3 tang = ( IN[0].binormal + IN[1].binormal + IN[2].binormal) / 3.0f;
				float3 bin = ( IN[0].tangent + IN[1].tangent + IN[2].tangent) / 3.0f;
				float2 uv = ( IN[0].uv + IN[1].uv + IN[2].uv) / 3.0f;	

				addGeom( center, norm, tang, bin, uv, stream);	
			}

			float4 frag(FragInput fragInput) : COLOR
			{
				return float4(fragInput.color, 1.0f);
			}
									
			ENDCG				
		}
	} 
	FallBack "Diffuse"
}
