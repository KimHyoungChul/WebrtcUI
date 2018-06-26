import { Component } from '@angular/core';
import { ToastController } from 'ionic-angular';


@Component(
{
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage
{

  /**
   * Complete data object containing all possible properties
   */
  public data: any =
  {
    environment: "integra",
    sipAddress: "",
    sipProxy: "",
    sipProxyWithTransport: "",
    sipPassword: "",
    outgoingSipAddress: "",
    useTurnServer: true,
    useTurnServer2: true,
    turnServer: "",
    iceServer1URL1: "",
    iceServer1URL2: "",
    turnRealm: "",
    turnUsername: "",
    turnPassword: "",
    turnServer2: "",
    iceServer2URL1: "",
    iceServer2URL2: "",
    turnRealm2: "",
    turnUsername2: "",
    turnPassword2: "",
    customCallSettings: false,
    settingsDownloadBandwidth: "",
    settingsUploadBandwidth: "",
    settingsFramerate: "",
    customGUISettings: false,
    appName: "",
    guiLanguage: "es",
    guiMainColor: "#0a79c7",
    guiSecondaryColor: "#70c8e1",
    guiFontSize: "17",
    guiFontColor: "#ffffff",
    guiTopViewDisplayMode: "atScreenTouch",
    guiConsultantName: "Dr. John Doe",
    guiConsultantAvatarURL: "https://api-integra.phemium.com/v1/api/resources?resid=6e8797a63909a995ce444372ca40bdb8&size=medium",
    guiServiceName: "Pediatrics",
    guiCallRecordingNotificationVisible: "no",
    settingsTransport: "udp",
    settingsEncryption: "none",
    settingsVideoSize: "vga",
    extraChat: "WithChat",
    extraZoom: "zoom",
    useWebrtc: false,
    extraLogMode: false,
    extraToEmail: "testphemium@gmail.com",
    onlyAudioCall: false
  };


  public view: string = 'general';
  public isLoaded: boolean = false;
  public isLoading: boolean = false;
  public isCalling: boolean = false;
  public isMinimized: boolean = false;
  private _softphone: any;
  private _error_message: Array<any>;
  public show_sip_config: boolean = false;

  /**
   * Constructor method
   */
  constructor
  (
    private toast: ToastController
  )
  {
  }



  load()
  {
    // Do not load while it's already loading
    if( this.isLoading )
    {
      return;
    }

    this.isLoading = true;

    let load_settings =
    {
      app_name: this.data.appName,
      event_cb: this._on_event_received.bind( this ),
      use_webrtc: this.data.useWebrtc
    };

    this._softphone = new window.SipVideoCall();
    this._softphone.load( load_settings );
  }



  /**
   * Execute call
   */
  call()
  {
    // Check we are not already calling
    if( this.isCalling === true )
    {
      return;
    }

    // Check we are not calling ourselves
    if( this.data.sipAddress === this.data.outgoingSipAddress )
    {
      this._show_message( "Your calling to yourself!! From and To SIP Address should not be equal" );
      return;
    }

    this.isCalling = true;
    let parameters = this._prepare_call_parameters();
    this._make_call( parameters );
  }



  _make_call( parameters: any )
  {
    this._softphone.call( this.data.outgoingSipAddress, parameters.credentials, parameters.settings, parameters.config,
      ( messageObject ) =>
      {
        let message = messageObject.event;

        if( message.substring( 0, 9 ) === 'minimized' )
        {
          this.isCalling = true;
          this.isMinimized = true;
          this._show_message( message );
        }

        if( message === "sendQuality" )
        {
          // @TODO

        }

        if( message === "released" )
        {
          this.isCalling = false;
          alert( "success: \n *Log*" + messageObject.workflow );
        }
      },
      ( errorObject ) =>
      {
        alert( "error code: " + errorObject.error_code + "\n" +
          "description: " + this._error_message[ errorObject.error_code ] + "\n" +
          " *Log* \n" + errorObject.workflow );
        this.isCalling = false;
      },
      ( eventObject ) =>
      {
        this._on_event_received( eventObject );
      });
  }



  _prepare_call_parameters() : any
  {
    let sipRealm = this.data.sipAddress.split( "@" )[ 1 ];

    // Credentials
    let credentials: any =
    {
      sip_proxy_with_transport: this.data.sipProxyWithTransport,
      sip_password: this.data.sipPassword,
      sip_realm: sipRealm,
      sip_proxy: this.data.sipProxy,
      sip_address: this.data.sipAddress,
      ice_servers: [],
      turn_udp_servers: [],
      ws_proxy: this.data.wsProxy
    };

    // Main Turn server
    if( this.data.useTurnServer )
    {
      credentials.turn_udp_servers.push(
      {
        address: this.data.turnServer,
        realm: this.data.turnRealm,
        username: this.data.turnUsername,
        password: this.data.turnPassword
      });

      if( !!this.data.iceServer1URL1 || !!this.data.iceServer1URL2 )
      {
        credentials.ice_servers.push(
        {
          urls: [],
          username: this.data.turnUsername,
          credential: this.data.turnPassword,
          credential_type: 'password'
        });

        if( this.data.iceServer1URL1 )
        {
          credentials.ice_servers[ 0 ].urls.push( this.data.iceServer1URL1 );
        }

        if( this.data.iceServer1URL2 )
        {
          credentials.ice_servers[ 0 ].urls.push( this.data.iceServer1URL2 )
        }
      }
    }

    // Alternative Turn Server
    if( this.data.useTurnServer2 )
    {
      credentials.turn_udp_servers.push(
      {
        address: this.data.turnServer2,
        realm: this.data.turnRealm2,
        username: this.data.turnUsername2,
        password: this.data.turnPassword2
      });

      if( !!this.data.iceServer2URL1 || !!this.data.iceServer2URL2 )
      {
        credentials.ice_servers.push(
        {
          urls: [],
          username: this.data.turnUsername2,
          credential: this.data.turnPassword2,
          credential_type: 'password'
        });

        if( this.data.iceServer2URL1 )
        {
          credentials.ice_servers[ credentials.ice_servers.length - 1 ].urls.push( this.data.iceServer2URL1 );
        }

        if( this.data.iceServer2URL2 )
        {
          credentials.ice_servers[ credentials.ice_servers.length - 1 ].urls.push( this.data.iceServer2URL2 )
        }
      }
    }

    // Settings
    var settings =
    {
      only_audio: this.data.onlyAudioCall,
      download_bandwidth: null,
      upload_bandwidth: null,
      framerate: null,
      transport_mode: "udp",
      encryption_mode: "none",
      video_size: 'vga'
    };

    // Custom Call Settings
    if( this.data.customCallSettings )
    {
      settings.download_bandwidth = this.data.settingsDownloadBandwidth;
      settings.upload_bandwidth = this.data.settingsUploadBandwidth;
      settings.framerate = this.data.settingsFramerate;
      settings.transport_mode = this.data.settingsTransport;
      settings.encryption_mode = this.data.settingsEncryption;
      settings.video_size = this.data.settingsVideoSize;
    }

    // Custom GUI Settings
    let guiSettings =
    {
      language: null,
      main_color: null,
      secondary_color: null,
      font_size: 0,
      font_color: null,
      display_topview_mode: null,
      consultant_name: "John Doe",
      consultant_avatar_url: null,
      service_name: null,
      call_recording_notification_visible: null,
      chat_mode: "WithChat",
      zoom_mode: "zoom",
      log_mode: false
    };

    if( this.data.customGUISettings )
    {
      guiSettings.language = this.data.guiLanguage;
      guiSettings.main_color = this.data.guiMainColor;
      guiSettings.secondary_color = this.data.guiSecondaryColor;
      guiSettings.font_size = parseInt( this.data.guiFontSize, 10 );
      guiSettings.font_color = this.data.guiFontColor;
      guiSettings.display_topview_mode = this.data.guiTopViewDisplayMode;
      guiSettings.consultant_name = this.data.guiConsultantName;
      guiSettings.consultant_avatar_url = this.data.guiConsultantAvatarURL;
      guiSettings.service_name = this.data.guiServiceName;
      guiSettings.call_recording_notification_visible = this.data.guiCallRecordingNotificationVisible;
      guiSettings.chat_mode = this.data.extraChat;
      guiSettings.zoom_mode = this.data.extraZoom;
      guiSettings.log_mode = this.data.extraLogMode;
    }

    // Extra Settings
    let extraSettings =
    {
      videocall_version: "2.6.0-beta04",
      enduser_version: "X.Y.Z",
      consultation_id: "111",
      extra_toemail: "testphemium@gmail.com"
    };

    window.settings.VideoCallPluginExtraSettings = extraSettings;
    window.settings.version = extraSettings.enduser_version;

    // Config
    var config =
    {
      gui_settings: guiSettings,
      extra_settings: extraSettings,
    };

    return {
      config: config,
      credentials: credentials,
      settings: settings
    };
  }



  /**
   * Simulate incoming Call
   */
  incomingCall()
  {
    let parameters = this._prepare_call_parameters();
    this._softphone.incomingCall( this.data.outgoingSipAddress, parameters.credentials, parameters.settings, parameters.config,
      ( messageObject ) =>
      {
        let message = messageObject.event;

        if( message.substring( 0, 9 ) === 'minimized' )
        {
          this.isCalling = true;
          this.isMinimized = true;
          this._show_message( message );
        }

        if( message === "sendQuality" )
        {
          // @TODO

        }

        if( message === "released" )
        {
          this.isCalling = false;
          alert( "success: \n *Log*" + messageObject.workflow );
        }
      },
      ( errorObject ) =>
      {
        alert( "error code: " + errorObject.error_code + "\n" +
          "description: " + this._error_message[ errorObject.error_code ] + "\n" +
          " *Log* \n" + errorObject.workflow );
        this.isCalling = false;
      },
      ( eventObject ) =>
      {
        this._on_event_received( eventObject );
      });
  }



  /**
   * Simulate Message arrived
   */
  onChatMessageArrived()
  {
    this._show_message( 'Please, go back to fullscreen video and in a few seconds, the message must appear' );

    setTimeout( () =>
    {
      this._softphone.onChatMessageArrived(
        () => this._show_message( 'Chat Message simulated successfully!' ),
        ( error ) => this._show_message( 'Error simulating message: ' + JSON.stringify( error ))
      );
    }, 5000 );
  }



  /**
   * HangUp call
   */
  hangUp()
  {
    this._softphone.hangUp();
  }



  set_environment_data()
  {
    this.data.appName = "TESTAPP";
    this.data.sipAddress = window.settings[ this.data.environment ].sipAddress;
    this.data.sipPassword = window.settings[ this.data.environment ].sipPassword;
    this.data.sipProxy = window.settings[ this.data.environment ].sipProxy;
    this.data.outgoingSipAddress = window.settings[ this.data.environment ].outgoingSipAddress;
    this.data.sipProxyWithTransport = window.settings[ this.data.environment ].sipProxyWithTransport;
    this.data.wsProxy = window.settings[ this.data.environment ].wsProxy;

    this.data.turnServer = window.settings[ this.data.environment ].turnServer;
    this.data.iceServer1URL1 = window.settings[ this.data.environment ].iceServer1URL1;
    this.data.iceServer1URL2 = window.settings[ this.data.environment ].iceServer1URL2;
    this.data.turnRealm = window.settings[ this.data.environment ].turnRealm;
    this.data.turnUsername = window.settings[ this.data.environment ].turnUsername;
    this.data.turnPassword = window.settings[ this.data.environment ].turnPassword;
    this.data.turnServer2 = window.settings[ this.data.environment ].turnServer2;
    this.data.iceServer2URL1 = window.settings[ this.data.environment ].iceServer2URL1;
    this.data.iceServer2URL2 = window.settings[ this.data.environment ].iceServer2URL2;
    this.data.turnRealm2 = window.settings[ this.data.environment ].turnRealm2;
    this.data.turnUsername2 = window.settings[ this.data.environment ].turnUsername2;
    this.data.turnPassword2 = window.settings[ this.data.environment ].turnPassword2;

    this.data.settingsDownloadBandwidth = window.settings[ this.data.environment ].settingsDownloadBandwidth;
    this.data.settingsUploadBandwidth = window.settings[ this.data.environment ].settingsUploadBandwidth;
    this.data.settingsFramerate = window.settings[ this.data.environment ].settingsFramerate;
  }



  /**
   * Show message
   *
   * @param text Text to show
   */
  _show_message( text: string )
  {
    let toast = this.toast.create(
    {
      message: text,
      duration: 3000
    });

    toast.present();
  }



  _on_event_received( eventObject )
  {
    if( eventObject.event === 'comm_loaded' )
    {
      this.isLoading = false;
      this.isLoaded = true;
      return;
    }

    if( eventObject.event === 'call_disconnected' )
    {
      this.isCalling = false;
    }

    if( eventObject.event === 'call_failed' )
    {
      this.isCalling = false;
    }

    this._show_message( eventObject.event );
  }

}
