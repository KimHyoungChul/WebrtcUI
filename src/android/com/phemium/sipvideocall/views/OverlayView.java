package com.phemium.sipvideocall.views;

import android.content.Context;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.phemium.sipvideocall.LinphoneManager;
import com.phemium.sipvideocall.SipVideoCall;
import com.phemium.sipvideocall.Utils;
import com.phemium.sipvideocall.activities.SipVideoCallActivity;

import java.util.Calendar;

/**
 * TODO: document your custom view class.
 */
public class OverlayView extends RelativeLayout {

    private WindowManager wm;
    private WindowManager.LayoutParams params;
    private DisplayMetrics metrics;

    private FrameLayout large_container;
    private FrameLayout small_container;
    private RelativeLayout.LayoutParams large_container_params;
    private RelativeLayout.LayoutParams small_container_params;
    private TextView timer_text;
    private float x;
    private float y;
    private Rect boundaryRect;
    private int xMargin;
    private int yMargin;
    private float touchX;
    private float touchY;
    private boolean dragEnabled;
    private boolean doubleClicked;
    private static final int MAX_CLICK_DURATION = 100;
    private static final int MIN_DOUBLE_CLICK_TIME = 1000;
    private long startClickTime;

    private static final int LARGE_CONTAINER_WIDTH = 128;
    private static final int LARGE_CONTAINER_HEIGHT = 96;
    private static final int SMALL_CONTAINER_WIDTH = 50;
    private static final int SMALL_CONTAINER_HEIGHT = 40;

    public OverlayView(Context context) {
        this(context, null);
    }

    public OverlayView(Context context, AttributeSet attrs) {
        this(context, null, 0);
    }

    public OverlayView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init();
    }

    public OverlayView(Context context, int position) {
        this(context);
        setLayoutParams(0,0, position);
    }

    private void init() {
        Context context = getContext().getApplicationContext();

        wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_TOAST,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL |
                 WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                ,PixelFormat.TRANSLUCENT);
