/*
	Standard Warped Noise
	---------------------

	Loosely based on the original by Shadertoy user "jackdavenport."
	https://www.shadertoy.com/view/Mt2SzR

	In keeping with the concept of the original, this was also coded straight off the top of my head.

*/

shader_type canvas_item;

// Virtually the same as your original function, just in more compact (and possibly less reliable) form.
float smoothNoise(vec2 p) {
	
	vec2 f = fract(p);
	p-=f;
	f *= f*(3.-f-f); 
	vec4 val = fract(sin(vec4(0, 1, 27, 28) + p.x+p.y*27.) * 1e5);    
    return dot(mat2(val.xy,val.zw)*vec2(1.-f.y,f.y), vec2(1.-f.x, f.x));
}

// Also the same as the original, but with one less layer.
float fractalNoise(vec2 p) {
    
    return smoothNoise(p)*0.5333 + smoothNoise(p*2.)*0.2667 + smoothNoise(p*4.)*0.1333 + smoothNoise(p*8.)*0.0667;
    
    // Similar version with fewer layers. The highlighting sample distance would need to be tweaked.
    //return smoothNoise(p)*0.57 + smoothNoise(p*2.45)*0.28 + smoothNoise(p*6.)*0.15;
    
    // Even fewer layers, but the sample distance would need to be tweaked.
    //return smoothNoise(p)*0.65 + smoothNoise(p*4.)*0.35;    
}

// Standard noise warping. Call the noise function, then feed a variation of the result
// into itself. Rinse and repeat, etc. Completely made up on the spot, but keeping your 
// original concept in mind, which involved combining noise layers travelling in opposing
// directions.
float warpedNoise(vec2 p, float time) {
    
    vec2 m = vec2(time, -time)*.5;//vec2(sin(iTime*0.5), cos(iTime*0.5));
    float x = fractalNoise(p + m);
    float y = fractalNoise(p + m.yx + x);
    float z = fractalNoise(p - m - x + y);
    return fractalNoise(p + vec2(x, y) + vec2(y, z) + vec2(z, x) + length(vec3(x, y, z))*0.25);
    
}

void fragment()
{
    // Screen coordinates. Using division by a scalar, namely "iResolution.y," for aspect correctness.
	vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).y;
    
    // Take two noise function samples near one another.
    float n = warpedNoise(uv * 6., TIME);
    float n2 = warpedNoise(uv * 6. + 0.02, TIME);
    
    // Highlighting - Effective, but not a substitute for bump mapping.
    //
    // Use a sample distance variation to produce some cheap and nasty highlighting. The process 
    // is vaguely related to directional derivative lighting, which in turn is mildly connected to 
    // Calculus from First Principles.
    float bump = max(n2 - n, 0.)/.02*.7071;
    float bump2 = max(n - n2, 0.)/.02*.7071;
    
    // Ramping the bump values up.
    bump = bump*bump*.5 + pow(bump, 4.)*.5;
    bump2 = bump2*bump2*.5 + pow(bump2, 4.)*.5;
    
    // Produce a color based on the original noise function, then add the highlights.
    //
    // Liquid glass, wax or ice, with sun glow?
    // vec3 col = vec3(n*n)*(vec3(.25, .5, 1.)*bump*.2 + vec3(1., .4, .2)*bump2*.2 + .5);
    // Fake jade.
    // vec3 col = vec3(n*n*0.7, n, n*n*0.4)*n*n*(vec3(0.25, 0.5, 1.)*bump*.2 + vec3(1)*bump2*.2 + .75);
    // Cheap fire palette.
    // vec3 col = pow(vec3(1.5, 1, 1)*n, vec3(2, 5, 24))*.8 + vec3(0.25, 0.5, 1.)*(bump + bump2)*.05;
    // Not sure. :)
    vec3 col = n*n*(vec3(1, .7, .6)*vec3(bump, (bump + bump2)*.4, bump2)*.2 + .5) + vec3(0.1, 0.3, 0.4);
    // etc.
    
    // Rough gamma correction.
	COLOR = vec4(sqrt(max(col, 0.)), 1.);
}