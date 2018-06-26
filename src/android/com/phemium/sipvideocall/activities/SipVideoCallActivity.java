package com.phemium.sipvideocall.activities;

import java.io.IOException;
import java.util.Calendar;
import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;
import org.linphone.core.VideoSize;
import org.linphone.mediastream.video.AndroidVideoWindowImpl;
import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.support.design.widget.FloatingActionButton;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.AccelerateInterpolator;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.phemium.sipvideocall.LinphoneManager;
import com.phemium.sipvideocall.Utils;
import com.phemium.sipvideocall.constant.Constant;
import com.phemium.sipvideocall.data.LanguageResource;
import com.phemium.sipvideocall.views.OverlayCreator;
import com.phemium.sipvideocall.views.SignalView;

import static com.phemium.sipvideocall.constant.Constant.SWIPE_BOTTOM;
import static com.phemium.sipvideocall.constant.Constant.SWIPE_LEFT;
import static com.phemium.sipvideocall.constant.Constant.SWIPE_RIGHT;
import static com.phemium.sipvideocall.constant.Constant.SWIPE_TOP;

public class SipVideoCallActivity extends AppCompatActivity{

    private LinphoneManager linphoneManager;
    //UI Objects
    private FloatingActionButton butMute;
    private FloatingActionButton butMuteCamera;
    private FloatingActionButton butSwitchCamera;
    private FloatingActionButton butEndcall;
    private LinearLayout mControlsContainer;
    private LinearLayout mLargeVideoViewContainer;
    private LinearLayout mSmallVideoViewcontainer;
    private ImageView mStatusImageView1;
    private ImageView mStatusImageView2;

    private SignalView mSignalQualityView;
    private FrameLayout mFrameAlertMessage;
    //Recording Layout
    private RelativeLayout mRecordingLayout;
    private Button mRecordingLayoutCloseButton;
    public Boolean bRecordingLayoutHidden = false;

    private TextView mTxtCallDuration;
    private LinearLayout mTopPanel;
    private ImageView mBtnChat;

    private RelativeLayout badgeLayout;
    private TextView mTxtBadgeNum;
    private int badgeNum;

    private RelativeLayout signalLayout;
    private TextView mTxtSignalAlert;

    private Timer mSmallVideoMovingTimer;
    private Timer mHideControlContainerTimer;
    public static Boolean bRemoteVideoShowingOnSmallContainer = false;

    private float smallVideoViewOringY = 0;
    private float smallVideoViewOringX = 0;
    private Boolean bShownControls = true;
    private int call_result = Constant.NO_ERROR;
    private final String TAG = "SipVideoCallActivity";

    private MediaPlayer messagetoneMediaPlayer;

    private Handler mHandler = new Handler();

    private float x;
    private float y;
    private float touchX;
    private float touchY;
    private static final int MAX_CLICK_DURATION = 100;
    private long startClickTime;

    private boolean bSmallViewSwipe = false;

    public static boolean ACTIVITY_VISIBLE = false;

// ** On hold until we can fully implement "overlay video on chat mode" **
//  private Intent mServiceIntent; 

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);

        this.getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON | WindowManager.LayoutParams.FLAG_FULLSCREEN
                        | WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD | WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                        | WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON | WindowManager.LayoutParams.FLAG_FULLSCREEN
                        | WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD | WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                        | WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);

        setContentView(getApplicationContext().getResources().getIdentifier("activity_call", "layout",
                getApplicationContext().getPackageName()));

        Log.e(TAG, "onCreate called.");

