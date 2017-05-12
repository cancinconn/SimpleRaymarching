// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Raymarching/Simple/Basic3"
{

	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Colour", Color) = (1,1,1,1)
		_SpecularPower("Specular Power", Float) = 0
		_Gloss("Gloss", Float) = 0
		_MinimumLight("Minimum Light", Range(0,1)) = 0
		_Steps("_Steps", Int) = 32  //how many iterations (max) in raymarch
		_MinDistance("MinimumDistance", Float) = 0.01  //how close ray has to be to render a point
		_RimColor("Rim Colour", Color) = (1,1,1,1)
		_RimPower("Rim Power", Float) = 0.1
			_Bias("Bias", Float) = 0
			_Scale("Scale", Float) = 1
			_Power("Power", Float) = 1
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			float _MinDistance;
			fixed _Steps;
			fixed _SpecularPower;
			fixed _Gloss;
			fixed _MinimumLight;
			fixed4 _RimColour;
			fixed _RimPower;
			float _Bias;
			float _Power;
			float _Scale;
			#define STEP_SIZE 0.01

			//Define the distance function for raymarching here
			float distanceFunction(float3 rpos) 
			{
				float3 centre = float3(0, 0, 0);
				float radius = 0.4;
				return distance(rpos, centre) - radius;
			}

			//Code for surface shading

			fixed4 _Color;

			
			fixed4 simpleLambert(fixed3 normal, fixed3 viewDirection) 
			{
				fixed3 lightDir = -_WorldSpaceLightPos0.xyz;	// Light direction, NOT sure why I had to flip it, but it seems to be accurate when it's flipped :c
				fixed3 lightCol = _LightColor0.rgb;		// Light color

				fixed NdotL = max(dot(normal, lightDir),0);
				fixed4 c;

				// Specular
			    fixed3 h = (lightDir - viewDirection) / 2.;
				fixed spec = pow(dot(normal, h), _SpecularPower) * _Gloss;

				//My addition, introduces minimum light - doesn't account for coloured light though.
				//lightCol = max(lightCol, _MinimumLight);

				//fixed3 lambertCol = _Color * lightCol * NdotL + s;

				fixed3 finalLight = lightCol + spec + UNITY_LIGHTMODEL_AMBIENT;
				fixed3 finalCol = _Color * finalLight * NdotL;

				fixed3 minimumCol = _Color * _MinimumLight;

				//rim lighting (doesn't work :c   dot(viewDirection, normal) always returns 0 for some reason... )
				//float3 normWorld = normalize(mul(float4x4(unity_ObjectToWorld), normal));
				//half rim = 1.0 - saturate(dot(lightDir, normWorld));
				//fixed3 rimCol = _RimColour.rgb * pow(rim, _RimPower);

				//basic fresnel instead, to serve as rim lighting. using the empirical approximation from NVidia CG guide and the simpler guide at http://kylehalladay.com/blog/tutorial/2014/02/18/Fresnel-Shaders-From-The-Ground-Up.html
				float3 I = viewDirection; //normalize(posWorld - _WorldSpaceCameraPos.xyz);
				float3 normWorld = normalize( mul(float4x4(unity_ObjectToWorld), normal) );
				float R = _Bias + _Scale * pow(1.0 + dot(I, normWorld), _Power);

				c.rgb = max(finalCol, minimumCol);

				//apply fresnel effect
				c.rgb = lerp(c.rgb, _Color, R); //lerp towards the intrinsic colour of the object by R, the fresnel strength.
				c.a = 1;

				return c;
			}

			float3 volumeNormal(float3 p)
			{
				const float eps = 0.01;

				return normalize
					(float3
						(distanceFunction(p + float3(eps, 0, 0)) - distanceFunction(p - float3(eps, 0, 0)),
							distanceFunction(p + float3(0, eps, 0)) - distanceFunction(p - float3(0, eps, 0)),
							distanceFunction(p + float3(0, 0, eps)) - distanceFunction(p - float3(0, 0, eps))
							)
						);
			}


			//get colour of raymarch volume's surface
			fixed4 renderVolumeSurface(float3 pos, float3 viewDirection)
			{
				float3 n = volumeNormal(pos);
				return simpleLambert(n, viewDirection);
			}

			//end code for surface shading


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD1; //World position
			};




			//Show Distance as output Colour
			fixed4 getRaymarchDistance(float3 position, float3 direction)
			{
				for (int i = 0; i < _Steps; i++)
				{
					float distance = distanceFunction(position);
					if (distance < _MinDistance) return i / (float)_Steps;

					//assuming direction is normalized
					position += distance * direction;
				}
				//discard;
				return fixed4(0, 0, 0, 0);
			}

			//
			fixed4 getRaymarchShaded(float3 position, float3 direction)
			{
				for (int i = 0; i < _Steps; i++)
				{
					float distance = distanceFunction(position);
					if (distance < _MinDistance) return renderVolumeSurface(position, direction);

					//assuming direction is normalized
					position += distance * direction;
				}
				discard;
				return fixed4(0, 0, 0, 0);
			}

			//raymarching function - return true if we hit simulated volume
			bool raymarchHit(float3 position, float3 direction)
			{
				for (int i = 0; i < _Steps; i++)
				{
					if (distanceFunction(position))
						return true;

					position += direction * STEP_SIZE;
				}

				return false;
			}




			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				//raymarching
				float3 worldPosition = i.wPos;
				float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

				return getRaymarchShaded(worldPosition, viewDirection);

			}



			


			ENDCG
		}
	}
}
