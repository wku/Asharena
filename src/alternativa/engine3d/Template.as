package alternativa.engine3d 
{
	/**
	 * ...
	 * @author Glenn Ko
	 */
	
    import alternativa.engine3d.alternativa3d;
    import alternativa.engine3d.primitives.GeoSphere;
    import alternativa.engine3d.controllers.SimpleObjectController;
    import alternativa.engine3d.core.Camera3D;
    import alternativa.engine3d.core.Object3D;
    import alternativa.engine3d.core.Resource;
    import alternativa.engine3d.core.View;
    import alternativa.engine3d.core.VertexAttributes;
    import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import flash.display.Bitmap;
    import flash.display.BitmapData;

    import alternativa.engine3d.objects.Mesh;
    import alternativa.engine3d.objects.Surface;
    import alternativa.engine3d.objects.Joint;
    import alternativa.engine3d.lights.AmbientLight;
    import alternativa.engine3d.lights.DirectionalLight;
    import alternativa.engine3d.resources.Geometry;
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.utils.Dictionary;
    import flash.geom.Vector3D;
    import flash.utils.Dictionary;
    import flash.geom.*;


    public class Template extends Sprite {
        public static const VIEW_CREATE:String = 'view_create'
        
        public var stage3D:Stage3D
        public var camera:Camera3D
        public var scene:Object3D
        public var cameraController:SimpleObjectController;
        public var objectController:SimpleObjectController;
        public var controlObject:Object3D;
        
        protected var directionalLight:DirectionalLight;
        protected var ambientLight:AmbientLight;   
		
		public var bitmapResource:BitmapTextureResource;
		public var normalResource:BitmapTextureResource;
		
		public var settings:TemplateSettings = new TemplateSettings();
		public var renderId:int = 0;
        
        public function Template() {
			
			
            addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        protected function init(e:Event = null):void 
        {
			 var diffuseMap:BitmapData = new BitmapData(16, 16, false, 0xFF6666);
            var normalMap:BitmapData = new BitmapData(16, 16, false, 0x8080FF);

            bitmapResource = new BitmapTextureResource(diffuseMap);
            normalResource = new BitmapTextureResource(normalMap);
			
            removeEventListener(Event.ADDED_TO_STAGE, init);
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.HIGH;            
            
            //Stage3Dを用意
            stage3D = stage.stage3Ds[0];
            //Context3Dの生成、呼び出し、初期化
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreate);
            stage3D.requestContext3D();
        }
        
        
        private function onContextCreate(e:Event):void {
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreate);
            //View3D(表示エリア)の作成
            var view:View = new View(stage.stageWidth, stage.stageHeight);
            view.antiAlias = 4
            addChild(view);
            
            //Scene（コンテナ）の作成
            scene = new Object3D();

            //Camera（カメラ）の作成
            camera = new Camera3D(1, 100000);
            camera.view = view;
            scene.addChild(camera)
            camera.diagram
            addChild(camera.diagram);
			camera.view.backgroundColor  = settings.viewBackgroundColor;
            
            //Cameraをコントロールする場合は、CameraControlerの作成
           if (cameraController == null) cameraController = new SimpleObjectController(stage, camera, settings.cameraSpeed, settings.cameraSpeedMultiplier, settings.cameraSensitivity);
            //cameraController.mouseSensitivity = 0;
            //cameraController.unbindAll();
		
            
            //Cameraの位置調整
            cameraController.setObjectPosXYZ(0, -300, 0);
            cameraController.lookAtXYZ(0, 0, 0);
            
            //Lightを追加
            ambientLight = new AmbientLight(0xFFFFFF);
            ambientLight.intensity = 0.5;
            scene.addChild(ambientLight);
            
            //Lightを追加
            directionalLight = new DirectionalLight(0xFFFFFF);
            //手前右上から中央へ向けた指向性light
            directionalLight.x = 0;
            directionalLight.y = -100;
            directionalLight.z = -100;
            directionalLight.lookAt(0, 0, 0);
            scene.addChild(directionalLight);
            //directionalLight.visible = false;
            
        
            //コントロールオブジェクトの作成
            controlObject = new Object3D()
            scene.addChild(controlObject);
            dispatchEvent(new Event(VIEW_CREATE));
			
			
			stage.addEventListener(Event.RESIZE, onStageResize);
			
			
        }
		
		   public function takeScreenshot( method:Function=null) : Bitmap  //width:int, height:int,
     {
          var view:View = camera.view;

          view.renderToBitmap = true;
          camera.render(stage3D);
         var canvas:BitmapData =  view.canvas.clone();
         // var bitmapData:BitmapData = view.canvas.clone();
          view.renderToBitmap = false;
        //  view.width = oldWidth;
        //  view.height = oldHeight;   
            var child:Bitmap = new Bitmap(canvas);
            stage.addChildAt( child,0 );
         // take screenshot here
             if (method!= null && method() ) {
                if (child.parent) child.parent.removeChild(child);
             }
          return child;
     }
		
		private function onStageResize(e:Event):void 
		{
			camera.view.width = stage.stageWidth;
			camera.view.height = stage.stageHeight;
		}
		
		public function startRendering():void {
			uploadResources ( scene.getResources(true) );
            
            //オブジェクト用のコントローラー（マウス操作）
            objectController = new SimpleObjectController(stage, controlObject, 100);
            objectController.mouseSensitivity = 0.2;
         
            //レンダリング
            camera.render(stage3D);
            
			
            addEventListener(Event.ENTER_FRAME, onRenderTick);
		}
		
		public function uploadResources(vec:Vector.<Resource>):void {
			 for each (var resource:Resource in vec) {
                //trace(resource)
                resource.upload(stage3D.context3D);
            }
		}
        
        


        
        public function onRenderTick(e:Event):void {
            cameraController.update()
            camera.render(stage3D);
		
        }
    }

}


class TemplateSettings {
	public var cameraSpeedMultiplier:Number = 3;
	public var cameraSpeed:Number = 100;
	public var cameraSensitivity:Number = 1;
	public var viewBackgroundColor:uint;
	public function TemplateSettings() {
		
	}
	
}