// ** On hold until we can fully implement "overlay video on chat mode" **
//      mServiceIntent = new Intent(this, LinphoneService.class); 
//      startService(mServiceIntent); 

        linphoneManager = LinphoneManager.getInstance();
        linphoneManager.mVideoCallActivity = this;
        linphoneManager.badgeNum = 0;
        int gravity = getIntent().getIntExtra("gravity", Gravity.BOTTOM | Gravity.END);
        switch (gravity){
            case Gravity.TOP | Gravity.START:
                linphoneManager.swipeWState = SWIPE_LEFT;
                linphoneManager.swipeHState = SWIPE_TOP;
                break;
            case Gravity.BOTTOM | Gravity.START:
                linphoneManager.swipeWState = SWIPE_LEFT;
                linphoneManager.swipeHState = SWIPE_BOTTOM;
                break;
            case Gravity.TOP | Gravity.END:
                linphoneManager.swipeWState = SWIPE_RIGHT;
                linphoneManager.swipeHState = SWIPE_TOP;
                break;
            case Gravity.BOTTOM | Gravity.END:
                linphoneManager.swipeWState = SWIPE_RIGHT;
                linphoneManager.swipeHState = SWIPE_BOTTOM;
                break;
            case 0:
                break;
        }

        setUp();
    }

    @Override
    public void onStart(){
        super.onStart();
        OverlayCreator.getInstance(getApplicationContext()).destroyOverlay();
        setupVideo();
    }

    private void setUp() {
        setUpUi();

        //Below code is needed for orientation change event.
        showCallDuration(linphoneManager.nCallDuration);
        if (shouldHideRecordingLayout()) {
            hideRecordingLayout();
        }

//        ViewGroup rootView = (ViewGroup) getWindow().getDecorView();
//        LinearLayout content = (LinearLayout)rootView.getChildAt(0);
//        content.setOnLongClickListener(new View.OnLongClickListener() {
//            @Override
//            public boolean onLongClick(View view) {
//                Log.e(TAG, "Enable Linphone Log");
//                linphoneManager.enableLogCollection(true);
//                return false;
//            }
//        });
    }


    public void showCallDuration(int duration) {
        mTxtCallDuration.setText(Utils.secToTimeString(duration));
    }

    @Override
    public void onBackPressed() {

    }


    private void fixZOrder(SurfaceView bottom, SurfaceView top) {
        bottom.setZOrderOnTop(false);
        top.setZOrderOnTop(true);
        top.setZOrderMediaOverlay(true);
    }

    private void setupVideo() {

        AndroidVideoWindowImpl.VideoWindowListener listener = new AndroidVideoWindowImpl.VideoWindowListener() {
            @Override
            public void onVideoRenderingSurfaceReady(AndroidVideoWindowImpl vw, SurfaceView surface) {
                Log.e(TAG, "onVideoRenderingSurfaceReady called.");
                linphoneManager.setLinphoneVideoView(vw);
                linphoneManager.videoView = surface;
                if (linphoneManager.mVideoCallActivity != null) {
                    if (bRemoteVideoShowingOnSmallContainer) {
                        linphoneManager.scaleVideo(mSmallVideoViewcontainer.getWidth(), mSmallVideoViewcontainer.getHeight());
                    } else {
                        linphoneManager.scaleVideo(-1, -1);
                    }
                }else{
                    OverlayCreator.getInstance(getApplicationContext()).zoomVideo();
                }
            }

            @Override
            public void onVideoRenderingSurfaceDestroyed(AndroidVideoWindowImpl vw) {
                Log.e(TAG, "onVideoRenderingSurfaceDestroyed called.");
//                if (linphoneManager != null) {
//                    linphoneManager.setLinphoneVideoView(null);
//                }
            }

            @Override
            public void onVideoPreviewSurfaceReady(AndroidVideoWindowImpl vw, SurfaceView surface) {
                Log.e(TAG, "onVideoPreviewSurfaceReady called.");
                linphoneManager.captureView = surface;
                linphoneManager.setLinphonePreviewView(linphoneManager.captureView);

                if (bRemoteVideoShowingOnSmallContainer) {
                    resizeLargeVideoViewContainer();
                } else {
                    restoreLargeVideoViewContainer();
                }
            }

            @Override
            public void onVideoPreviewSurfaceDestroyed(AndroidVideoWindowImpl vw) {
                // Remove references kept in jni code and restart camera
//                linphoneManager.setLinphonePreviewView(null);
            }
        };
        // captureView.getHolder().setFormat(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        linphoneManager.setupVideo(listener);

        if (!bRemoteVideoShowingOnSmallContainer) {
            fixZOrder(linphoneManager.videoView, linphoneManager.captureView);
        } else {
            fixZOrder(linphoneManager.captureView, linphoneManager.videoView);
        }

        linphoneManager.removeParent();
        if (!bRemoteVideoShowingOnSmallContainer) {
            mLargeVideoViewContainer.addView(linphoneManager.videoView);
            mSmallVideoViewcontainer.addView(linphoneManager.captureView);
        } else {
            mSmallVideoViewcontainer.addView(linphoneManager.videoView);
            mLargeVideoViewContainer.addView(linphoneManager.captureView);
        }

        linphoneManager.onOrientationChange();
    }

    private void setUpUi() {
        butEndcall = (FloatingActionButton) findViewById(getApplicationContext().getResources().getIdentifier("closeButton", "id", getApplicationContext().getPackageName()));
        butEndcall.setBackgroundTintList(ColorStateList.valueOf(Color.argb(255, 221, 61, 52)));
        butEndcall.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                closeCall();
            }
        });

        butMute = (FloatingActionButton) findViewById(getApplicationContext().getResources().getIdentifier("muteMicButton", "id", getApplicationContext().getPackageName()));
        butMute.setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(linphoneManager.callData.mainColor)));

        butMute.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                muteMic();
                hideControlsContainer();
                //startHidingControlContainerTimer();
            }
        });

        butMuteCamera = (FloatingActionButton) findViewById(getApplicationContext().getResources().getIdentifier("muteCamButton", "id", getApplicationContext().getPackageName()));
        butMuteCamera.setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(linphoneManager.callData.mainColor)));
        butMuteCamera.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                muteCamera();
                hideControlsContainer();
                //startHidingControlContainerTimer();
            }
        });
        // if camera is disabled,
        if (!linphoneManager.bCameraPermissionAllowed) {
            butMuteCamera.setAlpha(0.5f);
            butMuteCamera.setEnabled(false);
        }

        butSwitchCamera = (FloatingActionButton) findViewById(getApplicationContext().getResources().getIdentifier("switchCameraButton", "id", getApplicationContext().getPackageName()));
        butSwitchCamera.setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(linphoneManager.callData.mainColor)));
        butSwitchCamera.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                switchCamera();
                hideControlsContainer();
                //startHidingControlContainerTimer();
            }
        });
        // if camera is disabled or camera count is less than 2,
        if (!linphoneManager.bCameraPermissionAllowed || linphoneManager.getCameraCount() <= 1) {
            butSwitchCamera.setAlpha(0.5f);
            butSwitchCamera.setEnabled(false);
        }

        mControlsContainer = (LinearLayout) findViewById(getApplicationContext().getResources().getIdentifier("controlsContainer", "id", getApplicationContext().getPackageName()));
        mLargeVideoViewContainer = (LinearLayout) findViewById(getApplicationContext().getResources().getIdentifier("videoSurface", "id", getApplicationContext().getPackageName()));
        LinearLayout tapLayoutForShowingControlView = (LinearLayout) findViewById(getApplicationContext().getResources().getIdentifier("videoSurfaceContainer", "id", getApplicationContext().getPackageName()));
        tapLayoutForShowingControlView.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                onRemoteViewTapped();
            }
        });

        mSmallVideoViewcontainer = (LinearLayout) findViewById(getApplicationContext().getResources().getIdentifier("videoCaptureSurface", "id", getApplicationContext().getPackageName()));
        // if camera is disabled,
        if (!linphoneManager.bCameraPermissionAllowed && !bRemoteVideoShowingOnSmallContainer) {
            mSmallVideoViewcontainer.setVisibility(View.GONE);
        }
