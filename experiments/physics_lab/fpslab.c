/* Experimental only: stable, tiny C ABI over the unmodified MIT FPS.
 * No pointers or FPS struct layouts leak into the LuaJIT client.
 * WARNING: upstream is WIP, so this is not part of Manuscript production.
 */
#define FPS_IMPLEMENTATION
#include "vendor/fps.h"
#include <stdlib.h>
#include <math.h>

#if defined(_WIN32)
#define FPSLAB_API __declspec(dllexport)
#else
#define FPSLAB_API __attribute__((visibility("default")))
#endif
#define LAB_MAX_DICE 6
#define LAB_STATIC 5

typedef struct fpslab {
    int n;
    fps_body *dice[LAB_MAX_DICE];
    fps_part *die_parts[LAB_MAX_DICE];
    fps_body *boundaries[LAB_STATIC];
    fps_part *boundary_parts[LAB_STATIC];
    float gravity;
    float edge;
} fpslab;

static int valid_float(float f) { return isfinite(f); }
static int make_part(fps_body **out_body,fps_part **out_part,
                     float sx,float sy,float sz,float mass,
                     float x,float y,float z,int dynamic,
                     float friction,float restitution) {
    fps_body *b=fps_body_new();
    fps_part *p=fps_part_new();
    if(!b || !p) {
        if(p)fps_part_free(p);
        if(b)fps_body_free(b);
        return 0;
    }
    float dims[3]={sx,sy,sz};
    float pos[3]={x,y,z};
    fps_part_size_set(p,dims);
    fps_part_density_set(p,mass/(sx*sy*sz));
    fps_part_friction_set(p,friction);
    fps_part_restitution_set(p,restitution);
    fps_part_solid_set(p,FPS_TRUE);
    fps_body_part_add(b,p);
    fps_body_dynamic_set(b,dynamic?FPS_TRUE:FPS_FALSE);
    fps_body_position_set(b,pos);
    *out_body=b;*out_part=p;
    return 1;
}

FPSLAB_API void fpslab_free(fpslab *w) {
    if(!w)return;
    for(int i=0;i<LAB_MAX_DICE;i++) {
        if(w->die_parts[i])fps_part_free(w->die_parts[i]);
        if(w->dice[i])fps_body_free(w->dice[i]);
    }
    for(int i=0;i<LAB_STATIC;i++) {
        if(w->boundary_parts[i])fps_part_free(w->boundary_parts[i]);
        if(w->boundaries[i])fps_body_free(w->boundaries[i]);
    }
    free(w);
}

/* Initial states are n rows, each position[3], velocity[3], angular[3].
   The body edge is the true cube edge, not its bounding sphere radius. */
FPSLAB_API fpslab *fpslab_new(int n,const float *states,float edge,
                             float half_x,float half_y,float rim,float gravity) {
    if(n<1 || n>LAB_MAX_DICE || !states || !valid_float(edge) ||
       edge<=0 || half_x<=edge || half_y<=edge || rim<=0 ||
       !valid_float(gravity) || gravity<0) return NULL;
    fpslab *w=(fpslab*)calloc(1,sizeof(fpslab));
    if(!w)return NULL;
    w->n=n;w->gravity=gravity;w->edge=edge;
    /* A zero-height floor surface is represented by a thick static cuboid. */
    const float floor_t=.6f;
    const float wall_t=.30f;
    const float blocks[LAB_STATIC][6]={
        {2*half_x,2*half_y,floor_t,0,0,-floor_t/2},
        {wall_t,2*half_y+2*wall_t,rim,half_x+wall_t/2,0,rim/2},
        {wall_t,2*half_y+2*wall_t,rim,-half_x-wall_t/2,0,rim/2},
        {2*half_x+2*wall_t,wall_t,rim,0,half_y+wall_t/2,rim/2},
        {2*half_x+2*wall_t,wall_t,rim,0,-half_y-wall_t/2,rim/2}
    };
    for(int i=0;i<LAB_STATIC;i++) {
        const float *p=blocks[i];
        if(!make_part(&w->boundaries[i],&w->boundary_parts[i],
                      p[0],p[1],p[2],1000,p[3],p[4],p[5],
                      0,.75f,.25f)) goto fail;
    }
    for(int i=0;i<n;i++) {
        const float *s=states+9*i;
        for(int k=0;k<9;k++)if(!valid_float(s[k]))goto fail;
        if(!make_part(&w->dice[i],&w->die_parts[i],edge,edge,edge,
                      1.2f,s[0],s[1],s[2],1,.85f,.25f))goto fail;
        float vel[3]={s[3],s[4],s[5]};
        float spin[3]={s[6],s[7],s[8]};
        fps_body_velocity_set(w->dice[i],vel);
        fps_body_angular_velocity_set(w->dice[i],spin);
    }
    return w;
fail:
    fpslab_free(w);
    return NULL;
}

/* One fixed step, no variable dt. Collisions are tested before stepping as
   required by FPS upstream example; FPS sleep behaviour is deliberately
   unmodified so premature sleep will show up in the diagnostics. */
FPSLAB_API int fpslab_step(fpslab *w,float dt) {
    if(!w || !valid_float(dt) || dt<=0 || dt>.05f)return 0;
    for(int i=0;i<w->n;i++) {
        fps_body *b=w->dice[i];
        float force[3]={0,0,-w->gravity*fps_body_mass_get(b)};
        fps_body_force_apply(b,force);
    }
    for(int i=0;i<w->n;i++) {
        for(int j=i+1;j<w->n;j++)
            fps_collision_test(w->dice[i],w->dice[j]);
        for(int j=0;j<LAB_STATIC;j++)
            fps_collision_test(w->dice[i],w->boundaries[j]);
    }
    for(int i=0;i<w->n;i++)
        fps_body_step(w->dice[i],dt);
    return 1;
}

