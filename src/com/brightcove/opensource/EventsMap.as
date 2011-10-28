package com.brightcove.opensource
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class EventsMap extends EventDispatcher
	{
		private var _map:Array = new Array();
		private var _milestones:Array = new Array();
		
		//account-level stuff
		private var _dataSourceID:String;
		private var _beaconTracking:Boolean = false;
		private var _beaconInterval:uint = 5;
		private var _quartileTracking:Boolean = false;
		
		[Embed(source="../assets/events_map.xml", mimeType="application/octet-stream")]
		protected const XMLEventsMap:Class;

		public function EventsMap(xmlFileURL:String = null)
		{
			if(xmlFileURL)
			{
				var request:URLRequest = new URLRequest(xmlFileURL);
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onXMLFileLoaded);
				loader.load(request);
			}
			else
			{
				var byteArray:ByteArray = (new XMLEventsMap()) as ByteArray;
				var bytes:String = byteArray.readUTFBytes(byteArray.length);
				var eventsMapXML:XML = new XML(bytes);
				eventsMapXML.ignoreWhitespace = true;
				
				parseAccountInfo(eventsMapXML);
				parseEventsMap(eventsMapXML);
				
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function onXMLFileLoaded(event:Event):void
		{
			var eventsMapXML:XML = new XML(event.target.data);
			parseAccountInfo(eventsMapXML);
			parseEventsMap(eventsMapXML);
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function parseAccountInfo(eventsMap:XML):void
		{
			_dataSourceID = eventsMap.initialization.dataSourceID;
			
			//this still needs to be tested and proven
//			var trackingModes:XMLList = eventsMap.initialization.trackingModes.mode;
//				
//			for(var i:uint = 0; i < trackingModes.length(); i++)
//			{
//				var trackingMode:XML = trackingModes[i];
//				
//				switch(trackingMode.@name)
//				{
//					case 'beacon':
//						if(trackingMode.@value == "true")
//						{
//							_beaconTracking = true;
//						}
//						
//						_beaconInterval = trackingMode.@time;
//						break;
//					case 'quartile':
//						if(trackingMode.@value == "true")
//						{
//							_quartileTracking = true;
//						}
//						break;
//				}
//			}
		}
		
		private function parseEventsMap(eventsMap:XML):void
		{
			for(var node:String in eventsMap.events.event)
			{
				var event:XML = eventsMap.events.event[node];				
				var eventName:String = event.@name;

				var eventInfo:WebtrendsEventObject = new WebtrendsEventObject(eventName);
				var tags:XMLList = event.tag;
				
				for(var i:uint = 0; i < tags.length(); i++)
				{
					var tag:XML = tags[i];
					
					switch(String(tag.@name).toLowerCase())
					{
						case "eventname":
							eventInfo.eventName = tag.@value;
							break;
						case "clipname":
							eventInfo.clipName = tag.@value;
							break;
						case "cliptype":
							eventInfo.clipType = tag.@value;
							break;
						case "currentphase":
							eventInfo.currentPhase = tag.@value;
							break;
						case "clipid":
							eventInfo.clipID = tag.@value;
							break;
					}
				}
				
				if(eventName == 'milestone')
				{
					var milestone:Object = {
						eventInfo: eventInfo,
						type: event.@type,
						marker: event.@value
					};
					
					_milestones.push(milestone);
				}
				
				if(eventInfo.hasValues())
				{
					_map.push(eventInfo);
					trace("WEBTRENDS EVENT OBJECT: " + eventInfo.toString());
				}
			}
		}
		
		public function get dataSourceID():String
		{
			return _dataSourceID;
		}
		
		public function get map():Array
		{
			return _map;
		}
		
		public function get milestones():Array
		{
			return _milestones;
		}
	}
}