//        VideoSize localVideoSize = linphoneManager.getLocalVideoSize();
//        int rotation = ((WindowManager) getSystemService(WINDOW_SERVICE)).getDefaultDisplay().getRotation();
//        if (localVideoSize.width > 0 && localVideoSize.height > 0) {
//            int w = (localVideoSize.width > localVideoSize.height)? localVideoSize.width: localVideoSize.height;
//            int h = (localVideoSize.width < localVideoSize.height)? localVideoSize.width: localVideoSize.height;
//            if (rotation == 0 || rotation == 2) {
//                Log.e(TAG, "portrait mode. width:" + w + " height:" + h);
//                mSmallVideoViewcontainer.getLayoutParams().width = (int)(mSmallVideoViewcontainer.getLayoutParams().height * 1.0f / w * h);
//            } else {
//                Log.e(TAG, "landscape mode. width:" + w + " height:" + h);
//                mSmallVideoViewcontainer.getLayoutParams().width = (int)(mSmallVideoViewcontainer.getLayoutParams().height * 1.0f / h * w);
//            }
//        }

        mSignalQualityView = (SignalView) findViewById(getApplicationContext().getResources().getIdentifier("signalview", "id", getApplicationContext().getPackageName()));
        mFrameAlertMessage = (FrameLayout) findViewById(getApplicationContext().getResources().getIdentifier("alert_message", "id", getApplicationContext().getPackageName()));

        mStatusImageView1 = (ImageView) findViewById(getApplicationContext().getResources().getIdentifier("statusImage1", "id", getApplicationContext().getPackageName()));
        mStatusImageView2 = (ImageView) findViewById(getApplicationContext().getResources().getIdentifier("statusImage2", "id", getApplicationContext().getPackageName()));

        bShownControls = true;
        updateMuteCameraDrawable(linphoneManager.isMutedCamera());
        updateMuteMicDrawable(linphoneManager.isMutedMic());


        mTopPanel = (LinearLayout) findViewById(getApplicationContext().getResources().getIdentifier("topPanel", "id", getApplicationContext().getPackageName()));
        mTopPanel.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(View view, int i, int i1, int i2, int i3, int i4, int i5, int i6, int i7) {
                if (shouldHideRecordingLayout()) {
                    mTopPanel.setY(Utils.dpToPx(SipVideoCallActivity.this, 20));
                }
                moveSmallVideo(linphoneManager.swipeHState, linphoneManager.swipeWState);
                mTopPanel.removeOnLayoutChangeListener(this);
            }
        });

        mSmallVideoViewcontainer.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(View view, int i, int i1, int i2, int i3, int i4, int i5, int i6, int i7) {
                smallVideoViewOringY = mSmallVideoViewcontainer.getY();
                smallVideoViewOringX = mSmallVideoViewcontainer.getX();

                moveSmallVideo(linphoneManager.swipeHState, linphoneManager.swipeWState);
                mSmallVideoViewcontainer.removeOnLayoutChangeListener(this);
                Log.e(TAG, "SmallVideoViewContainer layout changed. orign.y = " + smallVideoViewOringY);
            }
        });
//        mSmallVideoViewcontainer.setOnClickListener(new OnClickListener() {
//            @Override
//            public void onClick(View view) {
//                switchVideo();
//            }
//        });

        badgeNum = linphoneManager.badgeNum;
        mTxtBadgeNum = (TextView) findViewById(getApplicationContext().getResources().getIdentifier("txtCount", "id", getApplicationContext().getPackageName()));
        badgeLayout = (RelativeLayout) findViewById(getApplicationContext().getResources().getIdentifier("badge_layout", "id", getApplicationContext().getPackageName()));
        badgeLayout.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(View view, int i, int i1, int i2, int i3, int i4, int i5, int i6, int i7) {
                if (shouldHideRecordingLayout()) {
                    badgeLayout.setY(Utils.dpToPx(SipVideoCallActivity.this, 20));
                }
            }
        });

        signalLayout = (RelativeLayout) findViewById(getApplicationContext().getResources().getIdentifier("signal_layout", "id", getApplicationContext().getPackageName()));
        signalLayout.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(View view, int i, int i1, int i2, int i3, int i4, int i5, int i6, int i7) {
                if (shouldHideRecordingLayout()) {
                    signalLayout.setY(Utils.dpToPx(SipVideoCallActivity.this, 20));
                }
            }
        });

        mTxtSignalAlert = (TextView) findViewById(getApplicationContext().getResources().getIdentifier("txt_signalalert", "id", getApplicationContext().getPackageName()));
        mTxtSignalAlert.setText(LanguageResource.getInstance().getStringValue("low_signal_alert"));

        mBtnChat = (ImageView) findViewById(getApplicationContext().getResources().getIdentifier("btn_chat", "id", getApplicationContext().getPackageName()));
        mBtnChat.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
                linphoneManager.minimizeVideo();
            }
        });
        if (linphoneManager.callData.chatMode.equals("NoChat")){
            mBtnChat.setVisibility(View.INVISIBLE);
        }

