package com.phemium.sipvideocall;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Rect;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import com.phemium.sipvideocall.constant.Constant;
import com.phemium.sipvideocall.data.CallData;
import com.phemium.sipvideocall.listener.CallManagerListener;

public class SipVideoCall extends CordovaPlugin implements CallManagerListener {

  private final int ERROR_DATA = 0;

  private final int CALL_REQUEST_CODE = 1;
  private final String ACTION_CALL = "call";
  private final String ACTION_INCOMING_CALL = "incomingCall";
  private final String ACTION_REOPEN = "reOpen";
  private final String ACTION_HANGUP = "hangUp";
  private final String ACTION_MESSAGE_ARRIVED = "onChatMessageArrived";
  private final String ACTION_CHECK_PERMISSION = "checkMediaPermissions";
  private final String ACTION_CHECK_NETWORK = "checkNetworkStatus";
  private final String ACTION_SET_OVERLAY_BOUNDARY = "setOverlayBoundary";
  private final String ACTION_RECALCULATE_OVERLAY_ORIENTATION = "recalculateOverlayOrientation";
  private CallbackContext callback;
  private CallbackContext mediaPermissionsCallback;
  private CallManager mCallManager;
  private CallData mCallData;

  private boolean minimized_video = false;

  private final static String TAG = "SipVideoCall";

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callback) {

    Log.e(TAG, "execute called:" + action);

    if (action.equals(this.ACTION_CALL) || action.equals(this.ACTION_INCOMING_CALL) || action.equals(this.ACTION_CHECK_NETWORK)) {
        this.callback = callback;
      mCallManager = new CallManager();
      mCallData = new CallData();
      try {
        String callToAddress = args.getString(0);
        mCallData.setToAddress(callToAddress);

        JSONObject credentials = args.getJSONObject(1);
        mCallData.setCredentialValues(credentials);

        JSONObject settings = args.getJSONObject(2);
        mCallData.setCallSettingValues(settings);

        JSONObject guiSettings = args.getJSONObject(3);
        mCallData.setGUISettingValues(guiSettings);

        JSONObject extraSettings = args.getJSONObject(4);
        mCallData.setExtraSettingValues(extraSettings);

      } catch (JSONException e) {
        callback.error(this.ERROR_DATA);
        return false;
      }
      if (action.equals(this.ACTION_CALL)) {
        mCallManager.startCall(mCallData, this, this);
      } else if (action.equals(this.ACTION_INCOMING_CALL)){
//        scheduleLocalNotification();
        mCallManager.bIncoming = true;
        mCallManager.startCall(mCallData, this, this);
      }else if (action.equals(this.ACTION_CHECK_NETWORK)){
        if(mCallManager != null){
          mCallManager.checkNetworkStatus(mCallData, this, this);
        }
      }
    }

    if (action.equals(this.ACTION_REOPEN)) {
//        this.callback = callback;
      minimized_video = false;
      if(mCallManager != null){
        mCallManager.reOpen();
      }
    }
    if (action.equals(this.ACTION_HANGUP)) {
      if(mCallManager != null){
        mCallManager.hangUp();
      }
    }
    if (action.equals(this.ACTION_MESSAGE_ARRIVED)) {
      if(mCallManager != null){
        mCallManager.onChatMessageArrived();
      }
    }

    if (action.equals(this.ACTION_SET_OVERLAY_BOUNDARY)) {
      if(mCallManager != null){
        Rect rect = new Rect();
        try {
          JSONObject object = args.getJSONObject(0);
          rect.bottom = object.getInt("bottom");
          rect.left = object.getInt("left");
          rect.right = object.getInt("right");
          rect.top = object.getInt("top");
        }catch (Exception e){

        }
        mCallManager.setOverlayBoundary(rect);
      }
    }

    if (action.equals(this.ACTION_RECALCULATE_OVERLAY_ORIENTATION)) {
      if(mCallManager != null){
        mCallManager.changeOrientation();
      }
    }

    if (action.equals(this.ACTION_CHECK_PERMISSION)) {
      mediaPermissionsCallback = callback;
      try {
        JSONObject permission = args.getJSONObject(0);
        Boolean audioPermission = permission.getBoolean("audio");
        Boolean videoPermission = permission.getBoolean("video");
        Log.e(TAG, "Permission: " + audioPermission.toString() + ":" + videoPermission.toString() );
//        mCallData.permission = permission;
        checkPermissions(videoPermission);
      } catch (JSONException e) {
        e.printStackTrace();
      }

    }
    return true;
  }

  @Override
  public void onNewIntent(Intent intent) {
    super.onNewIntent(intent);

    Log.e(TAG, "SipVideoCall onNewIntent called.");
    checkIntent(intent);
  }

  @Override
  protected void pluginInitialize() {
    super.pluginInitialize();
    Log.e(TAG, "SipVideoCall plugin initialized.");

    Intent intent = cordova.getActivity().getIntent();
    checkIntent(intent);
  }

  private void checkIntent(Intent intent) {
    int onlyAudio = intent.getIntExtra("onlyAudio", -1);
    if (onlyAudio == -1) {
      return;
    }

    String username = intent.getStringExtra("username");
    String password = intent.getStringExtra("password");
    String proxy = intent.getStringExtra("proxy");
    String to = intent.getStringExtra("to");
    String consultantName = intent.getStringExtra("consultantName");

    CallData callData = new CallData();
    callData.username = username;
    callData.password = password;
    callData.proxy = proxy;
    callData.consultantName = consultantName;
    callData.toAddress = to;
    callData.onlyAudio = onlyAudio==1?true:false;
    callData.checkGUIValues();

    mCallManager = new CallManager();
    mCallManager.bIncoming = true;
    mCallManager.startCall(callData, this, this);
  }

  @Override
  public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
    Log.e(TAG, "onRequestPermissionResult function called.");
    if (requestCode == Constant.PERMISSION_CHECK_MEDIA_BEFORE_CALL){
      if (mCallManager != null) {
        mCallManager.onRequestPermissionResult(requestCode, permissions, grantResults);
      }
      return;
    }
    for (int i = 0; i < grantResults.length; i++) {
      if (grantResults[i] == PackageManager.PERMISSION_DENIED) {
        PluginResult result = new PluginResult(PluginResult.Status.ERROR, -1);
        mediaPermissionsCallback.sendPluginResult(result);
        return;
      }
    }

    PluginResult result = new PluginResult(PluginResult.Status.OK);
    if (mediaPermissionsCallback != null){
      mediaPermissionsCallback.sendPluginResult(result);
    }

  }

  @Override
  public void onCallReleased(String workflow, String logPath) {
      try {
        Log.e(TAG, "Call Released");
        JSONObject jsonObject = new JSONObject();
        try {
          jsonObject.put("error_code", 0);
          jsonObject.put("workflow", workflow);
          jsonObject.put("event", "released");
          jsonObject.put("log_path", logPath);
        } catch (JSONException e) {
          e.printStackTrace();
        }
        PluginResult result = new PluginResult(PluginResult.Status.OK,  jsonObject);
        result.setKeepCallback(false);
        callback.sendPluginResult(result);
      }catch (Exception e){

      }
  }

  @Override
  public void onThrowError(int errorCode, String workflow, String logPath) {
      try{
        Log.e(TAG, "Call ended with error");
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("error_code", errorCode);
        jsonObject.put("workflow", workflow);
        jsonObject.put("log_path", logPath);
        PluginResult result = new PluginResult(PluginResult.Status.ERROR, jsonObject);
        callback.sendPluginResult(result);
      }catch (Exception e){
      }
  }

  @Override
  public void onEventComeUp(int eventCode) {
    String eventString = "";
    switch (eventCode){
      case Constant.CALL_EVENT_MICRO_MUTED:
        eventString = "microMuted";
        break;
      case Constant.CALL_EVENT_MICRO_UNMUTED:
        eventString = "microUnmuted";
        break;
      case Constant.CALL_EVENT_CAMERA_MUTED:
        eventString = "cameraMuted";
        break;
      case Constant.CALL_EVENT_CAMERA_UNMUTED:
        eventString = "cameraUnmuted";
        break;
      case Constant.CALL_EVENT_MINIMIZE_VIDEO:
        eventString = "minimized";
        break;
      case Constant.CALL_EVENT_SEND_QUALITY:

        break;
    }

    JSONObject jsonObject = new JSONObject();
    try {
      jsonObject.put("error_code", 0);
      jsonObject.put("workflow", "");
      jsonObject.put("event", eventString);
    } catch (JSONException e) {
      e.printStackTrace();
    }

    PluginResult result = new PluginResult(PluginResult.Status.OK, jsonObject);
    result.setKeepCallback(true);
    callback.sendPluginResult(result);
  }

    @Override
    public void onEventMinimized(int duration) {
        minimized_video = true;
        String eventString = "minimized";
        JSONObject jsonObject = new JSONObject();
        try {
          jsonObject.put("error_code", 0);
          jsonObject.put("workflow", "");
          jsonObject.put("event", eventString + ":" +  duration);
        } catch (JSONException e) {
          e.printStackTrace();
        }
        PluginResult result = new PluginResult(PluginResult.Status.OK, jsonObject );
          result.setKeepCallback(true);
          callback.sendPluginResult(result);
    }

  @Override
  public void onEventSendQuality(String quality) {
    String eventString = "sendQuality";
    JSONObject jsonObject = new JSONObject();
    try {
      jsonObject.put("error_code", 0);
      jsonObject.put("workflow", "");
      jsonObject.put("event", eventString);
      jsonObject.put("quality", quality);
    } catch (JSONException e) {
      e.printStackTrace();
    }
    PluginResult result = new PluginResult(PluginResult.Status.OK, jsonObject);
    result.setKeepCallback(true);
    callback.sendPluginResult(result);
  }

  @Override
  public void onCheckReleased(boolean registable, String networkType, float bandwidth) {
    JSONObject jsonObject = new JSONObject();

    try {
      jsonObject.put("registry_availiabity", registable);
      jsonObject.put("coverage", networkType);
      jsonObject.put("bandwidth", bandwidth);
    } catch (JSONException e) {
      e.printStackTrace();
    }
    PluginResult result = new PluginResult(PluginResult.Status.OK, jsonObject);
    callback.sendPluginResult(result);
  }

