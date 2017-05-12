// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Raymarching/Simple/RedSphere"
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

			#define STEPS 30
			#define STEP_SIZE 0.01

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
			bool distanceFunction(float3 rayPos) {
				float3 centre = float3(0, 0, 0);
				float radius = 1;
				return distance(rayPos, centre) < radius;
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

				if (raymarchHit(worldPosition, viewDirection))
				{
					return fixed4(1, 0, 0, 1); // Red if hit
				}
				else
				{
					discard;
					//return fixed4(1, 1, 1, 1); // White otherwise
				}


				return col;
			}



			


			ENDCG
		}
	}
}
