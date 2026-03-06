local pulse = love.graphics.newShader
[[

extern float time, radius, min;
extern vec2 center;

vec4 effect( vec4 color, Image texture, vec2 tc, vec2 pc )

{
	float x = ( pc.x - center.x ) / 127.0;
	float y = ( pc.y - center.y ) / 127.0;

	float a = sqrt( y * y + x * x ) / radius;

	float t = sin( time );

	float r = color[0];
	float g = color[1];
	float b = color[2];

	vec3 c = vec3( r, g, b );

	return vec4( c, clamp( color[3] * ( a + t ), min, 1.0 ) );
}

]]

return pulse
