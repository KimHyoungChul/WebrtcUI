package com.phemium.sipvideocall;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.phemium.sipvideocall.constant.Constant;

/**
 * Created by Tom on 1/14/2017.
 */

public class AlarmReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.e("AlarmReceiver", "scheduleLocalNotification called.");


    }
}