//    private void showAlert(final int errorCode,final String workflow) {
//        cordova.getActivity().runOnUiThread(new Runnable() {
//          @Override
//          public void run() {
//                String [] errorMessage = {"Success", "Microphone Permission Denied", "Registration Failed",
//                                    "Audio/Video Establishment Failed", "Callee is Busy" , "Callee is declined", "Callee Not Found",
//                                    "Init Timeout", "Ringing Timeout", "Outgoing SIP Address is not exist on Server", "No Internet", "Network Changed"};
//                String alertMessage = "";
//                if (errorCode == 0){
//                    alertMessage = "Success: \n Log: " + workflow;
//                }else{
//                    alertMessage = "error code:" + errorCode +" \n " + errorMessage[errorCode] + " \n Log: " + workflow;
//                }
//                new AlertDialog.Builder(cordova.getActivity())
//                        .setTitle("Alert")
//                        .setMessage(alertMessage)
//                        .setPositiveButton("Ok", new DialogInterface.OnClickListener() {
//                          @Override
//                          public void onClick(DialogInterface dialogInterface, int i) {
//                            dialogInterface.dismiss();
//                          }
//                        })
//                        .show();
//          }
//        });
//      }

  private void checkNetworkStatus(){

  }

  private void checkPermissions(boolean videoPermission) {
    Log.e(TAG, "checkPermissions called.");
    boolean checkCameraPermission = videoPermission;
    if (!cordova.hasPermission(Manifest.permission.RECORD_AUDIO)) {
      Log.e(TAG, "Hasn't Record Audio Permission.");
      if (!cordova.hasPermission(Manifest.permission.CAMERA) && checkCameraPermission) {
        cordova.requestPermissions(this, Constant.PERMISSION_CHECK_MEDIA,
                new String[] { Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO });
      } else {
        cordova.requestPermission(this, Constant.PERMISSION_CHECK_MEDIA, Manifest.permission.RECORD_AUDIO);
      }
    } else {
      Log.e(TAG, "Has Record Audio Permission.");
      if (!cordova.hasPermission(Manifest.permission.CAMERA) && checkCameraPermission) {
        cordova.requestPermissions(this, Constant.PERMISSION_CHECK_MEDIA, new String[] { Manifest.permission.CAMERA });
      } else {
        PluginResult result = new PluginResult(PluginResult.Status.OK);
        mediaPermissionsCallback.sendPluginResult(result);
      }
    }
  }

  private void scheduleLocalNotification() {
    Intent resultIntent = new Intent(cordova.getActivity(), cordova.getActivity().getClass());
    resultIntent.putExtra("onlyAudio", mCallData.onlyAudio?1:0);
    resultIntent.putExtra("username", mCallData.username);
    resultIntent.putExtra("password", mCallData.password);
    resultIntent.putExtra("proxy", mCallData.proxy);
    resultIntent.putExtra("consultantName", mCallData.consultantName);
    resultIntent.putExtra("to", mCallData.toAddress);

    PendingIntent pendingIntent = PendingIntent.getActivity(cordova.getActivity(), 0, resultIntent, PendingIntent.FLAG_UPDATE_CURRENT);

    NotificationCompat.Builder mBuilder =
            new NotificationCompat.Builder(cordova.getActivity())
                    .setContentTitle("Notification")
                    .setContentText("Simulate Incoming " + ((mCallData.onlyAudio==true)?"Audio":"Video") + " Call")
                    .setSmallIcon(cordova.getActivity().getApplicationContext().getResources().getIdentifier("screen", "drawable", cordova.getActivity().getApplicationContext().getPackageName()))
                    .setContentIntent(pendingIntent);

    Notification notification = mBuilder.build();
    notification.defaults |= Notification.DEFAULT_SOUND;

    NotificationManager mNotificationManager =
            (NotificationManager) cordova.getActivity().getSystemService(Context.NOTIFICATION_SERVICE);

    // mId allows you to update the notification later on.
    mNotificationManager.notify(Constant.VIDEO_CALL_NOTIFICATION_ID, notification);
  }
}