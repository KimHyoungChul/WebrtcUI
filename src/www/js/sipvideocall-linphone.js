/**
 * SipVideoCall plugin
 */
var SipVideoCallLinphone = function()
{

  /**
   * Executes a native method
   * It is used also to log each execution.
   *
   * @param {String} method
   * @param {Array} params
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   * @private
   */
  var _exec = function( method, params, success_cb, error_cb )
  {
    console.log( '[SipVideoCall._exec] Execute', method, params );
    cordova.exec( success_cb || function () { }, error_cb || function () { }, 'SipVideoCall', method, params || [] );
  };



  /**
   * Make call for Incoming Call or Outgoing Call
   *
   * @param {String} address
   * @param {Object} credentials
   * @param {Object} settings
   * @param {Object} gui_settings
   * @param {Object} extra_settings
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   * @private
   */
  var _makeCall = function( address, credentials, settings, config, success_cb, error_cb, event_cb, bIncoming )
  {
    var callFunction = 'call';

    if( bIncoming )
    {
      callFunction = 'incomingCall';
    }

    var custom_credentials = _define_custom_credentials( credentials );
    settings.transport_mode = custom_credentials.transport_mode;
    settings.download_bandwidth = ( isNaN( parseInt( settings.download_bandwidth ) ) ) ? -1 : settings.download_bandwidth;
    settings.upload_bandwidth = ( isNaN( parseInt( settings.upload_bandwidth ) ) ) ? -1 : settings.upload_bandwidth;
    settings.framerate = ( isNaN( parseInt( settings.framerate ) ) ) ? -1 : settings.framerate;

    var gui_settings = config.gui_settings;
    var extra_settings = config.extra_settings;
    _exec( callFunction, [address, custom_credentials, settings, gui_settings, extra_settings], success_cb, error_cb );
  };



  /**
   * Load Plugin
   *
   */
  this.load = function( load_settings )
  {
    _exec( 'load', [ load_settings ], null, null );
    if( load_settings.event_cb )
    {
      load_settings.event_cb( { event: 'comm_loaded', data: null } );
    }
  };



  /**
   * Set Overlay Boundary for overlay video movement
   *
   * @param {String} boundaries
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.setOverlayBoundary = function( boundaries, success_cb, error_cb )
  {
    _exec( 'setOverlayBoundary', [ boundaries ], success_cb, error_cb);
  };



  /**
   * Start a new call with the given address
   *
   * @param {String} address
   * @param {Object} credentials
   * @param {Object} settings
   * @param {Object} gui_settings
   * @param {Object} extra_settings
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.call = function( address, credentials, settings, config, success_cb, error_cb, event_cb )
  {
    _makeCall( address, credentials, settings, config, success_cb, error_cb, event_cb, false );
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
    _makeCall( address, credentials, settings, config, success_cb, error_cb, event_cb, true );
  };



  /**
   * Check Network Status with the given address
   *
   * @param {String} address
   * @param {Object} credentials
   * @param {Object} settings
   * @param {Object} gui_settings
   * @param {Object} extra_settings
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.checkNetworkStatus = function( address, credentials, settings, gui_settings, extra_settings, success_cb, error_cb )
  {
    var custom_credentials = _define_custom_credentials( credentials );

    settings.transport_mode = custom_credentials.transport_mode;
    settings.download_bandwidth = ( isNaN( parseInt( settings.download_bandwidth ) ) ) ? -1 : settings.download_bandwidth;
    settings.upload_bandwidth = ( isNaN( parseInt( settings.upload_bandwidth ) ) ) ? -1 : settings.upload_bandwidth;
    settings.framerate = ( isNaN( parseInt( settings.framerate ) ) ) ? -1 : settings.framerate;

    _exec( 'checkNetworkStatus', [ address, custom_credentials, settings, gui_settings, extra_settings ], success_cb, error_cb );
  };



  /**
   * Reopen call window
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.reOpen = function( success_cb, error_cb )
  {
    _exec( 'reOpen', null, success_cb, error_cb );
  };



  /**
   * Hangup current call
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.hangUp = function( success_cb, error_cb )
  {
    _exec( 'hangUp', null, success_cb, error_cb );
  };



  /**
   * Inform that a new chat message has arrived. Used to update chat badge
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.onChatMessageArrived = function onChatMessageArrived( success_cb, error_cb )
  {
    _exec( 'onChatMessageArrived', null, success_cb, error_cb );
  };



  /**
   * Check Media Permissions
   *
   * @param {String} calltype
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.checkMediaPermissions = function( calltype, success_cb, error_cb )
  {
    _exec( 'checkMediaPermissions', [ calltype ], success_cb, error_cb );
  };



  /**
   * Recalculate Overlay Orientation
   *
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.recalculateOverlayOrientation = function( success_cb, error_cb )
  {
    _exec( 'recalculateOverlayOrientation', null, success_cb, error_cb );
  };

};



/** Auxiliary private functions */

/**
 * Define credentials
 *
 * @param {Object} credentials
 */
function _define_custom_credentials( credentials )
{
  var custom_credentials = {};

  // 1: Sip Proxy: When sip_proxy_with_transport is declared, custom_credentials and extra_settings.transport_mode are build splitting its information
  if( credentials.sip_proxy_with_transport )
  {
    var sip_proxy = credentials.sip_proxy_with_transport.split( ":" )[0];
    var rest = credentials.sip_proxy_with_transport.split( ":" )[1];
    var sip_port = ( rest ) ? rest.split( "?" )[0] : "443";
    rest = rest.split( "?" )[1];
    var sip_transport = ( rest && rest.split( "=" )[0] == "transport" && rest.split( "=" )[1] ) ? rest.split( "=" )[1] : "tls";

    custom_credentials =
    {
      username: credentials.sip_address.split( '@', 1) [0].split( ':' )[1],
      password: credentials.sip_password,
      domain: credentials.sip_realm,
      proxy: sip_proxy + ":" + sip_port,
      address: credentials.sip_address,
      transport_mode: sip_transport
    };
  }
  else
  {
    custom_credentials =
    {
      username: credentials.sip_address.split( '@', 1 )[0].split( ':' )[1],
      password: credentials.sip_password,
      domain: credentials.sip_realm,
      proxy: credentials.sip_proxy,
      address: credentials.sip_address,
      transport_mode: 'udp'
    };
  }

  // 2: TurnServers: Workaround while we adapt plugins to multiple turn servers
  if( !credentials.turn_servers || credentials.turn_servers.length == 0 )
  {
    // If turn_servers (array) is defined, it is used rather turn_server0 and/or turn_server1
    if( credentials.turn_server0 && credentials.turn_server0.length > 0 )
    {
      custom_credentials.turnServer0 = credentials.turn_server0;
      custom_credentials.turnDomain0 = credentials.turn_realm0;
      custom_credentials.turnUsername0 = credentials.turn_username0;
      custom_credentials.turnPassword0 = credentials.turn_password0;
    }
    if( credentials.turn_server1 && credentials.turn_server1.length > 0 )
    {
      custom_credentials.turnServer1 = credentials.turn_server1;
      custom_credentials.turnDomain1 = credentials.turn_realm1;
      custom_credentials.turnUsername1 = credentials.turn_username1;
      custom_credentials.turnPassword1 = credentials.turn_password1;
    }
  }
  else
  {
    if( credentials.turn_servers.length > 0 )
    {
      custom_credentials.turnServer0 = credentials.turn_servers[0].address;
      custom_credentials.turnDomain0 = credentials.turn_servers[0].realm;
      custom_credentials.turnUsername0 = credentials.turn_servers[0].username;
      custom_credentials.turnPassword0 = credentials.turn_servers[0].password;
    }
    if( credentials.turn_servers.length > 1 )
    {
      custom_credentials.turnServer1 = credentials.turn_servers[1].address;
      custom_credentials.turnDomain1 = credentials.turn_servers[1].realm;
      custom_credentials.turnUsername1 = credentials.turn_servers[1].username;
      custom_credentials.turnPassword1 = credentials.turn_servers[1].password;
    }
  }

  return custom_credentials;
}


// Export SipVideoCall module
if( typeof module !== 'undefined' && module.exports )
{
  module.exports = SipVideoCallLinphone;
}

