package com.phemium.sipvideocall;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Rect;
import android.util.Log;

import com.phemium.sipvideocall.constant.Constant;
import com.phemium.sipvideocall.data.CallData;
import com.phemium.sipvideocall.data.LanguageResource;
import com.phemium.sipvideocall.listener.BandwidthListener;
import com.phemium.sipvideocall.listener.CallManagerListener;
import com.phemium.sipvideocall.listener.LinphoneManagerListener;
import org.apache.cordova.CordovaPlugin;

import java.util.Timer;
import java.util.TimerTask;

import static com.phemium.sipvideocall.constant.Constant.SWIPE_BOTTOM;
import static com.phemium.sipvideocall.constant.Constant.SWIPE_RIGHT;

/**
 * Created by Tom on 1/5/2017.
 */

public class CallManager extends Object implements LinphoneManagerListener, BandwidthListener {

    public CallData mCallData;
    public CallManagerListener mCallManagerListener;
    public CordovaPlugin mCordovaPlugin;

    private Context cordovaContext;
    private LinphoneManager mLinphoneManager;
    private Boolean bCameraPermissionAllowed = true;
    private final static String TAG = "CallManager";
    private static boolean isCalling = false;
    private boolean isCallConnected = false;
    public boolean bIncoming = false;
    public String logPath = "";
    private boolean bRetry = false;
    private boolean checkNetwork = false;
    private boolean registable = true;

    public void startCall(CallData callData, CallManagerListener listener, CordovaPlugin cordovaPlugin) {
        if (CallManager.isCalling){
            Log.e(TAG, "Call is already started.");
            return;
        }
        Log.e(TAG, "Start Call");
        this.mCallData = callData;
        this.mCallManagerListener = listener;
        this.mCordovaPlugin = cordovaPlugin;
        this.cordovaContext = cordovaPlugin.cordova.getActivity();
        LanguageResource.getInstance().readFromJsonFile(mCallData.language, cordovaContext);
        bRetry = false;
        checkNetwork = false;
        checkPermissions();
//        initializeCall();
    }

    public void checkNetworkStatus(CallData callData, CallManagerListener listener, CordovaPlugin cordovaPlugin){
        this.mCallData = callData;
        this.mCallManagerListener = listener;
        this.mCordovaPlugin = cordovaPlugin;
        this.cordovaContext = cordovaPlugin.cordova.getActivity();
        LanguageResource.getInstance().readFromJsonFile(mCallData.language, cordovaContext);

        checkNetwork = true;
        Log.e(TAG, "Check Network");
        initializeCall();
    }

    public void reOpen() {
        mLinphoneManager.reOpen();
    }

    public void hangUp() {
        mLinphoneManager.hangup();
    }

    public void onChatMessageArrived() {
        mLinphoneManager.onChatMessageArrived();
    }

    public void setOverlayBoundary(Rect newRect) {
        mLinphoneManager.setOverlayBoundary(newRect);
    }

    public void changeOrientation(){
        mLinphoneManager.changeOrientation();
    }

