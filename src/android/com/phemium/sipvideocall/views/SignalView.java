package com.phemium.sipvideocall.views;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.os.Build;
import android.util.AttributeSet;
import android.view.View;

/**
 * Created by praween on 9/9/16.
 */
public class SignalView extends View {
    private int mLineCount = 5;
    private Paint mPaint;
    private int mWidth;
    private int mHeight;
    private int mStroke = 5;
    private float mRadius = 3;
    private float mLineWidth;
    private int mProgress = 0;
    private float mTop;
    private Context mContext;

    private float mHorizontalSpacing;
    private float mVerticalHeightIncrement;

    private int firstSignalBarColor;
    private int secondSignalBarColor;
    private int thirdSignalBarColor;
    private int fourthSignalBarColor;
    private int fifthSignalBarColor;

    private int signal = 0;

    private int baseColor = Color.GRAY;
    private int lowSignalColor = Color.RED;
    private int moderateSignalColor = Color.rgb(255, 165, 0);
    private int excellentSignalColor = Color.rgb(0, 240, 30);

    public SignalView(Context context) {
        super(context);
        mContext = context;
        init();
    }

    public SignalView(Context context, AttributeSet attrs) {
        super(context, attrs);
        mContext = context;
        setAttributes(attrs);
        init();
    }

    public SignalView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        mContext = context;
        setAttributes(attrs);
        init();
    }

    /**
     * set the default attributes for the view
     *
     * @param attrs
     */
    private void setAttributes(AttributeSet attrs) {
    }

    @SuppressWarnings("ResourceAsColor")
    private void init() {
        mPaint = new Paint();
        mPaint.setDither(false);
        mPaint.setStyle(Paint.Style.FILL);
        mPaint.setStrokeWidth(mStroke);
        mPaint.setAntiAlias(true);
        mPaint.setStrokeJoin(Paint.Join.ROUND);
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float top = mTop;
        float left = 0;

        mLineWidth = mWidth / 8;

        switch (mProgress){
            case 5:
                firstSignalBarColor = excellentSignalColor;
                secondSignalBarColor = excellentSignalColor;
                thirdSignalBarColor = excellentSignalColor;
                fourthSignalBarColor = excellentSignalColor;
                fifthSignalBarColor = excellentSignalColor;
                break;
            case 4:
                firstSignalBarColor = moderateSignalColor;
                secondSignalBarColor = moderateSignalColor;
                thirdSignalBarColor = moderateSignalColor;
                fourthSignalBarColor = moderateSignalColor;
                fifthSignalBarColor = baseColor;
                break;
            case 3:
                firstSignalBarColor = moderateSignalColor;
                secondSignalBarColor = moderateSignalColor;
                thirdSignalBarColor = moderateSignalColor;
                fourthSignalBarColor = baseColor;
                fifthSignalBarColor = baseColor;
                break;
            case 2:
                firstSignalBarColor = lowSignalColor;
                secondSignalBarColor = lowSignalColor;
                thirdSignalBarColor = baseColor;
                fourthSignalBarColor = baseColor;
                fifthSignalBarColor = baseColor;
                break;
            case 1:
                firstSignalBarColor = lowSignalColor;
                secondSignalBarColor = baseColor;
                thirdSignalBarColor = baseColor;
                fourthSignalBarColor = baseColor;
                fifthSignalBarColor = baseColor;
                break;
            case 0:
                firstSignalBarColor = baseColor;
                secondSignalBarColor = baseColor;
                thirdSignalBarColor = baseColor;
                fourthSignalBarColor = baseColor;
                fifthSignalBarColor = baseColor;
                break;
            default:
                    break;
        }
        mHorizontalSpacing = mLineWidth * 0.5f;
        left = mHorizontalSpacing;

        RectF rect = new RectF(left, mHeight - top, left + mLineWidth, mHeight);
        mPaint.setColor(firstSignalBarColor);
        canvas.drawRoundRect(rect, mRadius, mRadius, mPaint);
        left += mLineWidth + mHorizontalSpacing;
        top += mTop;

        rect = new RectF(left, mHeight - top, left + mLineWidth, mHeight);
        mPaint.setColor(secondSignalBarColor);
        canvas.drawRoundRect(rect, mRadius, mRadius, mPaint);
        left += mLineWidth + mHorizontalSpacing;
        top += mTop;

        rect = new RectF(left, mHeight - top, left + mLineWidth, mHeight);
        mPaint.setColor(thirdSignalBarColor);
        canvas.drawRoundRect(rect, mRadius, mRadius, mPaint);
        left += mLineWidth + mHorizontalSpacing;
        top += mTop;

        rect = new RectF(left, mHeight - top, left + mLineWidth, mHeight);
        mPaint.setColor(fourthSignalBarColor);
        canvas.drawRoundRect(rect, mRadius, mRadius, mPaint);
        left += mLineWidth + mHorizontalSpacing;
        top += mTop;

        rect = new RectF(left, mHeight - top, left + mLineWidth, mHeight);
        mPaint.setColor(fifthSignalBarColor);
        canvas.drawRoundRect(rect, mRadius, mRadius, mPaint);
        left += mLineWidth + mHorizontalSpacing;
        top += mTop;
    }

    private void drawRoundRect(){

    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        mWidth = getWidth();
        mHeight = getHeight();

        mTop = mHeight / mLineCount;
    }

    /**
     * change selected color
     *
     * @param progress number of line need to show filled
     */
    public void setProgress(int progress) {
        mProgress = progress;
        invalidate();
    }

    /**
     * change line count of view
     *
     * @param lineCount number of lines which need to display
     */
    public void setLineCount(int lineCount) {
        mLineCount = lineCount;
        invalidate();
    }

    /**
     * change width of view
     *
     * @param width width of view
     */
    public void setWidth(int width) {
        mWidth = width;
    }

    public void setHeight(int height) {
        mHeight = height;
    }

}
