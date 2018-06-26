package com.phemium.sipvideocall.views;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;

public class CustomGLSurfaceView extends GLSurfaceView {

  public CustomGLSurfaceView(Context context, AttributeSet attrs) {
    super(context, attrs);
    setEGLContextClientVersion(2);
  }

  public CustomGLSurfaceView(Context applicationContext) {
    super(applicationContext);
    setEGLContextClientVersion(2);
  }
}
