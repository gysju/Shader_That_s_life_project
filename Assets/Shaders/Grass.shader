// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Grass"
{
	// Bound with the inspector.
	Properties
	{
		_WindTex("Wind texture", 2D) = "black" {}
		_WindIntensity("Wind intensity", Range(-.5,.5)) = 0.01
		_WindSpeedX("Wind speed X", Range(-2.0,2.0)) = 0.45
		_WindSpeedY("Wind speed Y", Range(-2.0,2.0)) = 0.52
		_Color("Color", Color) = (1,1,1,1)
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_GroundLighting("Ground lighting", Range(0,1)) = 0.5
		_MainTex("Grass base texture", 2D) = "white" {}
		_RandomRGBTex("Random RGB texture", 2D) = "white" {}
		_BladeLength("Blade length", Range(0,1)) = 0.15
		_BladeLowWidth("Blade low width", Range(0,0.2)) = 0.01
		_BladeHighWidth("Blade high width", Range(0,0.2)) = 0.000
		_BladeRandomisation("Blade randomisation", Range(0,1.0)) = 0.300
		_BladeOffset("Blade offset", Range(0,0.5)) = 0.1
		_StraightBlade("Blade straight orientation", Range(0,1.0)) = 1.0
		_FlowersHeight("Flowers relative height", Range(0,2.0)) = 0.5
		_BladeCurlIntensity("Blade curl", Range(-0.5,0.5)) = 0.1
		_BladeExtraCurlIntensity("Blade extra curl", Range(-4.5,4.5)) = 0.4
		_BladeColorLow("Color low", Color) = (0.02,.3,.05)
		_BladeColorHigh("Color high", Color) = (0.1,.75,.2)
		_FlowerSize("Flower size", Range(0.0, 0.25)) = 0.03
		_FlowerDensity("Flower density", Range(0.0, 1.0)) = 0.2
		_FlowerTex("Flower texture", 2D) = "white" {}
		_Tesselation("Tesselation", Range(1, 8)) = 1
		_TesselationRnd("Tesselation randomize", Range(0, 1)) = 0
		_RandomDensity("Random density texture", 2D) = "white" {}
	}

	SubShader
	{
		// La première passe rend le terrain grâce à un surface shader.
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

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo = texture x couleur
			fixed4 c = _Color * tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Metallic = 0.0f;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG

		// La deuxième passe rend l'herbe.
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma target 5.0

			// Definition des fonctions utilisées pour les shaders
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma hull hull
			#pragma domain domain

			#include "UnityCG.cginc"

			// Variables from the properties.
			sampler2D	_RandomRGBTex;
			sampler2D	_FlowerTex;
			sampler2D	_WindTex;
			sampler2D	_RandomDensity;

			// Longueur des brins d'herbe
			float		_BladeLength;
			// Largeur des brins d'herbe à la base
			float		_BladeLowWidth;
			// Largeur des brins d'herbe au sommet
			float		_BladeHighWidth;
			// Niveau de randomisation des paramètres des brins
			float		_BladeRandomisation;
			// Décallage par rapport à la position centrale d'un triangle du brin d'herbe associé
			float		_BladeOffset;
			// Courbure de base des brins
			float		_BladeCurlIntensity;
			// Courbure supplémentaire des brins (plus marqué sur le haut des brins d'herbe)
			float		_BladeExtraCurlIntensity;
			// Vitesse de scrolling de la texture utilisée pour représenter le vent
			float		_WindSpeedX;
			float		_WindSpeedY;
			// Intensité de déplacement des brins par le vent.
			float		_WindIntensity;
			// Taille des fleurs placées au sommets des brins
			float		_FlowerSize;
			// Probabilité d'avoir une fleur à la place d'un brin d'herbe simple
			float		_FlowerDensity;
			// Orientation des brins (0 = orienté par rapport à la normale du terrain, 1 = orientés vers le haut)
			float		_StraightBlade;
			// Longueur relative des brins à fleur par rapport aux brins sans fleurs
			float		_FlowersHeight;
			// Niveau de tesselation qui va influencer directement le densité de l'herbe
			float		_Tesselation;
			// Randomisation du niveau de tesselation par une texture
			float		_TesselationRnd;
			// Repartition de l'éclairage entre éclairage local au brin (0) et éclairage en fonction de la normale du terrain (1)
			float		_GroundLighting;
			// Couleur de la base des brins d'herbe
			float3		_BladeColorLow;
			// Couleur du sommet des brins d'hebre
			float3		_BladeColorHigh;


			// Structure utilisée en entrée du vertex shader
			struct VertInput
			{
				float4 position	: POSITION;
				float3 N		: NORMAL;
				float3 T		: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			// structure utilisée en entrée du geometry shader
			struct GeomInput
			{
				float4 position	: WORLDPOSITION;
				float3 N		: NORMAL;
				float3 B		: BINORMAL;
				float3 T		: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			// structure utilisée en entrée du pixel shader
			struct FragInput
			{
				float3 color	: COLOR;
				float3 normal	: NORMAL;
				float2 uv		: TEXCOORD0;
				float4 position	: SV_POSITION;
				float3 normalGround : TEXCOORD1;
			};

			// Vertex shader
			GeomInput vert(VertInput vertInput)
			{
				GeomInput geomInput;

				// Transformation de la position, normale et tangente en coordonnées world
				geomInput.position = mul(unity_ObjectToWorld, vertInput.position);
				geomInput.N = normalize(mul(unity_ObjectToWorld, float4(vertInput.N, 0.0f)).xyz);
				geomInput.T = normalize(mul(unity_ObjectToWorld, float4(vertInput.T, 0.0f)).xyz);
				// Création de la binormale à partir du cross product de la tangente et de la normale
				geomInput.B = cross(geomInput.N, geomInput.T);
				geomInput.uv = vertInput.uv;

				return geomInput;
			}


			// Tesselation
#ifdef UNITY_CAN_COMPILE_TESSELLATION
			// Structure utilisée par le hull shader pour passer les différents niveaux de tesselation
			struct OutputPatchConstant
			{
				float edge[3]         : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};
			// Fonction déterminant les différents niveaux de tesselation
			OutputPatchConstant hullconst(InputPatch<GeomInput, 3> v)
			{
				float2 uv = (v[0].uv + v[1].uv + v[2].uv) / 3.0f;
				float3 originalRandomRGB = tex2Dlod(_RandomDensity, float4(uv, 0, 0));

				float tessLevel = _Tesselation * lerp(1.0f, originalRandomRGB.r, _TesselationRnd);

				OutputPatchConstant o;
				// Niveau de tesselation des edges du triangle
				o.edge[0] = tessLevel;
				o.edge[1] = tessLevel;
				o.edge[2] = tessLevel;
				// Niveau de tesselation à l'intérieur du triangle
				o.inside  = tessLevel;
				return o;
			}
			// Format des patchs utilisés par le tesselator 
			// tri - triangles
			// quad - quadrilatères
			// line - isolines
			[domain("tri")]
			// Type de tesselation
			// fractional_odd (1..63)
			// fractional_even (2..64)
			// Integer (1..64)
			// Pow2 (1..64)
			[partitioning("fractional_odd")]
			// primitives générées par le tesselator
			// triangle_cw
			// triangle_ccw
			// line
			[outputtopology("triangle_cw")]
			// Fonction appellée une fois par patch qui va déterminer les niveaux de tesselation
			[patchconstantfunc("hullconst")]
			// Nombre de points de contrôle générés par le hull shader (0..32)
			[outputcontrolpoints(3)]
			// Pour plus d'info sur la tesselation : http://www.gamedev.net/page/resources/_/technical/directx-and-xna/d3d11-tessellation-in-depth-r3059
			// et aussi : https://msdn.microsoft.com/en-us/library/windows/desktop/ff476340%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
			// et : https://fgiesen.wordpress.com/2011/09/06/a-trip-through-the-graphics-pipeline-2011-part-12/
			GeomInput hull(InputPatch<GeomInput, 3> v, uint id : SV_OutputControlPointID)
			{
				// Code exécuté une fois par patch ...
				// aucun traitement n'est nécessaire dans notre cas ... 
				return v[id];
			}
			// Domain shader
			// Shader utilisé pour calculer la position des vertices tesselées
			[domain("tri")]
			GeomInput domain(OutputPatchConstant tessFactors, const OutputPatch<GeomInput, 3> vi, float3 bary : SV_DomainLocation)
			{
				GeomInput v;
				// Calcul de la position, normale, binormale et tangente des nouveaux vertices générés par la tesselation
				// Les positions sont calculées à partir des coordonnées barycentriques des points générés
				// pour plus d'information : https://en.wikipedia.org/wiki/Barycentric_coordinate_system
				v.position = vi[0].position*bary.x + vi[1].position*bary.y + vi[2].position*bary.z;
				v.N = vi[0].N*bary.x + vi[1].N*bary.y + vi[2].N*bary.z;
				v.B = vi[0].B*bary.x + vi[1].B*bary.y + vi[2].B*bary.z;
				v.T = vi[0].T*bary.x + vi[1].T*bary.y + vi[2].T*bary.z;
				v.uv = vi[0].uv*bary.x + vi[1].uv*bary.y + vi[2].uv*bary.z;

				return v;
			}
#endif

			// Geometry Shader
			// Fonction d'ajout de point dans le stream de données
			void addPoint(float3 pos, float3 norm, float3 normGround, float3 col, float2 uv, inout TriangleStream<FragInput> stream)
			{
				FragInput o;

				// Transformation de la position en coordonnées écran
				o.position = mul(UNITY_MATRIX_VP, float4(pos, 1.0f));
				o.color = col;
				o.normal = norm;
				o.normalGround = normGround;
				o.uv = uv;
				stream.Append(o);
			}

			// Nombre maximal de points ajoutés dans le stream par exécution du geometry shader
			[maxvertexcount(64)]
			void geom(triangle GeomInput input[3], inout TriangleStream<FragInput> stream)
			{

				float3 P1 = input[0].position;
				float3 P2 = input[1].position;
				float3 P3 = input[2].position;

				// Position centrale du triangle
				float3 center = (P1 + P2 + P3) / 3.0f;

				// Normale, binormale, tangente et uv au centre du triangle généré
				float3 centerN = (input[0].N + input[1].N + input[2].N) / 3.0f;
				float3 centerB = (input[0].B + input[1].B + input[2].B) / 3.0f;
				float3 centerT = (input[0].T + input[1].T + input[2].T) / 3.0f;
				float2 centerUV = (input[0].uv + input[1].uv + input[2].uv) / 3.0f;

				// Lecture d'une texture contenant des couleurs aléatoires différentes sur chaque channels RG et B
				float3 originalRandomRGB = tex2Dlod(_RandomRGBTex, float4(centerUV, 0, 0));
				// Transformation des valeurs aléatoires dans un range de -1 à 1
				float3 randomRGB = originalRandomRGB*2.0f;
				randomRGB -= float3(1.0f, 1.0f, 1.0f);

				// Déplacement du centre du triangle le long de la tangente et de la binormale en 
				// fonction de valeurs aléatoires
				center += _BladeOffset*randomRGB.b*centerB + _BladeOffset*randomRGB.g*centerT;

				// Angle aléatoire définissant l'orientation du brin d'herbe local
				float randomAngle = randomRGB.r*_BladeRandomisation;
				// Calcul d'une direction normalisée à partir de cet angle.
				// On utilise la tangente et la binormal comme base afin de calculer ce nouveau vecteur
				float3 bladeDir = normalize(sin(randomAngle*6.28)*centerT + cos(randomAngle*6.28)*centerB);
				// Direction de pousse du brin d'herbe qui est interpolé entre la normale du terrain
				// et la direction up
				float3 originalGrowDir = lerp(centerN, float3(0.0f, 1.0f, 0.0f), _StraightBlade);
				float3 growDir = originalGrowDir;
				// Direction perdendiculaire à l'orientation aléatoire calculée ci dessus (bladeDir)
				// qui servira a plier le brin d'herbe 
				float3 curlDir = cross(bladeDir, growDir);

				// Colorisation aléatoire des brins d'herbe, afin d'amener une variété dans ceux-ci
				float3 colorRND = (0.7f+randomRGB.g*0.7f*_BladeRandomisation);
				// Position centrale de l'étage courant du brin d'herbe
				float3 bladeRoot = center;

				// Nombre de segments utilisés pour construire un brin d'herbe. 
				// L'intéret de le mettre en const est qu'il permettra au compilateur d'optimiser
				// la boucle de construction du brin en effectuant un unroll (dépliage) de celle-ci
				const float segmentsCount = 8.0f;
				// Pas normalisé séparant deux étages
				float relativePosStep = 1.0f / segmentsCount;

				// Déplacement du au vent. On lit celui-ci dans une texture de type normale.
				// Par soucis d'optimisation, j'ai retiré la composante z inutilisée qui assure ainsi
				// une meilleure compression de la texture
				// La valeur est normalisée dans un range -1 à 1
				float3 windOffset = tex2Dlod(_WindTex, float4(centerUV*0.1f + float2(_Time.x*_WindSpeedX, _Time.x*_WindSpeedY), 0, 0));
				windOffset -= float3(0.5f, 0.5f, 0.5f);
				windOffset *= 2.0f;
				// le déplacement est multiplié par l'intensité du vent
				float3 windDirOffset = float3(windOffset.x, 0.0f, windOffset.y) * _WindIntensity;

				// Angle courant d'enroulement de l'herbe
				float angle = 0.0f;
				// Longueur finale du brin d'herbe qui est randomisé pour casser la régularité de l'ensemble
				float finalLength = _BladeLength * (1.5f+ randomRGB.r*1.2f*_BladeRandomisation);
				// Direction utilisée pour l'éclairage local du brin d'herbe
				// il s'agit bien de la direction de la pousse et non de la normale réelle du brin d'herbe. Celui-ci
				// étant double face et partiellement translucide n'utilise pas d'éclairage conventionnel
				float3 lightingNormal = normalize(growDir);
				// Randomisation de la largeur du brin
				float widthRandomisation = 1.0f + _BladeRandomisation*randomRGB.r;

				// Ajout des deux premiers points du brin d'herbe
				addPoint(bladeRoot + _BladeLowWidth*widthRandomisation*bladeDir, lightingNormal, centerN, _BladeColorLow, float2(0.0f, 0.0f), stream);
				addPoint(bladeRoot - _BladeLowWidth*widthRandomisation*bladeDir, lightingNormal, centerN, _BladeColorLow, float2(0.24f, 0.0f), stream);

				// Calcul de la valeur minimale et maximale de l'incrément d'angle.
				float lowAngle = _BladeCurlIntensity* (1.0f + randomRGB.g*_BladeRandomisation);
				float highAngle = lowAngle + _BladeExtraCurlIntensity * (1.0f+randomRGB.r*_BladeRandomisation);

				// Si le brin est une fleur, alors ajuster sa longueur et redresser sa courbure
				if (originalRandomRGB.r > 1.0f - _FlowerDensity)
				{
					highAngle = lowAngle = randomRGB.b*0.05f;
					finalLength *= _FlowersHeight;
				}

				// Boucle de création des étages du brin
				for (float relativePos = relativePosStep; relativePos <= 1.0f; relativePos += relativePosStep)
				{
					// Calcul de la largeur locale du brin
					float bladeWidth = lerp(_BladeLowWidth, _BladeHighWidth, relativePos)*widthRandomisation;
					// Mise à jour de la direction de pousse en fonction de l'angle de courbure
					growDir = (cos(angle)*originalGrowDir + sin(angle)*curlDir);
					// Mise à jour de la position centrale en fonction de la direction de pousse et de la longueur du brin
					bladeRoot += growDir * finalLength / segmentsCount;
					// Déplacement de la position centrale en fonction du vent
					bladeRoot += windDirOffset*_WindIntensity;
					// Mise à jour de l'angle de courbure en fonction de la position le long du brin
					angle += lerp(lowAngle, highAngle, relativePos)*colorRND;
					// normalisation de la direction de pousse pour utiliser comme normale d'éclairage
					lightingNormal = normalize(growDir);
					// interpolation de la couleur du brin en fonction de la position le long du brin
					float3 color = lerp(_BladeColorLow, _BladeColorHigh, relativePos)*colorRND;

					// Ajout des deux vertices de l'étage courant
					addPoint(bladeRoot + bladeWidth*bladeDir, lightingNormal, centerN, color, float2(0.0f, relativePos), stream);
					addPoint(bladeRoot - bladeWidth*bladeDir, lightingNormal, centerN, color, float2(0.24f, relativePos), stream);
				}

				// Si le brin est une fleur ... la dessiner
				if (originalRandomRGB.r > 1.0f-_FlowerDensity)
				{
					// Fin du strip du brin d'herbe 
					stream.RestartStrip();
					// Calcul de la direction perpendiculaire au brin afin de pouvoir générer le plan de la fleur
					float3 bladeDir2 = cross(bladeDir, normalize(growDir));
					// Taille de la fleur randomisée
					float flowerSize = _FlowerSize*(1.0f + randomRGB.g * .75f);
					// Choix aléatoire du modèle de fleur. Le nombre généré sera 1, 2 ou 3
					float flowerModel = 1.0f + floor(originalRandomRGB.b * 4.0f);
					// Ajout des 4 points de la fleur
					addPoint(bladeRoot + flowerSize*bladeDir + flowerSize*bladeDir2, lightingNormal, centerN, float3(1.0f, 1.0f, 1.0f)*colorRND, float2(0.25f + flowerModel*0.25f, 1.0f), stream);
					addPoint(bladeRoot - flowerSize*bladeDir + flowerSize*bladeDir2, lightingNormal, centerN, float3(1.0f, 1.0f, 1.0f)*colorRND, float2(flowerModel*0.25f, 1.0f), stream);
					addPoint(bladeRoot + flowerSize*bladeDir - flowerSize*bladeDir2, lightingNormal, centerN, float3(1.0f, 1.0f, 1.0f)*colorRND, float2(0.25f + flowerModel*0.25f, 0.0f), stream);
					addPoint(bladeRoot - flowerSize*bladeDir - flowerSize*bladeDir2, lightingNormal, centerN, float3(1.0f, 1.0f, 1.0f)*colorRND, float2(flowerModel*0.25f, 0.0f), stream);
				}
			}

			// Pixel shader
			float4 frag(FragInput fragInput) : COLOR
			{
				// Calcul de l'éclairage en fonction de la normale du terrain et de la normale locale du brin
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float NdotL = saturate(abs(dot(fragInput.normal, lightDirection)));
				float NdotLGround = saturate(abs(dot(fragInput.normalGround, lightDirection)));
				// Lecture de la texture du brin d'herbe
				float4 texColor = tex2D(_FlowerTex, fragInput.uv);
				// Si l'alpha est inférieur à 0.5, le pixel n'est pas rendu (clippé)
				clip(texColor.a - 0.5f);

				// Interpolation des deux éclairages et multiplication par la couleur de la tige
				float3 color = fragInput.color* lerp(NdotL, NdotLGround, _GroundLighting) * texColor.rgb;
				return float4(color, 1.0f);
			}
			ENDCG
		}
	}
	Fallback Off
}
