package com.phemium.sipvideocall.activities;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.content.res.ColorStateList;
import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.GradientDrawable;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.support.design.widget.FloatingActionButton;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.io.IOException;
import java.util.Locale;
import com.phemium.sipvideocall.LinphoneManager;
import com.phemium.sipvideocall.Utils;
import com.phemium.sipvideocall.constant.Constant;
import com.phemium.sipvideocall.data.CallData;
import com.phemium.sipvideocall.data.LanguageResource;

/**
 * Created by Tom on 1/4/2017.
 */

public class CallInitActivity extends Activity {

    private Button mMuteButton;
    private TextView mMuteLabel;
    private Button mSpeakerButton;
    private TextView mSpeakerLabel;
    private FloatingActionButton mCloseButton;
    private TextView mTxtView1;
    private TextView mTxtView2;
    private TextView mTxtView3;
    private ImageView mAvatarImageView;
    private LinearLayout mMuteLayout;
    private LinearLayout mSpeakerLayout;
    private RelativeLayout mRecordingLayout;

    private LinphoneManager linphoneManager;
    public Boolean bAudioCall;
    private MediaPlayer ringtoneMediaPlayer;
    private MediaPlayer messagetoneMediaPlayer;
    private Handler mHandler;
    private Boolean bSpeakerButtonPressed = false;
    private CallData callData;

    private ImageView mBtnChat;

    private Typeface typefaceGothamBold;
    private Typeface typefaceGothamLight;

    private RelativeLayout badgeLayout;
    private TextView mTxtBadgeNum;
    private int badgeNum;


    private final String TAG = "CallInitActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
        setContentView(getApplicationContext().getResources().getIdentifier("activity_connecting", "layout",
                getApplicationContext().getPackageName()));


