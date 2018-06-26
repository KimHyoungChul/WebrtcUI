package com.phemium.sipvideocall.listener;

/**
 * Created by Tom on 1/5/2017.
 */

public interface CallManagerListener {
    public void onCallReleased(String workflow, String logPath);
    public void onThrowError(int errorCode , String workflow, String logPath);
    public void onEventComeUp(int errorCode);
    public void onEventMinimized(int duration);
    public void onEventSendQuality(String quality);
    public void onCheckReleased(boolean registable, String networkType, float bandwidth);
}