    private void checkPermissions() {
        Log.e(TAG, "checkPermissions called.");
        if (mCordovaPlugin != null) {
            if (!mCordovaPlugin.cordova.hasPermission(Manifest.permission.RECORD_AUDIO)) {
                Log.e(TAG, "Hasn't Record Audio Permission.");
                if (!mCordovaPlugin.cordova.hasPermission(Manifest.permission.CAMERA)) {
                    mCordovaPlugin.cordova.requestPermissions(mCordovaPlugin, Constant.PERMISSION_CHECK_MEDIA_BEFORE_CALL, new String[]{Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO});
                } else {
                    mCordovaPlugin.cordova.requestPermission(mCordovaPlugin, Constant.PERMISSION_CHECK_MEDIA_BEFORE_CALL, Manifest.permission.RECORD_AUDIO);
                }
            } else {
                Log.e(TAG, "Has Record Audio Permission.");
                if (!mCordovaPlugin.cordova.hasPermission(Manifest.permission.CAMERA)) {
                    bCameraPermissionAllowed = false;
                } else {
                    bCameraPermissionAllowed = true;
                }
                initializeCall();
            }
        } else {
            initializeCall();
        }
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == Constant.PERMISSION_CHECK_MEDIA_BEFORE_CALL) {
            if (grantResults.length <= 0) {
                onCallFailed(Constant.CALL_RESULT_ERROR_RECORD_PERMISSION_NOT_ALLOWED , "Record Permission Not Allowed"); // requesting permission is interrupted by the user
                return;
            }
            int i = Utils.indexOfStringArray(permissions, Manifest.permission.RECORD_AUDIO);
            if (i > 0) {
                if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                    int j = Utils.indexOfStringArray(permissions, Manifest.permission.CAMERA);
                    if (j > 0) {
                        if (grantResults[j] == PackageManager.PERMISSION_GRANTED) {
                            bCameraPermissionAllowed = true;
                        } else {
                            bCameraPermissionAllowed = false;
                        }
                    } else {
                        bCameraPermissionAllowed = true;
                    }
                    initializeCall();

                } else {
                    onCallFailed(Constant.CALL_RESULT_ERROR_RECORD_PERMISSION_NOT_ALLOWED, "Record Permission Not Allowed"); // microphone permission not allowed.
                }
            }
        }
    }

    private boolean checkAndroidVersion() {
        return (android.os.Build.VERSION.SDK_INT > android.os.Build.VERSION_CODES.LOLLIPOP_MR1);
    }

    public void initializeCall() {
        isCallConnected = false;
        initializeLinphone();
        configureSettings();
        mLinphoneManager.bIncomingCall = bIncoming;
        mLinphoneManager.badgeNum = 0;
        bIncoming = true;   // When Call retry, shows connecting screen.

        mLinphoneManager.setCheckNetwork(checkNetwork);
        mLinphoneManager.doRegister();
    }

    private void initializeLinphone() {
        LinphoneManager linphoneManager = LinphoneManager.getInstance();
        mLinphoneManager = linphoneManager;
        mLinphoneManager.callData = mCallData;
        if (!bRetry) {
            mLinphoneManager.logsStatus = "";
            mLinphoneManager.connecting_failed_cnt = 0;
        }
        mLinphoneManager.startLibLinphone(cordovaContext, this);
    }

    private void configureSettings() {
        mLinphoneManager.bCameraPermissionAllowed = bCameraPermissionAllowed;
        mLinphoneManager.clearAuthInfoAndProxyConfig();
        mLinphoneManager.enableLogCollection(mCallData.logEnable);
        mLinphoneManager.setProxy();
        mLinphoneManager.setTurnSetting();
        mLinphoneManager.setUser();
        mLinphoneManager.setCallQualityParams();
        mLinphoneManager.setTransportValue();
        mLinphoneManager.setVideoSize();
    }

    @Override
    public void onRegisterSucceeded() {
        Log.e(TAG, "Register Success");
        if (checkNetwork){
            registable = true;
//            mLinphoneManager.doUnRegister();
            NetworkManager.getBandwidth(cordovaContext, this);
            return;
        }
        if (!isCallConnected){
            isCallConnected = true;
            Log.e(TAG, "Call Connected");

            Timer callStartTimer = new Timer();
            callStartTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    if (!mCallData.onlyAudio) {
                        mLinphoneManager.call(mCallData.toAddress);
                    } else {
                        mLinphoneManager.audioCall(mCallData.toAddress);
                    }
                }
            }, 2500);
        }
    }

    @Override
    public void onRegisterFailed(String workflow) {
        Log.e(TAG, "Register Failed");
        if (checkNetwork){
            registable = false;
            NetworkManager.getBandwidth(cordovaContext, this);
            return;
        }
    }

    @Override
    public void onCallFailed(int code , String workflow) {

        if (mCallManagerListener != null) {
//            mLinphoneManager.destroyLibLinphone();
            Utils.insertCallLog(cordovaContext, mCallData.consultantName, mLinphoneManager.bIncomingCall, mLinphoneManager.nCallDuration);
            mCallManagerListener.onThrowError(code, workflow, mLinphoneManager.logPath);

            mLinphoneManager.sendLinphoneDebug();
        }
    }

    @Override
    public void onCallReleased(String workflow) {
        mLinphoneManager.badgeNum = 0;
        mLinphoneManager.swipeHState = SWIPE_BOTTOM;
        mLinphoneManager.swipeWState = SWIPE_RIGHT;

        if (mCallManagerListener != null) {

//            mLinphoneManager.destroyLibLinphone();
            Utils.insertCallLog(cordovaContext, mCallData.consultantName,  mLinphoneManager.bIncomingCall, mLinphoneManager.nCallDuration);
            mCallManagerListener.onCallReleased(workflow , mLinphoneManager.logPath);

            mLinphoneManager.sendLinphoneDebug();
        }
    }

    @Override
    public void onCallEventOccur(int eventCode) {
        if (mCallManagerListener != null) {
            mCallManagerListener.onEventComeUp(eventCode);
        }
    }

    @Override
    public void onCallMinimized(int callDuration) {
        if (mCallManagerListener != null) {
            mCallManagerListener.onEventMinimized(callDuration);
        }
    }

    @Override
    public void onCallSendQuality(String quality) {
        if (mCallManagerListener != null) {
            mCallManagerListener.onEventSendQuality(quality);
        }
    }

    @Override
    public void onCallRetry() {
        bRetry = true;
        initializeCall();
    }

    @Override
    public void onCallRinging() {

    }

    @Override
    public void onBandwidthCalcuated(float bandwidth) {
        mCallManagerListener.onCheckReleased(registable, NetworkManager.getNetworkType(cordovaContext), bandwidth);
    }
}