/* 16 world transform values, then 3 linear + 3 angular velocities. */
FPSLAB_API int fpslab_state(const fpslab *w,int index,float *out22) {
    if(!w || !out22 || index<0 || index>=w->n)return 0;
    fps_body *b=w->dice[index];
    fps_body_transform_get(b,out22);
    fps_body_velocity_get(b,out22+16);
    fps_body_angular_velocity_get(b,out22+19);
    return 1;
}
FPSLAB_API int fpslab_sleeping(const fpslab *w,int index) {
    if(!w || index<0 || index>=w->n)return -1;
    return fps_body_sleeping_get(w->dice[index])?1:0;
}

/* Lab 2 diagnostic only: positional floor guard, NOT an upstream FPS solver
 * fix. This runs AFTER an FPS step, and must never be used by production.
 * Return number of corrected dice and the largest vertical correction.
 * The original fpslab_step() and FPS 1.2.5 header remain unmodified.
 */
FPSLAB_API int fpslab_floor_guard(fpslab *w,float *max_depth) {
    if(max_depth)*max_depth=0;
    if(!w)return -1;
    int corrected=0;
    const float half=w->edge*.5f;
    for(int i=0;i<w->n;i++) {
        fps_body *body=w->dice[i];
        float t[16];
        fps_body_transform_get(body,t);
        float lowest=INFINITY;
        for(int sx=-1;sx<=1;sx+=2)
        for(int sy=-1;sy<=1;sy+=2)
        for(int sz=-1;sz<=1;sz+=2) {
            const float x=half*sx,y=half*sy,z=half*sz;
            const float wz=t[8]*x+t[9]*y+t[10]*z+t[11];
            if(!isfinite(wz))return -1;
            if(wz<lowest)lowest=wz;
        }
        if(lowest<-.002f) {
            const float depth=-lowest;
            float pos[3],vel[3];
            fps_body_position_get(body,pos);
            pos[2]+=depth;
            fps_body_position_set(body,pos);
            fps_body_velocity_get(body,vel);
            if(vel[2]<0.0f) {
                vel[2]=0.0f;
                fps_body_velocity_set(body,vel);
            }
            corrected++;
            if(max_depth && depth>*max_depth)*max_depth=depth;
        }
    }
    return corrected;
}


/* Lab 3: read-only lowest transformed D6 corner in the floor's z=0 frame.
 * No mutation of the pinned upstream FPS 1.2.5 header or production physics.
 */
static float fpslab_lowest_z(const fpslab *w,int index) {
    float t[16];
    fps_body_transform_get(w->dice[index],t);
    const float h=w->edge*.5f;
    float lowest=INFINITY;
    for(int sx=-1;sx<=1;sx+=2)
    for(int sy=-1;sy<=1;sy+=2)
    for(int sz=-1;sz<=1;sz+=2) {
        float z=t[8]*(sx*h)+t[9]*(sy*h)+t[10]*(sz*h)+t[11];
        if(z<lowest)lowest=z;
    }
    return lowest;
}

/* Return 4 read-only per-step counters: number sleeping above support,
 * number penetrating below the floor, maximum penetration, and nearest
 * floor distance. No body pose or velocity is changed by this probe.
 */
FPSLAB_API int fpslab_probe(const fpslab *w,float *out4) {
    if(!w || !out4)return 0;
    out4[0]=0;out4[1]=0;out4[2]=0;out4[3]=INFINITY;
    for(int i=0;i<w->n;i++) {
        float bottom=fpslab_lowest_z(w,i);
        if(!isfinite(bottom))return 0;
        if(fps_body_sleeping_get(w->dice[i]) && bottom>.08f)out4[0]+=1;
        if(bottom<-.002f) {
            out4[1]+=1;
            if(-bottom>out4[2])out4[2]=-bottom;
        }
        if(bottom<out4[3])out4[3]=bottom;
    }
    return 1;
}

/* A diagnostic alternative only: before the UNCHANGED FPS step, wake any
 * sleeping body whose lowest corner is above the z=0 support surface.
 * Repeated wakeups expose FPS's unconditional low-speed sleeping, and do
 * NOT fix the contact solver. Non-penetrating grounded sleeping is untouched.
 */
FPSLAB_API int fpslab_step_support(fpslab *w,float dt) {
    if(!w || !valid_float(dt) || dt<=0 || dt>.05f)return -1;
    int wakes=0;
    for(int i=0;i<w->n;i++) {
        if(fps_body_sleeping_get(w->dice[i]) && fpslab_lowest_z(w,i)>.08f) {
            fps_body_sleeping_set(w->dice[i],FPS_FALSE);
            wakes++;
        }
    }
    if(!fpslab_step(w,dt))return -1;
    return wakes;
}

/* Set an initial Euler orientation only for the single-die lab fixture.
 * fps_body_rotation_set overwrites translation, so preserve and restore it.
 */
FPSLAB_API int fpslab_set_euler(fpslab *w,int index,float rx,float ry,float rz) {
    if(!w || index<0 || index>=w->n ||
       !valid_float(rx) || !valid_float(ry) || !valid_float(rz))return 0;
    fps_body *body=w->dice[index];
    float position[3],angles[3]={rx,ry,rz};
    fps_body_position_get(body,position);
    fps_body_rotation_set(body,angles);
    fps_body_position_set(body,position);
    fps_body_sleeping_set(body,FPS_FALSE);
    return 1;
}

FPSLAB_API int fpslab_version(void) { return 125; }
