package
{
	import com.brightcove.api.APIModules;
	import com.brightcove.api.CustomModule;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.modules.AdvertisingModule;
	import com.brightcove.api.modules.ExperienceModule;
	import com.brightcove.api.modules.VideoPlayerModule;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.system.Security;
	
	public class Webtrends extends CustomModule
	{
		//---------------------------------------------- API MODULES
		private var _experienceModule:ExperienceModule;
		private var _videoPlayerModule:VideoPlayerModule;
		private var _advertisingModule:AdvertisingModule;
		
		//---------------------------------------------- FLAGS 
		private var _mediaComplete:Boolean = true;
		
		public function Webtrends()
		{
			trace("@project Webtrends-SWF");
			trace("@author Brandon Aaskov");
			trace("@lastModified 08.15.11 0815 EST");
			
			Security.allowDomain('*');
		}
		
		//-------------------------------------------------------------------------------------------- SETUP
		override protected function initialize():void
		{
			_experienceModule = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
			_videoPlayerModule = player.getModule(APIModules.VIDEO_PLAYER) as VideoPlayerModule;
			_advertisingModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
			
			setupEventListeners();
		}
		
		/**
		 * Sets up the event listeners on the Brightcove API modules to listen for events we can use for tracking.
		 */
		private function setupEventListeners():void
		{
			_videoPlayerModule.addEventListener(MediaEvent.PLAY, onMediaPlay);
			
			if(_advertisingModule)
			{
				
			}
		}
		//-------------------------------------------------------------------------------------------- 
		
		
		
		//-------------------------------------------------------------------------------------------- EVENT HANDLERS
		private function onMediaPlay(pEvent:MediaEvent):void
		{
			if(_mediaComplete)
			{
				//this is a true media begin event (mediaBegin doesn't fire on replay)
				_mediaComplete = false;
			}
		}
		//-------------------------------------------------------------------------------------------- 
		
		
		
		//-------------------------------------------------------------------------------------------- HELPER FUNCTIONS
		/**
		 * Looks for the @param key in the URL of the page, the publishing code of the player, and 
		 * the URL for the SWF itself (in that order) and returns its value.
		 */
		public function getParamValue(key:String, onlyCheckPluginParams:Boolean = false):String
		{
			if(!onlyCheckPluginParams)
			{
				//1: check url params for the value
				var url:String = _experienceModule.getExperienceURL();
				if(url.indexOf("?") !== -1)
				{
					var urlParams:Array = url.split("?")[1].split("&");
					for(var i:uint = 0; i < urlParams.length; i++)
					{
						var keyValuePair:Array = urlParams[i].split("=");
						if(keyValuePair[0] == key) 
						{
							return keyValuePair[1];
						}
					}
				}
				
				//2: check player params for the value
				var playerParam:String = _experienceModule.getPlayerParameter(key);
				if(playerParam) 
				{
					return playerParam;
				}
			}
			
			//3: check plugin params for the value
			var pluginParams:Object = LoaderInfo(this.root.loaderInfo).parameters;
			for(var param:String in pluginParams)
			{
				if(param == key) 
				{
					return pluginParams[param];
				}
			}
			
			return null;
		}
		
		private function debug(pMessage:String):void
		{
			var	message:String = "WebTrends-SWF: " + pMessage;
			
			(_experienceModule) ? _experienceModule.debug(message) : trace(message);
		}
		//-------------------------------------------------------------------------------------------- 
	}
}