//        mBtnChat.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
//            @Override
//            public void onLayoutChange(View view, int i, int i1, int i2, int i3, int i4, int i5, int i6, int i7) {
//                if (shouldHideRecordingLayout()) {
//                    mBtnChat.setY(Utils.dpToPx(SipVideoCallActivity.this, 20));
//                }
//
//                // Get the SurfaceView layout parameters
//                ViewGroup.LayoutParams lp = (ViewGroup.LayoutParams) mBtnChat.getLayoutParams();
//                lp.width = Utils.dpToPx(SipVideoCallActivity.this, 30);
//                lp.height = Utils.dpToPx(SipVideoCallActivity.this, 28);
//
//                // Commit the layout parameters
//                mBtnChat.setLayoutParams(lp);
//
//                mBtnChat.removeOnLayoutChangeListener(this);
//            }
//        });

        if (badgeNum == 0){
            mTxtBadgeNum.setVisibility(View.INVISIBLE);
        }else{
            mTxtBadgeNum.setText(String.valueOf(badgeNum));
            mTxtBadgeNum.setVisibility(View.VISIBLE);
        }

        TextView calleeName = (TextView) findViewById(getApplicationContext().getResources().getIdentifier("calleeName", "id", getApplicationContext().getPackageName()));
        calleeName.setText(linphoneManager.callData.consultantName);
        mTxtCallDuration = (TextView) findViewById(getApplicationContext().getResources().getIdentifier("callDuration", "id", getApplicationContext().getPackageName()));
        if (linphoneManager.callData.displayTopViewMode.equals("never")) {
            mTopPanel.setVisibility(View.GONE);
        }

        mRecordingLayout = (RelativeLayout) findViewById(getApplicationContext().getResources().getIdentifier("videocall_recordingLayout", "id", getApplicationContext().getPackageName()));
        mRecordingLayoutCloseButton = (Button) findViewById(getResources().getIdentifier("videocall_recordingLayoutClose", "id", getApplicationContext().getPackageName()));
        mRecordingLayoutCloseButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                Log.e(TAG, "RecordingLayout close button pressed.");
                mRecordingLayout.setVisibility(View.GONE);
                animateRaiseTopPanel();
                bRecordingLayoutHidden = true;
            }
        });
        TextView recordingText = (TextView) findViewById(getApplicationContext().getResources().getIdentifier("videocall_recordingText", "id", getApplicationContext().getPackageName()));
        recordingText.setText(LanguageResource.getInstance().getStringValue("recording"));

        if (linphoneManager.callData.callRecordingNotificationVisible.equals("yes")) {
            bRecordingLayoutHidden = false;
        } else {
            bRecordingLayoutHidden = true;
        }

        AssetManager am = getApplicationContext().getAssets();
        Typeface typefaceGothamBold  = Typeface.createFromAsset(am, String.format(Locale.US, "fonts/%s", "ufonts.com_gotham-bold.ttf"));
        Typeface typefaceGothamLight = Typeface.createFromAsset(am, String.format(Locale.US, "fonts/%s", "ufonts.com_gotham-light.ttf"));
        calleeName.setTypeface(typefaceGothamBold);
        mTxtCallDuration.setTypeface(typefaceGothamLight);
        recordingText.setTypeface(typefaceGothamLight);
        calleeName.setTextSize(linphoneManager.callData.fontSize);

        mTxtCallDuration.setTextSize(linphoneManager.callData.fontSize - Constant.FONT_SIZE_OFFSET_STATUS_LABEL);

        mSmallVideoViewcontainer.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent event) {
                x = event.getRawX();
                y = event.getRawY();
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        touchX = event.getX();
                        touchY = event.getY();
                        startClickTime = Calendar.getInstance().getTimeInMillis();
                        break;
                    case MotionEvent.ACTION_MOVE:
                        updateViewPosition();
                        break;
                    case MotionEvent.ACTION_CANCEL:
                    case MotionEvent.ACTION_UP:
                        touchX = touchY = 0;
                        long clickDuration = Calendar.getInstance().getTimeInMillis() - startClickTime;
                        if(clickDuration < MAX_CLICK_DURATION) {
                            //click event has occurred
                            switchVideo();
                        }else {
//				            dragEnabled = false;
                            resetViewPosition();
                        }
                        break;
                    default:
                        break;
                }
                return true;
            }
        });

        startHidingControlContainerTimer();
    }


    public void updateCallStatus(final float callQuality){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (callQuality < Constant.CALL_QUALITY_ALERT_VALUE){
                    mFrameAlertMessage.setVisibility(View.VISIBLE);
                }else{
                    mFrameAlertMessage.setVisibility(View.INVISIBLE);
                }
                mSignalQualityView.setProgress((int)Math.round(callQuality));
            }
        });
    }

    private void updateViewPosition() {
        float xPos = x - touchX;
        float yPos = y - touchY;
        mSmallVideoViewcontainer.setX(xPos);
        mSmallVideoViewcontainer.setY(yPos);
    }

    private void resetViewPosition(){
        Log.e(TAG, "Reset View Position");
        float TopY = 0;
        if (y < mLargeVideoViewContainer.getHeight() / 2){
            TopY = mTopPanel.getY() + mTopPanel.getHeight() + 12;
            linphoneManager.swipeHState = SWIPE_TOP;
        }else{
            if (bShownControls) {
                TopY = smallVideoViewOringY;
            } else {
                TopY = smallVideoViewOringY + 100;
            }
            linphoneManager.swipeHState = SWIPE_BOTTOM;
        }

        float LeftX = 0;
        if (x < mLargeVideoViewContainer.getWidth() / 2){
            LeftX = 24;
            linphoneManager.swipeWState = SWIPE_LEFT;
        }else{
            LeftX = smallVideoViewOringX;
            linphoneManager.swipeWState = SWIPE_RIGHT;
        }

        AnimatorSet animatorSet = new AnimatorSet();
        ObjectAnimator xAnimator = ObjectAnimator.ofFloat(mSmallVideoViewcontainer, View.X, LeftX);
        xAnimator.setDuration(500);
        xAnimator.setInterpolator(new AccelerateInterpolator());

        ObjectAnimator yAnimator = ObjectAnimator.ofFloat(mSmallVideoViewcontainer, View.Y, TopY);
        yAnimator.setDuration(500);
        yAnimator.setInterpolator(new AccelerateInterpolator());

        animatorSet.playTogether(xAnimator, yAnimator);
        animatorSet.start();

        final float xPos = LeftX;
        final float yPos = TopY;
        animatorSet.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                 mSmallVideoViewcontainer.setX(xPos);
                 mSmallVideoViewcontainer.setY(yPos);

            }
        });
    }

    public void moveSmallVideo(int swipeHState, int swipeWState){
        Log.i(TAG, "hstate:"+ swipeHState + ", wstate: " + swipeWState + " originx:" + smallVideoViewOringX + " originY: "+ smallVideoViewOringY);
        if (swipeHState == SWIPE_TOP){
            float TopY = mTopPanel.getY() + mTopPanel.getHeight() + 12;
            mSmallVideoViewcontainer.setY(TopY);
        }else{
            if (bShownControls) {
                mSmallVideoViewcontainer.setY(smallVideoViewOringY);
            } else {
                mSmallVideoViewcontainer.setY(smallVideoViewOringY + 100);
            }
        }

        if (swipeWState == SWIPE_LEFT){
            float LeftX = 24;
            mSmallVideoViewcontainer.setX(LeftX);
        }else{
            mSmallVideoViewcontainer.setX(smallVideoViewOringX);
        }
        mSmallVideoViewcontainer.startLayoutAnimation();
    }

    public void increaseBadgeNumber(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mTxtBadgeNum != null) {
                    mTxtBadgeNum.setText("" + linphoneManager.badgeNum);
                    mTxtBadgeNum.setVisibility(View.VISIBLE);
                }
            }
        });
    }

    public void clearBadge(){
        mTxtBadgeNum.setText("");
        mTxtBadgeNum.setVisibility(View.INVISIBLE);
    }

    public void startMessageSound() {
        Log.e(TAG, "Playing Incoming Message Sound");

        if (messagetoneMediaPlayer != null) {
            return;
        }

        //ringtoneMediaPlayer = MediaPlayer.create(this, R.raw.ringback);
        messagetoneMediaPlayer = new MediaPlayer();
        try {
            messagetoneMediaPlayer.setDataSource(this, Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + getApplicationContext().getPackageName() + "/" + getApplicationContext().getResources().getIdentifier("orig", "raw", getApplicationContext().getPackageName())));
        } catch (IOException e) {
            e.printStackTrace();
        }
        messagetoneMediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
            @Override
            public boolean onError(MediaPlayer mediaPlayer, int i, int i1) {
                Log.e(TAG, "ringtone play error occured");
                return false;
            }
        });
        messagetoneMediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(final MediaPlayer mediaPlayer) {
                Log.e(TAG, "Mediaplay Play completed.");
            }
        });
        messagetoneMediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mediaPlayer) {
                Log.e(TAG, "Media Player prepared.");
                messagetoneMediaPlayer.start();
            }
        });
    }

    public void stopRingSound() {
        if (messagetoneMediaPlayer != null) {
            if (messagetoneMediaPlayer.isPlaying()) {
                messagetoneMediaPlayer.stop();
            }
            messagetoneMediaPlayer.release();
            messagetoneMediaPlayer.setOnCompletionListener(null);
            messagetoneMediaPlayer = null;
            mHandler.removeCallbacksAndMessages(null);
        }
    }

    private void resizeLargeVideoViewContainer() {
        int largeWidth = getWindowManager().getDefaultDisplay().getWidth();
        int largeHeight = getWindowManager().getDefaultDisplay().getHeight();
        float largeProportion = (float) largeWidth / (float) largeHeight;

        // Get the width of the screen
        int smallWidth = mSmallVideoViewcontainer.getWidth();
        int smallHeight = mSmallVideoViewcontainer.getHeight();
        float smallProportion = (float) smallWidth / (float) smallHeight;

        Log.e(TAG, "LargeProportion: " + largeProportion + " SmallProportion: " + smallProportion);

        // Get the SurfaceView layout parameters
        LinearLayout.LayoutParams lp = (LinearLayout.LayoutParams) mLargeVideoViewContainer.getLayoutParams();
        if (largeProportion < smallProportion) {
            lp.width = (int)(smallProportion * largeHeight);
            Log.e(TAG, "original width: " + largeWidth + " new width: " + lp.width);
            lp.height = LinearLayout.LayoutParams.MATCH_PARENT;
        } else {
            lp.width = LinearLayout.LayoutParams.MATCH_PARENT;
            lp.height = (int)(largeWidth / smallProportion);
        }
        // Commit the layout parameters
        mLargeVideoViewContainer.setLayoutParams(lp);
    }

    private void restoreLargeVideoViewContainer() {
        LinearLayout.LayoutParams lp = (LinearLayout.LayoutParams) mLargeVideoViewContainer.getLayoutParams();
        lp.width = LinearLayout.LayoutParams.MATCH_PARENT;
        lp.height = LinearLayout.LayoutParams.MATCH_PARENT;
        mLargeVideoViewContainer.setLayoutParams(lp);
    }

    private void startHidingControlContainerTimer() {
        if (mHideControlContainerTimer != null) {
            mHideControlContainerTimer.cancel();
            mHideControlContainerTimer = null;
        }
        mHideControlContainerTimer = new Timer();
        mHideControlContainerTimer.schedule(new HideControlContainerTask(), Constant.HIDE_CONTROL_CONTAINER_MSECS);
    }

    protected void muteMic() {
        boolean muted = linphoneManager.muteMic();
        updateMuteMicDrawable(muted);
    }

    protected void muteCamera() {
        boolean camera_muted = linphoneManager.isMutedCamera();
        if (!camera_muted && bRemoteVideoShowingOnSmallContainer) {
            switchVideo();
            updateMuteCameraDrawable(!linphoneManager.muteCamera());
        } else {
            updateMuteCameraDrawable(!linphoneManager.muteCamera());
        }
    }

    private void updateMuteMicDrawable(boolean muted) {
        if (muted) {
            butMute.setImageResource(getApplicationContext().getResources().getIdentifier("videocall_unmute",
                    "drawable", getApplicationContext().getPackageName()));
        } else {
            butMute.setImageResource(getApplicationContext().getResources().getIdentifier("videocall_status_mute",
                    "drawable", getApplicationContext().getPackageName()));
        }
    }

    private void updateMuteCameraDrawable(boolean camera_muted) {
        if (camera_muted) {
            butMuteCamera.setImageResource(getApplicationContext().getResources().getIdentifier("videocall_unmute_camera",
                    "drawable", getApplicationContext().getPackageName()));
            butSwitchCamera.setAlpha(0.5f);
            if (!bRemoteVideoShowingOnSmallContainer) {
                mSmallVideoViewcontainer.setVisibility(View.INVISIBLE);
            } else {
                mLargeVideoViewContainer.setVisibility(View.INVISIBLE);
            }
            if (linphoneManager.captureView != null) {
                linphoneManager.captureView.setVisibility(View.INVISIBLE);
            }
        } else {
            butMuteCamera.setImageResource(getApplicationContext().getResources().getIdentifier("videocall_mute_camera",
                    "drawable", getApplicationContext().getPackageName()));
            if (linphoneManager.getCameraCount() > 1) {
                if (linphoneManager.bCameraPermissionAllowed){
                    butSwitchCamera.setAlpha(1.0f);
                }else{
                    butSwitchCamera.setAlpha(0.5f);
                }
            }
            if (!bRemoteVideoShowingOnSmallContainer) {
                mSmallVideoViewcontainer.setVisibility(View.VISIBLE);
            } else {
                mLargeVideoViewContainer.setVisibility(View.VISIBLE);
            }
            if (linphoneManager.captureView != null) {
                linphoneManager.captureView.setVisibility(View.VISIBLE);
            }
        }
    }

    private void switchCamera() {
        linphoneManager.switchCamera();
        // previous call will cause graph reconstruction -> regive preview window

    }

    private void switchVideo() {
        if (linphoneManager.captureView != null) {
            if (!bRemoteVideoShowingOnSmallContainer) {
                mLargeVideoViewContainer.removeAllViews();
                mSmallVideoViewcontainer.removeAllViews();
                resizeLargeVideoViewContainer();

                mLargeVideoViewContainer.addView(linphoneManager.captureView);
                mSmallVideoViewcontainer.addView(linphoneManager.videoView);
                fixZOrder(linphoneManager.captureView, linphoneManager.videoView);
                linphoneManager.scaleVideo(mSmallVideoViewcontainer.getWidth(), mSmallVideoViewcontainer.getHeight());
            } else {
                mLargeVideoViewContainer.removeAllViews();
                mSmallVideoViewcontainer.removeAllViews();
                restoreLargeVideoViewContainer();
                mSmallVideoViewcontainer.addView(linphoneManager.captureView);
                fixZOrder(linphoneManager.videoView, linphoneManager.captureView);
                linphoneManager.scaleVideo(-1, -1);
                mLargeVideoViewContainer.addView(linphoneManager.videoView);
            }
            Log.e(TAG, "Switch Video");
            bRemoteVideoShowingOnSmallContainer = !bRemoteVideoShowingOnSmallContainer;
        }
    }

    public void hideRecordingLayout() {
        if (mRecordingLayout.getVisibility() != View.GONE) {
            Log.e(TAG, "hideRecordingLayout(): Hiding Recoring Layout");
            mRecordingLayout.setVisibility(View.GONE);
        }
    }

    public boolean isHiddenRecordingLayout() {
        if (mRecordingLayout.getVisibility() == View.VISIBLE) {
            return false;
        } else {
            return true;
        }
    }

    private boolean shouldHideRecordingLayout() {
        if (bRecordingLayoutHidden == false) {
            if(linphoneManager.nCallDuration >= 11) {
                return true;
            }
        } else {
            return true;
        }
        return false;
    }

    public void animateRaiseTopPanel() {
        float topPanelY = mTopPanel.getY();
        Log.e(TAG, "animateRaiseTopPanel function called. topPanelY: " + topPanelY);

        TranslateAnimation translateAnimation = new TranslateAnimation(Animation.ABSOLUTE, 0, Animation.ABSOLUTE, 0, Animation.ABSOLUTE, 0, Animation.ABSOLUTE,(-1)*(topPanelY -Utils.dpToPx(this, 20)));
        translateAnimation.setDuration(500);
        translateAnimation.setFillAfter(false);

        translateAnimation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                Log.e(TAG, "animateRaiseTopPanel animation end. currentY: " + mTopPanel.getY());
                mTopPanel.setTop(Utils.dpToPx(SipVideoCallActivity.this, 20));
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });
        mTopPanel.setAnimation(translateAnimation);
        badgeLayout.animate().translationY((-1)*(badgeLayout.getY() -Utils.dpToPx(this, 20))).withLayer();
    }

    protected void closeCall() {
        linphoneManager.setCallReleasedReason(Constant.CALL_HANGUP_BY_CALLER);
        linphoneManager.hangup();
    }


    private void finalize_activity() {
        // finishing_call = true;
        Intent intent = new Intent();
        setResult(call_result, intent);
        finish();
    }

