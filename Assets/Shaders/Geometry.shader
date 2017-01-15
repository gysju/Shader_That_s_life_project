Shader "Exam/Geometry" 
{
	Properties 
	{
		_Mask("Mask", Int) = 0
		_Color ("Color", Color) = (1,1,1,1)
		[NoScaleOffset] _MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _RandomTex ("Random", 2D) = "white" {}

		[Header(Cube helper)]
		_HexaSize ("Cube size", Range (0.001, 0.05)) = 0.025
		[Space(10)]

		_HexaHeight ("Cube height", Range (0.001, .5)) = 0.2
		_HexaRandomHeight ("Cube random height intensity ", Range (0, 2)) = 0

		[Space(10)]
		_CubeTimeXIntansity ("Cube time X intansity ", Range (0, 0.25)) = 0
		_CubeTimeYIntansity ("Cube time Y intansity ", Range (0, 0.25)) = 0
		_Tesselation ("Tesselation", Range(1, 50)) = 1
	}
	
	SubShader 
	{
		Pass
		{
			Cull Off
			Stencil
			{
				Ref[_Mask]
				Comp equal
				Pass keep
				Fail keep
			}

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
			float _HexaSize, _HexaHeight, _Tesselation, _HexaRandomHeight, _CubeTimeXIntansity, _CubeTimeYIntansity;

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
				float4 normal_u	: ATTR0;
				float4 tangent_v: ATTR1;
				float3 binormal	: ATTR2;
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
				geomInput.normal_u = normalize(mul(unity_ObjectToWorld, float4(IN.normal, 0.0f)));
				geomInput.tangent_v = normalize(mul(unity_ObjectToWorld, float4(IN.tangent, 0.0f)));
				geomInput.binormal = cross(geomInput.normal_u.xyz, geomInput.tangent_v.xyz);

				geomInput.normal_u.w = IN.uv.x;
				geomInput.tangent_v.w = IN.uv.y;

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
				float3 normal = (vi[0].normal_u*bary.x + vi[1].normal_u*bary.y + vi[2].normal_u*bary.z).xyz;
				float3 tangent = (vi[0].tangent_v*bary.x + vi[1].tangent_v*bary.y + vi[2].tangent_v*bary.z).xyz;
				float3 binormal = vi[0].binormal*bary.x + vi[1].binormal*bary.y + vi[2].binormal*bary.z;

				float2 uv = float2( vi[0].normal_u.w, vi[0].tangent_v.w)*bary.x + float2( vi[1].normal_u.w, vi[1].tangent_v.w)*bary.y + float2( vi[2].normal_u.w, vi[2].tangent_v.w)*bary.z;


				o.pos = float4(pos, 0.0f);
				o.normal_u = float4(normalize(normal), 0.0f);
				o.tangent_v = float4(normalize(tangent), 0.0f);
				o.binormal = normalize(binormal);

				o.normal_u.w = uv.x;
				o.tangent_v.w = uv.y;

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
				float GeomLength = saturate(_HexaHeight + RandomRGB.g * _HexaRandomHeight + sin(_Time.y * RandomRGB.b) * _CubeTimeYIntansity) ;

				pos += float3( sin(_Time.y * RandomRGB.b) * _CubeTimeXIntansity, 0,cos(_Time.y * RandomRGB.b) * _CubeTimeXIntansity); 

				if ( GeomLength > 0)
				{
					//left
					addPoint ( pos - _HexaSize * tang, norm, colorMainTex, stream);
					addPoint ( pos - _HexaSize * tang + norm * GeomLength, norm, colorMainTex, stream); // gauche

					//up
					addPoint ( pos + _HexaSize * bin, norm, float4(0.3,0.3,0.3,1), stream);
					addPoint ( pos + _HexaSize * bin + norm * GeomLength, norm, colorMainTex, stream); // haut gauche

					// right
					addPoint ( pos + _HexaSize * tang, norm, float4(0.3,0.3,0.3,1), stream);
					addPoint ( pos + _HexaSize * tang + norm * GeomLength, norm, colorMainTex, stream); // droite

					// down
					addPoint ( pos - _HexaSize * bin, norm, float4(0.3,0.3,0.3,1), stream);
					addPoint ( pos - _HexaSize * bin + norm * GeomLength, norm, colorMainTex, stream); // haut gauche

					//left
					addPoint ( pos - _HexaSize * tang, norm, float4(0.3,0.3,0.3,1), stream);
					addPoint ( pos - _HexaSize * tang + norm * GeomLength, norm, colorMainTex, stream); // gauche

					//cover

					addPoint ( pos + _HexaSize * bin + norm * GeomLength, norm,  colorMainTex, stream); // haut gauche
					addPoint ( pos + _HexaSize * tang + norm * GeomLength, norm, colorMainTex, stream); // droite
					addPoint ( pos - _HexaSize * bin + norm * GeomLength, norm,  colorMainTex, stream); // haut gauche
					addPoint ( pos - _HexaSize * tang + norm * GeomLength, norm, colorMainTex, stream); // droite
				}
			}

			[maxvertexcount(24)]
			void geom(triangle GeomInput IN[3], inout TriangleStream<FragInput> stream)
			{
				float3 center = ( IN[0].pos + IN[1].pos + IN[2].pos) / 3.0f;
				float3 norm = ( IN[0].normal_u + IN[1].normal_u + IN[2].normal_u).xyz / 3.0f;
				float3 tang = ( IN[0].binormal + IN[1].binormal + IN[2].binormal) / 3.0f;
				float3 bin = ( IN[0].tangent_v + IN[1].tangent_v + IN[2].tangent_v).xyz / 3.0f;
				float2 uv = ( float2(IN[0].normal_u.w, IN[0].tangent_v.w) + float2(IN[1].normal_u.w, IN[1].tangent_v.w) + float2(IN[2].normal_u.w, IN[2].tangent_v.w)) / 3.0f;	

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
