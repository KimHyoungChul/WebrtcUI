package com.phemium.sipvideocall.views;

import android.content.Context;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.Gravity;
import android.view.WindowManager;
import com.phemium.sipvideocall.LinphoneManager;
import com.phemium.sipvideocall.Utils;

import org.linphone.core.LinphoneCall;
import static android.content.Context.WINDOW_SERVICE;

/**
 * Created by super on 12/12/2017.
 */

public class OverlayCreator {
    private static OverlayCreator instance;

    private WindowManager mWindowManager;
    private OverlayView mOverlay;
    private Context mContext;


    private static final int LARGE_CONTAINER_WIDTH = 128;
    private static final int LARGE_CONTAINER_HEIGHT = 96;

    public static boolean isReady() {
        return instance != null;
    }

    /**
     * @throws RuntimeException service not instantiated
     */
    public synchronized static OverlayCreator getInstance(Context context)  {
        if (instance == null){
            instance = new OverlayCreator(context);
        }
        return instance;
    }

    private OverlayCreator(Context context) {
        mContext = context;
        mWindowManager = (WindowManager) mContext.getSystemService(WINDOW_SERVICE);
    }

    public void createOverlay(int width, int height, int position) {
        if (mOverlay != null) destroyOverlay();

        LinphoneCall call = LinphoneManager.getInstance().getLc().getCurrentCall();
        if (call == null || !call.getCurrentParams().getVideoEnabled()) return;

        mOverlay = new OverlayView(mContext, position);
        WindowManager.LayoutParams params = mOverlay.getWindowManagerLayoutParams();

        mWindowManager.addView(mOverlay, params);
        setOrientation(LinphoneManager.getInstance().getCurrentRotation());
    }

    public void destroyOverlay() {
        if (mOverlay != null) {
            synchronized (mOverlay) {
                try {
                    Handler handler = new Handler(Looper.getMainLooper()) {
                        @Override
                        public void handleMessage(Message msg) {
                            // Any UI task, example
                            mWindowManager.removeViewImmediate(mOverlay);
                            mOverlay.destroy();
                            mOverlay = null;
                        }
                    };
                    handler.sendEmptyMessage(1);

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public void updateTimeOverlay(final int callDuration){
        if (mOverlay != null) {
            synchronized (mOverlay) {
                mOverlay.post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            mOverlay.setCallTime(callDuration);
                        }catch (Exception e){
                            Log.e("OverlayCreator", "OverlayView is null");
                        }
                    }
                });
            }
        }
    }

    public void setOverlayBoundary(Rect newRect){
        if (mOverlay != null) {
            synchronized (mOverlay) {
                if (mOverlay != null) {
                    mOverlay.setOverlayBoundary(newRect);
                }
            }
        }
    }

    public void zoomVideo(){
        if (mOverlay != null) {
            synchronized (mOverlay) {
                if (mOverlay != null) {
                    LinphoneManager.getInstance().scaleVideo(mOverlay.getMeasuredWidth(), mOverlay.getMeasuredHeight());
                }
            }
        }
    }

    public void setOrientation(int rotation){
        if (mOverlay != null) {
            synchronized (mOverlay) {
                if (mOverlay != null) {
                    try {
                        mOverlay.setOrientation(rotation);
                        mOverlay.post(new Runnable() {
                            @Override
                            public void run() {
                                if (mOverlay != null) {
                                    mWindowManager.updateViewLayout(mOverlay, mOverlay.getWindowManagerLayoutParams());
                                }
                            }
                        });
                    }catch (Exception e){
                        Log.e("OverlayCreator", "setOrientation Failed");
                    }
                }
            }
        }
    }
}