//    private class HeadsetPlugReceiver extends BroadcastReceiver {
//        @Override
//        public void onReceive(Context context, Intent intent) {
//            if (intent.getAction().equals(Intent.ACTION_HEADSET_PLUG)) {
//                int state = intent.getIntExtra("state", -1);
//                switch (state) {
//                    case 0:
//                        linphoneCore.enableSpeaker(true);
//                        break;
//                    case 1:
//                        linphoneCore.enableSpeaker(false);
//                        break;
//                    default:
//                        break;
//                }
//            }
//        }
//    }

    @Override
    protected void onResume() {
//        if (headsetPlugReceiver != null) {
//            IntentFilter filter = new IntentFilter(Intent.ACTION_HEADSET_PLUG);
//            registerReceiver(headsetPlugReceiver, filter);
//        }
        super.onResume();
        ACTIVITY_VISIBLE = true;
    }

    @Override
    protected void onPause() {
//        if (headsetPlugReceiver != null) {
//            unregisterReceiver(headsetPlugReceiver);
//        }
        Log.e(TAG, "onPause called.");
        if (mSmallVideoMovingTimer != null) {
            mSmallVideoMovingTimer.cancel();
            mSmallVideoMovingTimer = null;
        }
        super.onPause();
        ACTIVITY_VISIBLE = false;
    }

    @Override
    protected void onStop() {
        Log.e(TAG, "onStop called.");
//        bOnceStopped = true;
        int position = 0;
        if (linphoneManager.swipeHState == SWIPE_TOP){
            if (linphoneManager.swipeWState == SWIPE_LEFT){
                position = 0;
            }
            if (linphoneManager.swipeWState == SWIPE_RIGHT){
                position = 1;
            }
        }
        if (linphoneManager.swipeHState == SWIPE_BOTTOM){
            if (linphoneManager.swipeWState == SWIPE_LEFT){
                position = 2;
            }
            if (linphoneManager.swipeWState == SWIPE_RIGHT){
                position = 3;
            }
        }

        mSmallVideoViewcontainer.removeAllViews();
        mLargeVideoViewContainer.removeAllViews();
//        if (LinphoneService.isReady()){
//            LinphoneService.instance().createOverlay(mSmallVideoViewcontainer.getWidth(), mSmallVideoViewcontainer.getHeight(), position);
//        }
        OverlayCreator.getInstance(getApplicationContext()).createOverlay(mSmallVideoViewcontainer.getWidth(), mSmallVideoViewcontainer.getHeight(), position);
        super.onStop();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        switch (requestCode) {
            case Constant.PERMISSION_CHECK_MEDIA: {
                if (grantResults.length > 1 && grantResults[0] == PackageManager.PERMISSION_GRANTED
                        && grantResults[1] == PackageManager.PERMISSION_GRANTED) {
                    setUp();
                } else {
                    call_result = Constant.CALL_RESULT_ERROR_RECORD_PERMISSION_NOT_ALLOWED;
                    finalize_activity();
                }
                return;
            }
        }
    }

    class HideControlContainerTask extends TimerTask {
        @Override
        public void run() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    hideControlsContainer();
                }
            });
        }
    }

    private void hideControlsContainer() {
        if (mSmallVideoMovingTimer != null ){
            startHidingControlContainerTimer();
            return;
        }

        if (mHideControlContainerTimer != null) {
            mHideControlContainerTimer.cancel();
            mHideControlContainerTimer = null;
        }

        bShownControls = false;
        AlphaAnimation animation = new AlphaAnimation(1.0f, 0.0f);
        animation.setDuration(500);
        animation.setStartOffset(0);
        animation.setFillAfter(true);

        animation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
                butMute.setEnabled(false);
                butMuteCamera.setEnabled(false);
                butSwitchCamera.setEnabled(false);
                butEndcall.setEnabled(false);
            }

            @Override
            public void onAnimationEnd(Animation animation) {
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });
        mControlsContainer.startAnimation(animation);
        if (linphoneManager.callData.displayTopViewMode.equals("atScreenTouch")) {
            mTopPanel.startAnimation(animation);
        }

        checkDisabledDeviceStatus();
        upLocalVideo(false);
    }

    private void showControlsContainer() {
        bShownControls = true;
        AlphaAnimation animation = new AlphaAnimation(0.0f, 1.0f);
        animation.setDuration(500);
        animation.setStartOffset(0);
        animation.setFillAfter(true);

        animation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                butMute.setEnabled(true);
                if (linphoneManager.bCameraPermissionAllowed){
                    butMuteCamera.setEnabled(true);
                    butSwitchCamera.setEnabled(true);
                }else {
                    butMuteCamera.setEnabled(false);
                    butSwitchCamera.setEnabled(false);
                }
                butEndcall.setEnabled(true);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });

        mControlsContainer.startAnimation(animation);
        if (linphoneManager.callData.displayTopViewMode.equals("atScreenTouch")) {
            mTopPanel.startAnimation(animation);
        }
        upLocalVideo(true);
    }


    private void upLocalVideo(boolean up){
        if (linphoneManager.swipeHState == SWIPE_TOP){
            return;
        }
        if (bSmallViewSwipe){
            return;
        }
        if (mSmallVideoMovingTimer != null) {
            mSmallVideoMovingTimer.cancel();
            mSmallVideoMovingTimer = null;
        }
        if (mSmallVideoViewcontainer == null){
            return;
        }
        mSmallVideoMovingTimer = new Timer();
        Log.e(TAG, "Original Y: " + smallVideoViewOringY + " Current Y: " + mSmallVideoViewcontainer.getY());
        if (up) {
            mSmallVideoMovingTimer.schedule(new TimerTask() {
                public void run() {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            if (smallVideoViewOringY >= mSmallVideoViewcontainer.getY()) {
                                if (mSmallVideoMovingTimer != null) {
                                    mSmallVideoMovingTimer.cancel();
                                    mSmallVideoMovingTimer = null;
                                }
                                mSmallVideoViewcontainer.setY(smallVideoViewOringY);
                            } else {
                                mSmallVideoViewcontainer.setY(mSmallVideoViewcontainer.getY() - 1);
                            }
                        }
                    });

                }
            }, 0, 5);
        }else {
            mSmallVideoMovingTimer.schedule(new TimerTask() {
                public void run() {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            if (smallVideoViewOringY + 100 <= mSmallVideoViewcontainer.getY()) {
                                if (mSmallVideoMovingTimer != null) {
                                    mSmallVideoMovingTimer.cancel();
                                    mSmallVideoMovingTimer = null;
                                }
                                mSmallVideoViewcontainer.setY(smallVideoViewOringY + 100);
                            } else {
                                mSmallVideoViewcontainer.setY(mSmallVideoViewcontainer.getY() + 1);
                            }
                        }
                    });

                }
            }, 0, 5);
        }
    }

    private void checkDisabledDeviceStatus() {
        ImageView statusImageView = mStatusImageView1;
        if (linphoneManager.isMutedMic()) {
            statusImageView.setImageResource(getApplicationContext().getResources().getIdentifier("videocall_status_mute","drawable", getApplicationContext().getPackageName()));
            // statusImageView.setLayoutParams(new RelativeLayout.LayoutParams(Utils.dpToPx(this, 18), RelativeLayout.LayoutParams.WRAP_CONTENT));
            statusImageView.getLayoutParams().width = Utils.dpToPx(this, 18);
            statusImageView.setVisibility(View.VISIBLE);
            statusImageView = mStatusImageView2;
        } else {
            mStatusImageView2.setVisibility(View.GONE);
        }
        if (linphoneManager.isMutedCamera()) {
            statusImageView.setImageResource(getApplicationContext().getResources().getIdentifier("videocall_mute_camera","drawable", getApplicationContext().getPackageName()));
            statusImageView.getLayoutParams().width = Utils.dpToPx(this, 28);
            statusImageView.setVisibility(View.VISIBLE);
        } else {
            statusImageView.setVisibility(View.GONE);
        }
    }

    private void onRemoteViewTapped() {
        Log.e(TAG, "onRemoteViewTapped called.");
        if (bShownControls) {
            hideControlsContainer();
        } else {
            showControlsContainer();
        }
    }

    @Override
    protected void onDestroy() {
        Log.e(TAG, "onDestroy called.");

// ** On hold until we can fully implement "overlay video on chat mode" **
//        if (mServiceIntent != null){ 
//            stopService(mServiceIntent); 
//        } 
        linphoneManager.mVideoCallActivity = null;
        if (mSmallVideoMovingTimer != null) {
            mSmallVideoMovingTimer.cancel();
            mSmallVideoMovingTimer = null;
        }
        super.onDestroy();

    }

}