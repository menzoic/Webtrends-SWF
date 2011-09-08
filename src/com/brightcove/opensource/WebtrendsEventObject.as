package com.brightcove.opensource
{
	import com.brightcove.api.dtos.VideoDTO;
	import com.brightcove.api.modules.ExperienceModule;

	public class WebtrendsEventObject extends Object
	{
		private var _internalEventName:String;
		private var _eventName:String;
		private var _clipName:String;
		private var _clipType:String;
		private var _currentPhase:String;
		private var _clipID:String;
		
		public function WebtrendsEventObject(internalEventName:String = null, eventName:String = null, clipName:String = null, clipType:String = null, currentPhase:String = null, clipID:String = null)
		{
			this.internalEventName = internalEventName;
			this.eventName = eventName;
			this.clipName = clipName;
			this.clipType = clipType;
			this.currentPhase = currentPhase;
			this.clipID = clipID;
		}
		
		public function toString():String
		{
			var response:String = "internalEventName = " + internalEventName + "\n";
			response += "eventName = " + eventName + "\n";
			response += "clipName = " + clipName + "\n";
			response += "clipType = " + clipType + "\n";
			response += "currentPhase = " + currentPhase + "\n";
			response += "clipID = " + clipID + "\n";
			
			return response;
		}
		
		public function hasValues():Boolean
		{
			if(eventName || clipName || clipType || currentPhase || clipID)
			{
				return true;
			}
			
			return false;
		}
		
		public function bindEventInfoValues(binder:DataBinder, experienceModule:ExperienceModule, video:VideoDTO):void
		{
			this.eventName = binder.getValue(eventName, experienceModule, video);
			this.clipName = binder.getValue(clipName, experienceModule, video);
			this.clipType = binder.getValue(clipType, experienceModule, video);
			this.currentPhase = binder.getValue(currentPhase, experienceModule, video);
			this.clipID = binder.getValue(clipID, experienceModule, video);
		}
		
		public function set internalEventName(name:String):void
		{
			_internalEventName = name;
		}
		
		public function get internalEventName():String
		{
			return _internalEventName;
		}
		
		public function set eventName(name:String):void
		{
			_eventName = name;
		}
		
		public function get eventName():String
		{
			return _eventName;
		}
		
		public function set clipName(clipName:String):void
		{
			_clipName = clipName;
		}
		
		public function get clipName():String
		{
			return _clipName;
		}
		
		public function set clipType(clipType:String):void
		{
			_clipType = clipType;
		}
		
		public function get clipType():String
		{
			return _clipType;
		}
		
		public function set currentPhase(phase:String):void
		{
			_currentPhase = phase;
		}
		
		public function get currentPhase():String
		{
			return _currentPhase;
		}
		
		public function set clipID(clipID:String):void
		{
			_clipID = clipID;
		}
		
		public function get clipID():String
		{
			return _clipID;
		}
	}
}