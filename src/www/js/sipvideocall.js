/**
 *
 * @method load
 * @method call
 * @method incomingCall
 * @method hangUp
 * @method reOpen
 * @method checkMediaPermissions
 * @method setOverlayBoundary
 * @method checkNetworkStatus
 * @method onChatMessageArrived
 * @method recalculateOverlayOrientation
 */
function SipVideoCall()
{
  _obj = {};


  /**
   * Loads plugin object with the given settings
   *
   * @param {Object} load_settings
   */
  this.load = function( load_settings )
  {
    var use_webrtc = load_settings.use_webrtc;
    var class_name = use_webrtc ? SipVideoCallWebRTC : SipVideoCallLinphone;
    this._obj = new class_name();
    this._obj.load( load_settings );
  };



  /**
   * Makes a call
   *
   * @param {String} address SIP address to call
   * @param {Object} credentials Callee credentials
   * @param {Object} settings Call settings
   * @param {Object} config Call config
   * @param {Function=} success_cb Call success callback function
   * @param {Function=} error_cb Call error callback function
   * @param {Function=} event_cb Call event callback function
   */
  this.call = function( address, credentials, settings, config, success_cb, error_cb, event_cb )
  {
    this._obj.call( address, credentials, settings, config, success_cb, error_cb, event_cb );
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
    this._obj.setOverlayBoundary( boundaries, success_cb, error_cb );
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
    this._obj.incomingCall( address, credentials, settings, config, success_cb, error_cb, event_cb );
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
    this._obj.checkNetworkStatus( address, credentials, settings, gui_settings, extra_settings, success_cb, error_cb );
  };



  /**
   * Reopen call window
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.reOpen = function( success_cb, error_cb )
  {
    this._obj.reOpen( success_cb, error_cb );
  };



  /**
   * Hangup current call
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.hangUp = function( success_cb, error_cb )
  {
    this._obj.hangUp( success_cb, error_cb );
  };



  /**
   * Inform that a new chat message has arrived. Used to update chat badge
   *
   * @param {Function} success_cb
   * @param {Function} error_cb
   */
  this.onChatMessageArrived = function( success_cb, error_cb )
  {
    this._obj.onChatMessageArrived( success_cb, error_cb );
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
    this._obj.checkMediaPermissions( calltype, success_cb, error_cb );
  };



  /**
   * Recalculate Overlay Orientation
   *
   * @param {Function=} success_cb
   * @param {Function=} error_cb
   */
  this.recalculateOverlayOrientation = function( success_cb, error_cb )
  {
    this._obj.recalculateOverlayOrientation( success_cb, error_cb );
  };
}

if( typeof module !== 'undefined' && module.exports )
{
  module.exports = SipVideoCall;
}


window.SipVideoCall = SipVideoCall;
window.JsSIP = JsSIP;