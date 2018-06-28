/**
 * SipVideoCall plugin
 *
 * @event initialized
 * @event registered
 * @event call_ringing
 * @event call_finished
 * @event call_cancelled
 * @event call_failed
 * @event error
 */
var SipVideoCallWebRTC = function()
{
  this._softphone = {};
  this._current_call = null;
  this._settings = {};
  this._config = {};
  this._call_connected = false;
  this._dom_call_wrapper_object = null;
  this._dom_outgoing_call_wrapper_object = null;
  this._dom_incoming_call_wrapper_object = null;
  this._fullscreen = true;
  this._load_settings = {};
  this._show_toolbar = false;
  this._old_pos_top = null;
  this._old_post_left = null;
  this._micro_enabled = true;
  this._camera_enabled = true;
  this._front_camera = true;
  this._inverse_video = false;



  /**
   * Load and prepare softphone
   */
  this.load = function( load_settings )
  {
    // If we are under an environment where the iOS WeRTC plugin is installed
    // we call the method to map the plugin functions to the native ones.
    // This is to be able to have navigator.mediaDevices...
    // WKWebView has only a restricted access to the WebRTC API, so this plugin is necessary.
    if( typeof cordova !== 'undefined' && typeof cordova.plugins.iosrtc === 'object' )
    {
      cordova.plugins.iosrtc.registerGlobals();
    }


    this._load_settings = load_settings;
    this._softphone = new Comm.webrtc.Softphone( 'comm', {} );

    this._softphone.Loader.on(
    {
      scope: this,
      comm_loading_error: function(){ this._fire_main_event( 'comm_loading_error' ); },
      installed: function(){ this._fire_main_event( 'comm_installed' ); },
      comm_loaded: function(){ this._fire_main_event( 'comm_loaded' ); }
    });

    this._softphone.Loader.load();

    // Add Call UI
    this._dom_call_wrapper_object = document.createElement( 'phe-videocall-webrtc' );
    this._dom_call_wrapper_object.innerHTML = window.phemium_videocall_plugin_templates[ 'webrtc_call.tpl.html' ];
    this._dom_call_wrapper_object.style.display = 'none';
    document.body.appendChild( this._dom_call_wrapper_object );

    // Add Outgoing Call UI
    this._dom_outgoing_call_wrapper_object = document.createElement( 'phe-videocall-outgoing-webrtc' );
    this._dom_outgoing_call_wrapper_object.innerHTML = window.phemium_videocall_plugin_templates[ 'outgoing_call.tpl.html' ];
    this._dom_outgoing_call_wrapper_object.style.display = 'none';
    document.body.appendChild( this._dom_outgoing_call_wrapper_object );

    // Add Incoming Call UI
    this._dom_incoming_call_wrapper_object = document.createElement( 'phe-videocall-outgoing-webrtc' );
    this._dom_incoming_call_wrapper_object.innerHTML = window.phemium_videocall_plugin_templates[ 'incoming_call.tpl.html' ];
    this._dom_incoming_call_wrapper_object.style.display = 'none';
    document.body.appendChild( this._dom_incoming_call_wrapper_object );

    // Prepare UI listeners
    this._prepare_ui_listeners();
  };



  /**
   * Prepare UI listeners
   */
  this._prepare_ui_listeners = function()
  {
    this._prepare_ui_call_listeners();
    this._prepare_ui_outgoing_call_listeners();
    this._prepare_ui_incoming_call_listeners();
    this._prepare_ui_video_call_listeners();
  };



  /**
   * Prepare UI listeners for Call in progress object
   */
  this._prepare_ui_call_listeners = function()
  {
    // Remote video listeners
    this._dom_remote_video = this._dom_call_wrapper_object.querySelector( '[data-id="video-remote"]' );
    this._dom_remote_video.onclick = this._remote_video_clicked.bind( this );
    this._dom_remote_video.ondragstart = this._on_start_drag_remote_video.bind( this );
    this._dom_remote_video.ondrag = this._on_drag_remote_video.bind( this );

    // Local video listeners
    this._dom_local_video = this._dom_call_wrapper_object.querySelector( '[data-id="video-local"]' );
    this._dom_local_video.ondragstart = this._on_start_drag_local_video.bind( this );
    this._dom_local_video.ondrag = this._on_drag_local_video.bind( this );

    // Chat button
    this._dom_chat_button = this._dom_call_wrapper_object.querySelector( '[data-id="chat-icon"]' );
    this._dom_chat_button.onclick = this._toggle_fullscreen.bind( this );

    // Actions Toolbar
    this._dom_actions_toolbar = this._dom_call_wrapper_object.querySelector( '[data-id="actions-toolbar"]' );
    this._dom_toggle_audio = this._dom_call_wrapper_object.querySelector( '[data-id="toggle-audio-button"]' );
    this._dom_toggle_audio.onclick = this._toggle_audio.bind( this );
    this._dom_toggle_video = this._dom_call_wrapper_object.querySelector( '[data-id="toggle-video-button"]' );
    this._dom_toggle_video.onclick = this._toggle_video.bind( this );
    this._dom_toggle_camera = this._dom_call_wrapper_object.querySelector( '[data-id="toggle-camera-button"]' );
    this._dom_toggle_camera.onclick = this._toggle_camera.bind( this );


    // Hangup buttons
    this._dom_call_wrapper_object.querySelectorAll( '[data-id="hangup-button"]' ).forEach( function( hangup_button )
    {
      hangup_button.onclick = this.hangUp.bind( this );
    }.bind( this ));

    // Badge Number
    this._dom_messages_video_badge = this._dom_call_wrapper_object.querySelector( '[data-id="video-badge-number"]' );
    this._dom_messages_audio_badge = this._dom_call_wrapper_object.querySelector( '[data-id="audio-badge-number"]' );

    // PiP containers
    this._dom_remote_pip_container = this._dom_call_wrapper_object.querySelector( '.phe-videocall-wrapper' );
    this._dom_local_pip_container = this._dom_call_wrapper_object.querySelector( '.phe-videocall-video.local' );
  };



  /**
   * Prepare Outgoing call listeners
   */
  this._prepare_ui_outgoing_call_listeners = function()
  {
    // Cancel button
    this._dom_outgoing_call_cancel_button = this._dom_outgoing_call_wrapper_object.querySelector( '[data-id="cancel-button"]' );
    this._dom_outgoing_call_cancel_button.onclick = this.hangUp.bind( this );
  };



  /**
   * Prepare Incoming call listeners
   */
  this._prepare_ui_incoming_call_listeners = function()
  {
    // Cancel button
    this._dom_incoming_call_cancel_button = this._dom_incoming_call_wrapper_object.querySelector( '[data-id="cancel-button"]' );
    this._dom_incoming_call_cancel_button.onclick = this.hangUp.bind( this );

    // Accept button
    this._dom_incoming_call_accept_button = this._dom_incoming_call_wrapper_object.querySelector( '[data-id="accept-button"]' );
    this._dom_incoming_call_cancel_button.onclick = this.hangUp.bind( this );
  };


  /**
   * Prepare Video call listeners
   */
  this._prepare_ui_video_call_listeners = function()
  {
    this._dom_video_call_video_fullview = this._dom_call_wrapper_object.querySelector( '.phe-videocall-video.remote' );
    this._dom_video_call_video_subview = this._dom_call_wrapper_object.querySelector( '.phe-videocall-video.local' );
    this._dom_video_call_video_subview.onclick = this._inverse_video.bind( this );
  };



  /**
   * Remote video has been clicked
   */
  this._remote_video_clicked = function()
  {
    if( this._fullscreen )
    {
      this._toggle_toolbar();
    }
    else
    {
      this._toggle_fullscreen();
    }
  };



  /**
   * Remote video is starting to be dragged
   *
   * @param {Object} evt
   */
  this._on_start_drag_remote_video = function( evt )
  {
    this._diff_x_remote = evt.pageX - this._dom_remote_pip_container.offsetLeft;
    this._diff_y_remote = evt.pageY - this._dom_remote_pip_container.offsetTop;
  };



  /**
   * Remote video is being dragged
   *
   * @param {Object} evt
   */
  this._on_drag_remote_video = function( evt )
  {
    evt.preventDefault();

    var left = parseInt( evt.pageX - this._diff_x_remote );
    var top = parseInt( evt.pageY - this._diff_y_remote );

    // Check screen boundaries to avoid position video outside viewable part.
    if( top < 0 )
    {
      top = 0;
    }

    if( left < 0 )
    {
      left = 0;
    }

    // Check taking into account remote video size.
    if( top > window.innerHeight - this._dom_remote_pip_container.clientHeight )
    {
      top = window.innerHeight - this._dom_remote_pip_container.clientHeight;
    }

    if( left > window.innerWidth - this._dom_remote_pip_container.clientWidth )
    {
      left = window.innerWidth - this._dom_remote_pip_container.clientWidth;
    }

    this._dom_remote_pip_container.style.left = left + 'px';
    this._dom_remote_pip_container.style.top = top + 'px';
  };



  /**
   * Local video is starting to be dragged
   *
   * @param {Object} evt
   */
  this._on_start_drag_local_video = function( evt )
  {
    this._diff_x_local = evt.pageX - this._dom_local_pip_container.offsetLeft;
    this._diff_y_local = evt.pageY - this._dom_local_pip_container.offsetTop;
  };



  /**
   * Local video is being dragged
   *
   * @param {Object} evt
   */
  this._on_drag_local_video = function( evt )
  {
    evt.preventDefault();

    var left = parseInt( evt.pageX - this._diff_x_local );
    var top = parseInt( evt.pageY - this._diff_y_local );

    // Check screen boundaries to avoid position video outside viewable part.
    if( top < 0 )
    {
      top = 0;
    }

    if( left < 0 )
    {
      left = 0;
    }

    // Check taking into account remote video size.
    if( top > window.innerHeight - this._dom_local_pip_container.clientHeight )
    {
      top = window.innerHeight - this._dom_local_pip_container.clientHeight;
    }

    if( left > window.innerWidth - this._dom_local_pip_container.clientWidth )
    {
      left = window.innerWidth - this._dom_local_pip_container.clientWidth;
    }

    this._dom_local_pip_container.style.left = left + 'px';
    this._dom_local_pip_container.style.top = top + 'px';
  };



  /**
   * Toggle actions toolbar
   */
  this._toggle_toolbar = function()
  {
    this._show_toolbar = !this._show_toolbar;

    if( this._show_toolbar )
    {
      this._dom_local_video.classList.add( 'with-toolbar' );
      Array.from( this._dom_actions_toolbar.children ).forEach( function( toolbar_button )
      {
        toolbar_button.classList.add( 'showed' );
      });
    }
    else
    {
      this._dom_local_video.classList.remove( 'with-toolbar' );
      Array.from( this._dom_actions_toolbar.children ).forEach( function( toolbar_button )
      {
        toolbar_button.classList.remove( 'showed' );
      });
    }
  };



  this._toggle_fullscreen = function()
  {
    this._fullscreen = !this._fullscreen;

    if( this._fullscreen )
    {
      // Undo Main wrapper minimization
      this._dom_call_wrapper_object.classList.remove( 'minimized' );

      // Locate main wrapper
      this._old_pos_top = this._dom_call_wrapper_object.style.top;
      this._old_post_left = this._dom_call_wrapper_object.style.left;
      this._dom_call_wrapper_object.style.top = '0px';
      this._dom_call_wrapper_object.style.left = '0px';
    }
    else
    {
      // Main wrapper minimization
      this._dom_call_wrapper_object.classList.add( 'minimized' );

      // Locate main wrapper
      this._dom_call_wrapper_object.style.top = this._old_pos_top;
      this._dom_call_wrapper_object.style.left = this._old_pos_left;

      // Update messages badge
      this._update_badge( 0 );
    }


    if( !this._settings.only_audio )
    {
      this._resize_videos();
      setTimeout( this._resize_videos.bind( this ), 100 );
      setTimeout( this._resize_videos.bind( this ), 200 );
      setTimeout( this._resize_videos.bind( this ), 300 );

      // Hide toolbar if necessary
      if( this._show_toolbar )
      {
        this._toggle_toolbar();
      }
    }
  };



  /**
   * Start a new call with the given address
   *
   * @param {String} address
   * @param {Object} credentials
   * @param {Object} settings
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   * @param {Function=} event_cb
   */
  this.call = function( address, credentials, settings, config, success_cb, error_cb, event_cb )
  {
    this._success_cb = success_cb;
    this._error_cb = error_cb;
    this._event_cb = event_cb;
    this._to_address = address;
    this._settings = settings;
    this._config = config;

    // Background calculation
    var background_style = '';

    if( !!this._config.gui_settings.main_color && !!this._config.gui_settings.secondary_color )
    {
      background_style = this._config.gui_settings.main_color + ' linear-gradient( ' + this._config.gui_settings.main_color + ', ' + this._config.gui_settings.secondary_color + ' )';
    }
    else if( !!this._config.gui_settings.main_color && !this._config.gui_settings.secondary_color )
    {
      background_style = this._config.gui_settings.main_color;
    }

    // Prepare Outgoing Call UI
    this._dom_outgoing_call_wrapper_object.querySelector( '[data-id="callee-name"]' ).innerHTML = this._config.gui_settings.consultant_name || '';
    // this._dom_outgoing_call_wrapper_object.querySelector( '[data-id="service-name"]' ).innerHTML = this._config.gui_settings.service_name || '';
    this._dom_outgoing_call_wrapper_object.querySelector( '[data-id="message"]' ).innerHTML = 'Registrando...';
    var avatar_url = ( this._config.gui_settings.consultant_avatar_url ) ? this._config.gui_settings.consultant_avatar_url : 'phemium-videocall/images/avatar.png';
    this._dom_outgoing_call_wrapper_object.querySelector( '[data-id="callee-avatar"]' ).innerHTML = '<img src="' + avatar_url + '" />';
    this._dom_outgoing_call_wrapper_object.querySelector( '.phe-preparing-call-wrapper' ).style.background = background_style;


    this._dom_outgoing_call_wrapper_object.style.display = '';


    // Prepare Call UI
    this._dom_call_wrapper_object.querySelector( '[data-id="callee-name"]' ).innerHTML = this._config.gui_settings.consultant_name;
    this._dom_toggle_camera.style.display = ( this._can_toggle_camera() ) ? '' : 'none';
    this._dom_call_wrapper_object.querySelector( '.phe-videocall-wrapper' ).style.background = background_style;


    // Set global extra headers
    var extra_headers =
    [
      'Phemium-Browser: ' + navigator.userAgent,
      'Phemium-Softphone-Version: ' + Comm.version
    ];

    this._softphone.Uac.set_extra_headers( extra_headers );

    // Set credentials
    delete credentials.username;
    this._softphone.Uac.set_credentials( credentials );

    // Register will execute the call after the REGISTER_SUCCESS event
    this.register();
  };



  /**
   * Start a new call simulating an incoming call with the given address
   *
   * @param {String} address
   * @param {Object} credentials
   * @param {Object} settings
   * @param {Object} gui_settings
   * @param {Object} extra_settings
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.incomingCall = function( address, credentials, settings, config, success_cb, error_cb, event_cb )
  {
    this._success_cb = success_cb;
    this._error_cb = error_cb;
    this._event_cb = event_cb;
    this._to_address = address;
    this._settings = settings;
    this._config = config;

    // Background calculation
    var background_style = '';

    if( !!this._config.gui_settings.main_color && !!this._config.gui_settings.secondary_color )
    {
      background_style = this._config.gui_settings.main_color + ' linear-gradient( ' + this._config.gui_settings.main_color + ', ' + this._config.gui_settings.secondary_color + ' )';
    }
    else if( !!this._config.gui_settings.main_color && !this._config.gui_settings.secondary_color )
    {
      background_style = this._config.gui_settings.main_color;
    }

    // Prepare Incoming Call UI
    this._dom_incoming_call_wrapper_object.querySelector( '[data-id="callee-name"]' ).innerHTML = this._config.gui_settings.consultant_name || '';
    // this._dom_incoming_call_wrapper_object.querySelector( '[data-id="service-name"]' ).innerHTML = this._config.gui_settings.service_name || '';
    this._dom_incoming_call_wrapper_object.querySelector( '[data-id="message"]' ).innerHTML = 'Registrando...';
    var avatar_url = ( this._config.gui_settings.consultant_avatar_url ) ? this._config.gui_settings.consultant_avatar_url : 'phemium-videocall/images/avatar.png';
    this._dom_incoming_call_wrapper_object.querySelector( '[data-id="callee-avatar"]' ).innerHTML = '<img src="' + avatar_url + '" />';
    this._dom_incoming_call_wrapper_object.querySelector( '.phe-preparing-call-wrapper' ).style.background = background_style;


    this._dom_incoming_call_wrapper_object.style.display = '';


    // Prepare Call UI
    this._dom_call_wrapper_object.querySelector( '[data-id="callee-name"]' ).innerHTML = this._config.gui_settings.consultant_name;
    this._dom_toggle_camera.style.display = ( this._can_toggle_camera() ) ? '' : 'none';
    this._dom_call_wrapper_object.querySelector( '.phe-videocall-wrapper' ).style.background = background_style;


    // Set global extra headers
    var extra_headers =
    [
      'Phemium-Browser: ' + navigator.userAgent,
      'Phemium-Softphone-Version: ' + Comm.version
    ];

    this._softphone.Uac.set_extra_headers( extra_headers );

    // Set credentials
    delete credentials.username;
    this._softphone.Uac.set_credentials( credentials );

    // Register will execute the call after the REGISTER_SUCCESS event
    this.register();
  };



  /**
   * Hangup current call
   *
   */
  this.hangUp = function()
  {
    this._current_call.release();
  };



  /**
   * Inform that a new chat message has arrived. Used to update chat badge
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.onChatMessageArrived = function onChatMessageArrived( success_cb, error_cb )
  {
    // Increase badge number
    try
    {
      this._update_badge();

      if( success_cb )
      {
        success_cb();
      }
    }
    catch( e )
    {
      if( error_cb )
      {
        error_cb( e );
      }
    }
  };



  /**
   * Return softphone object
   * @return {Object}
   */
  this.get_softphone = function()
  {
    return this._softphone;
  };



  /**
   * Return current call object
   * @return {Object}
   */
  this.get_current_call = function()
  {
    return this._current_call;
  };



  /**
   * Registers in SIP server
   */
  this.register = function()
  {
    // Set global reregister failed listener
    this._softphone.Uac.on( 'reregister_failed', this._on_register_error, this );

    // Set sipregister listeners for this login process
    this._softphone.Uac.on( 'register_success', this._on_register_success, this );
    this._softphone.Uac.on( 'register_failed', this._on_register_error, this );

    this._softphone.Uac.login();
  };




  /**
   * Register success handler
   * @private
   */
  this._on_register_success = function()
  {
    this._dom_outgoing_call_wrapper_object.querySelector( '[data-id="message"]' ).innerHTML = 'Llamando...';
    this._dom_outgoing_call_cancel_button.style.display = '';

    this._event_cb( { event: 'register_success' } );
    this._current_call = this._softphone.Uac.create_outgoing_call( this._to_address );

    this._set_call_listeners();
    this._set_default_media_constraints();

    this._current_call.connect( this._settings );
  };



  /**
   * Register error handler
   * @private
   */
  this._on_register_error = function()
  {
    this._dom_outgoing_call_wrapper_object.style.display = 'none';
    this._error_cb( 'register_error', arguments );
    this._destroy_softphone();
  };



  /**
   * Destroy softphone
   * @private
   */
  this._destroy_softphone = function()
  {
    this._softphone.Uac.shutdown();
    this._softphone = null;
  };



  /**
   * Set call event listeners
   * @private
   */
  this._set_call_listeners = function()
  {
    // On call connected
    this._current_call.on( 'connected', function(){ this._fire_call_event( 'call_connected' ); }, this );
    this._current_call.on( 'confirmed', function(){ this._fire_call_event( 'call_confirmed' ); }, this );
    this._current_call.on( 'accepted', function(){ this._fire_call_event( 'call_accepted' ); }, this );
    this._current_call.on( 'ended', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'released', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'declined', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'busy', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'rejected', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'not_found', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'timeout', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'cancel',  function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'cancelled', function(){ this._fire_call_event( 'call_disconnected' ); }, this );
    this._current_call.on( 'failed', function(){ this._fire_call_event( 'call_failed' ); }, this );
  };



  /**
   * Set default media constraints on webrtc
   *
   * @private
   */
  this._set_default_media_constraints = function()
  {
    var rtc_config = this._softphone.Options.getRTCConfig();

    rtc_config.mediaConstraints =
    {
      audio: true,
      video: !this._settings.only_audio
    };

    this._softphone.Options.setRTCConfig( rtc_config );
  };



  /**
   * Fire main event
   *
   * @param {String} event_name
   * @param {Object=} data
   * @private
   */
  this._fire_main_event = function( event_name, data )
  {
    if( this._load_settings.event_cb )
    {
      this._load_settings.event_cb( { event: event_name, data: data } );
    }
  };



  /**
   * Fire call event
   *
   * @param {String} event_name
   * @param {Object=} data
   * @private
   */
  this._fire_call_event = function( event_name, data )
  {
    switch( event_name )
    {
      case 'call_connected':
        this._on_call_connected();
        break;

      case 'call_disconnected':
      case 'call_failed':
        this._on_call_disconnected();
        break;
    }

    this._event_cb( { event: event_name, data: data } );
  };



  /**
   * Check media permissions
   *
   * @param {Object} constraints
   * @param {Function} allowed_cb
   * @param {Function} denied_cb
   */
  this.checkMediaPermissions = function( constraints, allowed_cb, denied_cb )
  {
    new Comm.webrtc.utils.UserMediaChecker(
    {
      constraints: constraints,
      listeners:
      {
        scope: this,
        denied:
        {
          scope: this,
          fn: function()
          {
            denied_cb();
          }
        },
        allowed:
        {
          scope: this,
          fn: function()
          {
            allowed_cb();
          }
        }
      }
    }).start();
  };



  /**
   * Call has been connected
   *
   */
  this._on_call_connected = function()
  {
    if( this._call_connected === true )
    {
      return;
    }

    this._call_connected = true;

    // Show Call UI
    this._dom_incoming_call_wrapper_object.style.display = 'none';
    this._dom_outgoing_call_wrapper_object.style.display = 'none';
    this._dom_call_wrapper_object.style.display = '';

    // Audio / Video call?
    if( this._settings.only_audio )
    {
      this._dom_call_wrapper_object.classList.add( 'audio' );
      this._dom_call_wrapper_object.querySelector( '[data-id="video-call"]' ).style.display = 'none';
      this._dom_call_wrapper_object.querySelector( '[data-id="audio-call"]' ).style.display = '';
    }
    else
    {
      this._dom_call_wrapper_object.classList.remove( 'audio' );
      this._dom_call_wrapper_object.querySelector( '[data-id="audio-call"]' ).style.display = 'none';
      this._dom_call_wrapper_object.querySelector( '[data-id="video-call"]' ).style.display = '';
      // Body background to transparent, and hidden all child
      document.body.style.background = 'transparent';
      let children = document.body.children;
      for(var child of children){
          if(child.nodeName.toLowerCase() !== "script" && child.nodeName.toLowerCase() != "phe-videocall-webrtc"){
              child.style.display = 'none';
          }
      }
      this._show_video_call();
    }

    // Show Video wrapper


    // var time = new Date();
    // this.time = time.getTime();

    // Comm.Log.debug('[sipvideocall-webrtc] _on_call_connected',arguments,call);

  };



  this._show_video_call = function()
  {
    var remote_address = this._current_call.to.get_address();
    var local_address = this._current_call.from.get_address();
	// clear child elements
	this._dom_video_call_video_fullview.innerHTML = '';
	this._dom_video_call_video_subview.innerHTML = '';

    if (!this._inverse_video) {
      this._softphone.MediaMixer.display_on( remote_address, this._dom_video_call_video_fullview, this._softphone.MediaMixer.PIP_OUTER, true );
      this._softphone.MediaMixer.display_on( local_address, this._dom_video_call_video_subview, this._softphone.MediaMixer.PIP_INNER, true );
	} else {
      this._softphone.MediaMixer.display_on( remote_address, this._dom_video_call_video_subview, this._softphone.MediaMixer.PIP_OUTER, true );
      this._softphone.MediaMixer.display_on( local_address, this._dom_video_call_video_fullview, this._softphone.MediaMixer.PIP_INNER, true );
	}

    this._resize_videos();
  };



  /**
   * Resize videos to fit current view
   *
   * @private
   */
  this._resize_videos = function()
  {
    var wrapper = this._dom_call_wrapper_object.querySelector( '.phe-videocall-wrapper' );
    var local = this._dom_call_wrapper_object.querySelector( '.phe-videocall-video.local video' );
    var remote = this._dom_call_wrapper_object.querySelector( '.phe-videocall-video.remote video' );
    var height = wrapper.clientHeight;
    var width = wrapper.clientWidth;

    // We have a 4:3 ratio.
    if( height >= width )
    {
      // Height greater than width
      remote.style.height = height + 'px';
      remote.style.width = ( ( height * 4 ) / 3 ) + 'px';
    }
    else if( width > height && ( height > ( width * 3 / 4 ) ) )
    {
      // Width is not wide enough to cover all screen. So we use height anyways
      remote.style.height = height + 'px';
      remote.style.width = ( ( height * 4 ) / 3 ) + 'px';
    }
    else
    {
      // Width is larger than height
      remote.style.width = width + 'px';
      remote.style.height = ( ( width * 3 ) / 4 ) + 'px';
    }
  }

  this._inverse_video = function()
  {
	this._inverse_video = !this._inverse_video;
	this._show_video_call();
  }


/*
  this._on_call_accepted = function()
  {
    // var time = new Date();
    // this.time = time.getTime();

    Comm.Log.debug('[sipvideocall-webrtc] _on_call_accepted',arguments);
    // this._display_video();
  };*/



  /**
   * Call has been disconnected
   */
  this._on_call_disconnected = function()
  {
    // Restore call UI
    // Body background restore, and show all child
    document.body.style.background = '';
    let children = document.body.children;
    for(var child of children){
        if(child.nodeName.toLowerCase() !== "script" && child.nodeName.toLowerCase() != "phe-videocall-webrtc"){
            child.style.display = '';
        }
    }
    this._dom_incoming_call_wrapper_object.style.display = 'none';
    this._dom_outgoing_call_wrapper_object.style.display = 'none';
    this._dom_call_wrapper_object.style.display = 'none';
    this._dom_outgoing_call_cancel_button.style.display = 'none';
    
    // Stop stream
    if( Comm.webrtc.utils.UserMediaChecker.current_stream )
    {
      Comm.webrtc.utils.UserMediaChecker.stop_stream( Comm.webrtc.utils.UserMediaChecker.current_stream );
    }



    if( this._call_connected === false )
    {
      return;
    }

    if( this._current_call )
    {
      this._current_call.release();
      this._current_call = null;
    }

    this._call_connected = false;

    // Stop videos
    this._softphone.MediaMixer.undisplay();

    // var time = new Date();
    // time = time.getTime() - this.time;

    // Comm.Log.debug('[sipvideocall-webrtc] _on_call_disconnected',arguments);
    // Comm.Log.debug('[sipvideocall-webrtc] time passed since connected or accepted: ' + (time/1000) );

    // if( this._div )
    // {
    //   this._div.innerHTML = '';
    // }

    // this.fire( 'call_finished' );
  };



  this._toggle_audio = function()
  {
    this._micro_enabled = !this._micro_enabled;

    if( this._micro_enabled )
    {
      this._current_call.unmute();
      this._dom_toggle_audio.querySelector( '[data-id="micro-disabled"]' ).style.display = 'none';
      this._dom_toggle_audio.querySelector( '[data-id="micro-enabled"]' ).style.display = '';
      this._dom_toggle_audio.classList.remove( 'phe-bg-orange' );
    }
    else
    {
      this._current_call.mute();
      this._dom_toggle_audio.querySelector( '[data-id="micro-enabled"]' ).style.display = 'none';
      this._dom_toggle_audio.querySelector( '[data-id="micro-disabled"]' ).style.display = '';
      this._dom_toggle_audio.classList.add( 'phe-bg-orange' );
    }
  };



  this._toggle_video = function()
  {
    this._camera_enabled = !this._camera_enabled;

    if( this._camera_enabled )
    {
      this._current_call.add_video();
      this._dom_local_video.classList.remove( 'no-camera' );
      this._dom_toggle_video.querySelector( '[data-id="camera-disabled"]' ).style.display = 'none';
      this._dom_toggle_video.querySelector( '[data-id="camera-enabled"]' ).style.display = '';
      this._dom_toggle_video.classList.remove( 'phe-bg-orange' );
    }
    else
    {
      this._current_call.remove_video();
      this._dom_local_video.classList.add( 'no-camera' );
      this._dom_toggle_video.querySelector( '[data-id="camera-enabled"]' ).style.display = 'none';
      this._dom_toggle_video.querySelector( '[data-id="camera-disabled"]' ).style.display = '';
      this._dom_toggle_video.classList.add( 'phe-bg-orange' );
    }
  };



  /**
   * Toggle user camera front/back
   *
   * @TODO implement camera streaming change
   * @TODO add different icons in the UI
   */
  this._toggle_camera = function()
  {
    this._front_camera = !this._front_camera;

    if( this._front_camera )
    {
      this._dom_toggle_camera.classList.remove( 'phe-bg-orange' );
    }
    else
    {
      this._dom_toggle_camera.classList.add( 'phe-bg-orange' );
    }
  };



  /**
   * Update corresponding badge number.
   * It hides the badge if number = 0.
   *
   * @param {Number=} number
   */
  this._update_badge = function( number )
  {
    var obj = ( this._settings.only_audio ) ? this._dom_messages_audio_badge : this._dom_messages_video_badge;

    if( !isNaN( number ) )
    {
      obj.innerHTML = number;
    }
    else if( !number && this._fullscreen )
    {
      // We only change badge number if we're in fullscreen mode (chat is not visible)
      obj.innerHTML = ( parseInt( obj.innerHTML ) || 0 ) + 1;
    }

    // Do not display badge if the number is 0.
    obj.style.display = ( number === 0 ) ? 'none' : '';
  };



  this._can_toggle_camera = function()
  {
    // Get cameras available
    var cameras = this._softphone.MediaDevices.getVideoInputDevices();

    return ( cameras.length > 1 );
  };


/*
  this._on_call_failed = function()
  {
    Comm.Log.debug('[sipvideocall-webrtc] _on_call_failed',arguments);
  };



  this._display_video = function()
  {
    Comm.Log.debug('[sipvideocall-webrtc] _display_video');
    this._div.innerHTML = '';
    this._softphone.MediaMixer.display_on( this._current_call.from.get_address(), this._div, this._softphone.MediaMixer.PIP_INNER, true );
    this._softphone.MediaMixer.display_on( this._current_call.to.get_address(), this._div, this._softphone.MediaMixer.PIP_OUTER, true );
  }



  this.set_div = function( div )
  {
    this._div = div;
  }



  this.accept_call = function()
  {
    this._current_call.accept();
  };



  this.reject_call = function()
  {
    this._current_call.decline();
  };



  this.end_call = function()
  {

    if( this._div )
    {
      this._div.innerHTML = '';
    }

    if( this._current_call )
    {
      this._current_call.release();
      this._current_call = null;
    }
  };




  this.unregister = function()
  {
    this._softphone.Uac.shutdown();
  };*/
}



if( typeof module !== 'undefined' && module.exports )
{
  module.exports = SipVideoCallWebRTC;
}