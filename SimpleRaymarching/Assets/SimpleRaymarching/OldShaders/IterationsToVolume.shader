// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Raymarching/Simple/IterationsToVolume"
{

	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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

			#define STEPS 30 //number of steps
			#define STEP_SIZE 0.01
			#define MIN_DISTANCE 0.01 //how close ray has to be to render a point

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


			//Define the distance function for raymarching here
			float distanceFunction(float3 rpos) {
				float3 centre = float3(0, 0, 0);
				float radius = .1;
				return distance(rpos, centre) - radius;
			}

			//Show Distance as output Colour
			fixed4 getRaymarchDistance(float3 position, float3 direction)
			{
				for (int i = 0; i < STEPS; i++)
				{
					float distance = distanceFunction(position);
					if (distance < MIN_DISTANCE) return i / (float)STEPS;

					//assuming direction is normalized
					position += distance * direction;
				}
				//discard;
				return fixed4(0, 0, 0, 0);
			}

			//raymarching function - return true if we hit simulated volume
			bool raymarchHit(float3 position, float3 direction)
			{
				for (int i = 0; i < STEPS; i++)
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

				return getRaymarchDistance(worldPosition, viewDirection);


				return col;
			}



			


			ENDCG
		}
	}
}
