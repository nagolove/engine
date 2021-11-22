local ffi = require'ffi'

ffi.cdef[[
typedef double cpFloat;
cpFloat cpfmax(cpFloat a, cpFloat b);
cpFloat cpfmin(cpFloat a, cpFloat b);
cpFloat cpfabs(cpFloat f);
cpFloat cpfclamp(cpFloat f, cpFloat min, cpFloat max);
cpFloat cpfclamp01(cpFloat f);
cpFloat cpflerp(cpFloat f1, cpFloat f2, cpFloat t);
cpFloat cpflerpconst(cpFloat f1, cpFloat f2, cpFloat d);
typedef uintptr_t cpHashValue;
typedef uint32_t cpCollisionID;
typedef int cpBool;
typedef void * cpDataPointer;
typedef uintptr_t cpCollisionType;
typedef uintptr_t cpGroup;
typedef unsigned int cpLayers;
typedef unsigned int cpTimestamp;
typedef struct cpVect{cpFloat x,y;} cpVect;
typedef struct cpMat2x2 {
 cpFloat a, b, c, d;
} cpMat2x2;
typedef struct cpArray cpArray;
typedef struct cpHashSet cpHashSet;
typedef struct cpBody cpBody;
typedef struct cpShape cpShape;
typedef struct cpConstraint cpConstraint;
typedef struct cpCollisionHandler cpCollisionHandler;
typedef struct cpArbiter cpArbiter;
typedef struct cpSpace cpSpace;
cpVect cpv(const cpFloat x, const cpFloat y);
cpVect cpvslerp(const cpVect v1, const cpVect v2, const cpFloat t);
cpVect cpvslerpconst(const cpVect v1, const cpVect v2, const cpFloat a);
char* cpvstr(const cpVect v);
cpBool cpveql(const cpVect v1, const cpVect v2);
cpVect cpvadd(const cpVect v1, const cpVect v2);
cpVect cpvsub(const cpVect v1, const cpVect v2);
cpVect cpvneg(const cpVect v);
cpVect cpvmult(const cpVect v, const cpFloat s);
cpFloat cpvdot(const cpVect v1, const cpVect v2);
cpFloat cpvcross(const cpVect v1, const cpVect v2);
cpVect cpvperp(const cpVect v);
cpVect cpvrperp(const cpVect v);
cpVect cpvproject(const cpVect v1, const cpVect v2);
cpVect cpvforangle(const cpFloat a);
cpFloat cpvtoangle(const cpVect v);
cpVect cpvrotate(const cpVect v1, const cpVect v2);
cpVect cpvunrotate(const cpVect v1, const cpVect v2);
cpFloat cpvlengthsq(const cpVect v);
cpFloat cpvlength(const cpVect v);
cpVect cpvlerp(const cpVect v1, const cpVect v2, const cpFloat t);
cpVect cpvnormalize(const cpVect v);
cpVect cpvnormalize_safe(const cpVect v);
cpVect cpvclamp(const cpVect v, const cpFloat len);
cpVect cpvlerpconst(cpVect v1, cpVect v2, cpFloat d);
cpFloat cpvdist(const cpVect v1, const cpVect v2);
cpFloat cpvdistsq(const cpVect v1, const cpVect v2);
cpBool cpvnear(const cpVect v1, const cpVect v2, const cpFloat dist);
cpMat2x2
cpMat2x2New(cpFloat a, cpFloat b, cpFloat c, cpFloat d);
cpVect cpMat2x2Transform(cpMat2x2 m, cpVect v);
typedef struct cpBB{
 cpFloat l, b, r ,t;
} cpBB;
cpBB cpBBNew(const cpFloat l, const cpFloat b, const cpFloat r, const cpFloat t);
cpBB cpBBNewForCircle(const cpVect p, const cpFloat r);
cpBool cpBBIntersects(const cpBB a, const cpBB b);
cpBool cpBBContainsBB(const cpBB bb, const cpBB other);
cpBool cpBBContainsVect(const cpBB bb, const cpVect v);
cpBB cpBBMerge(const cpBB a, const cpBB b);
cpBB cpBBExpand(const cpBB bb, const cpVect v);
cpVect cpBBCenter(cpBB bb);
cpFloat cpBBArea(cpBB bb);
cpFloat cpBBMergedArea(cpBB a, cpBB b);
cpFloat cpBBSegmentQuery(cpBB bb, cpVect a, cpVect b);
cpBool cpBBIntersectsSegment(cpBB bb, cpVect a, cpVect b);
cpVect cpBBClampVect(const cpBB bb, const cpVect v);
cpVect cpBBWrapVect(const cpBB bb, const cpVect v);
typedef cpBB (*cpSpatialIndexBBFunc)(void *obj);
typedef void (*cpSpatialIndexIteratorFunc)(void *obj, void *data);
typedef cpCollisionID (*cpSpatialIndexQueryFunc)(void *obj1, void *obj2, cpCollisionID id, void *data);
typedef cpFloat (*cpSpatialIndexSegmentQueryFunc)(void *obj1, void *obj2, void *data);
typedef struct cpSpatialIndexClass cpSpatialIndexClass;

typedef struct cpSpatialIndex cpSpatialIndex;
struct cpSpatialIndex {
 cpSpatialIndexClass *klass;
 cpSpatialIndexBBFunc bbfunc;
 cpSpatialIndex *staticIndex, *dynamicIndex;
};

typedef struct cpSpaceHash cpSpaceHash;
cpSpaceHash* cpSpaceHashAlloc(void);
cpSpatialIndex* cpSpaceHashInit(cpSpaceHash *hash, cpFloat celldim, int numcells, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex *staticIndex);
cpSpatialIndex* cpSpaceHashNew(cpFloat celldim, int cells, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex *staticIndex);
void cpSpaceHashResize(cpSpaceHash *hash, cpFloat celldim, int numcells);
typedef struct cpBBTree cpBBTree;
cpBBTree* cpBBTreeAlloc(void);
cpSpatialIndex* cpBBTreeInit(cpBBTree *tree, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex *staticIndex);
cpSpatialIndex* cpBBTreeNew(cpSpatialIndexBBFunc bbfunc, cpSpatialIndex *staticIndex);
void cpBBTreeOptimize(cpSpatialIndex *index);
typedef cpVect (*cpBBTreeVelocityFunc)(void *obj);
void cpBBTreeSetVelocityFunc(cpSpatialIndex *index, cpBBTreeVelocityFunc func);
typedef struct cpSweep1D cpSweep1D;
cpSweep1D* cpSweep1DAlloc(void);
cpSpatialIndex* cpSweep1DInit(cpSweep1D *sweep, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex *staticIndex);
cpSpatialIndex* cpSweep1DNew(cpSpatialIndexBBFunc bbfunc, cpSpatialIndex *staticIndex);
typedef void (*cpSpatialIndexDestroyImpl)(cpSpatialIndex *index);
typedef int (*cpSpatialIndexCountImpl)(cpSpatialIndex *index);
typedef void (*cpSpatialIndexEachImpl)(cpSpatialIndex *index, cpSpatialIndexIteratorFunc func, void *data);
typedef cpBool (*cpSpatialIndexContainsImpl)(cpSpatialIndex *index, void *obj, cpHashValue hashid);
typedef void (*cpSpatialIndexInsertImpl)(cpSpatialIndex *index, void *obj, cpHashValue hashid);
typedef void (*cpSpatialIndexRemoveImpl)(cpSpatialIndex *index, void *obj, cpHashValue hashid);
typedef void (*cpSpatialIndexReindexImpl)(cpSpatialIndex *index);
typedef void (*cpSpatialIndexReindexObjectImpl)(cpSpatialIndex *index, void *obj, cpHashValue hashid);
typedef void (*cpSpatialIndexReindexQueryImpl)(cpSpatialIndex *index, cpSpatialIndexQueryFunc func, void *data);
typedef void (*cpSpatialIndexQueryImpl)(cpSpatialIndex *index, void *obj, cpBB bb, cpSpatialIndexQueryFunc func, void *data);
typedef void (*cpSpatialIndexSegmentQueryImpl)(cpSpatialIndex *index, void *obj, cpVect a, cpVect b, cpFloat t_exit, cpSpatialIndexSegmentQueryFunc func, void *data);
struct cpSpatialIndexClass {
 cpSpatialIndexDestroyImpl destroy;
 cpSpatialIndexCountImpl count;
 cpSpatialIndexEachImpl each;
 cpSpatialIndexContainsImpl contains;
 cpSpatialIndexInsertImpl insert;
 cpSpatialIndexRemoveImpl remove;
 cpSpatialIndexReindexImpl reindex;
 cpSpatialIndexReindexObjectImpl reindexObject;
 cpSpatialIndexReindexQueryImpl reindexQuery;
 cpSpatialIndexQueryImpl query;
 cpSpatialIndexSegmentQueryImpl segmentQuery;
};
void cpSpatialIndexFree(cpSpatialIndex *index);
void cpSpatialIndexCollideStatic(cpSpatialIndex *dynamicIndex, cpSpatialIndex *staticIndex, cpSpatialIndexQueryFunc func, void *data);
void cpSpatialIndexDestroy(cpSpatialIndex *index);
int cpSpatialIndexCount(cpSpatialIndex *index);
void cpSpatialIndexEach(cpSpatialIndex *index, cpSpatialIndexIteratorFunc func, void *data);
cpBool cpSpatialIndexContains(cpSpatialIndex *index, void *obj, cpHashValue hashid);
void cpSpatialIndexInsert(cpSpatialIndex *index, void *obj, cpHashValue hashid);
void cpSpatialIndexRemove(cpSpatialIndex *index, void *obj, cpHashValue hashid);
void cpSpatialIndexReindex(cpSpatialIndex *index);
void cpSpatialIndexReindexObject(cpSpatialIndex *index, void *obj, cpHashValue hashid);
void cpSpatialIndexQuery(cpSpatialIndex *index, void *obj, cpBB bb, cpSpatialIndexQueryFunc func, void *data);
void cpSpatialIndexSegmentQuery(cpSpatialIndex *index, void *obj, cpVect a, cpVect b, cpFloat t_exit, cpSpatialIndexSegmentQueryFunc func, void *data);
void cpSpatialIndexReindexQuery(cpSpatialIndex *index, cpSpatialIndexQueryFunc func, void *data);
typedef void (*cpBodyVelocityFunc)(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt);
typedef void (*cpBodyPositionFunc)(cpBody *body, cpFloat dt);
typedef struct cpComponentNode {
 cpBody *root;
 cpBody *next;
 cpFloat idleTime;
} cpComponentNode;

/*
struct cpBody {
 cpBodyVelocityFunc velocity_func;
 cpBodyPositionFunc position_func;
 cpFloat m;
 cpFloat m_inv;
 cpFloat i;
 cpFloat i_inv;
 cpVect p;
 cpVect v;
 cpVect f;
 cpFloat a;
 cpFloat w;
 cpFloat t;
 cpVect rot;
 cpDataPointer data;
 cpFloat v_limit;
 cpFloat w_limit;
 cpVect v_bias_private;
 cpFloat w_bias_private;
 cpSpace *space_private;
 cpShape *shapeList_private;
 cpArbiter *arbiterList_private;
 cpConstraint *constraintList_private;
 cpComponentNode node_private;
};
*/

typedef struct cpTransform {
    cpFloat a, b, c, d, tx, ty;
} cpTransform;

struct cpBody {
    // Integration functions
    cpBodyVelocityFunc velocity_func;
    cpBodyPositionFunc position_func;
    
    // mass and it's inverse
    cpFloat m;
    cpFloat m_inv;
    
    // moment of inertia and it's inverse
    cpFloat i;
    cpFloat i_inv;
    
    // center of gravity
    cpVect cog;
    
    // position, velocity, force
    cpVect p;
    cpVect v;
    cpVect f;
    
    // Angle, angular velocity, torque (radians)
    cpFloat a;
    cpFloat w;
    cpFloat t;
    
    cpTransform transform;
    
    cpDataPointer userData;
    
    // "pseudo-velocities" used for eliminating overlap.
    // Erin Catto has some papers that talk about what these are.
    cpVect v_bias;
    cpFloat w_bias;
    
    cpSpace *space;
    
    cpShape *shapeList;
    cpArbiter *arbiterList;
    cpConstraint *constraintList;
    
    struct {
        cpBody *root;
        cpBody *next;
        cpFloat idleTime;
    } sleeping;
};

cpBody* cpBodyAlloc(void);
cpBody* cpBodyInit(cpBody *body, cpFloat m, cpFloat i);
cpBody* cpBodyNew(cpFloat m, cpFloat i);
cpBody* cpBodyInitStatic(cpBody *body);
cpBody* cpBodyNewStatic(void);
void cpBodyDestroy(cpBody *body);
void cpBodyFree(cpBody *body);
 void cpBodySanityCheck(cpBody *body);
void cpBodyActivate(cpBody *body);
void cpBodyActivateStatic(cpBody *body, cpShape *filter);
void cpBodySleep(cpBody *body);
void cpBodySleepWithGroup(cpBody *body, cpBody *group);
cpBool cpBodyIsSleeping(const cpBody *body);
cpBool cpBodyIsStatic(const cpBody *body);
cpBool cpBodyIsRogue(const cpBody *body);
cpSpace* cpBodyGetSpace(const cpBody *body);
cpFloat cpBodyGetMass(const cpBody *body);
void cpBodySetMass(cpBody *body, cpFloat m);
cpFloat cpBodyGetMoment(const cpBody *body);
void cpBodySetMoment(cpBody *body, cpFloat i);
cpVect cpBodyGetPos(const cpBody *body);
void cpBodySetPos(cpBody *body, cpVect pos);
cpVect cpBodyGetVel(const cpBody *body);
void cpBodySetVel(cpBody *body, const cpVect value);
cpVect cpBodyGetForce(const cpBody *body);
void cpBodySetForce(cpBody *body, const cpVect value);
cpFloat cpBodyGetAngle(const cpBody *body);
void cpBodySetAngle(cpBody *body, cpFloat a);
cpFloat cpBodyGetAngVel(const cpBody *body);
void cpBodySetAngVel(cpBody *body, const cpFloat value);
cpFloat cpBodyGetTorque(const cpBody *body);
void cpBodySetTorque(cpBody *body, const cpFloat value);
cpVect cpBodyGetRot(const cpBody *body);
cpFloat cpBodyGetVelLimit(const cpBody *body);
void cpBodySetVelLimit(cpBody *body, const cpFloat value);
cpFloat cpBodyGetAngVelLimit(const cpBody *body);
void cpBodySetAngVelLimit(cpBody *body, const cpFloat value);
cpDataPointer cpBodyGetUserData(const cpBody *body);
void cpBodySetUserData(cpBody *body, const cpDataPointer value);
void cpBodyUpdateVelocity(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt);
void cpBodyUpdatePosition(cpBody *body, cpFloat dt);
cpVect cpBodyLocal2World(const cpBody *body, const cpVect v);
cpVect cpBodyWorld2Local(const cpBody *body, const cpVect v);
void cpBodyResetForces(cpBody *body);
void cpBodyApplyForce(cpBody *body, const cpVect f, const cpVect r);
void cpBodyApplyImpulse(cpBody *body, const cpVect j, const cpVect r);
cpVect cpBodyGetVelAtWorldPoint(cpBody *body, cpVect point);
cpVect cpBodyGetVelAtLocalPoint(cpBody *body, cpVect point);
cpFloat cpBodyKineticEnergy(const cpBody *body);
typedef void (*cpBodyShapeIteratorFunc)(cpBody *body, cpShape *shape, void *data);
void cpBodyEachShape(cpBody *body, cpBodyShapeIteratorFunc func, void *data);
typedef void (*cpBodyConstraintIteratorFunc)(cpBody *body, cpConstraint *constraint, void *data);
void cpBodyEachConstraint(cpBody *body, cpBodyConstraintIteratorFunc func, void *data);
typedef void (*cpBodyArbiterIteratorFunc)(cpBody *body, cpArbiter *arbiter, void *data);
void cpBodyEachArbiter(cpBody *body, cpBodyArbiterIteratorFunc func, void *data);
typedef struct cpShapeClass cpShapeClass;
typedef struct cpNearestPointQueryInfo {
 cpShape *shape;
 cpVect p;
 cpFloat d;
 cpVect g;
} cpNearestPointQueryInfo;
typedef struct cpSegmentQueryInfo {
 cpShape *shape;
 cpFloat t;
 cpVect n;
} cpSegmentQueryInfo;
typedef enum cpShapeType{
 CP_CIRCLE_SHAPE,
 CP_SEGMENT_SHAPE,
 CP_POLY_SHAPE,
 CP_NUM_SHAPES
} cpShapeType;
typedef cpBB (*cpShapeCacheDataImpl)(cpShape *shape, cpVect p, cpVect rot);
typedef void (*cpShapeDestroyImpl)(cpShape *shape);
typedef void (*cpShapeNearestPointQueryImpl)(cpShape *shape, cpVect p, cpNearestPointQueryInfo *info);
typedef void (*cpShapeSegmentQueryImpl)(cpShape *shape, cpVect a, cpVect b, cpSegmentQueryInfo *info);
struct cpShapeClass {
 cpShapeType type;
 cpShapeCacheDataImpl cacheData;
 cpShapeDestroyImpl destroy;
 cpShapeNearestPointQueryImpl nearestPointQuery;
 cpShapeSegmentQueryImpl segmentQuery;
};
struct cpShape {
 const cpShapeClass *klass_private;
 cpBody *body;
 cpBB bb;
 cpBool sensor;
 cpFloat e;
 cpFloat u;
 cpVect surface_v;
 cpDataPointer data;
 cpCollisionType collision_type;
 cpGroup group;
 cpLayers layers;
 cpSpace *space_private;
 cpShape *next_private;
 cpShape *prev_private;
 cpHashValue hashid_private;
};
void cpShapeDestroy(cpShape *shape);
void cpShapeFree(cpShape *shape);
cpBB cpShapeCacheBB(cpShape *shape);
cpBB cpShapeUpdate(cpShape *shape, cpVect pos, cpVect rot);
cpBool cpShapePointQuery(cpShape *shape, cpVect p);
cpFloat cpShapeNearestPointQuery(cpShape *shape, cpVect p, cpNearestPointQueryInfo *out);
cpBool cpShapeSegmentQuery(cpShape *shape, cpVect a, cpVect b, cpSegmentQueryInfo *info);
cpVect cpSegmentQueryHitPoint(const cpVect start, const cpVect end, const cpSegmentQueryInfo info);
cpFloat cpSegmentQueryHitDist(const cpVect start, const cpVect end, const cpSegmentQueryInfo info);
cpSpace* cpShapeGetSpace(const cpShape *shape);
cpBody* cpShapeGetBody(const cpShape *shape);
void cpShapeSetBody(cpShape *shape, cpBody *body);
cpBB cpShapeGetBB(const cpShape *shape);
cpBool cpShapeGetSensor(const cpShape *shape); void cpShapeSetSensor(cpShape *shape, cpBool value);
cpFloat cpShapeGetElasticity(const cpShape *shape); void cpShapeSetElasticity(cpShape *shape, cpFloat value);
cpFloat cpShapeGetFriction(const cpShape *shape); void cpShapeSetFriction(cpShape *shape, cpFloat value);
cpVect cpShapeGetSurfaceVelocity(const cpShape *shape); void cpShapeSetSurfaceVelocity(cpShape *shape, cpVect value);
cpDataPointer cpShapeGetUserData(const cpShape *shape); void cpShapeSetUserData(cpShape *shape, cpDataPointer value);
cpCollisionType cpShapeGetCollisionType(const cpShape *shape); void cpShapeSetCollisionType(cpShape *shape, cpCollisionType value);
cpGroup cpShapeGetGroup(const cpShape *shape); void cpShapeSetGroup(cpShape *shape, cpGroup value);
cpLayers cpShapeGetLayers(const cpShape *shape); void cpShapeSetLayers(cpShape *shape, cpLayers value);
void cpResetShapeIdCounter(void);
typedef struct cpCircleShape {
 cpShape shape;
 cpVect c, tc;
 cpFloat r;
} cpCircleShape;
cpCircleShape* cpCircleShapeAlloc(void);
cpCircleShape* cpCircleShapeInit(cpCircleShape *circle, cpBody *body, cpFloat radius, cpVect offset);
cpShape* cpCircleShapeNew(cpBody *body, cpFloat radius, cpVect offset);
cpVect cpCircleShapeGetOffset(const cpShape *shape);
cpFloat cpCircleShapeGetRadius(const cpShape *shape);
typedef struct cpSegmentShape {
 cpShape shape;
 cpVect a, b, n;
 cpVect ta, tb, tn;
 cpFloat r;
 cpVect a_tangent, b_tangent;
} cpSegmentShape;
cpSegmentShape* cpSegmentShapeAlloc(void);
cpSegmentShape* cpSegmentShapeInit(cpSegmentShape *seg, cpBody *body, cpVect a, cpVect b, cpFloat radius);
cpShape* cpSegmentShapeNew(cpBody *body, cpVect a, cpVect b, cpFloat radius);
void cpSegmentShapeSetNeighbors(cpShape *shape, cpVect prev, cpVect next);
cpVect cpSegmentShapeGetA(const cpShape *shape);
cpVect cpSegmentShapeGetB(const cpShape *shape);
cpVect cpSegmentShapeGetNormal(const cpShape *shape);
cpFloat cpSegmentShapeGetRadius(const cpShape *shape);
typedef struct cpSplittingPlane {
 cpVect n;
 cpFloat d;
} cpSplittingPlane;
typedef struct cpPolyShape {
 cpShape shape;
 int numVerts;
 cpVect *verts, *tVerts;
 cpSplittingPlane *planes, *tPlanes;
 cpFloat r;
} cpPolyShape;
cpPolyShape* cpPolyShapeAlloc(void);
cpPolyShape* cpPolyShapeInit(cpPolyShape *poly, cpBody *body, int numVerts, const cpVect *verts, cpVect offset);
cpPolyShape* cpPolyShapeInit2(cpPolyShape *poly, cpBody *body, int numVerts, const cpVect *verts, cpVect offset, cpFloat radius);
cpShape* cpPolyShapeNew(cpBody *body, int numVerts, const cpVect *verts, cpVect offset);
cpShape* cpPolyShapeNew2(cpBody *body, int numVerts, const cpVect *verts, cpVect offset, cpFloat radius);
cpPolyShape* cpBoxShapeInit(cpPolyShape *poly, cpBody *body, cpFloat width, cpFloat height);
cpPolyShape* cpBoxShapeInit2(cpPolyShape *poly, cpBody *body, cpBB box);
cpPolyShape* cpBoxShapeInit3(cpPolyShape *poly, cpBody *body, cpBB box, cpFloat radius);
cpShape* cpBoxShapeNew(cpBody *body, cpFloat width, cpFloat height, cpFloat radius);
cpShape* cpBoxShapeNew2(cpBody *body, cpBB box);
cpShape* cpBoxShapeNew3(cpBody *body, cpBB box, cpFloat radius);
cpBool cpPolyValidate(const cpVect *verts, const int numVerts);
int cpPolyShapeGetNumVerts(const cpShape *shape);
cpVect cpPolyShapeGetVert(const cpShape *shape, int idx);
cpFloat cpPolyShapeGetRadius(const cpShape *shape);
typedef cpBool (*cpCollisionBeginFunc)(cpArbiter *arb, cpSpace *space, void *data);
typedef cpBool (*cpCollisionPreSolveFunc)(cpArbiter *arb, cpSpace *space, void *data);
typedef void (*cpCollisionPostSolveFunc)(cpArbiter *arb, cpSpace *space, void *data);
typedef void (*cpCollisionSeparateFunc)(cpArbiter *arb, cpSpace *space, void *data);
struct cpCollisionHandler {
 cpCollisionType a;
 cpCollisionType b;
 cpCollisionBeginFunc begin;
 cpCollisionPreSolveFunc preSolve;
 cpCollisionPostSolveFunc postSolve;
 cpCollisionSeparateFunc separate;
 void *data;
};
typedef struct cpContact cpContact;
typedef enum cpArbiterState {
 cpArbiterStateFirstColl,
 cpArbiterStateNormal,
 cpArbiterStateIgnore,
 cpArbiterStateCached,
} cpArbiterState;
struct cpArbiterThread {
 struct cpArbiter *next, *prev;
};
struct cpArbiter {
 cpFloat e;
 cpFloat u;
 cpVect surface_vr;
 cpDataPointer data;
 cpShape *a_private;
 cpShape *b_private;
 cpBody *body_a_private;
 cpBody *body_b_private;
 struct cpArbiterThread thread_a_private;
 struct cpArbiterThread thread_b_private;
 int numContacts_private;
 cpContact *contacts_private;
 cpTimestamp stamp_private;
 cpCollisionHandler *handler_private;
 cpBool swappedColl_private;
 cpArbiterState state_private;
};
cpFloat cpArbiterGetElasticity(const cpArbiter *arb);
void cpArbiterSetElasticity(cpArbiter *arb, cpFloat value);
cpFloat cpArbiterGetFriction(const cpArbiter *arb);
void cpArbiterSetFriction(cpArbiter *arb, cpFloat value);
cpVect cpArbiterGetSurfaceVelocity(cpArbiter *arb);
void cpArbiterSetSurfaceVelocity(cpArbiter *arb, cpVect vr);
cpDataPointer cpArbiterGetUserData(const cpArbiter *arb);
void cpArbiterSetUserData(cpArbiter *arb, cpDataPointer value);
cpVect cpArbiterTotalImpulse(const cpArbiter *arb);
cpVect cpArbiterTotalImpulseWithFriction(const cpArbiter *arb);
cpFloat cpArbiterTotalKE(const cpArbiter *arb);
void cpArbiterIgnore(cpArbiter *arb);
void cpArbiterGetShapes(const cpArbiter *arb, cpShape **a, cpShape **b);
void cpArbiterGetBodies(const cpArbiter *arb, cpBody **a, cpBody **b);
typedef struct cpContactPointSet {
 int count;
 struct {
  cpVect point;
  cpVect normal;
  cpFloat dist;
 } points[2];
} cpContactPointSet;
cpContactPointSet cpArbiterGetContactPointSet(const cpArbiter *arb);
void cpArbiterSetContactPointSet(cpArbiter *arb, cpContactPointSet *set);
cpBool cpArbiterIsFirstContact(const cpArbiter *arb);
int cpArbiterGetCount(const cpArbiter *arb);
cpVect cpArbiterGetNormal(const cpArbiter *arb, int i);
cpVect cpArbiterGetPoint(const cpArbiter *arb, int i);
cpFloat cpArbiterGetDepth(const cpArbiter *arb, int i);
typedef struct cpConstraintClass cpConstraintClass;
typedef void (*cpConstraintPreStepImpl)(cpConstraint *constraint, cpFloat dt);
typedef void (*cpConstraintApplyCachedImpulseImpl)(cpConstraint *constraint, cpFloat dt_coef);
typedef void (*cpConstraintApplyImpulseImpl)(cpConstraint *constraint, cpFloat dt);
typedef cpFloat (*cpConstraintGetImpulseImpl)(cpConstraint *constraint);
struct cpConstraintClass {
 cpConstraintPreStepImpl preStep;
 cpConstraintApplyCachedImpulseImpl applyCachedImpulse;
 cpConstraintApplyImpulseImpl applyImpulse;
 cpConstraintGetImpulseImpl getImpulse;
};
typedef void (*cpConstraintPreSolveFunc)(cpConstraint *constraint, cpSpace *space);
typedef void (*cpConstraintPostSolveFunc)(cpConstraint *constraint, cpSpace *space);
struct cpConstraint {
 const cpConstraintClass *klass_private;
 cpBody *a;
 cpBody *b;
 cpSpace *space_private;
 cpConstraint *next_a_private;
 cpConstraint *next_b_private;
 cpFloat maxForce;
 cpFloat errorBias;
 cpFloat maxBias;
 cpConstraintPreSolveFunc preSolve;
 cpConstraintPostSolveFunc postSolve;
 cpDataPointer data;
};
void cpConstraintDestroy(cpConstraint *constraint);
void cpConstraintFree(cpConstraint *constraint);
void cpConstraintActivateBodies(cpConstraint *constraint);
cpSpace* cpConstraintGetSpace(const cpConstraint *constraint);
cpBody* cpConstraintGetA(const cpConstraint *constraint);
cpBody* cpConstraintGetB(const cpConstraint *constraint);
cpFloat cpConstraintGetMaxForce(const cpConstraint *constraint);
void cpConstraintSetMaxForce(cpConstraint *constraint, cpFloat value);
cpFloat cpConstraintGetErrorBias(const cpConstraint *constraint);
void cpConstraintSetErrorBias(cpConstraint *constraint, cpFloat value);
cpFloat cpConstraintGetMaxBias(const cpConstraint *constraint);
void cpConstraintSetMaxBias(cpConstraint *constraint, cpFloat value);
cpConstraintPreSolveFunc cpConstraintGetPreSolveFunc(const cpConstraint *constraint);
void cpConstraintSetPreSolveFunc(cpConstraint *constraint, cpConstraintPreSolveFunc value);
cpConstraintPostSolveFunc cpConstraintGetPostSolveFunc(const cpConstraint *constraint);
void cpConstraintSetPostSolveFunc(cpConstraint *constraint, cpConstraintPostSolveFunc value);
cpDataPointer cpConstraintGetUserData(const cpConstraint *constraint);
void cpConstraintSetUserData(cpConstraint *constraint, cpDataPointer value);
cpFloat cpConstraintGetImpulse(cpConstraint *constraint);
const cpConstraintClass *cpPinJointGetClass(void);
typedef struct cpPinJoint {
 cpConstraint constraint;
 cpVect anchr1, anchr2;
 cpFloat dist;
 cpVect r1, r2;
 cpVect n;
 cpFloat nMass;
 cpFloat jnAcc;
 cpFloat bias;
} cpPinJoint;
cpPinJoint* cpPinJointAlloc(void);
cpPinJoint* cpPinJointInit(cpPinJoint *joint, cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2);
cpConstraint* cpPinJointNew(cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2);
cpVect cpPinJointGetAnchr1(const cpConstraint *constraint);
void cpPinJointSetAnchr1(cpConstraint *constraint, cpVect value);
cpVect cpPinJointGetAnchr2(const cpConstraint *constraint);
void cpPinJointSetAnchr2(cpConstraint *constraint, cpVect value);
cpFloat cpPinJointGetDist(const cpConstraint *constraint);
void cpPinJointSetDist(cpConstraint *constraint, cpFloat value);
const cpConstraintClass *cpSlideJointGetClass(void);
typedef struct cpSlideJoint {
 cpConstraint constraint;
 cpVect anchr1, anchr2;
 cpFloat min, max;
 cpVect r1, r2;
 cpVect n;
 cpFloat nMass;
 cpFloat jnAcc;
 cpFloat bias;
} cpSlideJoint;
cpSlideJoint* cpSlideJointAlloc(void);
cpSlideJoint* cpSlideJointInit(cpSlideJoint *joint, cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2, cpFloat min, cpFloat max);
cpConstraint* cpSlideJointNew(cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2, cpFloat min, cpFloat max);
cpVect cpSlideJointGetAnchr1(const cpConstraint *constraint); void cpSlideJointSetAnchr1(cpConstraint *constraint, cpVect value);
cpVect cpSlideJointGetAnchr2(const cpConstraint *constraint); void cpSlideJointSetAnchr2(cpConstraint *constraint, cpVect value);
cpFloat cpSlideJointGetMin(const cpConstraint *constraint); void cpSlideJointSetMin(cpConstraint *constraint, cpFloat value);
cpFloat cpSlideJointGetMax(const cpConstraint *constraint); void cpSlideJointSetMax(cpConstraint *constraint, cpFloat value);
const cpConstraintClass *cpPivotJointGetClass(void);
typedef struct cpPivotJoint {
 cpConstraint constraint;
 cpVect anchr1, anchr2;
 cpVect r1, r2;
 cpMat2x2 k;
 cpVect jAcc;
 cpVect bias;
} cpPivotJoint;
cpPivotJoint* cpPivotJointAlloc(void);
cpPivotJoint* cpPivotJointInit(cpPivotJoint *joint, cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2);
cpConstraint* cpPivotJointNew(cpBody *a, cpBody *b, cpVect pivot);
cpConstraint* cpPivotJointNew2(cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2);
cpVect cpPivotJointGetAnchr1(const cpConstraint *constraint); void cpPivotJointSetAnchr1(cpConstraint *constraint, cpVect value);
cpVect cpPivotJointGetAnchr2(const cpConstraint *constraint); void cpPivotJointSetAnchr2(cpConstraint *constraint, cpVect value);
const cpConstraintClass *cpGrooveJointGetClass(void);
typedef struct cpGrooveJoint {
 cpConstraint constraint;
 cpVect grv_n, grv_a, grv_b;
 cpVect anchr2;
 cpVect grv_tn;
 cpFloat clamp;
 cpVect r1, r2;
 cpMat2x2 k;
 cpVect jAcc;
 cpVect bias;
} cpGrooveJoint;
cpGrooveJoint* cpGrooveJointAlloc(void);
cpGrooveJoint* cpGrooveJointInit(cpGrooveJoint *joint, cpBody *a, cpBody *b, cpVect groove_a, cpVect groove_b, cpVect anchr2);
cpConstraint* cpGrooveJointNew(cpBody *a, cpBody *b, cpVect groove_a, cpVect groove_b, cpVect anchr2);
cpVect cpGrooveJointGetGrooveA(const cpConstraint *constraint);
void cpGrooveJointSetGrooveA(cpConstraint *constraint, cpVect value);
cpVect cpGrooveJointGetGrooveB(const cpConstraint *constraint);
void cpGrooveJointSetGrooveB(cpConstraint *constraint, cpVect value);
cpVect cpGrooveJointGetAnchr2(const cpConstraint *constraint); void cpGrooveJointSetAnchr2(cpConstraint *constraint, cpVect value);
typedef struct cpDampedSpring cpDampedSpring;
typedef cpFloat (*cpDampedSpringForceFunc)(cpConstraint *spring, cpFloat dist);
const cpConstraintClass *cpDampedSpringGetClass(void);
struct cpDampedSpring {
 cpConstraint constraint;
 cpVect anchr1, anchr2;
 cpFloat restLength;
 cpFloat stiffness;
 cpFloat damping;
 cpDampedSpringForceFunc springForceFunc;
 cpFloat target_vrn;
 cpFloat v_coef;
 cpVect r1, r2;
 cpFloat nMass;
 cpVect n;
 cpFloat jAcc;
};
cpDampedSpring* cpDampedSpringAlloc(void);
cpDampedSpring* cpDampedSpringInit(cpDampedSpring *joint, cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2, cpFloat restLength, cpFloat stiffness, cpFloat damping);
cpConstraint* cpDampedSpringNew(cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2, cpFloat restLength, cpFloat stiffness, cpFloat damping);
cpVect cpDampedSpringGetAnchr1(const cpConstraint *constraint); void cpDampedSpringSetAnchr1(cpConstraint *constraint, cpVect value);
cpVect cpDampedSpringGetAnchr2(const cpConstraint *constraint); void cpDampedSpringSetAnchr2(cpConstraint *constraint, cpVect value);
cpFloat cpDampedSpringGetRestLength(const cpConstraint *constraint); void cpDampedSpringSetRestLength(cpConstraint *constraint, cpFloat value);
cpFloat cpDampedSpringGetStiffness(const cpConstraint *constraint); void cpDampedSpringSetStiffness(cpConstraint *constraint, cpFloat value);
cpFloat cpDampedSpringGetDamping(const cpConstraint *constraint); void cpDampedSpringSetDamping(cpConstraint *constraint, cpFloat value);
cpDampedSpringForceFunc cpDampedSpringGetSpringForceFunc(const cpConstraint *constraint); void cpDampedSpringSetSpringForceFunc(cpConstraint *constraint, cpDampedSpringForceFunc value);
typedef cpFloat (*cpDampedRotarySpringTorqueFunc)(struct cpConstraint *spring, cpFloat relativeAngle);
const cpConstraintClass *cpDampedRotarySpringGetClass(void);
typedef struct cpDampedRotarySpring {
 cpConstraint constraint;
 cpFloat restAngle;
 cpFloat stiffness;
 cpFloat damping;
 cpDampedRotarySpringTorqueFunc springTorqueFunc;
 cpFloat target_wrn;
 cpFloat w_coef;
 cpFloat iSum;
 cpFloat jAcc;
} cpDampedRotarySpring;
cpDampedRotarySpring* cpDampedRotarySpringAlloc(void);
cpDampedRotarySpring* cpDampedRotarySpringInit(cpDampedRotarySpring *joint, cpBody *a, cpBody *b, cpFloat restAngle, cpFloat stiffness, cpFloat damping);
cpConstraint* cpDampedRotarySpringNew(cpBody *a, cpBody *b, cpFloat restAngle, cpFloat stiffness, cpFloat damping);
cpFloat cpDampedRotarySpringGetRestAngle(const cpConstraint *constraint); void cpDampedRotarySpringSetRestAngle(cpConstraint *constraint, cpFloat value);
cpFloat cpDampedRotarySpringGetStiffness(const cpConstraint *constraint); void cpDampedRotarySpringSetStiffness(cpConstraint *constraint, cpFloat value);
cpFloat cpDampedRotarySpringGetDamping(const cpConstraint *constraint); void cpDampedRotarySpringSetDamping(cpConstraint *constraint, cpFloat value);
cpDampedRotarySpringTorqueFunc cpDampedRotarySpringGetSpringTorqueFunc(const cpConstraint *constraint); void cpDampedRotarySpringSetSpringTorqueFunc(cpConstraint *constraint, cpDampedRotarySpringTorqueFunc value);
const cpConstraintClass *cpRotaryLimitJointGetClass(void);
typedef struct cpRotaryLimitJoint {
 cpConstraint constraint;
 cpFloat min, max;
 cpFloat iSum;
 cpFloat bias;
 cpFloat jAcc;
} cpRotaryLimitJoint;
cpRotaryLimitJoint* cpRotaryLimitJointAlloc(void);
cpRotaryLimitJoint* cpRotaryLimitJointInit(cpRotaryLimitJoint *joint, cpBody *a, cpBody *b, cpFloat min, cpFloat max);
cpConstraint* cpRotaryLimitJointNew(cpBody *a, cpBody *b, cpFloat min, cpFloat max);
cpFloat cpRotaryLimitJointGetMin(const cpConstraint *constraint); void cpRotaryLimitJointSetMin(cpConstraint *constraint, cpFloat value);
cpFloat cpRotaryLimitJointGetMax(const cpConstraint *constraint); void cpRotaryLimitJointSetMax(cpConstraint *constraint, cpFloat value);
const cpConstraintClass *cpRatchetJointGetClass(void);
typedef struct cpRatchetJoint {
 cpConstraint constraint;
 cpFloat angle, phase, ratchet;
 cpFloat iSum;
 cpFloat bias;
 cpFloat jAcc;
} cpRatchetJoint;
cpRatchetJoint* cpRatchetJointAlloc(void);
cpRatchetJoint* cpRatchetJointInit(cpRatchetJoint *joint, cpBody *a, cpBody *b, cpFloat phase, cpFloat ratchet);
cpConstraint* cpRatchetJointNew(cpBody *a, cpBody *b, cpFloat phase, cpFloat ratchet);
cpFloat cpRatchetJointGetAngle(const cpConstraint *constraint); void cpRatchetJointSetAngle(cpConstraint *constraint, cpFloat value);
cpFloat cpRatchetJointGetPhase(const cpConstraint *constraint); void cpRatchetJointSetPhase(cpConstraint *constraint, cpFloat value);
cpFloat cpRatchetJointGetRatchet(const cpConstraint *constraint); void cpRatchetJointSetRatchet(cpConstraint *constraint, cpFloat value);
const cpConstraintClass *cpGearJointGetClass(void);
typedef struct cpGearJoint {
 cpConstraint constraint;
 cpFloat phase, ratio;
 cpFloat ratio_inv;
 cpFloat iSum;
 cpFloat bias;
 cpFloat jAcc;
} cpGearJoint;
cpGearJoint* cpGearJointAlloc(void);
cpGearJoint* cpGearJointInit(cpGearJoint *joint, cpBody *a, cpBody *b, cpFloat phase, cpFloat ratio);
cpConstraint* cpGearJointNew(cpBody *a, cpBody *b, cpFloat phase, cpFloat ratio);
cpFloat cpGearJointGetPhase(const cpConstraint *constraint); void cpGearJointSetPhase(cpConstraint *constraint, cpFloat value);
cpFloat cpGearJointGetRatio(const cpConstraint *constraint);
void cpGearJointSetRatio(cpConstraint *constraint, cpFloat value);
const cpConstraintClass *cpSimpleMotorGetClass(void);
typedef struct cpSimpleMotor {
 cpConstraint constraint;
 cpFloat rate;
 cpFloat iSum;
 cpFloat jAcc;
} cpSimpleMotor;
cpSimpleMotor* cpSimpleMotorAlloc(void);
cpSimpleMotor* cpSimpleMotorInit(cpSimpleMotor *joint, cpBody *a, cpBody *b, cpFloat rate);
cpConstraint* cpSimpleMotorNew(cpBody *a, cpBody *b, cpFloat rate);
cpFloat cpSimpleMotorGetRate(const cpConstraint *constraint); void cpSimpleMotorSetRate(cpConstraint *constraint, cpFloat value);
typedef struct cpContactBufferHeader cpContactBufferHeader;
typedef void (*cpSpaceArbiterApplyImpulseFunc)(cpArbiter *arb);

/*
struct cpSpace {
 int iterations;
 cpVect gravity;
 cpFloat damping;
 cpFloat idleSpeedThreshold;
 cpFloat sleepTimeThreshold;
 cpFloat collisionSlop;
 cpFloat collisionBias;
 cpTimestamp collisionPersistence;
 cpBool enableContactGraph;
 cpDataPointer data;
 cpBody *staticBody;
 cpTimestamp stamp_private;
 cpFloat curr_dt_private;
 cpArray *bodies_private;
 cpArray *rousedBodies_private;
 cpArray *sleepingComponents_private;
 cpSpatialIndex *staticShapes_private;
 cpSpatialIndex *activeShapes_private;
 cpArray *arbiters_private;
 cpContactBufferHeader *contactBuffersHead_private;
 cpHashSet *cachedArbiters_private;
 cpArray *pooledArbiters_private;
 cpArray *constraints_private;
 cpArray *allocatedBuffers_private;
 int locked_private;
 cpHashSet *collisionHandlers_private;
 cpCollisionHandler defaultHandler_private;
 cpBool skipPostStep_private;
 cpArray *postStepCallbacks_private;
 cpBody _staticBody_private;
};
*/

struct cpSpace {
    int iterations;
    
    cpVect gravity;
    cpFloat damping;
   
    cpFloat idleSpeedThreshold;
    cpFloat sleepTimeThreshold;
    
    cpFloat collisionSlop;
    cpFloat collisionBias;
    cpTimestamp collisionPersistence;
    
    cpDataPointer userData;
    
    cpTimestamp stamp;
    cpFloat curr_dt;

    cpArray *dynamicBodies;
    cpArray *staticBodies;
    cpArray *rousedBodies;
    cpArray *sleepingComponents;
    
    cpHashValue shapeIDCounter;
    cpSpatialIndex *staticShapes;
    cpSpatialIndex *dynamicShapes;
    
    cpArray *constraints;
    
    cpArray *arbiters;
    cpContactBufferHeader *contactBuffersHead;
    cpHashSet *cachedArbiters;
    cpArray *pooledArbiters;
    
    cpArray *allocatedBuffers;
    unsigned int locked;
    
    cpBool usesWildcards;
    cpHashSet *collisionHandlers;
    cpCollisionHandler defaultHandler;
    
    cpBool skipPostStep;
    cpArray *postStepCallbacks;
    
    cpBody *staticBody;
    cpBody _staticBody;
};

cpSpace* cpSpaceAlloc(void);
cpSpace* cpSpaceInit(cpSpace *space);
cpSpace* cpSpaceNew(void);
void cpSpaceDestroy(cpSpace *space);
void cpSpaceFree(cpSpace *space);
int cpSpaceGetIterations(const cpSpace *space); void cpSpaceSetIterations(cpSpace *space, int value);
cpVect cpSpaceGetGravity(const cpSpace *space); void cpSpaceSetGravity(cpSpace *space, cpVect value);
cpFloat cpSpaceGetDamping(const cpSpace *space); void cpSpaceSetDamping(cpSpace *space, cpFloat value);
cpFloat cpSpaceGetIdleSpeedThreshold(const cpSpace *space); void cpSpaceSetIdleSpeedThreshold(cpSpace *space, cpFloat value);
cpFloat cpSpaceGetSleepTimeThreshold(const cpSpace *space); void cpSpaceSetSleepTimeThreshold(cpSpace *space, cpFloat value);
cpFloat cpSpaceGetCollisionSlop(const cpSpace *space); void cpSpaceSetCollisionSlop(cpSpace *space, cpFloat value);
cpFloat cpSpaceGetCollisionBias(const cpSpace *space); void cpSpaceSetCollisionBias(cpSpace *space, cpFloat value);
cpTimestamp cpSpaceGetCollisionPersistence(const cpSpace *space); void cpSpaceSetCollisionPersistence(cpSpace *space, cpTimestamp value);
cpBool cpSpaceGetEnableContactGraph(const cpSpace *space); void cpSpaceSetEnableContactGraph(cpSpace *space, cpBool value);
cpDataPointer cpSpaceGetUserData(const cpSpace *space); void cpSpaceSetUserData(cpSpace *space, cpDataPointer value);
cpBody* cpSpaceGetStaticBody(const cpSpace *space);
cpFloat cpSpaceGetCurrentTimeStep(const cpSpace *space);
cpBool cpSpaceIsLocked(cpSpace *space);
void cpSpaceSetDefaultCollisionHandler(
 cpSpace *space,
 cpCollisionBeginFunc begin,
 cpCollisionPreSolveFunc preSolve,
 cpCollisionPostSolveFunc postSolve,
 cpCollisionSeparateFunc separate,
 void *data
);
void cpSpaceAddCollisionHandler(
 cpSpace *space,
 cpCollisionType a, cpCollisionType b,
 cpCollisionBeginFunc begin,
 cpCollisionPreSolveFunc preSolve,
 cpCollisionPostSolveFunc postSolve,
 cpCollisionSeparateFunc separate,
 void *data
);
void cpSpaceRemoveCollisionHandler(cpSpace *space, cpCollisionType a, cpCollisionType b);
cpShape* cpSpaceAddShape(cpSpace *space, cpShape *shape);
cpShape* cpSpaceAddStaticShape(cpSpace *space, cpShape *shape);
cpBody* cpSpaceAddBody(cpSpace *space, cpBody *body);
cpConstraint* cpSpaceAddConstraint(cpSpace *space, cpConstraint *constraint);
void cpSpaceRemoveShape(cpSpace *space, cpShape *shape);
void cpSpaceRemoveStaticShape(cpSpace *space, cpShape *shape);
void cpSpaceRemoveBody(cpSpace *space, cpBody *body);
void cpSpaceRemoveConstraint(cpSpace *space, cpConstraint *constraint);
cpBool cpSpaceContainsShape(cpSpace *space, cpShape *shape);
cpBool cpSpaceContainsBody(cpSpace *space, cpBody *body);
cpBool cpSpaceContainsConstraint(cpSpace *space, cpConstraint *constraint);
void cpSpaceConvertBodyToStatic(cpSpace *space, cpBody *body);
void cpSpaceConvertBodyToDynamic(cpSpace *space, cpBody *body, cpFloat mass, cpFloat moment);
typedef void (*cpPostStepFunc)(cpSpace *space, void *key, void *data);
cpBool cpSpaceAddPostStepCallback(cpSpace *space, cpPostStepFunc func, void *key, void *data);
typedef void (*cpSpacePointQueryFunc)(cpShape *shape, void *data);
void cpSpacePointQuery(cpSpace *space, cpVect point, cpLayers layers, cpGroup group, cpSpacePointQueryFunc func, void *data);
cpShape *cpSpacePointQueryFirst(cpSpace *space, cpVect point, cpLayers layers, cpGroup group);
typedef void (*cpSpaceNearestPointQueryFunc)(cpShape *shape, cpFloat distance, cpVect point, void *data);
void cpSpaceNearestPointQuery(cpSpace *space, cpVect point, cpFloat maxDistance, cpLayers layers, cpGroup group, cpSpaceNearestPointQueryFunc func, void *data);
cpShape *cpSpaceNearestPointQueryNearest(cpSpace *space, cpVect point, cpFloat maxDistance, cpLayers layers, cpGroup group, cpNearestPointQueryInfo *out);
typedef void (*cpSpaceSegmentQueryFunc)(cpShape *shape, cpFloat t, cpVect n, void *data);
void cpSpaceSegmentQuery(cpSpace *space, cpVect start, cpVect end, cpLayers layers, cpGroup group, cpSpaceSegmentQueryFunc func, void *data);
cpShape *cpSpaceSegmentQueryFirst(cpSpace *space, cpVect start, cpVect end, cpLayers layers, cpGroup group, cpSegmentQueryInfo *out);
typedef void (*cpSpaceBBQueryFunc)(cpShape *shape, void *data);
void cpSpaceBBQuery(cpSpace *space, cpBB bb, cpLayers layers, cpGroup group, cpSpaceBBQueryFunc func, void *data);
typedef void (*cpSpaceShapeQueryFunc)(cpShape *shape, cpContactPointSet *points, void *data);
cpBool cpSpaceShapeQuery(cpSpace *space, cpShape *shape, cpSpaceShapeQueryFunc func, void *data);
void cpSpaceActivateShapesTouchingShape(cpSpace *space, cpShape *shape);
typedef void (*cpSpaceBodyIteratorFunc)(cpBody *body, void *data);
void cpSpaceEachBody(cpSpace *space, cpSpaceBodyIteratorFunc func, void *data);
typedef void (*cpSpaceShapeIteratorFunc)(cpShape *shape, void *data);
void cpSpaceEachShape(cpSpace *space, cpSpaceShapeIteratorFunc func, void *data);
typedef void (*cpSpaceConstraintIteratorFunc)(cpConstraint *constraint, void *data);
void cpSpaceEachConstraint(cpSpace *space, cpSpaceConstraintIteratorFunc func, void *data);
void cpSpaceReindexStatic(cpSpace *space);
void cpSpaceReindexShape(cpSpace *space, cpShape *shape);
void cpSpaceReindexShapesForBody(cpSpace *space, cpBody *body);
void cpSpaceUseSpatialHash(cpSpace *space, cpFloat dim, int count);
void cpSpaceStep(cpSpace *space, cpFloat dt);
extern const char *cpVersionString;
void cpInitChipmunk(void);
void cpEnableSegmentToSegmentCollisions(void);
cpFloat cpMomentForCircle(cpFloat m, cpFloat r1, cpFloat r2, cpVect offset);
cpFloat cpAreaForCircle(cpFloat r1, cpFloat r2);
cpFloat cpMomentForSegment(cpFloat m, cpVect a, cpVect b);
cpFloat cpAreaForSegment(cpVect a, cpVect b, cpFloat r);
cpFloat cpMomentForPoly(cpFloat m, int numVerts, const cpVect *verts, cpVect offset);
cpFloat cpAreaForPoly(const int numVerts, const cpVect *verts);
cpVect cpCentroidForPoly(const int numVerts, const cpVect *verts);
void cpRecenterPoly(const int numVerts, cpVect *verts);
cpFloat cpMomentForBox(cpFloat m, cpFloat width, cpFloat height);
cpFloat cpMomentForBox2(cpFloat m, cpBB box);
int cpConvexHull(int count, cpVect *verts, cpVect *result, int *first, cpFloat tol);
]]