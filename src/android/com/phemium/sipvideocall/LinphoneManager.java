package com.phemium.sipvideocall;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Rect;
import android.media.AudioManager;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkInfo;
import android.os.AsyncTask;
import android.os.Build;
import android.os.PowerManager;
import android.util.DisplayMetrics;
import android.os.Environment;
import android.util.Log;
import android.view.Display;
import android.view.Gravity;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.view.WindowManager;

import com.phemium.sipvideocall.constant.Constant;
import com.phemium.sipvideocall.data.CallData;
import com.phemium.sipvideocall.listener.LinphoneManagerListener;
import com.phemium.sipvideocall.activities.SipVideoCallActivity;
import com.phemium.sipvideocall.activities.CallInitActivity;
import com.phemium.sipvideocall.receiver.NetworkReceiver;
import com.phemium.sipvideocall.views.CustomGLSurfaceView;
import com.phemium.sipvideocall.views.OverlayCreator;
import com.phemium.sipvideocall.views.OverlayView;

import org.linphone.core.LinphoneAddress;
import org.linphone.core.LinphoneAuthInfo;
import org.linphone.core.LinphoneCall;
import org.linphone.core.LinphoneCallParams;
import org.linphone.core.LinphoneCallStats;
import org.linphone.core.LinphoneChatMessage;
import org.linphone.core.LinphoneChatRoom;
import org.linphone.core.LinphoneContent;
import org.linphone.core.LinphoneCore;
import org.linphone.core.LinphoneCoreException;
import org.linphone.core.LinphoneCoreFactory;
import org.linphone.core.LinphoneCoreListener;
import org.linphone.core.LinphoneEvent;
import org.linphone.core.LinphoneFriend;
import org.linphone.core.LinphoneFriendList;
import org.linphone.core.LinphoneInfoMessage;
import org.linphone.core.LinphoneNatPolicy;
import org.linphone.core.LinphoneProxyConfig;
import org.linphone.core.PayloadType;
import org.linphone.core.PublishState;
import org.linphone.core.Reason;
import org.linphone.core.SubscriptionState;
import org.linphone.core.VideoSize;
import org.linphone.mediastream.video.AndroidVideoWindowImpl;
import org.linphone.mediastream.video.capture.hwconf.AndroidCameraConfiguration;

import java.io.IOException;
import java.net.InetAddress;
import java.nio.ByteBuffer;
import java.util.List;
import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ExecutionException;

import static android.content.Context.WINDOW_SERVICE;
import static com.phemium.sipvideocall.constant.Constant.CALL_ENDED;
import static com.phemium.sipvideocall.constant.Constant.CALL_RESULT_DECLINED_MESSAGE;
import static com.phemium.sipvideocall.constant.Constant.CALL_RESULT_ERROR_DECLINED;
import static com.phemium.sipvideocall.constant.Constant.CALL_RESULT_ERROR_INIT_TIMEOUT;
import static com.phemium.sipvideocall.constant.Constant.CALL_RESULT_ERROR_RINGING_TIMEOUT;
import static com.phemium.sipvideocall.constant.Constant.CALL_RESULT_ERROR_UNKNOWN;
import static com.phemium.sipvideocall.constant.Constant.MAX_RETRY_COUNT;
import static com.phemium.sipvideocall.constant.Constant.QUALITY_COUNT_FOR_AVERAGE;
import static com.phemium.sipvideocall.constant.Constant.SWIPE_BOTTOM;
import static com.phemium.sipvideocall.constant.Constant.SWIPE_RIGHT;

/**
 * Created by Tom on 1/5/2017.
 */

public class LinphoneManager implements LinphoneCoreListener {

    static private LinphoneManager _instance;
    private LinphoneCore linphoneCore;
    private Context mContext;
    //    private LinphoneCall currentCall;
    private LinphoneProxyConfig proxyCfg;

    private Timer linphoneScheduler;
    private Timer qualityScheduler;

    private LinphoneManagerListener mListener;

    private IntentFilter mNetworkIntentFilter;
    private BroadcastReceiver mNetworkReceiver;

    private boolean bAudioCall = false;
    private boolean bCallEnded = true;
    public boolean bIncomingCall = false;

    private boolean isCalling = false;

    public CallData callData;
    public CallInitActivity mCallInitActivity;
    public SipVideoCallActivity mVideoCallActivity;
    private Integer currentRotation;

    private Timer mRegisteringTimer;
    private Timer mUnregisteringTimer;
    private Timer mInitTimer;
    private Timer mRingTimer;
    private Timer mRingingTimer;
    private Timer mConnectingTimer;
    private Timer mCallTimer;
    public int nCallDuration;

    private int nErrorCode = Constant.NO_ERROR;
    private int nHangupReason = Constant.CALL_HANGUP_BY_CALLEE;
    private Display mVideoCallDisplay = null;
    public int nCurCallState;
    public Integer[] originalAudioStatus = null;
    // camera permission
    public Boolean bCameraPermissionAllowed = true;

    public int swipeHState = SWIPE_BOTTOM;
    public int swipeWState = SWIPE_RIGHT;
    public int badgeNum = 0;

    public SurfaceView videoView; // remote
    public SurfaceView captureView; // local
    private AndroidVideoWindowImpl androidVideoWindowImpl;

    private int regist_failed_cnt = 0;
    private boolean is_register_failed = false;
    private boolean is_unregister_failed = false;

    private int regist_retry_cnt = 0;

    private String current_turn_server = null; // Temporary current data
    private String current_turn_server_info = "not-defined";
    public int connecting_failed_cnt = 0;
    private boolean bCallRetry = false;

    public String logsStatus = "";
    private boolean logEnable = false;
    public String logPath = "";

    private boolean checkNetwork = false;

    private String qualityLog = "Call Average Quality Array: ";

    private int qualityCnt = 0;
    private float qualitySumof10 = 0f;
    private float [] qualityArray = new float[Constant.QUALITY_COUNT_FOR_AVERAGE];

    private boolean dozeModeEnabled;
    private int mLastNetworkType = -1;
    private ConnectivityManager mConnectivityManager;

    private static final String TAG = "LinphoneManager";

    public static boolean isInstanciated() {
        return _instance != null;
    }

    public synchronized static LinphoneManager getInstance() {
        if (_instance == null) {
            Log.e(TAG, "LinphoneManager Created new Instance");
            _instance = new LinphoneManager();
        }
        return _instance;
    }

    public void startLibLinphone(Context context, LinphoneManagerListener listener) {
        mContext = context;
        mListener = listener;
        setUpLinphone();
        iterate();
        qualityLog = "Call Average Quality Array: ";
    }

    private void iterate() {
        TimerTask lTask = new TimerTask() {
            @Override
            public void run() {
                UIThreadDispatcher.dispatch(new Runnable() {
                    @Override
                    public void run() {
                        if (linphoneCore != null) {
                            linphoneCore.iterate();
                        }
                    }
                });
            }
        };


        /*
        * use schedule instead of scheduleAtFixedRate to avoid iterate from being
        * call in burst after cpu wake up
        */
        if (linphoneScheduler == null) {
            linphoneScheduler = new Timer("Linphone scheduler");
        }
        linphoneScheduler.schedule(lTask, 0, 20);
        Log.e(TAG, "LinphoneScheduler scheduled");
    }


    private void qualityLoop() {
        if (qualityScheduler == null) {
            TimerTask qualityTask = new TimerTask() {
                @Override
                public void run() {
                    if (linphoneCore != null) {
                        calculateAverageQuality();
                    }
                }
            };

            /*
            * use schedule instead of scheduleAtFixedRate to avoid iterate from being
            * call in burst after cpu wake up
            */
            qualityScheduler = new Timer("Quality Scheduler");

            qualityScheduler.schedule(qualityTask, 0, 1000);
        }
    }


    private void calculateAverageQuality(){

        LinphoneCall linphoneCall = linphoneCore.getCurrentCall();
        if (linphoneCall == null){
            return;
        }

        float currentQuality = linphoneCall.getCurrentQuality();
        qualityCnt++;

        qualitySumof10 += currentQuality;
        if (qualityCnt % Constant.QUALITY_COUNT_SEND_PHEMIUM == 0){
            String strCurrentQuality = String.format(Locale.US, "%.2f", currentQuality);
            qualityLog += strCurrentQuality + ",";
            mListener.onCallSendQuality(strCurrentQuality);
        }
        if (qualityCnt <= Constant.QUALITY_COUNT_FOR_AVERAGE){
            qualityArray[qualityCnt - 1] = currentQuality;
        }else {
            for (int i = 1; i < Constant.QUALITY_COUNT_FOR_AVERAGE; i++) {
                qualityArray[i - 1] = qualityArray[i];
            }
            qualityArray[Constant.QUALITY_COUNT_FOR_AVERAGE - 1] = currentQuality;

            float qualitySum = 0;
            for (int i = 0; i < Constant.QUALITY_COUNT_FOR_AVERAGE; i++) {
                qualitySum += qualityArray[i];
            }

            float qualityAvg = qualitySum / Constant.QUALITY_COUNT_FOR_AVERAGE;


            if (mVideoCallActivity != null) {
                mVideoCallActivity.updateCallStatus(qualityAvg);
            }
        }
    }