//        params.width = 300;
//        params.height = 300;
        xMargin = Utils.dpToPx(context,10);
        yMargin = Utils.dpToPx(context,10);

        params.x = xMargin;
        params.y = yMargin;
        
        metrics = new DisplayMetrics();
        wm.getDefaultDisplay().getMetrics(metrics);
        doubleClicked = false;
        dragEnabled = true;
        setLayoutParams(getWidth(), getHeight(), 0);
        inflate(getContext(),context.getResources().getIdentifier("overlay_view", "layout", context.getPackageName()), this);

        boundaryRect = new Rect(0, 0, (int)(metrics.widthPixels), (int)(metrics.heightPixels));

        large_container = (FrameLayout) findViewById(context.getResources().getIdentifier("large_container", "id", context.getPackageName()));
        small_container = (FrameLayout) findViewById(context.getResources().getIdentifier("small_container", "id", context.getPackageName()));

        timer_text = (TextView) findViewById(context.getResources().getIdentifier("overlay_textclock", "id", context.getPackageName()));
        timer_text.setVisibility(View.GONE);

        LinphoneManager.getInstance().removeParent();

        if (!SipVideoCallActivity.bRemoteVideoShowingOnSmallContainer) {
            fixZOrder(LinphoneManager.getInstance().videoView, LinphoneManager.getInstance().captureView);
            large_container.addView(LinphoneManager.getInstance().videoView);
            small_container.addView(LinphoneManager.getInstance().captureView);
        } else {
            fixZOrder(LinphoneManager.getInstance().captureView, LinphoneManager.getInstance().videoView);
            small_container.addView(LinphoneManager.getInstance().videoView);
            large_container.addView(LinphoneManager.getInstance().captureView);
        }
    }

    private void fixZOrder(SurfaceView bottom, SurfaceView top) {
        bottom.setZOrderOnTop(false);
        top.setZOrderOnTop(true);
        top.setZOrderMediaOverlay(true);
    }

    public void setCallTime(int callDuration){
        String timeValue = "";
        if (callDuration != 0) {
            int seconds = callDuration % 60;
            int minutes = callDuration / 60 % 60;
            int hours = callDuration / 3600;

            if (hours > 0){
                timeValue += String.valueOf(hours) + "h ";
            }
            timeValue += String.valueOf(minutes) + "m " + String.valueOf(seconds) + "s";
        }

        timer_text.setText(timeValue);
    }

    public void destroy() {
        large_container.removeAllViews();
        small_container.removeAllViews();
    }

    public void setLayoutParams(int width , int height, int position){
//        width = params.width = width;
//        height = params.height = height;
        switch (position){
            case 0:
                params.gravity = Gravity.TOP | Gravity.START;
                break;
            case 1:
                params.gravity = Gravity.TOP | Gravity.END;
                break;
            case 2:
                params.gravity = Gravity.BOTTOM | Gravity.START;
                break;
            case 3:
                params.gravity = Gravity.BOTTOM | Gravity.END;
                break;
        }

    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        x = event.getRawX();
        y = event.getRawY();
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                touchX = event.getX();
                touchY = event.getY();
                if (Calendar.getInstance().getTimeInMillis() - startClickTime > MIN_DOUBLE_CLICK_TIME) {
                    startClickTime = Calendar.getInstance().getTimeInMillis();
                    doubleClicked = false;
                }else {
                    doubleClicked = true;
                }
                break;
            case MotionEvent.ACTION_MOVE:
                if (dragEnabled) {
                    updateViewPosition();
                }
                break;
            case MotionEvent.ACTION_CANCEL:
            case MotionEvent.ACTION_UP:
                touchX = touchY = 0;
                long clickDuration = Calendar.getInstance().getTimeInMillis() - startClickTime;
                if(clickDuration < MAX_CLICK_DURATION) {
                    if (doubleClicked){
                        Log.e("OverlayView", "Double Clicked, not start Activity");
                        return false;
                    }
                    if (SipVideoCallActivity.ACTIVITY_VISIBLE){
                        return false;
                    }
                    if (LinphoneManager.getInstance().mVideoCallActivity != null){
                        return false;
                    }
                    Intent videoIntent = new Intent(getContext(), SipVideoCallActivity.class);
                    videoIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                    videoIntent.putExtra("gravity", params.gravity);
                    getContext().startActivity(videoIntent);
                }else {
//				dragEnabled = false;
                    resetViewPosition();
                }
                break;
            default:
                break;
        }
        return true;
    }

    private void updateViewPosition() {
        int gravity = params.gravity;
        params.gravity = Gravity.TOP | Gravity.START;
//        params.x = Math.min(Math.max(0, (int) (x - touchX)), metrics.widthPixels - getMeasuredWidth());
//        params.y = Math.min(Math.max(0, (int) (y - touchY)), metrics.heightPixels - getMeasuredHeight());

        // Change boundary Rect Logic for setOverlayBoundary() function
        params.x = Math.min(Math.max(boundaryRect.left, (int) (x - touchX)), boundaryRect.right - getMeasuredWidth());
        params.y = Math.min(Math.max(boundaryRect.top, (int) (y - touchY)), boundaryRect.bottom - getMeasuredHeight());

        wm.updateViewLayout(this, params);
        params.gravity = gravity;
    }

    private void resetViewPosition() {
        Log.e("OverlayView", "Reset Position-x: " + x + ", y: " + y);
        Log.e("OverlayView", "Boundary: "+ boundaryRect.toShortString());
        if (x < (boundaryRect.left + boundaryRect.right) / 2){  // middle point of boundaryRect width
            if (y < (boundaryRect.top + boundaryRect.bottom) / 2 ){
                params.gravity = Gravity.TOP | Gravity.START;
            }else{
                params.gravity = Gravity.BOTTOM | Gravity.START;
            }
        }else{
            if (y < (boundaryRect.top + boundaryRect.bottom) / 2 ){ // middle point of boundaryRect height
                params.gravity = Gravity.TOP | Gravity.END;
            }else{
                params.gravity = Gravity.BOTTOM | Gravity.END;
            }
        }
        drawView();
    }

    private void drawView(){
        wm.getDefaultDisplay().getMetrics(metrics);
        int deviceWidth = metrics.widthPixels;
        int deviceHeight = metrics.heightPixels;

        Log.e("OverlayView", "Metrics Width: " + metrics.widthPixels + ", Height: " + metrics.heightPixels);

        switch (params.gravity){
            case Gravity.TOP | Gravity.START:
                params.x = boundaryRect.left + xMargin;
                params.y = boundaryRect.top + yMargin;
                Log.e("OverlayView", "Params-x: " + params.x + ", y: " + params.y + ", gravity: TOP|START");
                break;
            case Gravity.TOP | Gravity.END:
                params.x = (deviceWidth - boundaryRect.right) + xMargin;
                params.y = boundaryRect.top + yMargin;
                Log.e("OverlayView", "Params-x: " + params.x + ", y: " + params.y + ", gravity: TOP|END");
                break;
            case Gravity.BOTTOM | Gravity.START:
                params.x = boundaryRect.left + xMargin;
                params.y = (deviceHeight - boundaryRect.bottom) + yMargin;
                Log.e("OverlayView", "Params-x: " + params.x + ", y: " + params.y + ", gravity: BOTTOM|START");
                break;
            case Gravity.BOTTOM | Gravity.END:
                params.x = (deviceWidth - boundaryRect.right) + xMargin;
                params.y = (deviceHeight - boundaryRect.bottom) + yMargin;
                Log.e("OverlayView", "Params-x: " + params.x + ", y: " + params.y + ", gravity: BOTTOM|END");
                break;
        }
        wm.updateViewLayout(this, params);
    }

    public void setOverlayBoundary(Rect rect){
        boundaryRect.left = (int)(rect.left * metrics.density);
        boundaryRect.right = (int)(rect.right * metrics.density);
        boundaryRect.top = (int)(rect.top * metrics.density);
        boundaryRect.bottom = (int)(rect.bottom * metrics.density);
        synchronized (this) {
            try {
                Handler handler = new Handler(Looper.getMainLooper()) {
                    @Override
                    public void handleMessage(Message msg) {
                        // Any UI task, example
                        drawView();
                    }
                };
                handler.sendEmptyMessage(1);

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public WindowManager.LayoutParams getWindowManagerLayoutParams() {
        return params;
    }

    public void setOrientation(int rotation){
        large_container_params = (RelativeLayout.LayoutParams)large_container.getLayoutParams();
        small_container_params = (RelativeLayout.LayoutParams)small_container.getLayoutParams();
        switch (rotation){
            case 0:
                large_container_params.width = LARGE_CONTAINER_HEIGHT * (int)metrics.density;
                large_container_params.height = LARGE_CONTAINER_WIDTH * (int)metrics.density;
                small_container_params.width = SMALL_CONTAINER_HEIGHT * (int)metrics.density;
                small_container_params.height = SMALL_CONTAINER_WIDTH * (int)metrics.density;
                break;
            case 1:
                large_container_params.width = LARGE_CONTAINER_WIDTH * (int)metrics.density;
                large_container_params.height = LARGE_CONTAINER_HEIGHT * (int)metrics.density;
                small_container_params.width = SMALL_CONTAINER_WIDTH * (int)metrics.density;
                small_container_params.height = SMALL_CONTAINER_HEIGHT * (int)metrics.density;
                break;
            case 2:
                large_container_params.width = LARGE_CONTAINER_HEIGHT * (int)metrics.density;
                large_container_params.height = LARGE_CONTAINER_WIDTH * (int)metrics.density;
                small_container_params.width = SMALL_CONTAINER_HEIGHT * (int)metrics.density;
                small_container_params.height = SMALL_CONTAINER_WIDTH * (int)metrics.density;
                break;
            case 3:
                large_container_params.width = LARGE_CONTAINER_WIDTH * (int)metrics.density;
                large_container_params.height = LARGE_CONTAINER_HEIGHT * (int)metrics.density;
                small_container_params.width = SMALL_CONTAINER_WIDTH * (int)metrics.density;
                small_container_params.height = SMALL_CONTAINER_HEIGHT * (int)metrics.density;
                break;
            default:
                break;
        }

        this.post(new Runnable() {
            @Override
            public void run() {
                large_container.setLayoutParams(large_container_params);
                small_container.setLayoutParams(small_container_params);
            }
        });
    }
}
