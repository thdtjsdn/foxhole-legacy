/*
Copyright (c) 2011 Josh Tynjala

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
package org.josht.foxhole.controls
{
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.errors.IllegalOperationError;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;
	
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	/**
	 * The class that provides the skin for the up state of the component.
	 *
	 * @default Button_upSkin
	 */
	[Style(name="upSkin", type="Class")]
	
	/**
	 * The class that provides the skin for the down state of the component.
	 *
	 * @default Button_downSkin
	 */
	[Style(name="downSkin", type="Class")]
	
	/**
	 * The class that provides the skin for the disabled state of the component.
	 *
	 * @default Button_disabledSkin
	 */
	[Style(name="disabledSkin", type="Class")]
	
	/**
	 * The padding that separates the border of the button from its contents, in pixels.
	 *
	 * @default null
	 */
	[Style(name="contentPadding", type="Number", format="Length")]
	
	public class Button extends UIComponent
	{
		private static const STATE_UP:String = "up";
		private static const STATE_DOWN:String = "down";
		private static const STATE_DISABLED:String = "disabled";
		
		private static var defaultStyles:Object =
		{
			upSkin: "Button_upSkin",
			downSkin: "Button_downSkin",
			disabledSkin: "Button_disabledSkin",
			contentPadding: null
		};
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, UIComponent.getStyleDefinition());
		}
		
		public function Button()
		{
			this.mouseChildren = false;
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}
		
		override public function set enabled(value:Boolean):void
		{
			super.enabled = value;
			if(!this.enabled)
			{
				this.mouseEnabled = false;
				this.currentState = STATE_DISABLED;
			}
			else
			{
				if(this.currentState == STATE_DISABLED)
				{
					this.currentState = STATE_UP;
				}
				this.mouseEnabled = true;
			}
		}
		
		private var _stateToDefaultSize:Object = {};
		private var _stateToSkin:Object = {};
		
		private var _currentState:String = STATE_UP;

		protected function get currentState():String
		{
			return _currentState;
		}

		protected function set currentState(value:String):void
		{
			if(this._currentState == value)
			{
				return;
			}
			if(this.stateNames.indexOf(value) < 0)
			{
				throw new ArgumentError("Invalid state: " + value + ".");
			}
			this._currentState = value;
			this.invalidate(InvalidationType.STATE);
		}

		protected var labelField:TextField;
		protected var currentSkin:DisplayObject;
		
		private var _label:String = "";

		public function get label():String
		{
			return this._label;
		}

		public function set label(value:String):void
		{
			if(!value)
			{
				//don't allow null or undefined
				value = "";
			}
			if(this._label == value)
			{
				return;
			}
			this._label = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		protected function get stateNames():Vector.<String>
		{
			return Vector.<String>([STATE_UP, STATE_DOWN, STATE_DISABLED]);
		}

		override protected function configUI():void
		{
			super.configUI();
			
			this._width = 160;
			this._height = 22;
			
			if(!this.labelField)
			{
				this.labelField = new TextField();
				this.labelField.selectable = this.labelField.mouseEnabled =
					this.labelField.mouseWheelEnabled = false;
				this.addChild(this.labelField);
			}
		}
		
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			const stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			const sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			const stateInvalid:Boolean = this.isInvalid(InvalidationType.STATE);
			
			if(dataInvalid)
			{
				this.labelField.text = this._label;
			}
			
			var contentPaddingChanged:Boolean = false;
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			if(stylesInvalid || stateInvalid)
			{
				this.refreshSkins();
				this.refreshLabelStyles();
				contentPaddingChanged = this.labelField.x != contentPadding;
			}
			
			if(dataInvalid || sizeInvalid || contentPaddingChanged)
			{
				const contentWidth:Number = Math.max(0, this._width - contentPadding * 2);
				const contentHeight:Number = Math.max(0, this._height - contentPadding * 2);
				this.labelField.width = contentWidth;
				this.labelField.height = this.labelField.textHeight + 4;
				this.labelField.x = contentPadding;
				this.labelField.y = Math.round((this._height - this.labelField.height) / 2);
			}
			
			if(stateInvalid)
			{
				for(var state:String in this._stateToSkin)
				{
					var skin:DisplayObject = DisplayObject(this._stateToSkin[state]);
					if(this._currentState != state)
					{
						skin.visible = false;
					}
					else
					{
						skin.visible = true;
						this.currentSkin = skin;
					}
				}
			}
			
			if(stylesInvalid || stateInvalid || sizeInvalid)
			{
				this.scaleSkin();
			}
			
			super.draw();
		}
		
		protected function refreshSkins():void
		{
			const states:Vector.<String> = this.stateNames;
			for each(var state:String in states)
			{
				var skin:DisplayObject = this._stateToSkin[state];
				var skinName:String = state + "Skin";
				var skinStyle:Object = this.getStyleValue(skinName);
				if(!skinStyle)
				{
					throw new IllegalOperationError("Skin must be defined for state: " + state);
				}
				if(skinStyle is String)
				{
					skinStyle = getDefinitionByName(skinStyle as String) as Class;
				}
				if(skinStyle is Class)
				{
					var SkinType:Class = Class(skinStyle);
					if(!(skin is SkinType))
					{
						if(skin)
						{
							this.removeChild(skin);
						}
						skin = new SkinType();
						this.addChild(skin);
					}
				}
				else if(skinStyle is DisplayObject)
				{
					if(skin != skinStyle)
					{
						if(skin)
						{
							this.removeChild(skin);
						}
						skin = DisplayObject(skinStyle);
						if(skin is InteractiveObject)
						{
							InteractiveObject(skin).mouseEnabled = false;
						}
						if(skin is DisplayObjectContainer)
						{
							DisplayObjectContainer(skin).mouseChildren = false;
						}
						this.addChild(skin);
					}
				}
				else
				{
					throw new IllegalOperationError("Unknown skin type: " + skinStyle);
				}
				
				if(state == this._currentState)
				{
					this.currentSkin = skin;
				}
				this._stateToSkin[state] = skin;
				var size:Point = this._stateToDefaultSize[state];
				if(!size)
				{
					size = new Point();
				}
				size.x = skin.width;
				size.y = skin.height;
				this._stateToDefaultSize[state] = size;
			}
			
			//make sure the label is always on top.
			var topChildIndex:int = this.numChildren - 1;
			if(this.getChildIndex(this.labelField) != topChildIndex)
			{
				this.setChildIndex(this.labelField, topChildIndex);
			}
		}
		
		protected function refreshLabelStyles():void
		{	
			var textFormat:TextFormat;
			if(this._enabled)
			{
				textFormat = this.getStyleValue("textFormat") as TextFormat;
			}
			else
			{
				textFormat = this.getStyleValue("disabledTextFormat") as TextFormat;
			}
			this.labelField.setTextFormat(textFormat);
			this.labelField.defaultTextFormat = textFormat;
			this.labelField.embedFonts = this.getStyleValue("embedFonts") as Boolean;
		}
		
		protected function scaleSkin():void
		{
			if(this.currentSkin.width != this._width)
			{
				this.currentSkin.width = this._width;
			}
			if(this.currentSkin.height != this._height)
			{
				this.currentSkin.height = this._height;
			}
		}
		
		private function mouseDownHandler(event:MouseEvent):void
		{
			this.currentState = STATE_DOWN;
			this.addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			this.currentState = STATE_UP;
			this.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			this.currentState = STATE_DOWN;
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
			this.removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			this.currentState = STATE_UP;
		}
	}
}