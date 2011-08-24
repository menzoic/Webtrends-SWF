package
{
	import com.brightcove.api.APIModules;
	import com.brightcove.api.CustomModule;
	import com.brightcove.api.dtos.RenditionAssetDTO;
	import com.brightcove.api.dtos.VideoCuePointDTO;
	import com.brightcove.api.dtos.VideoDTO;
	import com.brightcove.api.events.AdEvent;
	import com.brightcove.api.events.CuePointEvent;
	import com.brightcove.api.events.EmbedCodeEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.MenuEvent;
	import com.brightcove.api.events.ShortenedLinkEvent;
	import com.brightcove.api.modules.AdvertisingModule;
	import com.brightcove.api.modules.CuePointsModule;
	import com.brightcove.api.modules.ExperienceModule;
	import com.brightcove.api.modules.MenuModule;
	import com.brightcove.api.modules.SocialModule;
	import com.brightcove.api.modules.VideoPlayerModule;
	import com.brightcove.opensource.EventsMap;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.utils.Timer;
	
	public class Webtrends extends CustomModule
	{
		//---------------------------------------------- API MODULES
		private var _experienceModule:ExperienceModule;
		private var _videoPlayerModule:VideoPlayerModule;
		private var _advertisingModule:AdvertisingModule;
		private var _socialModule:SocialModule;
		private var _menuModule:MenuModule;
		private var _cuePointsModule:CuePointsModule;
		
		//---------------------------------------------- FLAGS 
		private var _mediaComplete:Boolean = true;
		private var _mediaBegin:Boolean = false;
		private var _videoMuted:Boolean = false;
		private var _trackSeekForward:Boolean = false;
		private var _trackSeekBackward:Boolean = false;
		private var _multitrackAvailabilityChecked:Boolean = false;
		private var _multitrackAvailable:Boolean = false;
		
		private var _dataSourceID:String; //Webtrends Profile ID
		private var _currentVideo:VideoDTO;
		private var _currentRendition:RenditionAssetDTO;
		private var _eventsMap:EventsMap;
		private var _seekCheckTimer:Timer;
		private var _positionBeforeSeek:Number;
		private var _currentPosition:Number;
		private var _currentVolume:Number;
		private var _customID:String;
		private var _previousTimestamp:Number;
		private var _timeWatched:Number;
		
		public function Webtrends()
		{
			trace("@project Webtrends-SWF");
			trace("@author Brandon Aaskov");
			trace("@lastModified 08.23.11 2129 EST");
			
			Security.allowDomain('*');
		}
		
		//-------------------------------------------------------------------------------------------- SETUP
		override protected function initialize():void
		{
			_experienceModule = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
			_videoPlayerModule = player.getModule(APIModules.VIDEO_PLAYER) as VideoPlayerModule;
			_advertisingModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
			_socialModule = player.getModule(APIModules.SOCIAL) as SocialModule;
			_menuModule = player.getModule(APIModules.MENU) as MenuModule;
			_cuePointsModule = player.getModule(APIModules.CUE_POINTS) as CuePointsModule;
			
			setupEventListeners();
			
			_dataSourceID = getParamValue('dsid');
			if(!_dataSourceID)
			{
				throw new Error("You did not provide a Webtrends Data Source ID (dsid). No analytics will be tracked.");
			}
			
			_currentVideo = _videoPlayerModule.getCurrentVideo();
			
			/*
			Look for an eventsMap XML file URL. If it exists, load it and use that for the _eventsMap. When the 'complete' 
			handler fires, we can configure the actionsource object and anything else that relies on the _eventsMap being 
			populated. If there isn't an XML file, we must be using the compiled XML file, in which case we can just 
			manually call the onEventsMapParsed handler and it will configure everything straight away.
			*/
			var xmlFileURL:String = getParamValue('eventsMap');
			if(xmlFileURL)
			{
				_eventsMap = new EventsMap(xmlFileURL);
				_eventsMap.addEventListener(Event.COMPLETE, onEventsMapParsed);
			}
			else
			{
				onEventsMapParsed(null);
			}
		}
		
		/**
		 * Sets up the event listeners on the Brightcove API modules to listen for events we can use for tracking.
		 */
		private function setupEventListeners():void
		{
			_videoPlayerModule.addEventListener(MediaEvent.CHANGE, onMediaChange);
			_videoPlayerModule.addEventListener(MediaEvent.BEGIN, onMediaBegin);
			_videoPlayerModule.addEventListener(MediaEvent.PLAY, onMediaPlay);
			_videoPlayerModule.addEventListener(MediaEvent.PROGRESS, onMediaProgress);
			_videoPlayerModule.addEventListener(MediaEvent.SEEK, onMediaSeek);
			_videoPlayerModule.addEventListener(MediaEvent.STOP, onMediaStop);
			_videoPlayerModule.addEventListener(MediaEvent.COMPLETE, onMediaComplete);
			_videoPlayerModule.addEventListener(MediaEvent.MUTE_CHANGE, onMuteChange);
			_videoPlayerModule.addEventListener(MediaEvent.VOLUME_CHANGE, onVolumeChange);
			_videoPlayerModule.addEventListener(MediaEvent.RENDITION_CHANGE_REQUEST, onRenditionChangeRequest);
			_videoPlayerModule.addEventListener(MediaEvent.RENDITION_CHANGE_COMPLETE, onRenditionChangeComplete);
			
			if(_advertisingModule)
			{
				_advertisingModule.addEventListener(AdEvent.AD_START, onAdStart);
				_advertisingModule.addEventListener(AdEvent.AD_PAUSE, onAdPause);
				_advertisingModule.addEventListener(AdEvent.AD_RESUME, onAdResume);
				_advertisingModule.addEventListener(AdEvent.EXTERNAL_AD, onExternalAd);
				_advertisingModule.addEventListener(AdEvent.AD_COMPLETE, onAdComplete);
				_advertisingModule.addEventListener(AdEvent.AD_CLICK, onAdClick);
				_advertisingModule.addEventListener(AdEvent.AD_POSTROLLS_COMPLETE, onAdPostrollsComplete);
			}
			
			_socialModule.addEventListener(EmbedCodeEvent.EMBED_CODE_RETRIEVED, onEmbedCodeRetrieved);
			_socialModule.addEventListener(ShortenedLinkEvent.LINK_GENERATED, onLinkGenerated);
			
			_menuModule.addEventListener(MenuEvent.COPY_CODE, onCopyCode);
			_menuModule.addEventListener(MenuEvent.COPY_LINK, onCopyLink);
			_menuModule.addEventListener(MenuEvent.BLOG_POST_CLICK, onBlogPostClick);
			_menuModule.addEventListener(MenuEvent.MENU_PAGE_OPEN, onMenuPageOpen);
			_menuModule.addEventListener(MenuEvent.MENU_PAGE_CLOSE, onMenuPageClose);
			_menuModule.addEventListener(MenuEvent.SEND_EMAIL_CLICK, onSendEmailClick);
			
			_cuePointsModule.addEventListener(CuePointEvent.CUE, onCuePoint);
			
			_seekCheckTimer.addEventListener(TimerEvent.TIMER, onSeekCheckTimer);
		}
		//-------------------------------------------------------------------------------------------- 
		
		
		
		//-------------------------------------------------------------------------------------------- EVENT HANDLERS
		private function onEventsMapParsed(pEvent:Event):void
		{
//			configureOmnitureDefaults();
		}
		
		private function onMediaChange(pEvent:MediaEvent):void
		{
			_currentVideo = _videoPlayerModule.getCurrentVideo();	
		}
		
		private function onMediaBegin(pEvent:MediaEvent):void
		{
			if(!_mediaBegin)
			{				
				updateVideoInfo();
				
				_mediaBegin = true;
				_mediaComplete = false;
			}
		}
		
		private function onMediaPlay(pEvent:MediaEvent):void
		{
			if(_mediaComplete)
			{
				//this is a true media begin event (mediaBegin doesn't fire on replay)
				_mediaComplete = false;
				_currentVideo = _videoPlayerModule.getCurrentVideo();
			}
		}
		
		private function onMediaProgress(pEvent:MediaEvent):void
		{
			_currentPosition = pEvent.position;
			updateTrackedTime();	
			
			/*
			This will track the media complete event when the user has watched 98% or more of the video. 
			Why do it this way and not use the Player API's event? The mediaComplete event will 
			only fire once, so if a video is replayed, it won't fire again. Why 98%? If the video's 
			duration is 3 minutes, it might really be 3 minutes and .145 seconds (as an example). When 
			we track the position here, there's a very high likelihood that the current position will 
			never equal the duration's value, even when the video gets to the very end. We use 98% since 
			short videos may never see 99%: if the position is 15.01 seconds and the video's duration 
			is 15.23 seconds, that's just over 98% and that's not an unlikely scenario. If the video is 
			long-form content (let's say an hour), that leaves 1.2 minutes of video to play before the 
			true end of the video. However, most content of that length has credits where a user will 
			drop off anyway, and in most cases content owners want to still track that as a media 
			complete event. Feel free to change this logic as needed, but do it cautiously and test as 
			much as you possibly can!
			*/
			if(pEvent.position/pEvent.duration > .98 && !_mediaComplete)
			{
				onMediaComplete(pEvent);
			}
		}
		
		private function onMediaSeek(event:MediaEvent):void
		{
			if(!_positionBeforeSeek)
			{
				_positionBeforeSeek = _currentPosition;
			}
			
			if(event.position > _positionBeforeSeek)
			{
				_trackSeekForward = true;
				_trackSeekBackward = false;
			}
			else
			{
				_trackSeekForward = false;
				_trackSeekBackward = true;
			}
			
			_seekCheckTimer.stop();
			_seekCheckTimer.start();
		}
		
		private function onMediaStop(event:MediaEvent):void
		{
			if(!_mediaComplete)
			{
			}
		}
		
		private function onMediaComplete(pEvent:MediaEvent):void
		{
			_mediaComplete = true;
		}
		
		private function onMuteChange(pEvent:MediaEvent):void
		{
			if(_videoPlayerModule.getVolume() > 0)
			{
				_videoMuted = false;
			}
			else
			{
				_videoMuted = true;
			}
		}
		
		private function onVolumeChange(pEvent:MediaEvent):void
		{
			_videoMuted = false;
			
			if(_videoPlayerModule.getVolume() !== _currentVolume) //have to check this, otherwise the event fires twice for some reason
			{
				_currentVolume = _videoPlayerModule.getVolume();
			}
		}
		
		private function onRenditionChangeRequest(pEvent:MediaEvent):void
		{
		}
		
		private function onRenditionChangeComplete(pEvent:MediaEvent):void
		{
			_currentRendition = _videoPlayerModule.getCurrentRendition();
		}
		
		private function onAdStart(pEvent:AdEvent):void
		{		
		}
		
		private function onAdPause(pEvent:AdEvent):void
		{
		}
		
		private function onAdResume(pEvent:AdEvent):void
		{
		}
		
		private function onExternalAd(pEvent:AdEvent):void
		{
		}
		
		private function onAdComplete(pEvent:AdEvent):void
		{
		}
		
		private function onAdClick(pEvent:AdEvent):void
		{
		}
		
		private function onAdPostrollsComplete(pEvent:AdEvent):void
		{
		}
		
		private function onEmbedCodeRetrieved(pEvent:EmbedCodeEvent):void
		{
		}
		
		private function onLinkGenerated(pEvent:ShortenedLinkEvent):void
		{	
		}
		
		private function onCopyCode(pEvent:MenuEvent):void
		{
		}
		
		private function onCopyLink(pEvent:MenuEvent):void
		{
		}
		
		private function onBlogPostClick(pEvent:MenuEvent):void
		{
		}
		
		private function onMenuPageOpen(pEvent:MenuEvent):void
		{
		}
		
		private function onMenuPageClose(pEvent:MenuEvent):void
		{
		}
		
		private function onSendEmailClick(pEvent:MenuEvent):void
		{
		}
		
		private function onCuePoint(pEvent:CuePointEvent):void
		{
			var cuePoint:VideoCuePointDTO = pEvent.cuePoint;
			
			if(cuePoint.type == 1 && cuePoint.name == "webtrends-milestone")
			{   
				var metadataSplit:Array;
				
				if(cuePoint.metadata.indexOf('%') !== -1) //percentage
				{
					metadataSplit = cuePoint.metadata.split('%');
//					trackingInfo = findEventInformation("milestone", _eventsMap.map, _currentVideo, "percent", metadataSplit[0]);
					
					_cuePointsModule.removeCodeCuePointsAtTime(_currentVideo.id, cuePoint.time);
				}
				else if(cuePoint.metadata.indexOf('s') !== -1) //seconds
				{
					metadataSplit = cuePoint.metadata.split('s');
//					trackingInfo = findEventInformation("milestone", _eventsMap.map, _currentVideo, "time", metadataSplit[0]);
					
					_cuePointsModule.removeCodeCuePointsAtTime(_currentVideo.id, cuePoint.time);
				}
				
//				trackEvent(trackingInfo);
			}
		}
		
		private function onSeekCheckTimer(pEvent:TimerEvent):void
		{
			if(_trackSeekBackward || _trackSeekForward)
			{
				var eventName:String = (_trackSeekForward) ? "seekForward" : "seekBackward";
				
				//reset values
				_trackSeekForward = false;
				_trackSeekBackward = false;
				_positionBeforeSeek = new Number();
			}
			
			_seekCheckTimer.stop();
		}
		//-------------------------------------------------------------------------------------------- 
		
		
		//-------------------------------------------------------------------------------------------- EVENT TRACKING
		private function trackEvent():void
		{
			if(ExternalInterface.available)
			{
				//check if we can use multitrack
			}
			else
			{
				//we can't use multitrack, so just call the URL directly
				var request:URLRequest = new URLRequest();
			}
		}
		
		private function getRequestString(pMultitrackAvailable:Boolean = false):String
		{
			var requestString:String;
//			
//			var dcsuri:String = "Brightcove_event.htm";
//			var pgtitle:String = "Brightove Player Event";
//			
//			if(pMultitrackAvailable)
//			{
//				requestString = "dcsMultiTrack('DCS.dcsuri','" + dcsuri + "','WT.ti','"+ pgtitle +"','DCSext.bc_evt','"+ eventName +"','DCSext.bc_expid','"+ _experienceModule.getExperienceID() +"','DCSext.bc_expname','"+ _experienceModule.getPlayerName() +"','DCSext.bc_url','"+ _experienceModule.getExperienceURL() +"','DCSext.bc_vid','"+ _currentVideo.id +"','DCSext.bc_vname','"+ _currentVideo.displayName +"','DCSext.bc_pid','"+ _currentVideo.lineupId +"'" + multitrackstr +")";
//			}
//			else
//			{
//				var sdcserver:String = "statse.webtrendslive.com";
//				var nojsstr = "http://" + sdcserver + "/" + _dataSourceID + "/dcs.gif?dcsuri=" + dcsuri + "&WT.js=No&WT.ti=" + pgtitle + "&bc_evt=" + eventName + "&bc_expid=" + _experienceModule.getExperienceID() + "&bc_expname=" + _experienceModule.getPlayerName() + "&bc_url=" + _experienceModule.getExperienceURL() + "&bc_vid=" + _currentVideo.id + "&bc_vname=" + _currentVideo.displayName + "&bc_pid=" + _currentVideo.lineupId + nojsstr;
//			}
//			
			return requestString;
		}
		//--------------------------------------------------------------------------------------------
		
		
		//-------------------------------------------------------------------------------------------- HELPER FUNCTIONS
		public function getCustomVideoName(video:VideoDTO):String
		{
			return video.id + " | " + video.displayName;
		}
		
		private function updateVideoInfo():void
		{
			_currentVideo = _videoPlayerModule.getCurrentVideo();
			_customID = getCustomVideoName(_currentVideo);
			
			if(!_mediaBegin) //we only want to call this once per video
			{
				createCuePoints(_eventsMap.milestones, _currentVideo);
			}
		}
		
		/**
		 * Keeps track of the aggregate time the user has been watching the video. If a user watches 10 seconds, 
		 * skips forward, watches another 10 seconds, skips again and watches 30 more seconds, the _timeWatched 
		 * will track as 50 seconds when the mediaComplete event fires. 
		 */ 
		private function updateTrackedTime():void
		{
			var currentTimestamp:Number = new Date().getTime();
			var timeElapsed:Number = (currentTimestamp - _previousTimestamp)/1000;
			_previousTimestamp = currentTimestamp;
			
			//check if it's more than 2 seconds in case the user paused or changed their local time or something
			if(timeElapsed < 2) 
			{
				_timeWatched += timeElapsed;
			} 
		}
		
		private function createCuePoints(milestones:Array, video:VideoDTO):void
		{
			if(milestones)
			{
				var cuePoints:Array = new Array();
				
				for(var i:uint = 0; i < milestones.length; i++)
				{
					var milestone:Object = milestones[i];
					var cuePoint:Object = {};
					
					if(milestone.type == 'percent')
					{
						cuePoint = {
							type: 1, //code cue point
							name: "omniture-milestone",
							metadata: milestone.marker + "%", //percent
								time: (video.length/1000) * (milestone.marker/100)
						};
					}
					else if(milestone.type == 'time')
					{
						cuePoint = {
							type: 1, //code cue point
							name: "omniture-milestone",
							metadata: milestone.marker + "s", //seconds
								time: milestone.marker
						};
					}
					
					cuePoints.push(cuePoint);
				}
				
				//clear out existing omniture cue points if they're still around after replay
				var existingCuePoints:Array = _cuePointsModule.getCuePoints(video.id);
				if(existingCuePoints)
				{
					for(var j:uint = 0; j < existingCuePoints.length; j++)
					{
						var existingCuePoint:VideoCuePointDTO = existingCuePoints[j];
						if(existingCuePoint.type == 1 && existingCuePoint.name == 'omniture-milestone')
						{
							_cuePointsModule.removeCodeCuePointsAtTime(video.id, existingCuePoint.time);
						}
					}
				}
				
				_cuePointsModule.addCuePoints(video.id, cuePoints);
			}
		}
		
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