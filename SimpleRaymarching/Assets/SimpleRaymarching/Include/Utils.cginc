#ifndef UTILS_H
#define UTILS_H

inline float3 ToLocal(float3 pos)
{
    return mul(unity_WorldToObject, float4(pos, 1.0)).xyz;
}

inline float3 ToWorld(float3 pos)
{
    return mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
}

inline float GetDepth(float3 pos)
{
    float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
#if defined(SHADER_API_D3D9) || defined(SHADER_API_D3D11)
    return vpPos.z / vpPos.w;
#else 
    return (vpPos.z / vpPos.w) * 0.5 + 0.5;
#endif 
}

inline float3 EncodeNormal(float3 normal)
{
    return normal * 0.5 + 0.5;
}

inline bool IsInnerCube(float3 pos, float3 scale)
{
    return all(max(scale * 0.5 - abs(pos), 0.0));
}

inline bool IsInnerSphere2(float3 pos, float radius)
{
	return length(float3(0,0,0) - pos) < radius ;
}

inline bool IsInnerSphere(float3 pos, float3 scale)
{
    return length(pos) <= length(scale) * 0.28867513459;
}

inline bool __IsInnerObject(float3 pos, float3 scale)
{
//#ifdef OBJECT_SHAPE_CUBE
    return IsInnerCube(pos, scale);
//#elif OBJECT_SHAPE_SPHERE
//    return IsInnerSphere(pos, scale);
//#else
//    return true;
//#endif    
}

inline bool _IsInnerObject(float3 pos, float3 scale)
{
//#ifdef OBJECT_SCALE
    return __IsInnerObject(pos, scale);
//#else
//    return __IsInnerObject(pos * scale, scale);
//#endif
}

inline bool IsInnerObject(float3 pos)
{
	//removing scale for now and replacing with direct comparison for being in cube
	return IsInnerSphere2(pos, .5);


//#ifdef OBJECT_SCALE
    //return _IsInnerObject(ToLocal(pos), 1.0);
//#else
//    return _IsInnerObject(ToLocal(pos), abs(_Scale));
//#endif
}

inline bool IsOutsideSphere(float3 pos, float3 scale)
{
	return (length(float3(0, 0, 0) - pos) > scale);
}

inline bool IsOutsideBox(float3 pos, float3 scale)
{
	return !all(max(scale * 0.5 - abs(pos), 0.0));

	//!all(max(1.0 * 0.5 - abs(position), 0.0))
}

#endif
