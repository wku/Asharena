package ;
import ash.core.Engine;
import ash.fsm.EngineState;
import ash.fsm.EngineStateMachine;
import ash.tick.FrameTickProvider;
import components.ActionUIntSignal;
import flash.display.Stage;
import input.KeyPoll;
import systems.animation.AnimationSystem;
import systems.collisions.EllipsoidColliderSystem;
import systems.collisions.GroundPlaneCollisionSystem;
import systems.movement.FlockingSystem;
import systems.movement.MovementSystem;
import systems.movement.PlayerSurfaceMovementSystem;
import systems.movement.QPhysicsSystem;
import systems.SystemPriorities;
import util.geom.Geometry;

import systems.collisions.EllipsoidCollider;
import systems.movement.GravitySystem;
import systems.movement.SurfaceMovementSystem;
import systems.player.PlayerControlActionSystem;
import systems.player.PlayerJumpSystem;
import systems.rendering.RenderSystem;

/**
 * ...
 * @author Glenn Ko
 */

class TheGame 
{

	public var colliderSystem:EllipsoidColliderSystem;
	
	public var engine:Engine;
	public var engineState:EngineStateMachine;
	
	public var spawner:Spawner;  // to depeciate
	
	public var stage:Stage;
	public var ticker:FrameTickProvider;
	public var keyPoll:KeyPoll;
	
	public var gameStates:GameStates;
	
	
	public function new(stage:Stage) 
	{
		Type.getClass(stage);
		
		keyPoll = new KeyPoll(stage);
		
		engine = new Engine();
		this.stage = stage;
		spawner =  getSpawner();
		

		// Craete ticker
		ticker = new FrameTickProvider(stage, 1000/15);
		ticker.add(engine.update);
		
		colliderSystem = new EllipsoidColliderSystem( new Geometry(), 0.001);
		
		gameStates = new GameStates(engine, colliderSystem, keyPoll);
		
		
		ActionUIntSignal;
		RenderSystem;
		FlockingSystem;
		Spawner;
		GroundPlaneCollisionSystem;
	
		
		// Spawn starting entities
	
		// Start
		//ticker.start(); 
	}
	
	public function getSpawner():Spawner {
		return new Spawner(engine);
	}
	
	public static function main():Void {
		
	}

	
}