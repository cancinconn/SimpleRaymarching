// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Raymarching/Simple/Basic2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	_Centre ("Centre", Vector) = (0,0,0,0)
		_Radius("Radius", Float) = 0.4
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
				float3 wPos : TEXCOORD1;	// World position
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

#define STEPS 64
#define STEP_SIZE 0.01


			float3 _Centre;
			float _Radius;

			bool sphereHit(float3 p)
			{
				return distance(p, _Centre) < _Radius;
			}

			bool raymarchHit(float3 position, float3 direction)
			{
				for (int i = 0; i < STEPS; i++)
				{
					if (sphereHit(position))
						return true;

					position += direction * STEP_SIZE;
				}

				return false;
			}




			fixed4 frag(v2f i) : SV_Target
			{
				float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
				if (raymarchHit(i.wPos, viewDirection))
					return fixed4(1,0,0,1); // Red if hit the ball
				else
					return fixed4(1,1,1,1); // White otherwise
			}








			ENDCG
		}
	}
}
