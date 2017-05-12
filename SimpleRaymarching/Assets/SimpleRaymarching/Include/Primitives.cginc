#ifndef PRIMITIVES_H
#define PRIMITIVES_H

inline float Sphere(float3 pos, float radius)
{
    return length(pos) - radius;
}

inline float RoundBox(float3 pos, float3 size, float round)
{
    return length(max(abs(pos) - size, 0.0)) - round;
}

inline float Box(float3 pos, float3 size)
{
    // complete box (round = 0.0) cannot provide high-precision normals.
    return RoundBox(pos, size, 0.0001);
}

inline float Torus(float3 pos, float2 radius)
{
    float2 r = float2(length(pos.xy) - radius.x, pos.z);
    return length(r) - radius.y;
}

inline float Plane(float3 pos, float3 dir)
{
    return dot(pos, dir);
}

inline float Cylinder(float3 pos, float2 r)
{
    float2 d = abs(float2(length(pos.xy), pos.z)) - r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - 0.1;
}

inline float HexagonalPrismX(float3 pos, float2 h)
{
    float3 p = abs(pos);
    return max(
        p.x - h.y, 
        max(
            (p.z * 0.866025 + p.y * 0.5),
            p.y
        ) - h.x
    );
}

inline float HexagonalPrismY(float3 pos, float2 h)
{
    float3 p = abs(pos);
    return max(
        p.y - h.y, 
        max(
            (p.z * 0.866025 + p.x * 0.5),
            p.x
        ) - h.x
    );
}

inline float HexagonalPrismZ(float3 pos, float2 h)
{
    float3 p = abs(pos);
    return max(
        p.z - h.y, 
        max(
            (p.x * 0.866025 + p.y * 0.5),
            p.y
        ) - h.x
    );
}

//===========MY ADDITIONS==============

//From: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

inline float TriangularPrismZ(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.z - h.y, max(q.x*0.866025 + p.y*0.5, -p.y) - h.x*0.5);
}

inline float TriangularPrismY(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.y - h.y, max(q.z*0.866025 + p.x*0.5, -p.x) - h.x*0.5);
}

inline float Capsule(float3 p, float3 a, float3 b, float r)
{
	float3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba*h) - r;
}

inline float CappedCone(in float3 p, in float3 c)
{
	float2 q = float2(length(p.xz), p.y);
	float2 v = float2(c.z*c.y / c.x, -c.z);
	float2 w = v - q;
	float2 vv = float2(dot(v, v), v.x*v.x);
	float2 qv = float2(dot(v, w), v.x*w.x);
	float2 d = max(qv, 0.0)*qv / vv;
	return sqrt(dot(w, w) - max(d.x, d.y)) * sign(max(q.y*v.x - q.x*v.y, w.y));
}

#endif
