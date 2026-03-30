//----------------------------------------------------------------------------
//	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
//	This program is free software; you can redistribute it and/or modify it	
//	under the terms of the GNU General Public License as published by the	
//	Free Software Foundation; either version 2 of the License, or (at your	
//	option) any later version. This program is distributed in the hope that	
//	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
//	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
//	the GNU General Public License for more details. A full copy of this	
//	license is available at http://www.gnu.org/licenses/gpl.txt.
//----------------------------------------------------------------------------

// coplanar_checker.fx
float4x4 WorldViewProj : WorldViewProjection;
float4x4 World         : World;

float Scale       = 176.3;
float ScaleG      = 171.2;
float ScaleB      = 186.6;
float Modulo      = 1.0;
float Sensitivity = 18.0;

// -- Vertex Shader ------------------------------------------
struct VS_INPUT {
    float4 Pos : POSITION;
};

struct VS_OUTPUT {
    float4 Pos      : SV_POSITION;
    float3 WorldPos : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT In) {
    VS_OUTPUT Out;
    Out.Pos      = mul(In.Pos, WorldViewProj);
    Out.WorldPos = mul(In.Pos, World).xyz;
    return Out;
}

// -- Geometry Shader ----------------------------------------
struct GS_OUTPUT {
    float4 Pos      : SV_POSITION;
    float3 FaceNorm : TEXCOORD1;
};

[maxvertexcount(3)]
void GS(triangle VS_OUTPUT In[3],
        inout TriangleStream<GS_OUTPUT> stream)
{
    float3 edge1 = In[1].WorldPos - In[0].WorldPos;
    float3 edge2 = In[2].WorldPos - In[0].WorldPos;
    float3 faceNormal = normalize(cross(edge1, edge2));

    GS_OUTPUT Out;
    for (int i = 0; i < 3; i++) {
        Out.Pos      = In[i].Pos;
        Out.FaceNorm = faceNormal;
        stream.Append(Out);
    }
}

// -- Pixel Shader -------------------------------------------
float4 PS(GS_OUTPUT In) : SV_TARGET {
    float3 Nabs = abs(In.FaceNorm);
    // Sensitivity amplifies the normal before fmod
    // Higher values ​​result in greater contrast between triangles with small differences
    float r = fmod(Nabs.x * Scale * Sensitivity, Modulo);
    float g = fmod(Nabs.y * ScaleG * Sensitivity, Modulo);
    float b = fmod(Nabs.z * ScaleB * Sensitivity, Modulo);

    return float4(r, g, b, 1.0);
}

// -- Render States ------------------------------------------
BlendState NoBlend {
    BlendEnable[0]           = false;
    RenderTargetWriteMask[0] = 0x0F;
};

DepthStencilState DepthOn {
    DepthEnable    = true;
    DepthWriteMask = ALL;
    DepthFunc      = LESS_EQUAL;
};

RasterizerState SolidBack {
    CullMode = BACK;
    FillMode = SOLID;
};

// -- Technique ----------------------------------------------
technique11 CoplanarChecker {
    pass P0 {
        SetBlendState       ( NoBlend,  float4(0,0,0,0), 0xFFFFFFFF );
        SetDepthStencilState( DepthOn,  0 );
        SetRasterizerState  ( SolidBack );
        VertexShader   = compile vs_5_0 VS();
        GeometryShader = compile gs_5_0 GS();
        PixelShader    = compile ps_5_0 PS();
    }
}