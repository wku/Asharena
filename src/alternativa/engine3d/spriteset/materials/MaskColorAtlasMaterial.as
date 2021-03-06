/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.spriteset.materials {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.A3DUtils;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;
	import flash.geom.Vector3D;

	import avmplus.getQualifiedClassName;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	use namespace alternativa3d;

	/**
	 * 
	 * 
	 * To be drawn with this material, geometry shoud have UV coordinates.
	 * @see alternativa.engine3d.objects.Skin#divide()
	 * @see alternativa.engine3d.core.VertexAttributes#TEXCOORDS
	 */
	public class MaskColorAtlasMaterial extends Material  implements IAtlasVertexMaterial  {  //

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Dictionary;
		private static var _transformProcedures:Dictionary = new Dictionary();
		
		//public static const MIP_LINEAR:String = "miplinear";
		//public static const MIP_NONE:String = "nomip";
		//public static const PIXEL_NEAREST:String = "nearest";
		//public static const PIXEL_LINEAR:String = "miplinear";
		//public var pixelSetting:String = PIXEL_LINEAR;
		//public var mipSetting:String = MIP_LINEAR;
		private static var diffuseProcedures:Vector.<Procedure> = new Vector.<Procedure>(8,true);
		
		public static const FLAG_PIXEL_NEAREST:uint = 2;
		public static  const FLAG_MIPNONE:uint = 4;
		public var flags:uint = 0;

		/*
		private var maskRed:Number;
		private var maskBlue:Number;
		private var maskGreen:Number;
		*/
		private var red:Number; 
		private var blue:Number;
		private var green:Number;

		
			public function get color():uint {
			return (red*0xFF << 16) + (green*0xFF << 8) + blue*0xFF;
			}

			/**
			* @private
			*/
			public function set color(value:uint):void {
			red = ((value >> 16) & 0xFF)/0xFF;
			green = ((value >> 8) & 0xFF)/0xFF;
			blue = (value & 0xff)/0xFF;
			}

			/*
			private function get maskColor():uint {
			return (maskRed*0xFF << 16) + (maskGreen*0xFF << 8) + maskBlue*0xFF;
			}
			*/


		
		
		/**
		 * @private
		 * Procedure for diffuse map with alpha channel
		 */
		alternativa3d function getDiffuseProcedure():Procedure { 
			var procedure:Procedure;
			var key:uint = flags;

			procedure = diffuseProcedures[key];
			if (procedure!=null) return procedure;
			
			procedure=new Procedure([
				"#v0=vUV",
				"#s0=sDiffuse",
				"#c0=cThresholdAlpha",
				"#c1=cColor",
				"tex t0, v0, s0 <2d,"+((flags & FLAG_PIXEL_NEAREST) ? "nearest" : "linear")+",repeat,"+((flags & FLAG_MIPNONE) ? "mipnone" : "miplinear")+">",  //nearest,repeat,nomip  //linear,repeat,miplinear
				"sge t1.w, t0.z, c1.w",   // should we mask? c1.w is mask color value on blue at full 255
				"mul t1.xyz, t1.www, c1.xyz",  // setup color to add if any...
				"sub t1.w, c0.z, t1.w",  // flip 1/0.
				"mul t0.xyz, t0.xyz, t1.www",   
				"add t0.xyz, t0.xyz, t1.xyz",  // add color
				
				"mul t0.w, t0.w, c0.w",
				"mov o0, t0"
			], "getDiffuseProcedure");
			return procedure;
		}
		
		alternativa3d function getDiffuseOpacityProcedure():Procedure { 
			var procedure:Procedure;
			var key:uint = (1 | flags);
			procedure = diffuseProcedures[key];
			if (procedure!=null) return procedure;
			
			procedure=new Procedure([
				"#v0=vUV",
				"#s0=sDiffuse",
				"#s1=sOpacity",
				"#c0=cThresholdAlpha",
				"#c1=cColor",
				"tex t0, v0, s0 <2d,"+((flags & FLAG_PIXEL_NEAREST) ? "nearest" : "linear")+",repeat,"+((flags & FLAG_MIPNONE) ? "mipnone" : "miplinear")+">",
								"sge t1.w, t0.z, c1.w",   // should we mask? c1.w is mask color value on blue at full 255
				"mul t1.xyz, t1.www, c1.xyz",  // setup color to add if any...
				"sub t1.w, c0.z, t1.w", // flip 1/0. if not masking, than set value to to 1 to multiply against original color, else, it'll be zero which will negate original color.
			
				
				"mul t0.xyz, t0.xyz, t1.www",   
				"add t0.xyz, t0.xyz, t1.xyz",  // add color
				
				"tex t1, v0, s1 <2d,"+((flags & FLAG_PIXEL_NEAREST) ? "nearest" : "linear")+",repeat,"+((flags & FLAG_MIPNONE) ? "mipnone" : "miplinear")+">",
				"mul t0.w, t1.x, c0.w",
				"mov o0, t0"
			], "getDiffuseOpacityProcedure");
			return procedure;
		}

		

		/**
		 * @private
		 * Alpha-test check procedure.
		 */
		static alternativa3d const thresholdOpaqueAlphaProcedure:Procedure = new Procedure([
			"#c0=cThresholdAlpha",
			"sub t0.w, i0.w, c0.x",
			"kil t0.w",
			"mov o0, i0"
		], "thresholdOpaqueAlphaProcedure");

		/**
		 * @private
		 * Alpha-test check procedure.
		 */
		static alternativa3d const thresholdTransparentAlphaProcedure:Procedure = new Procedure([
			"#c0=cThresholdAlpha",
			"slt t0.w, i0.w, c0.x",
			"mul i0.w, t0.w, i0.w",
			"mov o0, i0"
		], "thresholdTransparentAlphaProcedure");

		/**
		 * @private
		 * Pass UV to the fragment shader procedure
		 */
		static alternativa3d const _passUVProcedure:Procedure = new Procedure(["#v0=vUV", "#a0=aUV", "#a1=joint", "#c1=spriteSet",
			"add t1.w, c1.w, a1.x", 	// use offseted t1.w as +1 (c1.w) offset property from joint index to get texture atlas index
			"mov t0, a0",				// prepare starting a0  uv coordinate variable into t0
			"mov t1, c[t1.w]",   		// grab texture atlas data for sprite 
			"mov t0.xy, t1.xy",         // use starting UV coordinates of atlas rect's x, and y accordignly
			"mul t1.xy, a0.xy, t1.zw",  // multiple texture atlas rect's width and height against normalized a0 uv coordinates
			
			//"add t0.xy, t0.xy, t1.zw",  // offset starting UV coodtinates with rect width and height (if needed, based on normalized uv coordinates)
			
			"add t0.xy, t0.xy, t1.xy",	
	
			
		//	"add t0.x, t0.x, a0.x",
		//	"add t0.y, t0.y, a0.y",
			
			"mov v0, t0"				// that's it!!
		], 
		"passUVProcedure");

		/**
		 * Diffuse map.
		 */
		public var diffuseMap:TextureResource;
		
		/**
		 *  Opacity map.
		 */
		public var opacityMap:TextureResource;
		
		/**
		 *  If <code>true</code>, perform transparent pass. Parts of surface, cumulative alpha value of which is below than  <code>alphaThreshold</code> will be drawn within transparent pass.
		 * @see #alphaThreshold
		 */
		public var transparentPass:Boolean = true;
		
		/**
		 * If <code>true</code>, perform opaque pass. Parts of surface, cumulative alpha value of which is greater or equal than  <code>alphaThreshold</code> will be drawn within opaque pass.
		 * @see #alphaThreshold
		 */
		public var opaquePass:Boolean = true;
		
		/**
		 * alphaThreshold defines starts from which value of alpha a fragment of the surface will get into transparent pass.
		 * @see #transparentPass
		 * @see #opaquePass
		 */
		public var alphaThreshold:Number = 0;
		
		/**
		 *  Transparency.
		 */
		public var alpha:Number = 1;
		
		/**
		 * Creates a new MaskColorAtlasMaterial instance.
		 *
		 * @param diffuseMap Diffuse map.
		 * @param alpha Transparency.
		 */
		public function MaskColorAtlasMaterial(diffuseMap:TextureResource = null, opacityMap:TextureResource = null, alpha:Number = 1) {
			this.diffuseMap = diffuseMap;
			this.opacityMap = opacityMap;
			this.alpha = alpha;
			color = 0xAACC88;
		}

		/**
		 * @private
		 */
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void {
			super.fillResources(resources, resourceType);
			if (diffuseMap != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(diffuseMap)) as Class, resourceType)) {
				resources[diffuseMap] = true;
			}
			if (opacityMap != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(opacityMap)) as Class, resourceType)) {
				resources[opacityMap] = true;
			}
		}

		/**
		 * @param object
		 * @param programs
		 * @param camera
		 * @param opacityMap
		 * @param alphaTest 0 - disabled, 1 - opaque, 2 - contours
		 * @return
		 */
		private function getProgram(object:Object3D, programs:Vector.<MaskColorAtlasMaterialProgram>, camera:Camera3D, opacityMap:TextureResource, alphaTest:int):MaskColorAtlasMaterialProgram {
			var key:int = (opacityMap != null ? 3 : 0) + alphaTest;
			var program:MaskColorAtlasMaterialProgram = programs[key];
			if (program == null) {
				// Make program
				// Vertex shader
				var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
				
				var positionVar:String = "aPosition";
				vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
				if (object.transformProcedure != null) {
					positionVar = appendPositionTransformProcedure(object.transformProcedure, vertexLinker);
				}
				vertexLinker.addProcedure(_projectProcedure);
				vertexLinker.setInputParams(_projectProcedure, positionVar);
				vertexLinker.addProcedure(_passUVProcedure);

				// Pixel shader
				var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
				var outProcedure:Procedure = (opacityMap != null ? getDiffuseOpacityProcedure() : getDiffuseProcedure());
				fragmentLinker.addProcedure(outProcedure);
				if (alphaTest > 0) {
					fragmentLinker.declareVariable("tColor");
					fragmentLinker.setOutputParams(outProcedure, "tColor");
					if (alphaTest == 1) {
						fragmentLinker.addProcedure(thresholdOpaqueAlphaProcedure, "tColor");
					} else {
						fragmentLinker.addProcedure(thresholdTransparentAlphaProcedure, "tColor");
					}
				}
				fragmentLinker.varyings = vertexLinker.varyings;
				
				program = new MaskColorAtlasMaterialProgram(vertexLinker, fragmentLinker);

				program.upload(camera.context3D);
				programs[key] = program;
			}
			return program;
		}
		
		public function getAtlasTransformProcedure(maxSprites:int, NUM_REGISTERS_PER_SPR:int, viewAligned:Boolean = true, axis:Vector3D = null):Procedure {
		
			var key:String = maxSprites + "_" + (maxSprites * NUM_REGISTERS_PER_SPR) + "_view";
			var res:Procedure = _transformProcedures[key];
			if (res != null) return res;
			res = _transformProcedures[key] = new Procedure(null, "SpriteSetTransformProcedure");
			
			
			res.compileFromArray([
				"mov t2, c[a0.x].xyz",  // origin position in local coordinate space
				
				"mov t1, t2",  //dummy not needed if using latest flash player version
				"add t1.x, a0.x, c3.w",  // CHANGED from original SpriteSet class
				"mov t1, c[t1.x]",

		
				"mul t0.xyz, c2.xyz, i0.xxx",
				"mul t0.xyz, t0.xyz, c3.xxx", // scale according to spriteset setting (right vector)
				"mul t0.xyz, t0.xyz, t1.zzz",   // CHANGED from original SpriteSet class (scale by tileAtlas U height)
				"add t2.xyz, t2.xyz, t0.xyz",
				
				"mul t0.xyz, c1.xyz, i0.yyy",
				"mul t0.xyz, t0.xyz, c3.yyy",  // scale according to spriteset setting  (up vector)
				"mul t0.xyz, t0.xyz, t1.www",   // CHANGED from original SpriteSet class (scale by tileAtlas V height)	
				"add t2.xyz, t2.xyz, t0.xyz",
				
				"mov t2.w, i0.w",	
				"mov o0, t2",
				
				"#a0=joint",
				//"#c0=array",
				"#c1=up", 
				"#c2=right",
				"#c3=spriteSet"
				]);
			
			
		
			res.assignConstantsArray(maxSprites*NUM_REGISTERS_PER_SPR);
		
			return res;
		}
		
		private function getDrawUnit(program:MaskColorAtlasMaterialProgram, camera:Camera3D, surface:Surface, geometry:Geometry, opacityMap:TextureResource):DrawUnit {
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);

			var object:Object3D = surface.object;

			// Draw call
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);

			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			//Constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.cProjMatrix, object.localToCameraTransform);
			drawUnit.setFragmentConstantsFromNumbers(program.cThresholdAlpha, alphaThreshold, 0, 1, alpha);
			drawUnit.setFragmentConstantsFromNumbers(program.cColor, red, green, blue, 1);
			// Textures
			drawUnit.setTextureAt(program.sDiffuse, diffuseMap._texture);
			if (opacityMap != null) {
				drawUnit.setTextureAt(program.sOpacity, opacityMap._texture);
			}
			return drawUnit;
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			var object:Object3D = surface.object;
			
			// Buffers
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			
			// Check validity
			if (positionBuffer == null || uvBuffer == null || diffuseMap == null || diffuseMap._texture == null || opacityMap != null && opacityMap._texture == null) return;
			
			// Refresh program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				if (programsCache == null) {
					programsCache = new Dictionary();
					caches[cachedContext3D] = programsCache;
				}
			}
			var optionsPrograms:Vector.<MaskColorAtlasMaterialProgram> = programsCache[object.transformProcedure];
			if(optionsPrograms == null) {
				optionsPrograms = new Vector.<MaskColorAtlasMaterialProgram>(6, true);
				programsCache[object.transformProcedure] = optionsPrograms;
			}

			var program:MaskColorAtlasMaterialProgram;
			var drawUnit:DrawUnit;
			// Opaque pass
			if (opaquePass && alphaThreshold <= alpha) {
				if (alphaThreshold > 0) {
					// Alpha test
					// use opacityMap if it is presented
					program = getProgram(object, optionsPrograms, camera, opacityMap, 1);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				} else {
					// do not use opacityMap at all
					program = getProgram(object, optionsPrograms, camera, null, 0);
					drawUnit = getDrawUnit(program, camera, surface, geometry, null);
				}
				// Use z-buffer within DrawCall, draws without blending
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
			}
			// Transparent pass
			if (transparentPass && alphaThreshold > 0 && alpha > 0) {
				// use opacityMap if it is presented
				if (alphaThreshold <= alpha && !opaquePass) {
					// Alpha threshold
					program = getProgram(object, optionsPrograms, camera, opacityMap, 2);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				} else {
					// There is no Alpha threshold or check z-buffer by previous pass
					program = getProgram(object, optionsPrograms, camera, opacityMap, 0);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				}
				// Do not use z-buffer, draws with blending
				drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
				drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.TRANSPARENT_SORT);
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Material {
			var res:MaskColorAtlasMaterial = new MaskColorAtlasMaterial(diffuseMap, opacityMap, alpha);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Material):void {
			super.clonePropertiesFrom(source);
			var tex:MaskColorAtlasMaterial = source as MaskColorAtlasMaterial;
			diffuseMap = tex.diffuseMap;
			opacityMap = tex.opacityMap;
			opaquePass = tex.opaquePass;
			transparentPass = tex.transparentPass;
			alphaThreshold = tex.alphaThreshold;
			alpha = tex.alpha;
			flags = tex.flags;
			red = tex.red;
			green = tex.green;
			blue = tex.blue;
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class MaskColorAtlasMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var cProjMatrix:int = -1;
	public var cThresholdAlpha:int = -1;
	public var sDiffuse:int = -1;
	public var sOpacity:int = -1;
	public var cColor:int = -1;

	public function MaskColorAtlasMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition = vertexShader.findVariable("aPosition");
		aUV = vertexShader.findVariable("aUV");
		cProjMatrix = vertexShader.findVariable("cProjMatrix");
		cThresholdAlpha = fragmentShader.findVariable("cThresholdAlpha");
		sDiffuse = fragmentShader.findVariable("sDiffuse");
		sOpacity = fragmentShader.findVariable("sOpacity");
		
		cColor = fragmentShader.findVariable("cColor");

	}

}
