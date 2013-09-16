package alternativa.a3d.cullers 
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.IMeshSetCloneCuller;
	import alternativa.engine3d.objects.MeshSetClone;
	import alternativa.engine3d.alternativa3d;
	use namespace alternativa3d;
	
	/**
	 * ...
	 * @author Glenn Ko
	 */
	public class CircleRadiusCuller implements IMeshSetCloneCuller
	{
		private var squaredRadius:Number;
		private var offsetObj:Object3D;
		public function setRadius(radius:Number):void {
			var a:Number = Math.sin(Math.PI * .125) * radius;
			var b:Number = Math.cos(Math.PI * .125) * radius;
			squaredRadius = a * a + b * b;
		}
		
		public function CircleRadiusCuller(radius:Number, offsetObj:Object3D) 
		{
			this.offsetObj = offsetObj;
			setRadius(radius);
		}
		
		/* INTERFACE alternativa.engine3d.objects.IMeshSetCloneCuller */
		
		public function cull(numClones:int, clones:Vector.<MeshSetClone>, collector:Vector.<MeshSetClone>):int 
		{
			var count:int = 0;
			for (var i:int = 0; i < numClones; i++ ) {
				var candidate:MeshSetClone = clones[i];
				var x:Number = offsetObj._x + candidate.root._x;
				var y:Number = offsetObj._y + candidate.root._y;
				if (x * x + y * y > squaredRadius) continue;
				collector[count++] = candidate;
			}
			return count;
		}
		
	}

}