    private void initLiblinphone(LinphoneCore lc) {
        linphoneCore  = lc;
        try {
            String basePath = mContext.getFilesDir().getAbsolutePath();
            copyAssetsFromPackage(basePath);
            linphoneCore.migrateToMultiTransport();
            linphoneCore.setContext(mContext);
            linphoneCore.setVideoPolicy(true, true);
            linphoneCore.enableVideo(true, true);
            linphoneCore.setUserAgent("Phemium VideoCall Plugin", callData.videoCallPluginVersion);

            linphoneCore.setRootCA(basePath + "/rootca.pem");
            //Disable IPv6
            linphoneCore.enableIpv6(false);

            Log.e(TAG, "Linphone Created, Version:" + linphoneCore.getVersion());

            //Set Default Camera
            AndroidCameraConfiguration.AndroidCamera[] cameras = AndroidCameraConfiguration.retrieveCameras();

            for (AndroidCameraConfiguration.AndroidCamera androidCamera : cameras) {
                if (androidCamera.frontFacing) {
                    linphoneCore.setVideoDevice(androidCamera.id);
                }
            }
//                updateNetworkReachability();
            dozeModeEnabled = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                    && ((PowerManager) mContext.getSystemService(Context.POWER_SERVICE)).isDeviceIdleMode();
            disableAllCodecs();

            // Configure audio codecs
            configurePayloadType("OPUS", 48000, 98);
            configurePayloadType("SPEEX", 32000, 99);
            configurePayloadType("SPEEX", 16000, 100);
            configurePayloadType("PCMU", 8000, -1);
            configurePayloadType("PCMA", 8000, -1);

            // Configure video codecs
            configurePayloadType("VP8", 90000, 96);
            configurePayloadType("H264", 90000, 97);
        } catch (Exception e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    private void setUpLinphone() {
        if (linphoneCore == null) {
            try {
                String basePath = mContext.getFilesDir().getAbsolutePath();
                copyAssetsFromPackage(basePath);

                linphoneCore = LinphoneCoreFactory.instance().createLinphoneCore(this, mContext);
                linphoneCore.migrateToMultiTransport();
                linphoneCore.setContext(mContext);
                linphoneCore.setVideoPolicy(true, true);
                linphoneCore.enableVideo(true, true);
                linphoneCore.setUserAgent("Phemium VideoCall Plugin", callData.videoCallPluginVersion);
                linphoneCore.setUserCertificatesPath(basePath);
                linphoneCore.setRootCA(basePath + "/rootca.pem");
                //Disable IPv6
                linphoneCore.enableIpv6(false);

                Log.e(TAG, "Linphone Created, Version:" + linphoneCore.getVersion());

                //Set Default Camera
                AndroidCameraConfiguration.AndroidCamera[] cameras = AndroidCameraConfiguration.retrieveCameras();

                for (AndroidCameraConfiguration.AndroidCamera androidCamera : cameras) {
                    if (androidCamera.frontFacing) {
                        linphoneCore.setVideoDevice(androidCamera.id);
                    }
                }
//                updateNetworkReachability();
                dozeModeEnabled = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                        && ((PowerManager) mContext.getSystemService(Context.POWER_SERVICE)).isDeviceIdleMode();
                disableAllCodecs();

                // Configure audio codecs
                configurePayloadType("OPUS", 48000, 98);
                configurePayloadType("SPEEX", 32000, 99);
                configurePayloadType("SPEEX", 16000, 100);
                configurePayloadType("PCMU", 8000, -1);
                configurePayloadType("PCMA", 8000, -1);

                // Configure video codecs
                configurePayloadType("VP8", 90000, 96);
                configurePayloadType("H264", 90000, 97);

                // Since Android N we need to register the network manager
                if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
                    mNetworkReceiver = new NetworkReceiver();
                    mNetworkIntentFilter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
                    mContext.registerReceiver(mNetworkReceiver, mNetworkIntentFilter);
                }
            } catch (Exception e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
    }




    public void enableLogCollection(boolean enabled){
        //Linphone Debug
//        logEnable = enabled;  ////   only when logEnable is ture
        if (callData.logEnable){
            Log.e(TAG, "Log Path:" +Environment.getExternalStorageDirectory().getAbsolutePath());
            LinphoneCoreFactory.instance().setLogCollectionPath(Environment.getExternalStorageDirectory().getAbsolutePath()+"");
            linphoneCore.resetLogCollection();
            LinphoneCoreFactory.instance().enableLogCollection(true);
            LinphoneCoreFactory.instance().setDebugMode(true, "Phemium VideoCall Plugin");

            logPath =  Environment.getExternalStorageDirectory().getAbsolutePath() + "/linphone1";
        }else{
            Log.e(TAG, "Log Path:" + "");
            linphoneCore.resetLogCollection();
            LinphoneCoreFactory.instance().enableLogCollection(false);
            LinphoneCoreFactory.instance().setDebugMode(false, "Phemium VideoCall Plugin");

            logPath = "";
        }
    }

    public void destroyLibLinphone() {
        if (linphoneScheduler != null) {
            linphoneScheduler.cancel();
            linphoneScheduler = null;
        }
        if (qualityScheduler != null){
            qualityScheduler.cancel();
            qualityScheduler = null;
        }
        if (linphoneCore != null) {
            linphoneCore.destroy();
            linphoneCore = null;
        }
    }

    public void resetLibLinphone() {
        destroyLibLinphone();
        setUpLinphone();
        iterate();
        linphoneCore.setNetworkReachable(false);
    }

    public void setVideoSize() {
        // Check Video size can be supported for device
        String[] supportVideoSizes = linphoneCore.getSupportedVideoSizes();
        String videoSize = callData.videoSize == null ? "vga" : callData.videoSize;  // videoSize will "VGA" by default if enduser(or testapp) does not send
        boolean bSupport = false;

        for (String supportVideoSize : supportVideoSizes){
            if(videoSize.equals(supportVideoSize)){
                bSupport = true;
                break;
            }
        }
        if (bSupport) {
            if (videoSize.equals("qcif")) {
                linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_QCIF);
            }
            if (videoSize.equals("cif")) {
                linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_CIF);
            }
            if (videoSize.equals("qvga")) {
                linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_QVGA);
            }
            if (videoSize.equals("vga")) {
                linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_VGA);
            }
            if (videoSize.equals("720p")) {
                linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_720P);
            }
            if (videoSize.equals("1080p")) {
                linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_1020P);
            }
        }else{  // IF NOT SUPPORT, please set video size to "QVGA"
            linphoneCore.setPreferredVideoSize(VideoSize.VIDEO_SIZE_QVGA);
        }

        String logString = String.format(Locale.US, "---Set Video Resolution: %s",videoSize);
        insertLogString(logString);
    }

    public void setTransportValue() {
        // Use random ports
        LinphoneCore.Transports transports = linphoneCore.getSignalingTransportPorts();
        if (callData.transportMode.equals("tcp")) {
            transports.tcp = -1;
            transports.udp = 0;
            transports.tls = 0;
        }
        if (callData.transportMode.equals("udp")){
            transports.tcp = 0;
            transports.udp = -1;
            transports.tls = 0;
        }
        if (callData.transportMode.equals("tls")){
            transports.tcp = -1;
            transports.udp = -1;
            transports.tls = -1;
        }
        linphoneCore.setSignalingTransportPorts(transports);
        linphoneCore.setAudioPortRange(10000, 10199);
        linphoneCore.setVideoPortRange(12000, 12199);
//        linphoneCore.setNortpTimeout(30);
//        linphoneCore.setAudioJittcomp(60);
//        linphoneCore.setVideoJittcomp(60);
    }

    public void setCallQualityParams() {
        if (callData.downloadBandwidth != -1) {
            linphoneCore.setDownloadBandwidth(callData.downloadBandwidth);
        }

        if (callData.uploadBandwidth != -1) {
            linphoneCore.setUploadBandwidth(callData.uploadBandwidth);
        }

        if (callData.framerate != -1) {
            linphoneCore.setPreferredFramerate(callData.framerate);
        }
    }
    public void setTurnSetting() {

        String LOGTRYTEXT = "--- Turn definition when try #%d. Address: %s, Domain: %s, Username: %s, Password: %s";
        // Enable turn server
        LinphoneNatPolicy policy = linphoneCore.createNatPolicy();
        policy.enableIce(true);
        policy.enableTurn(true);

        // [J] Calculate next Turn to be try depending on number of retries and how many of them are configured
        int currentIndex = connecting_failed_cnt % 2; // [J] main accesses: #0 , secondary accesses: #1
        // [J] Set current configuration
        String currentServer = callData.turnServer0;
        String currentDomain = callData.turnDomain0;
        String currentUsername = callData.turnUsername0;
        String currentPassword = callData.turnPassword0;
        if( currentIndex == 1 )
        {
            currentServer = callData.turnServer1;
            currentDomain = callData.turnDomain1;
            currentUsername = callData.turnUsername1;
            currentPassword = callData.turnPassword1;
        }

        Log.e( TAG, String.format( Locale.ENGLISH, LOGTRYTEXT,
                connecting_failed_cnt, currentServer, currentDomain, currentUsername, currentPassword ) );

        policy.setStunServer( currentServer );

        current_turn_server = currentServer;
        current_turn_server_info = currentServer;

        // [J] AuthInfo
        if( currentUsername != null && currentUsername.length() > 0 && !currentUsername.equals("null") )
        {
            LinphoneAuthInfo currentAuthInfo = LinphoneCoreFactory.instance().createAuthInfo(
                    currentUsername, currentPassword, currentDomain, currentDomain );
            linphoneCore.addAuthInfo( currentAuthInfo );
            policy.setStunServerUsername( currentUsername );
            current_turn_server_info += "(" + currentUsername + ";" + currentPassword + ";" + currentDomain + ")";
        }
        else
            current_turn_server_info += "(none)";

        linphoneCore.setNatPolicy( policy );


        //encryption: default is none
        if (callData.encryptionMode.equals("none")){
            linphoneCore.setMediaEncryptionMandatory(false);
            linphoneCore.setMediaEncryption(LinphoneCore.MediaEncryption.None);
        }
        if (callData.encryptionMode.equals("srtp")){
            linphoneCore.setMediaEncryptionMandatory(true);
            linphoneCore.setMediaEncryption(LinphoneCore.MediaEncryption.SRTP);
        }

        if (callData.encryptionMode.equals("zrtp")){
            linphoneCore.setMediaEncryptionMandatory(true);
            linphoneCore.setMediaEncryption(LinphoneCore.MediaEncryption.ZRTP);
        }

        if (callData.encryptionMode.equals("dtls")){
            linphoneCore.setMediaEncryptionMandatory(true);
            linphoneCore.setMediaEncryption(LinphoneCore.MediaEncryption.DTLS);
        }

        String logString = String.format(Locale.US, "---Encryption Mode: %s",
                callData.encryptionMode);
        insertLogString(logString);
    }

    public void setUser() {
        // Add user auth info
        LinphoneAuthInfo lAuthInfo = LinphoneCoreFactory.instance().createAuthInfo(callData.username, callData.password,
                null, callData.domain);
        linphoneCore.addAuthInfo(lAuthInfo);
    }

    public void setProxy() {
        try {
            LinphoneProxyConfig oldProxyCfg = linphoneCore.getDefaultProxyConfig();
            if (oldProxyCfg != null){
                oldProxyCfg.edit();
                oldProxyCfg.setExpires(0);
                oldProxyCfg.done();
                linphoneCore.removeProxyConfig(oldProxyCfg);
            }

            if (!callData.proxy.startsWith("sip:")) {
                callData.proxy = "sip:" + callData.proxy;
            }
            String identity = "sip:" + callData.username + "@" + callData.domain;

            LinphoneAddress proxyAddr = LinphoneCoreFactory.instance().createLinphoneAddress(callData.proxy);

            if (callData.transportMode.equals("tcp")) {
                proxyAddr.setTransport(LinphoneAddress.TransportType.LinphoneTransportTcp);
            }
            if (callData.transportMode.equals("udp")){
                proxyAddr.setTransport(LinphoneAddress.TransportType.LinphoneTransportUdp);
            }
            if (callData.transportMode.equals("tls")){
                proxyAddr.setTransport(LinphoneAddress.TransportType.LinphoneTransportTls);
            }

            try {
                proxyCfg = linphoneCore.createProxyConfig(identity, proxyAddr.asStringUriOnly(), proxyAddr.asStringUriOnly(),
                        true);
                linphoneCore.addProxyConfig(proxyCfg);
                linphoneCore.setDefaultProxyConfig(proxyCfg);
            } catch (LinphoneCoreException e1) {
                // TODO Auto-generated catch block
                e1.printStackTrace();
            }

            String logString = String.format(Locale.ENGLISH, "---Platform: %s",
                     "Android");
            insertLogString(logString);

            logString = String.format(Locale.ENGLISH, "---ProxyServer Address: %s",
                    proxyCfg != null ? proxyCfg.getProxy() : "null");
            insertLogString(logString);

            logString = String.format(Locale.ENGLISH, "---SIP Transport: %s",
                    callData.transportMode);
            insertLogString(logString);

            logString = String.format(Locale.ENGLISH, "---Debug Mode: %s",
                    callData.logEnable ? "true" : "false");
            insertLogString(logString);
        } catch (Exception e) {

        }
    }

    public void clearAuthInfoAndProxyConfig() {
        linphoneCore.clearAuthInfos();
        linphoneCore.clearProxyConfigs();
    }

    public void doRegister() {
        isCalling = false;
        String videocallPluginVersion = callData.videoCallPluginVersion;
        String logString = String.format(Locale.ENGLISH, "---Plugin Version: %s", videocallPluginVersion);
        insertLogString(logString);

        logString = String.format(Locale.ENGLISH, "---Network Info: %s", NetworkManager.getNetworkType(mContext));
        insertLogString(logString);

        AudioManager audioManager = (AudioManager) mContext.getSystemService(Context.AUDIO_SERVICE);
        int currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        Log.e(TAG, "Current music volume: " + currentVolume);
        currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL);
        Log.e(TAG, "Current music volume: " + currentVolume);

        String cameraPermission = "";
        if (bCameraPermissionAllowed){
            cameraPermission = "Allowed";
        }else{
            cameraPermission = "Not Allowed";
        }
        logString = String.format(Locale.ENGLISH, "---Camera Permission: %s", cameraPermission);
        insertLogString(logString);

        logString = String.format(Locale.ENGLISH, "---Consultaion Id: %s", callData.consultationId);
        insertLogString(logString);

        if (!NetworkManager.isOnline(mContext)) {
            nErrorCode = Constant.CALL_RESULT_ERROR_NOINTERNET;
            if (mCallInitActivity != null) {
                mCallInitActivity.finish();
                mCallInitActivity = null;
            }
            mListener.onCallFailed(nErrorCode, logsStatus);
            return;
        }

        nCurCallState = Constant.CALL_REGISTERING;
        nErrorCode = Constant.NO_ERROR;
        nHangupReason = Constant.CALL_HANGUP_BY_CALLEE;
        regist_failed_cnt = 0;
        is_register_failed = false;
        is_unregister_failed = false;

        if (bIncomingCall) {
            showConnectingScreen();
        }
        if (mCallInitActivity != null) {
            mCallInitActivity.setCallStatus(nCurCallState, 0, current_turn_server_info);
        }

        logString = String.format(Locale.ENGLISH, "---%s", "Login...");
        insertLogString(logString);
        try {
            linphoneCore.getDefaultProxyConfig().edit();
            linphoneCore.getDefaultProxyConfig().enableRegister(true);
            linphoneCore.getDefaultProxyConfig().done();
        } catch (Exception e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        linphoneCore.setNetworkReachable(true);

        this.stopAllTimer();
        mRegisteringTimer = new Timer();
        mRegisteringTimer.schedule(new RegisteringTimerTask(), Constant.CALL_REGISTER_MAX_DELAY);
    }

    public void doUnRegister() {
        String logString = String.format(Locale.ENGLISH, "---%s", "UnRegistration...");
        insertLogString(logString);

        try {
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
                mContext.unregisterReceiver(mNetworkReceiver);
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }

        Log.e(TAG, "unregistering...");
        try {
            linphoneCore.getDefaultProxyConfig().edit();
            linphoneCore.getDefaultProxyConfig().enableRegister(false);
            linphoneCore.getDefaultProxyConfig().setExpires(0);
            linphoneCore.getDefaultProxyConfig().done();
        } catch (Exception e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        clearAuthInfoAndProxyConfig();

        mUnregisteringTimer = new Timer();
        mUnregisteringTimer.schedule(new UnregisteringTimerTask(), Constant.CALL_UNREGISTER_MAX_DELAY);
    }

    public void call(String to) {
        nErrorCode = Constant.NO_ERROR;
        bAudioCall = false;

        if (!bCallEnded) {
            Log.e(TAG, "Trying to setup second call when one is in progress");
            return;
        }
        Log.e(TAG, "call started");

        bCallEnded = false;
//        linphoneCore.setPreferredVideoSize(VideoSize.createStandard(VideoSize.QCIF, true));
        isCalling = true;
        LinphoneAddress lAddress;
        try {
            lAddress = linphoneCore.interpretUrl(to);
        } catch (LinphoneCoreException e) {
            return;
        }
        startInitTimer();
        String consultationId = callData.consultationId;
        String enduserPluginVersion = callData.enduserPluginVersion;
        LinphoneCallParams params = linphoneCore.createCallParams(null);

        params.addCustomHeader("PhemiumInfo", consultationId + "/" + enduserPluginVersion + "/" + "videocall" + "/" + Build.MODEL + "/" + Build.VERSION.RELEASE);
        params.setVideoEnabled(true);
        linphoneCore.enableSpeaker(true);
        try {
            linphoneCore.inviteAddressWithParams(lAddress, params);
        } catch (LinphoneCoreException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    public void audioCall(String to) {
        bAudioCall = true;
        nErrorCode = Constant.NO_ERROR;
        if (!bCallEnded) {
            Log.e(TAG, "Trying to setup second call when one is in progress");
            return;
        }
        linphoneCore.setPreferredVideoSize(VideoSize.createStandard(VideoSize.QCIF, true));
        bCallEnded = false;
        isCalling = true;
        LinphoneAddress lAddress;
        try {
            lAddress = linphoneCore.interpretUrl(to);
        } catch (LinphoneCoreException e) {
            return;
        }
        startInitTimer();
        String consultationId = callData.consultationId;
        String enduserPluginVersion = callData.enduserPluginVersion;
        LinphoneCallParams params = linphoneCore.createCallParams(null);
        params.addCustomHeader("PhemiumInfo", consultationId + "/"  + enduserPluginVersion + "/" + "audiocall" + "/" + Build.MODEL + "/" + Build.VERSION.RELEASE);
        params.setVideoEnabled(false);
        linphoneCore.enableSpeaker(false);
        try {
            linphoneCore.inviteAddressWithParams(lAddress, params);
        } catch (LinphoneCoreException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    public void setCallReleasedReason(int reason) {
        nHangupReason = reason;
    }

    public void hangup() {
        if (linphoneCore.isIncall()) {
            LinphoneCall lCall = linphoneCore.getCurrentCall();
            if (lCall != null) {
//                setLinphoneVideoView(null);
//                setLinphonePreviewView(null);
                Log.e(TAG, "Hangup - current call = " + lCall);
                linphoneCore.terminateCall(lCall);
            }
        }
    }

    public void onRegisterState(LinphoneCore.RegistrationState state, String message) {
        String logString = String.format(Locale.ENGLISH, "Server Response, message: %s ", message != null ? message : "");
        insertLogString(logString);
        if (state == LinphoneCore.RegistrationState.RegistrationOk) {
            if (!is_register_failed) {
                is_register_failed = false;
                stopRegisteringTimer();
                regist_failed_cnt = 0;
                mListener.onRegisterSucceeded();
            }
        }

        if (state == LinphoneCore.RegistrationState.RegistrationFailed) {
            if (checkNetwork){
                stopRegisteringTimer();
                mListener.onRegisterFailed(logString);
                return;
            }
            if (!isCalling){
                regist_failed_cnt++;
                if (regist_failed_cnt > Constant.MAX_FAILED_COUNT) {
                    if (is_register_failed) {
                        return;
                    }
                    Log.e(TAG, proxyCfg.getErrorInfo().getDetails());
                    is_register_failed = true;
                    doUnRegister();
                }
            }
        }

        if (state == LinphoneCore.RegistrationState.RegistrationCleared) {
            stopUnregisteringTimer();
            if (is_unregister_failed) {
                return;
            }
            if (!isCalling) {
                regist_retry_cnt++;
                if (regist_retry_cnt < Constant.MAX_RETRY_COUNT) {

                    enableLogCollection(true);

                    logString = String.format(Locale.ENGLISH, "---%s", "Register Retrying");
                    insertLogString(logString);
                    if (mCallInitActivity != null) {
                        mCallInitActivity.setCallStatus(Constant.CALL_RETRYING, 0, current_turn_server_info);
                    }

                    new Timer().schedule(new TimerTask() {
                        @Override
                        public void run() {
                            Log.e(TAG, "Register Retrying...");
                            doRegister();
                        }
                    }, 10000);
                } else {
                    regist_retry_cnt = 0;
                    nErrorCode = Constant.CALL_RESULT_ERROR_REGISTER_FAILURE;

                    stopRegisteringTimer();
                    if (mCallInitActivity != null) {
                        mCallInitActivity.finish();
                        mCallInitActivity = null;
                    }
                    mListener.onCallFailed(nErrorCode, logsStatus);
                }
            } else {
                isCalling = false;

                bCallEnded = true;
                nCurCallState = Constant.CALL_ENDED;
                //                currentCall = null;
                if (!bCallRetry) {
                    connecting_failed_cnt = 0;
                    if (mCallInitActivity != null) {
                        mCallInitActivity.finish();
                        mCallInitActivity = null;
                    } else {
                        if (mVideoCallActivity != null) {
                            mVideoCallActivity.finish();
                            mVideoCallActivity = null;
                        }
                    }
                    Log.e(TAG, "Call No Retry");
                    if (nErrorCode != Constant.NO_ERROR) {
                        mListener.onCallFailed(nErrorCode, logsStatus);
                    } else {
                        mListener.onCallReleased(logsStatus);
                    }
                } else {
                    if (mCallInitActivity != null) {
                        mCallInitActivity.setCallStatus(Constant.CALL_RETRYING, 0, current_turn_server_info);
                    }

                    enableLogCollection(true);
                    Log.e(TAG, "Call Retry");
                    Timer retryTimer = new Timer();
                    retryTimer.schedule(new TimerTask() {
                        @Override
                        public void run() {
                            resetLibLinphone();
                            bCallRetry = false;
                            mListener.onCallRetry();
                        }
                    }, 10000);
                }
            }
        }

        if (state == LinphoneCore.RegistrationState.RegistrationNone) {
//            if (isCalling){
//
//            }else{
//                regist_retry_cnt = 0;
//                nErrorCode = Constant.CALL_RESULT_ERROR_REGISTER_FAILURE;
//                stopRegisteringTimer();
//                stopUnregisteringTimer();
//                if (mCallInitActivity != null) {
//                    mCallInitActivity.finish();
//                    mCallInitActivity = null;
//                }
//                if (mVideoCallActivity != null) {
//                    mVideoCallActivity.finish();
//                    mVideoCallActivity = null;
//                }
//                mListener.onCallFailed(nErrorCode, logsStatus);
//            }
        }

        if (state == LinphoneCore.RegistrationState.RegistrationProgress) {

        }

    }

    public void onCallState(LinphoneCall linphoneCall, LinphoneCall.State state, String s) {
        LinphoneCall call = linphoneCore.getCurrentCall();
        String logString = "";
        switch (state.value()) {
            case 1: //Incoming received
                Log.e(TAG, logString + "Incoming received.");

                break;
            case 2: //Outgoing init
                logString = String.format(Locale.ENGLISH, "---%s", "Connecting...");
                insertLogString(logString);
                stopInitTimer();
                Log.e(TAG, "Outgoing init.");
                nCurCallState = Constant.CALL_INITIALISING;
                if (mCallInitActivity != null) {
                    mCallInitActivity.setCallStatus(nCurCallState, 0, current_turn_server_info);
                }
                startRingTimer();
                if (!bIncomingCall) {
                    this.showCallingScreen();
                }
                break;
            case 4: //Outgoing Ringing
                Log.e(TAG, logString + "Outgoing ringing.");
                nCurCallState = Constant.CALL_RINGING;
                if (mCallInitActivity != null) {
                    mCallInitActivity.setCallStatus(nCurCallState, 0, current_turn_server_info);
                }
                stopRingTimer();
                mListener.onCallRinging();

                if (!bIncomingCall) {
                    this.startRingSound();
                    this.showCallingAnimationEffect();
                }
                this.startRingingTimer();
                break;
            case 5: //Outgoing Early Media
                Log.e(TAG, "Outgoing Early Media");
                break;
            case 6: //Connected
                if (linphoneCore.isSdp200AckEnabled()) {
                    Log.e(TAG, "SDP is enabled. now it will be disabled.");
                    linphoneCore.enableSdp200Ack(false);
                }

                Log.e(TAG, logString + "Connected.");
                stopRingingTimer();
                nCurCallState = Constant.CALL_CONNECTING;
                if (mCallInitActivity != null) {
                    mCallInitActivity.setCallStatus(nCurCallState, 0, current_turn_server_info);
                }
                call.enableEchoCancellation(true);
                call.enableEchoLimiter(true);

                nCallDuration = 0;
                this.stopRingSound();

                // Scale video task
                if (!bAudioCall) {
                    if (!bIncomingCall) {
                        showConnectingScreen();
                    }

                    logString = String.format(Locale.ENGLISH, "---%s", "Establishing Call...");
                    insertLogString(logString);

                    startConnectingTimer();
                    LinphoneManager.ScaleVideoTask task = new LinphoneManager.ScaleVideoTask();
                    task.execute();
                    showConnectingAnimationEffect();
                } else {
                    // audio call
                    qualityLoop();
                    nCurCallState = Constant.CALL_CONNECTED;
                    this.showAudioChattingScreen();
                    this.startCallTimer();
                }
                break;
            case 7: //Streams Running
                Log.e(TAG, "The media streams are established and running.");
                break;
            case 12: //Error
                Log.e(TAG, logString + "Call error:" + "State: " + state.toString() + " ,Message: " + s);
                Reason reason = linphoneCall.getReason();
                if (reason != null) {
                    Log.e(TAG, "Reason is not null. " + reason.toString());
                }
                if (reason != null || s != null) {
                    if ((reason != null && reason.equals(Reason.None)) || (s != null && s.equals(""))) {
                        nErrorCode = Constant.NO_ERROR;
                    } else if ((reason != null && reason.equals(Reason.NotAnswered))
                            || (s != null && s.equals("Request timeout"))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_CALLEE_NOT_FOUND;
                    } else if ((reason != null && reason.equals(Reason.Declined)) || (s != null && s.equals("Declined"))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_DECLINED;
                    } else if ((reason != null && reason.equals(Reason.NotFound)) || (s != null && s.equals("Not Found"))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_CALLEE_NOT_FOUND;
                    } else if ((reason != null && reason.equals(Reason.Busy)) || (s != null && s.equals("Busy"))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_BUSY;
                    } else if ((reason != null && reason.equals(Reason.DoNotDisturb))
                            || (s != null && s.equals("Do Not Disturb"))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_BUSY;
                    } else if ((reason != null && reason.equals(Reason.Unknown)) || (s != null && s.equals("Unknown"))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_CALLEE_NOT_EXIST;
                    } else if ((reason != null && reason.equals(Reason.TemporarilyUnavailable)) || (s != null && s.equals(""))) {
                        nErrorCode = Constant.CALL_RESULT_ERROR_CALLEE_NOT_FOUND;
                    } else {
                        nErrorCode = Constant.CALL_RESULT_ERROR_UNKNOWN;
                    }
                }
                setCallReleasedReason(Constant.CALL_HANGUP_BY_ERROR);
                break;
            case 13: //CallEnded
                Log.e(TAG, logString + "Call ended. reason:" + s);
                onEndCall(linphoneCall, s);
                if (nErrorCode == CALL_RESULT_ERROR_INIT_TIMEOUT || nErrorCode == CALL_RESULT_ERROR_RINGING_TIMEOUT) {
                    doUnRegister();
                }
                break;
            case 18: //Call Released
                Log.e(TAG, logString + "Call Released.");
                onEndCall(linphoneCall, s);
                if (nErrorCode != CALL_RESULT_ERROR_INIT_TIMEOUT && nErrorCode != CALL_RESULT_ERROR_RINGING_TIMEOUT) {
                    doUnRegister();
                }
                break;
            default:
                break;
        }

        logString = String.format(Locale.ENGLISH, "Server Response, message: %s, state : %d ", s != null ? s : "",
                state.value());
        insertLogString(logString);
    }


    public boolean isLogEnable() {
        return logEnable;
    }

    public void setLogEnable(boolean logEnable) {
        this.logEnable = logEnable;
    }

    private void startInitTimer() {
        Log.e(TAG, "Start Init Timer");
        mInitTimer = new Timer();
        mInitTimer.schedule(new CallInitTimerTask(), Constant.CALL_INIT_MAX_DELAY);
    }

    private void startRingTimer() {
        Log.e(TAG, "Start Ring Timer");
        mRingTimer = new Timer();
        mRingTimer.schedule(new CallRingTimerTask(), Constant.CALL_RING_MAX_DELAY);
    }

    private void startRingingTimer() {
        Log.e(TAG, "Start Ringing Timer");
        mRingingTimer = new Timer();
        mRingingTimer.schedule(new CallRingingTimerTask(), Constant.CALL_RINGING_MAX_DELAY);
    }

    private void startConnectingTimer() {
        Log.e(TAG, "Start Connecting Timer");
        mConnectingTimer = new Timer();
        mConnectingTimer.schedule(new ConnectingTimerTask(), Constant.CALL_CONNECTING_MAX_DELAY);
    }

    private void startCallTimer() {
        Log.e(TAG, "Start Call Timer");

        String message = "";
        if (bAudioCall){
            message = "Doing an Audio Call";
        }else{
            message = "Doing a Video Call";
        }
        String logString = String.format(Locale.ENGLISH, "---%s", message);
        insertLogString(logString);

        this.stopAllTimer();
        mCallTimer = new Timer();
        mCallTimer.schedule(new CallTimerTask(), 0, 1000);
    }

    private void stopRegisteringTimer() {
        if (mRegisteringTimer != null) {
            mRegisteringTimer.cancel();
            mRegisteringTimer = null;
        }
    }

    private void stopUnregisteringTimer() {
        if (mUnregisteringTimer != null) {
            mUnregisteringTimer.cancel();
            mUnregisteringTimer = null;
        }
    }

    private void stopInitTimer() {
        Log.e(TAG, "Stop Init Timer");
        if (mInitTimer != null) {
            mInitTimer.cancel();
            mInitTimer = null;
        }
    }

    private void stopRingTimer() {
        Log.e(TAG, "Stop Ring Timer");
        if (mRingTimer != null) {
            mRingTimer.cancel();
            mRingTimer = null;
        }
    }

    private void stopRingingTimer() {
        Log.e(TAG, "Stop Ringing Timer");
        if (mRingingTimer != null) {
            mRingingTimer.cancel();
            mRingingTimer = null;
        }
    }

    private void stopConnectingTimer() {
        if (mConnectingTimer != null) {
            mConnectingTimer.cancel();
            mConnectingTimer = null;
        }
    }

    private void stopCallTimer() {
        if (mCallTimer != null) {
            mCallTimer.cancel();
            mCallTimer = null;
        }
    }

    private void stopAllTimer() {
        stopInitTimer();
        stopRegisteringTimer();
        stopRingTimer();
        stopRingingTimer();
        stopConnectingTimer();
        stopCallTimer();
    }

    private void onEndCall(LinphoneCall linphoneCall, String message) {
        if (!bCallEnded) {
            stopAllTimer();
            bCallEnded = true;

            insertLogString(qualityLog);

            String reason = "";
            switch (nHangupReason) {
                case Constant.CALL_HANGUP_BY_CALLER:
                    reason = "Caller did hangup call";
                    break;
                case Constant.CALL_HANGUP_BY_ERROR:
                    reason = "Error Occured";
                    break;
                default:
                    reason = "Callee did hangup call";
                    break;
            }
            String logString = "Call Terminated. reason: " + reason;
            insertLogString(logString);

            Log.e(TAG, message + " reason: " + reason + " error code:" + nErrorCode);

            int seconds = nCallDuration % 60;
            int minutes = nCallDuration / 60 % 60;
            int hours = nCallDuration / 3600;
            logString = "Call Duration: " + hours + "h " + minutes + "m " + seconds + "s ";
            insertLogString(logString);

            if (originalAudioStatus != null) {
                AudioManager audioManager = (AudioManager) mContext.getSystemService(Context.AUDIO_SERVICE);
                Log.e(TAG,
                        String.format(Locale.ENGLISH, "Current Audio Status(mode:%d, speaker:%d). Restoring Original Status...",
                                audioManager.getMode(), (audioManager.isSpeakerphoneOn() ? 1 : 0)));
                audioManager.setMode(originalAudioStatus[0]);
                audioManager.setSpeakerphoneOn(originalAudioStatus[1] == 1);
            }
            if (message.equals(CALL_RESULT_DECLINED_MESSAGE)) {
                nErrorCode = CALL_RESULT_ERROR_DECLINED;
            }
            OverlayCreator.getInstance(mContext).destroyOverlay();
            qualityCnt = 0;
            qualitySumof10 = 0;
            if (qualityScheduler != null){
                qualityScheduler.cancel();
                qualityScheduler = null;
            }
            nCurCallState = CALL_ENDED;
        }
    }

    private void showCallingScreen() {
        if (mCallInitActivity != null) {
            mCallInitActivity.bAudioCall = bAudioCall;
            mCallInitActivity.showCallingScreen();
        } else {
            Intent intent = new Intent(mContext, CallInitActivity.class);
            intent.putExtra("show_mode", 0);
            intent.putExtra("isAudioCall", bAudioCall);
            mContext.startActivity(intent);
        }
    }

    private void showCallingAnimationEffect() {
        if (mCallInitActivity != null) {
            mCallInitActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    mCallInitActivity.showCallingAnimationEffect();
                }
            });
        }
    }

    private void startRingSound() {
        if (mCallInitActivity != null) {
            Log.e(TAG, "mCallInitActivity is not null.");
            mCallInitActivity.startRingSound();
        } else {
            Log.e(TAG, "mCallInitActivity is null.");
        }
    }

    private void showVideoCallScreen() {
        if (mVideoCallActivity != null) {
            //ScaleVideoTask is called again. probably from onorientationchanged function.
        } else {
            Log.e(TAG, "Presenting SipVideoCallActivity");
            nCurCallState = Constant.CALL_CONNECTED;
            SipVideoCallActivity.bRemoteVideoShowingOnSmallContainer = false;

            if (mCallInitActivity != null) {
                Intent intent = new Intent(mCallInitActivity, SipVideoCallActivity.class);
                intent.putExtra("gravity", Gravity.BOTTOM | Gravity.END);
                mCallInitActivity.startActivity(intent);
                mCallInitActivity.finish();
                mCallInitActivity = null;
            } else {
                Intent intent = new Intent(mContext, SipVideoCallActivity.class);
                intent.putExtra("gravity", Gravity.BOTTOM | Gravity.END);
                mContext.startActivity(intent);
            }
            startCallTimer();
        }
    }

    private void stopRingSound() {
        if (mCallInitActivity != null) {
            mCallInitActivity.stopRingSound();
        }
    }

    private void showConnectingScreen() {
        if (mCallInitActivity != null) {
            mCallInitActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    mCallInitActivity.showConnectingScreen();
                }
            });
        } else {
            Intent intent = new Intent(mContext, CallInitActivity.class);
            intent.putExtra("show_mode", 1);
            intent.putExtra("isAudioCall", bAudioCall);
            mContext.startActivity(intent);
        }
    }

    private void showConnectingAnimationEffect() {
        if (mCallInitActivity != null) {
            mCallInitActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    mCallInitActivity.showConnectingAnimationEffect();
                }
            });
        }
    }

    private void showAudioChattingScreen() {
        if (mCallInitActivity != null) {
            mCallInitActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    mCallInitActivity.showAudioChattingScreen();
                }
            });
        } else {
            Intent intent = new Intent(mContext, CallInitActivity.class);
            intent.putExtra("show_mode", 2);
            intent.putExtra("isAudioCall", bAudioCall);
            mContext.startActivity(intent);
        }
    }

    public void enableSpeaker(Boolean bEnable) {
        if (linphoneCore != null) {
            linphoneCore.enableSpeaker(bEnable);
        }
    }

    public Boolean isEnabledSpeaker() {
        return linphoneCore.isSpeakerEnabled();
    }

    public Boolean isMutedMic() {
        return linphoneCore.isMicMuted();
    }

    public boolean muteMic() {
        LinphoneCall currentCall = linphoneCore.getCurrentCall();
        if (currentCall != null) {
            if (linphoneCore.isMicMuted()) {
                linphoneCore.muteMic(false);
                mListener.onCallEventOccur(Constant.CALL_EVENT_MICRO_MUTED);
            } else {
                linphoneCore.muteMic(true);
                mListener.onCallEventOccur(Constant.CALL_EVENT_MICRO_UNMUTED);
            }
        }
        return linphoneCore.isMicMuted();
    }

    public Boolean isMutedCamera() {
        LinphoneCall currentCall = linphoneCore.getCurrentCall();
        if (currentCall != null) {
            return !currentCall.cameraEnabled();
        }
        return false;
    }

    public boolean muteCamera() {
        LinphoneCall currentCall = linphoneCore.getCurrentCall();
        if (currentCall != null) {
            if (currentCall.cameraEnabled()) {
                currentCall.enableCamera(false);
                mListener.onCallEventOccur(Constant.CALL_EVENT_CAMERA_MUTED);
            } else {
                currentCall.enableCamera(true);
                mListener.onCallEventOccur(Constant.CALL_EVENT_CAMERA_UNMUTED);
            }
            return currentCall.cameraEnabled();
        }
        return false;
    }

    public void reOpen() {
        if (bAudioCall) {
            Intent intent = new Intent(mContext, CallInitActivity.class);
            intent.putExtra("show_mode", 2);
            mContext.startActivity(intent);
        } else {
            if (mVideoCallActivity != null){
                return;
            }
            Intent intent = new Intent(mContext, SipVideoCallActivity.class);
            intent.putExtra("gravity", 0);
            mContext.startActivity(intent);
        }
    }

    public void onChatMessageArrived() {
        badgeNum++;
        if (bAudioCall) {
            if (mCallInitActivity != null) {
                mCallInitActivity.startMessageSound();
                mCallInitActivity.increaseBadgeNumber();
            }
        } else {
            if (mVideoCallActivity != null) {
                mVideoCallActivity.startMessageSound();
                mVideoCallActivity.increaseBadgeNumber();
            }
        }
    }

    public void setOverlayBoundary(Rect newRect) {
        if (OverlayCreator.isReady()){
            OverlayCreator.getInstance(mContext).setOverlayBoundary(newRect);
        }
    }

    public void minimizeVideo() {
        String logString = "Event: User returned to normal view";
        insertLogString(logString);
        mListener.onCallMinimized(nCallDuration);
    }

    public void switchCamera() {
        try {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    Log.e(TAG, "Currently switching camera");
                    int videoDeviceId = linphoneCore.getVideoDevice();
                    videoDeviceId = (videoDeviceId + 1) % AndroidCameraConfiguration.retrieveCameras().length;

                    Log.e(TAG, "Original Video Device Id: " + linphoneCore.getVideoDevice() + " New Video Device Id: "
                            + videoDeviceId + " Video Device count: " + AndroidCameraConfiguration.retrieveCameras().length);
                    linphoneCore.setVideoDevice(videoDeviceId);

                    // update call
                    LinphoneCall lCall = linphoneCore.getCurrentCall();
                    linphoneCore.updateCall(lCall, null);

                    if (captureView != null) {
                        Log.e(TAG, "Setting linphone preview view again");
                        setLinphonePreviewView(captureView);
                    }
                }
            }).start();
        } catch (ArithmeticException ae) {
        }
    }

    public int getCameraCount() {
        return AndroidCameraConfiguration.retrieveCameras().length;
    }

    public void scaleVideo(int targetWidth, int targetHeight) {
        LinphoneManager.ScaleVideoTask scaleVideoTask = new LinphoneManager.ScaleVideoTask();
        scaleVideoTask.setDisplaySize(targetWidth, targetHeight);
        scaleVideoTask.execute();
    }

    public VideoSize getLocalVideoSize() {
        return linphoneCore.getPreferredVideoSize();
    }

    public LinphoneCore getLc(){
        return linphoneCore;
    }

    public void setLinphoneVideoView(AndroidVideoWindowImpl view) {// participant video
        if (linphoneCore != null) {
            linphoneCore.setVideoWindow(view);
        }
    }

    public void setLinphonePreviewView(SurfaceView view) {// local video
        if (linphoneCore != null) {
            linphoneCore.setPreviewWindow(view);
        }
    }

    public void setupVideo(AndroidVideoWindowImpl.VideoWindowListener listener) {
        if (listener != null && androidVideoWindowImpl == null){
            videoView = new CustomGLSurfaceView(mContext);
            captureView = new SurfaceView(mContext);

            androidVideoWindowImpl = new AndroidVideoWindowImpl(videoView, captureView, listener);
        }
    }

    public void removeParent(){
        if (videoView.getParent() != null){
            ((ViewGroup)videoView.getParent()).removeAllViews();
        }
        if (captureView.getParent() != null){
            ((ViewGroup)captureView.getParent()).removeAllViews();
        }
    }

    public Integer getCurrentRotation() {
            int rotation = ((WindowManager) mContext.getSystemService(WINDOW_SERVICE)).getDefaultDisplay()
                    .getRotation();
            return rotation;
    }

    public void onOrientationChange() {
        if (mVideoCallActivity == null){
            return;
        }
        int rotation = ((WindowManager) mVideoCallActivity.getSystemService(WINDOW_SERVICE)).getDefaultDisplay()
                .getRotation();

        if (linphoneCore == null || linphoneCore.getCurrentCall() == null)
            return;

        if (currentRotation != null && rotation != currentRotation) {
            Log.e(TAG, "Video Call Activity Orientation Changed.");
            setDeviceRotation(rotation);
            linphoneCore.updateCall(linphoneCore.getCurrentCall(), null);
        }

        currentRotation = rotation;
    }

    private void setDeviceRotation(Integer rotation) {

        rotation = (rotation != null) ? rotation : mVideoCallDisplay.getRotation();
        Log.e(TAG, "Current orientation = " + rotation);

        switch (rotation) {
            case Surface.ROTATION_0:
                linphoneCore.setDeviceRotation(0);
                break;
            case Surface.ROTATION_90:
                linphoneCore.setDeviceRotation(90);
                break;
            case Surface.ROTATION_180:
                linphoneCore.setDeviceRotation(180);
                break;
            case Surface.ROTATION_270:
                linphoneCore.setDeviceRotation(270);
                break;
            default:
                break;
        }
    }


    public void changeOrientation() {
        if (mVideoCallActivity != null){
            return;
        }
        int rotation = ((WindowManager) mContext.getSystemService(WINDOW_SERVICE)).getDefaultDisplay()
                .getRotation();

        if (linphoneCore == null || linphoneCore.getCurrentCall() == null)
            return;

        if (currentRotation != null && rotation != currentRotation) {
            setDeviceRotation(rotation);
            linphoneCore.updateCall(linphoneCore.getCurrentCall(), null);
        }

        currentRotation = rotation;

        OverlayCreator.getInstance(mContext).setOrientation(rotation);
    }

    public void disableAllCodecs() {
        PayloadType[] audioCodecs = linphoneCore.getAudioCodecs();
        for (PayloadType elem : audioCodecs) {
            try {
                linphoneCore.enablePayloadType(elem, false);
            } catch (LinphoneCoreException e) {
                e.printStackTrace();
            }
        }

        PayloadType[] videoCodecs = linphoneCore.getVideoCodecs();
        for (PayloadType elem : videoCodecs) {
            try {
                linphoneCore.enablePayloadType(elem, false);
            } catch (LinphoneCoreException e) {
                e.printStackTrace();
            }
        }
    }

    public void configurePayloadType(String type, int rate, int number) {
        PayloadType pt = linphoneCore.findPayloadType(type, rate);
        if (pt != null) {
            Log.e(TAG, "Payload Type: " + pt);
            try {
                if (number != -1) {
                    linphoneCore.setPayloadTypeNumber(pt, number);
                }
                linphoneCore.enablePayloadType(pt, true);
            } catch (LinphoneCoreException e) {
                e.printStackTrace();
            }
        }
    }

    private void insertLogString(String logString){
        String timeValue = "";
        if (nCallDuration != 0) {
            int seconds = nCallDuration % 60;
            int minutes = nCallDuration / 60 % 60;
            int hours = nCallDuration / 3600;

            if (hours > 0){
                timeValue += String.valueOf(hours) + "h ";
            }
            timeValue += String.valueOf(minutes) + "m " + String.valueOf(seconds) + "s";
        }
        String logStringWithTimevalue = "";
        if (!timeValue.isEmpty()) {
            logStringWithTimevalue = timeValue + ": " + logString;
        }else{
            logStringWithTimevalue = logString;
        }
        logsStatus += logStringWithTimevalue + ";\n";
    }

    public void updateNetworkReachability() {
        if (mConnectivityManager == null) return;

        boolean connected = false;
        NetworkInfo networkInfo = mConnectivityManager.getActiveNetworkInfo();
        connected = networkInfo != null && networkInfo.isConnected();

        if (networkInfo == null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                for (Network network : mConnectivityManager.getAllNetworks()) {
                    if (network != null) {
                        networkInfo = mConnectivityManager.getNetworkInfo(network);
                        if (networkInfo != null && networkInfo.isConnected()) {
                            connected = true;
                            break;
                        }
                    }
                }
            }
        }

        if (networkInfo == null || !connected) {
            Log.e(TAG, "No connectivity: setting network unreachable");
            nErrorCode = Constant.CALL_RESULT_ERROR_NETWORK_CHANGED;
            linphoneCore.setNetworkReachable(false);
//            mListener.onCallFailed(nErrorCode, logsStatus);
        } else if (dozeModeEnabled) {
            Log.e(TAG, "Doze Mode enabled: shutting down network");
            nErrorCode = Constant.CALL_RESULT_ERROR_NETWORK_CHANGED;
            linphoneCore.setNetworkReachable(false);
        } else if (connected){
//            manageTunnelServer(networkInfo);

            boolean wifiOnly = false;
            if (wifiOnly){
                if (networkInfo.getType() == ConnectivityManager.TYPE_WIFI) {
                    setDnsServers();
                    linphoneCore.setNetworkReachable(true);
                }
                else {
                    Log.e(TAG, "Wifi-only mode, setting network not reachable");
                    nErrorCode = Constant.CALL_RESULT_ERROR_NETWORK_CHANGED;
                    linphoneCore.setNetworkReachable(false);
                    mListener.onCallFailed(nErrorCode, logsStatus);
                }
            } else {
                int curtype = networkInfo.getType();

                if (curtype != mLastNetworkType) {
                    //if kind of network has changed, we need to notify network_reachable(false) to make sure all current connections are destroyed.
                    //they will be re-created during setNetworkReachable(true).
                    Log.e(TAG, "Connectivity has changed.");
                    nErrorCode = Constant.CALL_RESULT_ERROR_NETWORK_CHANGED;
                    linphoneCore.setNetworkReachable(false);
//                    mListener.onCallFailed(nErrorCode, logsStatus);
                }
                setDnsServers();
                linphoneCore.setNetworkReachable(true);
                mLastNetworkType = curtype;
            }
        }
    }

    public void setDnsServers() {
        if (mConnectivityManager == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M)
            return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (mConnectivityManager.getActiveNetwork() == null
                    || mConnectivityManager.getLinkProperties(mConnectivityManager.getActiveNetwork()) == null)
                return;

            int i = 0;
            List<InetAddress> inetServers = null;
            inetServers = mConnectivityManager.getLinkProperties(mConnectivityManager.getActiveNetwork()).getDnsServers();

            String[] servers = new String[inetServers.size()];

            for (InetAddress address : inetServers) {
                servers[i++] = address.getHostAddress();
            }
            linphoneCore.setDnsServers(servers);
        }
    }

    private void copyAssetsFromPackage(String basePath) throws IOException {
        Log.e(TAG, "base path: " + basePath);
        Log.e(TAG,"Rootca pem file Identifier: " + mContext.getApplicationContext().getResources().getIdentifier("rootca", "raw", mContext.getApplicationContext().getPackageName()));
        Utils.copyIfNotExist(mContext, mContext.getApplicationContext().getResources().getIdentifier("rootca", "raw", mContext.getApplicationContext().getPackageName()), basePath + "/rootca.pem");
    }

    /* Simple implementation as Android way seems very complicate:
        For example: with wifi and mobile actives; when pulling mobile down:
        I/Linphone( 8397): WIFI connected: setting network reachable
        I/Linphone( 8397): new state [RegistrationProgress]
        I/Linphone( 8397): mobile disconnected: setting network unreachable
        I/Linphone( 8397): Managing tunnel
        I/Linphone( 8397): WIFI connected: setting network reachable
        */
    public void connectivityChanged(ConnectivityManager cm, boolean noConnectivity) {
        mConnectivityManager = cm;
        updateNetworkReachability();
    }

    @Override
    public void authInfoRequested(LinphoneCore linphoneCore, String s, String s1, String s2) {

    }

    @Override
    public void authenticationRequested(LinphoneCore linphoneCore, LinphoneAuthInfo linphoneAuthInfo,
                                        LinphoneCore.AuthMethod authMethod) {

    }

    @Override
    public void callStatsUpdated(LinphoneCore linphoneCore, LinphoneCall linphoneCall,
                                 LinphoneCallStats linphoneCallStats) {

    }

    @Override
    public void newSubscriptionRequest(LinphoneCore linphoneCore, LinphoneFriend linphoneFriend, String s) {

    }

    @Override
    public void notifyPresenceReceived(LinphoneCore linphoneCore, LinphoneFriend linphoneFriend) {

    }

    @Override
    public void dtmfReceived(LinphoneCore linphoneCore, LinphoneCall linphoneCall, int i) {

    }

    @Override
    public void notifyReceived(LinphoneCore linphoneCore, LinphoneCall linphoneCall, LinphoneAddress linphoneAddress,
                               byte[] bytes) {

    }

    @Override
    public void transferState(LinphoneCore linphoneCore, LinphoneCall linphoneCall, LinphoneCall.State state) {

    }

    @Override
    public void infoReceived(LinphoneCore linphoneCore, LinphoneCall linphoneCall,
                             LinphoneInfoMessage linphoneInfoMessage) {

    }

    @Override
    public void subscriptionStateChanged(LinphoneCore linphoneCore, LinphoneEvent linphoneEvent,
                                         SubscriptionState subscriptionState) {

    }

    @Override
    public void publishStateChanged(LinphoneCore linphoneCore, LinphoneEvent linphoneEvent, PublishState publishState) {

    }

    @Override
    public void show(LinphoneCore linphoneCore) {

    }

    @Override
    public void displayStatus(LinphoneCore linphoneCore, String s) {
        Log.e(TAG, "Status: " + s);
    }

    @Override
    public void displayMessage(LinphoneCore linphoneCore, String s) {
        Log.e(TAG, "Message: " + s);
    }

    @Override
    public void displayWarning(LinphoneCore linphoneCore, String s) {
        Log.e(TAG, "Warning: " + s);
    }

    @Override
    public void fileTransferProgressIndication(LinphoneCore linphoneCore, LinphoneChatMessage linphoneChatMessage,
                                               LinphoneContent linphoneContent, int i) {

    }

    @Override
    public void fileTransferRecv(LinphoneCore linphoneCore, LinphoneChatMessage linphoneChatMessage,
                                 LinphoneContent linphoneContent, byte[] bytes, int i) {

    }

    @Override
    public int fileTransferSend(LinphoneCore linphoneCore, LinphoneChatMessage linphoneChatMessage,
                                LinphoneContent linphoneContent, ByteBuffer byteBuffer, int i) {
        return 0;
    }

    @Override
    public void globalState(LinphoneCore linphoneCore, LinphoneCore.GlobalState globalState, String s) {
        Log.e(TAG, "Global State:" + s);
        if (globalState == LinphoneCore.GlobalState.GlobalOn){
            try {
                Log.e("LinphoneManager"," globalState ON");
//                initLiblinphone(linphoneCore);
            } catch (Exception e) {
                Log.e(TAG, e.getMessage());
            }
        }
    }

    @Override
    public void registrationState(LinphoneCore linphoneCore, LinphoneProxyConfig linphoneProxyConfig,
                                  LinphoneCore.RegistrationState registrationState, String message) {
        Log.e(TAG, "Registration State: " + registrationState + " message: " + message);
        onRegisterState(registrationState, message);
    }

    @Override
    public void configuringStatus(LinphoneCore linphoneCore, LinphoneCore.RemoteProvisioningState remoteProvisioningState,
                                  String s) {
        Log.e(TAG, "Configuring Status:" + s);
    }

    @Override
    public void messageReceived(LinphoneCore linphoneCore, LinphoneChatRoom linphoneChatRoom,
                                LinphoneChatMessage linphoneChatMessage) {

    }

    @Override
    public void messageReceivedUnableToDecrypted(LinphoneCore linphoneCore, LinphoneChatRoom linphoneChatRoom,
                                                 LinphoneChatMessage linphoneChatMessage) {

    }

    @Override
    public void callState(LinphoneCore linphoneCore, LinphoneCall linphoneCall, LinphoneCall.State state, String s) {
        onCallState(linphoneCall, state, s);
    }

    @Override
    public void callEncryptionChanged(LinphoneCore linphoneCore, LinphoneCall linphoneCall, boolean b, String s) {

    }

    @Override
    public void notifyReceived(LinphoneCore linphoneCore, LinphoneEvent linphoneEvent, String s,
                               LinphoneContent linphoneContent) {

    }

    @Override
    public void isComposingReceived(LinphoneCore linphoneCore, LinphoneChatRoom linphoneChatRoom) {

    }

    @Override
    public void ecCalibrationStatus(LinphoneCore linphoneCore, LinphoneCore.EcCalibratorStatus ecCalibratorStatus, int i,
                                    Object o) {

    }

    @Override
    public void uploadProgressIndication(LinphoneCore linphoneCore, int i, int i1) {

    }

    @Override
    public void uploadStateChanged(LinphoneCore linphoneCore,
                                   LinphoneCore.LogCollectionUploadState logCollectionUploadState, String s) {

    }

    @Override
    public void friendListCreated(LinphoneCore linphoneCore, LinphoneFriendList linphoneFriendList) {

    }

    @Override
    public void friendListRemoved(LinphoneCore linphoneCore, LinphoneFriendList linphoneFriendList) {

    }

    @Override
    public void networkReachableChanged(LinphoneCore linphoneCore, boolean b) {
        Log.e(TAG, "Network Reachable Changed");
    }

    public void sendLinphoneDebug() {
        if (callData.logEnable){
            Utils.sendEmail(mContext, callData.toEmail, "Linphone Log file attached", "Linphone Debug");
        }
    }

    public class ScaleVideoTask extends AsyncTask<Void, Integer, Float> {

        private int displayWidth = -1;
        private int displayHeight = -1;

        public void setDisplaySize(int dw, int dh) {
            displayHeight = dh;
            displayWidth = dw;
        }

        @Override
        protected Float doInBackground(Void... params) {
            LinphoneCall call = linphoneCore.getCurrentCall();
            if (call != null) {
                Integer remoteVideoWidth = call.getCurrentParams().getReceivedVideoSize().width;
                Integer remoteVideoHeight = call.getCurrentParams().getReceivedVideoSize().height;
                Log.e(TAG, String.format("ScaleVideoTask: doInBackground, remoteVideoWidth = %d remoteVideoHeight = %d",
                        remoteVideoWidth, remoteVideoHeight));
                if (remoteVideoWidth != 0 && remoteVideoHeight != 0) {
                    return calculateScaleFactor(remoteVideoWidth, remoteVideoHeight);
                }
            }
            return null;
        }

        private Float calculateScaleFactor(float remoteVideoWidth, float remoteVideoHeight) {

            Log.e(TAG, "Remote video width: " + remoteVideoWidth);
            Log.e(TAG, "Remote video height: " + remoteVideoHeight);

            Float scaleFactor = 1f;

            float remoteDisplayWidth = displayWidth;
            float remoteDisplayHeight = displayHeight;

            if (displayHeight == -1 && displayWidth == -1) {
                // Get remote display ratio
                DisplayMetrics displaymetrics = new DisplayMetrics();
                ((Activity) mContext).getWindowManager().getDefaultDisplay().getMetrics(displaymetrics);
                remoteDisplayHeight = displaymetrics.heightPixels;
                remoteDisplayWidth = displaymetrics.widthPixels;
            }

            if (callData.zoomMode.equals("zoom")) {

            } else {
                remoteDisplayHeight = remoteDisplayWidth / remoteVideoWidth * remoteVideoHeight;
            }

            float remoteDisplayRatio = remoteDisplayWidth / remoteDisplayHeight;

            Log.e(TAG, "Remote display width: " + remoteDisplayWidth);
            Log.e(TAG, "Remote display height: " + remoteDisplayHeight);

            // Get remote video ratio
            float remoteVideoRatio = remoteVideoWidth / remoteVideoHeight;

            if (remoteVideoRatio > remoteDisplayRatio) {
                scaleFactor = 1 / (1 - ((remoteDisplayHeight - (remoteDisplayWidth / remoteVideoRatio)) / remoteDisplayHeight));
            } else if (remoteVideoRatio < remoteDisplayRatio) {
                scaleFactor = 1 / (1 - ((remoteDisplayWidth - (remoteDisplayHeight * remoteVideoRatio)) / remoteDisplayWidth));
            }

            return scaleFactor;
        }

        @Override
        protected void onPostExecute(Float scaleFactor) {
            Log.e(TAG, String.format("ScaleVideoTask: onPostExecute, scaleFactor = %f", scaleFactor));

            if (nCurCallState == Constant.CALL_ENDED) { // In this case, no need to execute following code.
                return;
            }

            if (scaleFactor != null && linphoneCore.getCurrentCall() != null) {
                linphoneCore.getCurrentCall().zoomVideo(scaleFactor, 0.5f, 0.5f);
                if (nCurCallState == Constant.CALL_CONNECTING) {
                    stopConnectingTimer();
                    showVideoCallScreen();
                    qualityLoop();
                }
            } else if (scaleFactor == null) {
                LinphoneManager.ScaleVideoTask task = new LinphoneManager.ScaleVideoTask();
                task.execute();
            }

            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
    }

    class CallTimerTask extends TimerTask {
        @Override
        public void run() {
            nCallDuration++;
            if (bAudioCall) {
                if (mCallInitActivity != null) {
                    mCallInitActivity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            if (mCallInitActivity != null) {
                                if (callData.callRecordingNotificationVisible.equals("yes") && nCallDuration >= 11) {
                                    mCallInitActivity.hideRecordingLayout();
                                }
                                mCallInitActivity.showCallDuration(nCallDuration);
                            }
                        }
                    });
                }
            } else {
                if (mVideoCallActivity != null) {
                    mVideoCallActivity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            if (mVideoCallActivity != null) {
                                if (mVideoCallActivity.bRecordingLayoutHidden == false && nCallDuration >= 11) {
                                    if (!mVideoCallActivity.isHiddenRecordingLayout()) {
                                        mVideoCallActivity.animateRaiseTopPanel();
                                        mVideoCallActivity.hideRecordingLayout();
                                    }
                                }
                                mVideoCallActivity.showCallDuration(nCallDuration);
                            }
                        }
                    });
                }
            }
            if (OverlayCreator.isReady()){
                OverlayCreator.getInstance(mContext).updateTimeOverlay(nCallDuration);
            }
        }
    }

    ;

    class ConnectingTimerTask extends TimerTask {
        @Override
        public void run() {
            Log.e(TAG, "Call Connecting Timeout");
            if (nCurCallState == Constant.CALL_CONNECTING) {

                String logString = String.format(Locale.ENGLISH, "---%s", "Establishing Timeout...");
                insertLogString(logString);

                nErrorCode = Constant.CALL_RESULT_ERROR_CONNECTING_TIMEOUT;
                connecting_failed_cnt++;
                bCallRetry = true;
                if (connecting_failed_cnt > MAX_RETRY_COUNT) {
                    bCallRetry = false;
                }
            }
            setCallReleasedReason(Constant.CALL_HANGUP_BY_ERROR);
            hangup();
        }
    }

    class RegisteringTimerTask extends TimerTask {
        @Override
        public void run() {
            if (checkNetwork){
                stopRegisteringTimer();
                mListener.onRegisterFailed("");
                return;
            }
            if (is_register_failed) {
                return;
            }
            Log.e(TAG, "Registering Timeout");
            String logString = String.format(Locale.ENGLISH, "---%s", "Registering Timeout...");
            insertLogString(logString);

            is_register_failed = true;

            regist_retry_cnt++;
            if (regist_retry_cnt < Constant.MAX_RETRY_COUNT) {

                enableLogCollection(true);

                logString = String.format(Locale.ENGLISH, "---%s", "Register Retrying");
                insertLogString(logString);
                if (mCallInitActivity != null) {
                    mCallInitActivity.setCallStatus(Constant.CALL_RETRYING, 0, current_turn_server_info);
                }

                new Timer().schedule(new TimerTask() {
                    @Override
                    public void run() {
                        Log.e(TAG, "Register Retrying...");
                        doRegister();
                    }
                }, 10000);
            } else {
                regist_retry_cnt = 0;
                nErrorCode = Constant.CALL_RESULT_ERROR_REGISTER_FAILURE;
                stopRegisteringTimer();
                if (mCallInitActivity != null) {
                    mCallInitActivity.finish();
                    mCallInitActivity = null;
                }
                mListener.onCallFailed(nErrorCode, logsStatus);
            }
        }
    }

    class UnregisteringTimerTask extends TimerTask {
        @Override
        public void run() {
            stopUnregisteringTimer();
            if (is_unregister_failed) {
                return;
            }
            Log.e(TAG, "Unregistering Timeout");
            //            String logString = String.format(Locale.ENGLISH, "---%s", "Unregistering Timeout...");
            //            logsStatus += logString + "\n";

            is_unregister_failed = true;

            nErrorCode = CALL_RESULT_ERROR_UNKNOWN;
            if (mCallInitActivity != null) {
                mCallInitActivity.finish();
                mCallInitActivity = null;
            }
            if (mVideoCallActivity != null) {
                mVideoCallActivity.finish();
                mVideoCallActivity = null;
            }
            mListener.onCallFailed(nErrorCode, logsStatus);
        }
    }

    class CallInitTimerTask extends TimerTask {
        @Override
        public void run() {
            Log.e(TAG, "Call Init Timeout");
            String logString = String.format(Locale.ENGLISH, "---%s", "Init Timeout...");
            insertLogString(logString);
            nErrorCode = CALL_RESULT_ERROR_INIT_TIMEOUT;
            hangup();
        }
    }

    class CallRingTimerTask extends TimerTask {
        @Override
        public void run() {
            Log.e(TAG, "Call Ring timeout");

            String logString = String.format(Locale.ENGLISH, "---%s", "Web User Not Found...");
            insertLogString(logString);

            nErrorCode = Constant.CALL_RESULT_ERROR_CALLEE_NOT_FOUND;
            setCallReleasedReason(Constant.CALL_HANGUP_BY_ERROR);
            hangup();
        }
    }

    class CallRingingTimerTask extends TimerTask {
        @Override
        public void run() {
            Log.e(TAG, "Call Ringing Timeout");
            String logString = String.format(Locale.ENGLISH, "---%s", "Ringing Timeout...");
            insertLogString(logString);

            nErrorCode = Constant.CALL_RESULT_ERROR_RINGING_TIMEOUT;
            setCallReleasedReason(Constant.CALL_HANGUP_BY_ERROR);
            hangup();
        }
    }

    public void setCheckNetwork(boolean check){
        checkNetwork = check;
    }
}
