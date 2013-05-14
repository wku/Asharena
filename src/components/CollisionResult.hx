package components;
import util.geom.Vec3;

/**
 * A component to help calculate and store required collision results
 * @author Glenn Ko
 */

class CollisionResult 
{
	// Settings

	 // default .8, the slope to be considered a jumpable ground surface (Component var could be static inlined as well)
	 public static inline var MAX_GROUND_NORMAL_THRESHOLD:Float = .8;
	public var max_ground_normal_threshold:Float; 
	
	// What results are calculated. In some cases, not calculating certain things might force engines to re-calculate stuff, or ignore
	// situations where it can't find the relavant results.
	public var flags:Int;	
	public static inline var FLAG_MAX_NORMAL_IMPULSE:Int = 1;
	public static inline var FLAG_MAX_GROUND_NORMAL:Int = 2;
	
	// Results
	public var gotCollision:Bool;
	public var maximum_normal_impulse:Float;  
	public var maximum_ground_normal:Vec3;

	public function new() 
	{
		gotCollision = false;
		
		flags = 0;
		
		max_ground_normal_threshold = MAX_GROUND_NORMAL_THRESHOLD;
		
		maximum_normal_impulse = 0;
		maximum_ground_normal = new Vec3();
	}
	
	private inline function get_gotGroundNormal():Bool 
	{
		return (flags & FLAG_MAX_GROUND_NORMAL) != 0;
	}
	
	private inline function set_gotGroundNormal(value:Bool):Bool 
	{
		if (value) {
			flags |= FLAG_MAX_GROUND_NORMAL;
		}
		else {
			flags &= ~(FLAG_MAX_GROUND_NORMAL);
		}
		return value;
	}
	
	public var gotGroundNormal(get_gotGroundNormal, set_gotGroundNormal):Bool;
	
	
	
}