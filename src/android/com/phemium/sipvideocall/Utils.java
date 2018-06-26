package com.phemium.sipvideocall;

import android.Manifest;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Environment;
import android.provider.CallLog;
import android.support.v4.app.ActivityCompat;
import android.util.DisplayMetrics;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Created by Tom on 1/6/2017.
 */

public class Utils {
    public static int dpToPx(Context context, int dp) {
        DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
        return Math.round(dp * (displayMetrics.xdpi / DisplayMetrics.DENSITY_DEFAULT));
    }

    public static int pxToDp(Context context, int px) {
        DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
        return Math.round(px / (displayMetrics.densityDpi / DisplayMetrics.DENSITY_DEFAULT));
    }

    public static String secToTimeString(int seconds) {
        int minutes = seconds / 60;
        int secs = seconds % 60;
        String timeStr = String.format("%02d:%02d", minutes, secs);
        return timeStr;
    }

    public static Boolean isStringEmpty(String str) {
        if (str == null || str.equals("null") || str.isEmpty()) {
            return true;
        }
        return false;
    }

    public static int indexOfStringArray(String[] array, String str) {
        int i = 0;
        for (String istr : array) {
            if (str.equals(istr)) {
                return i;
            }
            i++;
        }
        return -1;
    }

    public static void copyIfNotExist(Context context, int ressourceId, String target) throws IOException {
        File lFileToCopy = new File(target);
        if (!lFileToCopy.exists()) {
            copyFromPackage(context, ressourceId, lFileToCopy.getName());
        }
    }

    public static void copyFromPackage(Context context, int ressourceId, String target) throws IOException {
        FileOutputStream lOutputStream = context.openFileOutput(target, 0);
        InputStream lInputStream = context.getResources().openRawResource(ressourceId);
        int readByte;
        byte[] buff = new byte[8048];
        while ((readByte = lInputStream.read(buff)) != -1) {
            lOutputStream.write(buff, 0, readByte);
        }
        lOutputStream.flush();
        lOutputStream.close();
        lInputStream.close();
    }

    public static void sendEmail(Context context, String toEmail, String message, String subject) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.putExtra(Intent.EXTRA_EMAIL, new String[]{ toEmail});
        intent.putExtra(Intent.EXTRA_TEXT, message);
        intent.putExtra(Intent.EXTRA_SUBJECT, subject);
        //need this to prompts email client only
        intent.setType("message/rfc822");
        String root = Environment.getExternalStorageDirectory().getAbsolutePath();
        File file = new File(root, "linphone1.log");
        if (!file.exists() || !file.canRead()) {
            Log.e("EMAIL", "Attachment Error");
            return;
        }
        Uri uri = Uri.parse("file://" + file);
        intent.putExtra(Intent.EXTRA_STREAM, uri);
        context.startActivity(Intent.createChooser(intent, "Choose an Email client :"));
    }

    public static void insertCallLog(Context context , String username, boolean isIncoming, int duration) {
        ContentValues values = new ContentValues();
        values.put(CallLog.Calls.NUMBER, username);
        values.put(CallLog.Calls.DATE, System.currentTimeMillis());
        values.put(CallLog.Calls.DURATION, duration);
        if (isIncoming){
            values.put(CallLog.Calls.TYPE, CallLog.Calls.INCOMING_TYPE);
        }else{
            values.put(CallLog.Calls.TYPE, CallLog.Calls.OUTGOING_TYPE);
        }
        values.put(CallLog.Calls.NEW, 1);
        values.put(CallLog.Calls.CACHED_NAME, "");
        values.put(CallLog.Calls.CACHED_NUMBER_TYPE, 0);
        values.put(CallLog.Calls.CACHED_NUMBER_LABEL, "");
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.WRITE_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return;
        }
        context.getContentResolver().insert(CallLog.Calls.CONTENT_URI, values);
    }
}
