package com.phemium.sipvideocall.listener;

/**
 * Created by Tom on 1/5/2017.
 */

public interface LinphoneManagerListener {
    public void onRegisterSucceeded();
    public void onRegisterFailed(String workflow);

    public void onCallFailed(int code, String workflow);
    public void onCallReleased(String workflow);
    public void onCallRinging();
    public void onCallEventOccur(int eventCode);
    public void onCallMinimized(int callDuration);
    public void onCallSendQuality(String quality);
    public void onCallRetry();
}
