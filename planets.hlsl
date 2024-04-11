#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0001

uv.y = 1-uv.y;
uv -= 0.5;

float t = Time;
//Coordinate manipulation

//kiminus setup

float kTime = lerp(-0.1, 0.1, frac(t));
float4 kiminus = float4(0, 3, 10, 2.5);
    float s = sin(kTime);
    float c = cos(kTime);
    float2x2 rot = float2x2(c, -s, s, c);
kiminus.xz = mul(kiminus.xz ,rot);

float4x4 toKiminus = float4x4(	1, 0, 0, 0,
								0, 1, 0, 0,
								0, 0, 1, 0,
								kiminus.x, kiminus.y, kiminus.z, 1);


//First moon setup
float mTime =lerp(-0.2, 5.1, frac(t));

float4 moon = float4(2.6, -1, 3, 1);
    s = sin(mTime);
    c = cos(mTime);
    rot = float2x2(c, -s, s, c);
moon.xz = mul(moon.xz ,rot);
moon = mul(moon, toKiminus);
moon.w = 0.5; //the SDF spheres radius is stored in the w component

float4x4 toMoon = float4x4(	1, 0, 0, 0,
							0, 1, 0, 0,
							0, 0, 1, 0,
							moon.x, moon.y, moon.z, 1);


//Second moon setup
float mmTime =lerp(-3, 4.9*10, frac(t));

float4 moonMoon = float4(0.7,-0.2,0.6, 1);
    s = sin(mmTime);
    c = cos(mmTime);
    rot = float2x2(c, -s, s, c);
moonMoon.xz = mul(moonMoon.xz ,rot);
moonMoon = mul(moonMoon, toMoon);

moonMoon.w = 0.08; //the SDF spheres radius is stored in the w component

//Raymarching loop

//Ray origin
float3 ro = float3(0, 3.5, -1); 
//Ray direction
float3 rd = normalize(float3(uv.x, uv.y, 1));
float kiminusDist = 0;
float moonDist = 0;
float moonMoonDist = 0;
int objID = 0; //1 = Kiminus, 2 = Moon, 3 = MoonMoon

float dO = 0.0;
for(int i=0; i<MAX_STEPS; i++){
   float3 p = ro + rd*dO;
   kiminusDist = length(p-kiminus.xyz)-kiminus.w;
   moonDist = length(p-moon.xyz)-moon.w;
   moonMoonDist = length(p-moonMoon.xyz)-moonMoon.w;
   float dS = min(min(moonMoonDist,moonDist),kiminusDist);
   dO += dS;
   if(dS<SURF_DIST){     
	  if (dS == kiminusDist){
	     objID = 1;
         break;
	  };
	  if (dS == moonDist){
	     objID = 2;
         break;
	  };
	  if (dS == moonMoonDist){
	     objID = 3;
         break;
	  };		     
      break;
   };
   if(dO>MAX_DIST) break;
}



//Shading
//Get light
float3 p = ro + rd*dO;
float3 lightPos = float3(-15, -5 ,-10);

float2 e = float2(0.01, 0);

//Calculate Normal
//Get distans to point
   kiminusDist = length(p-kiminus.xyz)-kiminus.w;
   moonDist = length(p-moon.xyz)-moon.w;
   moonMoonDist = length(p-moonMoon.xyz)-moonMoon.w;
   float d = min(min(moonMoonDist,moonDist), kiminusDist);

//Get distance to point -e.xyy
   float3 pe = p - e.xyy;
   kiminusDist = length(pe-kiminus.xyz)-kiminus.w;
   moonDist = length(pe-moon.xyz)-moon.w;
   moonMoonDist = length(pe-moonMoon.xyz)-moonMoon.w;
   float dexyy = min(min(moonMoonDist,moonDist), kiminusDist);

//Get distance to point -e.yxy
   pe = p - e.yxy;
   kiminusDist = length(pe-kiminus.xyz)-kiminus.w;
   moonDist = length(pe-moon.xyz)-moon.w;
   moonMoonDist = length(pe-moonMoon.xyz)-moonMoon.w;
   float deyxy = min(min(moonMoonDist,moonDist), kiminusDist);

//Get distance to point -e.yyx
   pe = p - e.yyx;
   kiminusDist = length(pe-kiminus.xyz)-kiminus.w;
   moonDist = length(pe-moon.xyz)-moon.w;
   moonMoonDist = length(pe-moonMoon.xyz)-moonMoon.w;
   float deyyx = min(min(moonMoonDist,moonDist), kiminusDist);

   float3 n = normalize(d - float3(dexyy, deyxy, deyyx));
   
   float3 l = normalize(lightPos-p);
   float diffuse = saturate(dot(n, l));
   
//Calculate shadows
//Raymarching loop
p = ro + rd * dO;
dO=0.0;
for(int j=0; j<MAX_STEPS; j++){
   float3 ps = p+n*SURF_DIST*2 + l*dO;
   kiminusDist = length(ps-kiminus.xyz)-kiminus.w;
   float moonDist = length(ps-moon.xyz)-moon.w;
   float moonMoonDist = length(ps-moonMoon.xyz)-moonMoon.w;
   float dS = min(min(moonMoonDist,moonDist), kiminusDist);
   dO += dS;
   if(dO>MAX_DIST || dS<SURF_DIST) break;
}
if(dO<length(lightPos-p)) diffuse *= .1;


//Color differently depending on Id

float3 col = 0;
float3 kiminusCol = float3(0.180 ,0.251 ,0.341);
if (objID == 1) col = kiminusCol*25;
if (objID == 2) col = (1-kiminusCol)*25;
if (objID == 3) col = float3(0.5 ,0.8 ,0.9)*22;

col *= diffuse;
return col;
