#version 450 
#extension GL_ARB_shader_storage_buffer_object : require

layout(local_size_x = 1024, local_size_y = 1) in;	


layout (std430, binding=0) volatile buffer shader_data
{ 
	vec4 pos_rad[100];
	vec4 velo_mass[100];
 
};

uniform int sizeofbuffer;

float dotProduct(vec3 v1, vec3 v2) 
{
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

vec3 scale(vec3 v, float a) {
    vec3 r;
    r.x = v.x * a;
    r.y = v.y * a;
    r.z = v.z * a;
    return r;
}

vec4 projectUonV(vec4 vel, vec4 minus)
{
	vec3 u = vec3(vel.x, vel.y, vel.z);
	vec3 v = vec3(minus.x, minus.y, minus.z);

	return vec4(scale(v, dotProduct(u, v) / dotProduct(v, v)), 0);
}

void main() 
{
	uint index = gl_LocalInvocationID.x;
	for(int i = 0; i < 100; i++)
	{
		vec4 diffpos = pos_rad[index] - pos_rad[i];
		diffpos.w = 0;
		float sumrad = pos_rad[index].w + pos_rad[i].w;
		if(i != index && (diffpos.x*diffpos.x + diffpos.y*diffpos.y + diffpos.z*diffpos.z) < sumrad*sumrad)
		{
			// this can probably be optimised a bit, but it basically swaps the velocity amounts
			// that are perpendicular to the surface of the collistion.
			// If the spheres had different masses, then u would need to scale the amounts of
			// velocities exchanged inversely proportional to their masses.
			//nv1 = s1.velocity;
			//pos_rad[index].w = 1.0f;
			velo_mass[index] += projectUonV(velo_mass[i], (pos_rad[i] - pos_rad[index]));

			velo_mass[index] -= projectUonV(velo_mass[index], (pos_rad[index] - pos_rad[i]));
			
			//collision

		}
	}
	if ((pos_rad[index].y - pos_rad[index].w) < -5.0)
		velo_mass[index].y = abs(velo_mass[index].y);

	if ((pos_rad[index].x - pos_rad[index].w) < -5.0)
		velo_mass[index].x = abs(velo_mass[index].x);

	if ((pos_rad[index].x + pos_rad[index].w) > 5.0)
		velo_mass[index].x = -abs(velo_mass[index].x);

	if ((pos_rad[index].z - pos_rad[index].w) < -25.0)
		velo_mass[index].z = abs(velo_mass[index].z);

	if ((pos_rad[index].z + pos_rad[index].w) > -15.0)
		velo_mass[index].z = -abs(velo_mass[index].z);
}