        ViewGroup rootView = (ViewGroup) getWindow().getDecorView();
        LinearLayout content = (LinearLayout)rootView.getChildAt(0);
        content.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View view) {
                Log.e(TAG, "Enable Linphone Log");
                linphoneManager.enableLogCollection(true);
                return false;
            }
        });

        linphoneManager = LinphoneManager.getInstance();
        linphoneManager.mCallInitActivity = this;
        badgeNum = linphoneManager.badgeNum;
        mHandler = new Handler();

        initControlVariables();

        Intent intent = getIntent();
        this.callData = linphoneManager.callData;

        initAppearence();

        int show_mode = intent.getIntExtra("show_mode", -1);
        bAudioCall = intent.getBooleanExtra("isAudioCall", false);

        switch (show_mode) {
            case 0:
                showCallingScreen();
                if (linphoneManager.nCurCallState == Constant.CALL_RINGING) {
                    startRingSound();
                }
                break;
            case 1:
                showConnectingScreen();
                break;
            case 2:
                showAudioChattingScreen();
                break;
        }


    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
    }


    private void initAppearence() {
        GradientDrawable gd = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, new int[] {Color.parseColor(callData.mainColor), Color.parseColor(callData.secondaryColor)});
        gd.setCornerRadius(0f);
        getWindow().setBackgroundDrawable(gd);

        mTxtView1.setTextColor(Color.parseColor(callData.fontColor));
        mTxtView2.setTextColor(Color.parseColor(callData.fontColor));
        mTxtView3.setTextColor(Color.parseColor(callData.fontColor));
        mSpeakerLabel.setTextColor(Color.parseColor(callData.fontColor));
        mMuteLabel.setTextColor(Color.parseColor(callData.fontColor));

        mTxtView3.setTextSize(callData.fontSize - Constant.FONT_SIZE_OFFSET_STATUS_LABEL);
        mSpeakerLabel.setTextSize(callData.fontSize - Constant.FONT_SIZE_OFFSET_BUTTON_LABEL);
        mMuteLabel.setTextSize(callData.fontSize - Constant.FONT_SIZE_OFFSET_BUTTON_LABEL);

        AssetManager am = getApplicationContext().getAssets();
        typefaceGothamBold  = Typeface.createFromAsset(am, String.format(Locale.US, "fonts/%s", "ufonts.com_gotham-bold.ttf"));
        typefaceGothamLight = Typeface.createFromAsset(am, String.format(Locale.US, "fonts/%s", "ufonts.com_gotham-light.ttf"));
        mTxtView3.setTypeface(typefaceGothamBold);
        mMuteLabel.setTypeface(typefaceGothamLight);
        mSpeakerLabel.setTypeface(typefaceGothamLight);
        mMuteLabel.setText(LanguageResource.getInstance().getStringValue("calling_mute"));
        mSpeakerLabel.setText(LanguageResource.getInstance().getStringValue("calling_speaker"));

        TextView recordingTextView = (TextView)findViewById(getApplicationContext().getResources().getIdentifier("recordingText", "id", getApplicationContext().getPackageName()));
        recordingTextView.setText(LanguageResource.getInstance().getStringValue("recording"));
        recordingTextView.setTypeface(typefaceGothamLight);

        hideRecordingLayout();
    }

    private void initControlVariables() {
        mTxtView1 = (TextView)findViewById(getApplicationContext().getResources().getIdentifier("calling_label1", "id",
                getApplicationContext().getPackageName()));
        mTxtView2 = (TextView)findViewById(getApplicationContext().getResources().getIdentifier("calling_label2", "id",
                getApplicationContext().getPackageName()));
        mTxtView3 = (TextView)findViewById(getApplicationContext().getResources().getIdentifier("calling_connecting_label", "id",
                getApplicationContext().getPackageName()));

        mMuteButton = (Button)findViewById(getApplicationContext().getResources().getIdentifier("calling_mute_button", "id",
                getApplicationContext().getPackageName()));
        mMuteButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onMuteButtonClicked();
            }
        });

        mMuteLabel = (TextView)findViewById(getApplicationContext().getResources().getIdentifier("calling_mute_label", "id",
                getApplicationContext().getPackageName()));
        mSpeakerButton = (Button)findViewById(getApplicationContext().getResources().getIdentifier("calling_speaker_button", "id",
                getApplicationContext().getPackageName()));
        mSpeakerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onSpeakerButtonClicked();
            }
        });

        mSpeakerLabel = (TextView)findViewById(getApplicationContext().getResources().getIdentifier("calling_speaker_label", "id",
                getApplicationContext().getPackageName()));
        mCloseButton = (FloatingActionButton) findViewById(getApplicationContext().getResources().getIdentifier("calling_end_button", "id",
                getApplicationContext().getPackageName()));
        mCloseButton.setBackgroundTintList(ColorStateList.valueOf(Color.argb(255, 221, 61, 52)));
        mCloseButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onCloseButtonClicked();
            }
        });

        mAvatarImageView = (ImageView) findViewById(getApplicationContext().getResources().getIdentifier("calling_avatar", "id",
                getApplicationContext().getPackageName()));
        setAvatarImage();

        mMuteLayout = (LinearLayout)findViewById(getApplicationContext().getResources().getIdentifier("calling_mute_layout", "id", getApplicationContext().getPackageName()));
        mSpeakerLayout = (LinearLayout)findViewById(getApplicationContext().getResources().getIdentifier("calling_speaker_layout", "id", getApplicationContext().getPackageName()));

        mRecordingLayout = (RelativeLayout)findViewById(getApplicationContext().getResources().getIdentifier("recordingLayout", "id", getApplicationContext().getPackageName()));
        Button recordingLayoutCloseButton = (Button)findViewById(getApplicationContext().getResources().getIdentifier("recordingLayoutClose", "id", getApplicationContext().getPackageName()));
        recordingLayoutCloseButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                hideRecordingLayout();
            }
        });

        mTxtBadgeNum = (TextView) findViewById(getApplicationContext().getResources().getIdentifier("txtCount", "id", getApplicationContext().getPackageName()));
        badgeLayout = (RelativeLayout) findViewById(getApplicationContext().getResources().getIdentifier("badge_layout", "id", getApplicationContext().getPackageName()));

        mBtnChat = (ImageView) findViewById(getApplicationContext().getResources().getIdentifier("btn_chat", "id", getApplicationContext().getPackageName()));
        mBtnChat.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
                linphoneManager.minimizeVideo();
            }
        });

        if (badgeNum == 0){
            mTxtBadgeNum.setVisibility(View.INVISIBLE);
        }else{
            mTxtBadgeNum.setText("" + badgeNum);
            mTxtBadgeNum.setVisibility(View.VISIBLE);
        }
    }

    private void setAvatarImage() {
        Bitmap mbitmap = ((BitmapDrawable) getResources().getDrawable(getApplicationContext().getResources().getIdentifier("doctor_example", "drawable", getApplicationContext().getPackageName()))).getBitmap();
        Bitmap imageRounded = Bitmap.createBitmap(mbitmap.getWidth(), mbitmap.getHeight(), mbitmap.getConfig());
        Canvas canvas = new Canvas(imageRounded);
        Paint mpaint = new Paint();
        mpaint.setAntiAlias(true);
        mpaint.setShader(new BitmapShader(mbitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP));
        canvas.drawRoundRect((new RectF(0, 0, mbitmap.getWidth(), mbitmap.getHeight())), mbitmap.getWidth()/2, mbitmap.getHeight()/2, mpaint);// Round Image Corner 100 100 100 100
        mAvatarImageView.setImageBitmap(imageRounded);
    }

    public void showCallingScreen() {
        mTxtView1.setVisibility(View.VISIBLE);
        mTxtView2.setVisibility(View.VISIBLE);
        mTxtView3.setVisibility(View.GONE);
        mMuteLayout.setVisibility(View.VISIBLE);
        mSpeakerLayout.setVisibility(bAudioCall?View.VISIBLE:View.GONE);
        mCloseButton.setVisibility(View.VISIBLE);
        mAvatarImageView.setVisibility(View.VISIBLE);
        mRecordingLayout.setVisibility(View.GONE);
        mBtnChat.setVisibility(View.INVISIBLE);

        //mTxtView1.setText(getApplicationContext().getResources().getIdentifier("calling", "string", getApplicationContext().getPackageName()));
        mTxtView1.setText(LanguageResource.getInstance().getStringValue("calling"));
        mTxtView2.setText(callData.consultantName);
        mTxtView1.setTextSize(callData.fontSize - Constant.FONT_SIZE_OFFSET_STATUS_LABEL);
        mTxtView2.setTextSize(callData.fontSize);
        mTxtView1.setTypeface(typefaceGothamLight);
        mTxtView2.setTypeface(typefaceGothamBold);


        if (!bAudioCall) {
            mMuteLayout.setPadding(0, 0, 0, 0);
        } else {
            mMuteLayout.setPadding(0, 0, Utils.dpToPx(this, 150), 0);
        }

        if (linphoneManager != null) {
            updateMicButtonDrawable();
            updateSpeakerButtonDrawable();
        }

        badgeLayout.setVisibility(View.INVISIBLE);
    }

    public void increaseBadgeNumber(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mTxtBadgeNum.setText("" + linphoneManager.badgeNum);
                mTxtBadgeNum.setVisibility(View.VISIBLE);
            }
        });
    }

    public void showCallingAnimationEffect() {
        startBlurAnimation(mTxtView1, Constant.CALL_RINGING);
    }

    private void startBlurAnimation(final TextView textView, final int animateCallState) {
        Log.e(TAG, "Anitmation is go on...");
        final AlphaAnimation animation1 = new AlphaAnimation(1.0f, 0.0f);
        animation1.setDuration(1000);
        animation1.setStartOffset(0);

        final AlphaAnimation animation2 = new AlphaAnimation(0.0f, 1.0f);
        animation2.setDuration(1000);
        animation2.setStartOffset(0);

        animation1.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
            }
            @Override
            public void onAnimationEnd(Animation animation) {
                if (linphoneManager.nCurCallState == animateCallState) {
                    textView.startAnimation(animation2);
                }
            }
            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });


        animation2.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
            }
            @Override
            public void onAnimationEnd(Animation animation) {
                if (linphoneManager.nCurCallState == animateCallState) {
                    textView.startAnimation(animation1);
                }
            }
            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });

        if (linphoneManager.nCurCallState == animateCallState) {
            textView.startAnimation(animation1);
        }
    }

    public void setCallStatus(final int callStatus, final int retryCount, final String currentTurnServerInfo ){
        mTxtView3.post(new Runnable() {
            @Override
            public void run() {
                String text = "registering";
                switch (callStatus){
                    case Constant.CALL_REGISTERING:
                        text = "registering";
                        break;
                    case Constant.CALL_INITIALISING:
                    case Constant.CALL_RINGING:
                        text = "connecting";
                        break;
                    case Constant.CALL_CONNECTING:
                        text = "establishing";
                        break;
                    case Constant.CALL_CONNECTED:
                        text = "connected";
                        break;
                    case Constant.CALL_RETRYING:
                        text = "retrying";
                        break;
                    case Constant.CALL_ENDING:
                        text = "ending";
                        break;
                    default:
                        break;
                }
                String message = LanguageResource.getInstance().getStringValue(text);
                if (retryCount > 0){
                    message += " (" + retryCount + ")";
                }
                // message = "[" + currentTurnServerInfo + "] " + message;
                mTxtView3.setText(message);
            }
        });
        Log.e(TAG, "setCallStatus Called. status:" + callStatus);
    }

    public void showConnectingScreen() {
        mTxtView1.clearAnimation();
        mTxtView1.setVisibility(View.GONE);
        mTxtView2.setVisibility(View.GONE);
        mTxtView3.setVisibility(View.VISIBLE);
        mMuteLayout.setVisibility(View.GONE);
        mSpeakerLayout.setVisibility(View.GONE);
        mCloseButton.setVisibility(View.GONE);
        mAvatarImageView.setVisibility(View.GONE);
        mRecordingLayout.setVisibility(View.GONE);
        //mTxtView3.setText(getApplicationContext().getResources().getIdentifier("connecting", "string", getApplicationContext().getPackageName()));
        mTxtView3.setText(LanguageResource.getInstance().getStringValue("connecting"));
        badgeLayout.setVisibility(View.INVISIBLE);
        mBtnChat.setVisibility(View.INVISIBLE);
    }

    public void showConnectingAnimationEffect() {
        startBlurAnimation(mTxtView3, Constant.CALL_CONNECTING);
    }

    public void showAudioChattingScreen() {
        mTxtView1.setVisibility(View.VISIBLE);
        mTxtView2.setVisibility(View.VISIBLE);
        mTxtView3.setVisibility(View.GONE);
        mMuteLayout.setVisibility(View.VISIBLE);
        mSpeakerLayout.setVisibility(View.VISIBLE);
        mCloseButton.setVisibility(View.VISIBLE);
        mAvatarImageView.setVisibility(View.VISIBLE);

        if (callData.callRecordingNotificationVisible.equals("yes")) {
            mRecordingLayout.setVisibility(View.VISIBLE);
        } else {
            mRecordingLayout.setVisibility(View.GONE);
        }

        if (callData.chatMode.equals("NoChat")){
            mBtnChat.setVisibility(View.INVISIBLE);
        }else{
            mBtnChat.setVisibility(View.VISIBLE);
        }

        mTxtView1.setText(callData.consultantName);
        mTxtView2.setText("00:00");
        mTxtView1.setTextSize(callData.fontSize);
        mTxtView2.setTextSize(callData.fontSize - Constant.FONT_SIZE_OFFSET_STATUS_LABEL);
        mTxtView1.setTypeface(typefaceGothamBold);
        mTxtView2.setTypeface(typefaceGothamLight);

        if (linphoneManager != null) {
            updateMicButtonDrawable();
            updateSpeakerButtonDrawable();
        }
        badgeLayout.setVisibility(View.VISIBLE);
    }

    public void showCallDuration(int duration) {
        mTxtView2.setText(Utils.secToTimeString(duration));
    }

    public void startRingSound() {
        Log.e(TAG, "Playing Ring sound");

        if (ringtoneMediaPlayer != null) {
            return;
        }

        //ringtoneMediaPlayer = MediaPlayer.create(this, R.raw.ringback);
        ringtoneMediaPlayer = new MediaPlayer();
        try {
            ringtoneMediaPlayer.setDataSource(this, Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + getApplicationContext().getPackageName() + "/" + getApplicationContext().getResources().getIdentifier("ringback", "raw", getApplicationContext().getPackageName())));
        } catch (IOException e) {
            e.printStackTrace();
        }
        ringtoneMediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
            @Override
            public boolean onError(MediaPlayer mediaPlayer, int i, int i1) {
                Log.e(TAG, "ringtone play error occured");
                return false;
            }
        });
        ringtoneMediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(final MediaPlayer mediaPlayer) {
                Log.e(TAG, "Mediaplay Play completed.");
                mHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        Log.e(TAG, "Mediaplay Play Replaying. bSpeakerButtonPressed: " + bSpeakerButtonPressed);
                        if (ringtoneMediaPlayer != null) {
                            if (!bSpeakerButtonPressed) {
                                ringtoneMediaPlayer.start();
                            } else {
                                bSpeakerButtonPressed = false;
                            }
                        }
                    }
                }, 2000);
            }
        });
        ringtoneMediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mediaPlayer) {
                Log.e(TAG, "Media Player prepared.");
                bSpeakerButtonPressed = false;
                ringtoneMediaPlayer.start();
            }
        });

        linphoneManager.originalAudioStatus = getAudioOriginalStatus();
        Log.e(TAG, "This is " + (bAudioCall?"":"not ") + "audio call. OriginalAudioStatus(mode: " + linphoneManager.originalAudioStatus[0] + " speaker: " + (linphoneManager.originalAudioStatus[1]==1?"on":"off") + ")");
        if (bAudioCall) {
            setSpeakerOnoff(false);
        } else {
            setSpeakerOnoff(true);
        }
    }

    public void stopRingSound() {
        if (ringtoneMediaPlayer != null) {
            if (ringtoneMediaPlayer.isPlaying()) {
                ringtoneMediaPlayer.stop();
            }
            ringtoneMediaPlayer.release();
            ringtoneMediaPlayer.setOnCompletionListener(null);
            ringtoneMediaPlayer = null;
            mHandler.removeCallbacksAndMessages(null);
        }
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

    public Integer[] getAudioOriginalStatus() {
        Integer[] res = new Integer[2];
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        res[0] = audioManager.getMode();
        res[1] = audioManager.isSpeakerphoneOn()?1:0;
        return res;
    }

    public void setSpeakerOnoff(Boolean bOn) {
        Log.e(TAG, "setSpeakerOnOff function called.");
        if (bOn) {
            AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
            audioManager.setMode(AudioManager.MODE_IN_CALL);
            audioManager.setSpeakerphoneOn(true);
        } else {
            AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
            audioManager.setMode(AudioManager.MODE_IN_CALL);
            audioManager.setSpeakerphoneOn(false);
        }
        if (ringtoneMediaPlayer != null) {
            if (ringtoneMediaPlayer.isPlaying()) {
                Log.e(TAG, "Ringtone Media Player stopped.");
                ringtoneMediaPlayer.stop();
            }
            if (bOn) {
                ringtoneMediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
                try {
                    ringtoneMediaPlayer.prepare();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            } else {
                ringtoneMediaPlayer.setAudioStreamType(AudioManager.STREAM_VOICE_CALL);
                try {
                    ringtoneMediaPlayer.prepare();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    @Override
    protected void onDestroy() {
        stopRingSound();
        super.onDestroy();
    }

    private void onCloseButtonClicked() {
        linphoneManager.setCallReleasedReason(Constant.CALL_HANGUP_BY_CALLER);
        linphoneManager.hangup();
        stopRingSound();
    }

    private void onMuteButtonClicked() {
        linphoneManager.muteMic();
        updateMicButtonDrawable();
    }

    private void onSpeakerButtonClicked() {
        Boolean speakerEnabled = linphoneManager.isEnabledSpeaker();
        Log.e(TAG, "onSpeakerButtonClicked: Original Speaker Status: " + speakerEnabled);
        bSpeakerButtonPressed = true;
        mHandler.removeCallbacksAndMessages(null);

        if (ringtoneMediaPlayer != null) {
            if (ringtoneMediaPlayer.isPlaying()) {
                ringtoneMediaPlayer.stop();
            }
            ringtoneMediaPlayer.reset();
            try {
                ringtoneMediaPlayer.setDataSource(this, Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + getApplicationContext().getPackageName() + "/" + getApplicationContext().getResources().getIdentifier("ringback", "raw", getApplicationContext().getPackageName())));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        setSpeakerOnoff(speakerEnabled == true ? false : true);

        linphoneManager.enableSpeaker(speakerEnabled==true?false:true);
        updateSpeakerButtonDrawable();
    }

    private void updateSpeakerButtonDrawable() {
        if (linphoneManager.isEnabledSpeaker()) {
            mSpeakerButton.setBackgroundResource(getApplicationContext().getResources().getIdentifier("calling_speaker_muted", "drawable", getApplicationContext().getPackageName()));
        } else {
            mSpeakerButton.setBackgroundResource(getApplicationContext().getResources().getIdentifier("calling_speaker", "drawable", getApplicationContext().getPackageName()));
        }
    }

    private void updateMicButtonDrawable() {
        if (linphoneManager.isMutedMic()) {
            mMuteButton.setBackgroundResource(getApplicationContext().getResources().getIdentifier("calling_muted",
                    "drawable", getApplicationContext().getPackageName()));
        } else {
            mMuteButton.setBackgroundResource(getApplicationContext().getResources().getIdentifier("calling_mute",
                    "drawable", getApplicationContext().getPackageName()));
        }
    }

    public void hideRecordingLayout() {
        if (mRecordingLayout.getVisibility() != View.GONE) {
            mRecordingLayout.setVisibility(View.GONE);
        }
    }
}
