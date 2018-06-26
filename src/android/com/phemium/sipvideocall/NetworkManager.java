package com.phemium.sipvideocall;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.telephony.TelephonyManager;
import android.util.Log;

import com.phemium.sipvideocall.listener.BandwidthListener;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Headers;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

/**
 * Created by super on 5/11/2017.
 */

public class NetworkManager {

    private static double bandwidth;

    public static String getNetworkType(Context context){
        String networkType = "No Internet";
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();
        if (activeNetwork != null) { // connected to the internet
            if (activeNetwork.getType() == ConnectivityManager.TYPE_WIFI) {
                networkType = "WiFi";
            } else if (activeNetwork.getType() == ConnectivityManager.TYPE_MOBILE) {
                networkType = getNetworkClass(context);
            }
        } else {
            networkType = "No Internet";
        }
        return networkType;
    }

    public static boolean isOnline(Context context){
        ConnectivityManager cm =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo netInfo = cm.getActiveNetworkInfo();
        Log.e("NetworkManager", "NetworkInfo:" + netInfo);
        return netInfo != null && netInfo.isConnectedOrConnecting();
    }

    private static String getNetworkClass(Context context) {
        TelephonyManager mTelephonyManager = (TelephonyManager)
                context.getSystemService(Context.TELEPHONY_SERVICE);
        int networkType = mTelephonyManager.getNetworkType();
        switch (networkType) {
            case TelephonyManager.NETWORK_TYPE_GPRS:
            case TelephonyManager.NETWORK_TYPE_EDGE:
            case TelephonyManager.NETWORK_TYPE_CDMA:
            case TelephonyManager.NETWORK_TYPE_1xRTT:
            case TelephonyManager.NETWORK_TYPE_IDEN:
                Log.e("NetworkManager" , "2G");
                return "2G";
            case TelephonyManager.NETWORK_TYPE_UMTS:
            case TelephonyManager.NETWORK_TYPE_EVDO_0:
            case TelephonyManager.NETWORK_TYPE_EVDO_A:
            case TelephonyManager.NETWORK_TYPE_HSDPA:
            case TelephonyManager.NETWORK_TYPE_HSUPA:
            case TelephonyManager.NETWORK_TYPE_HSPA:
            case TelephonyManager.NETWORK_TYPE_EVDO_B:
            case TelephonyManager.NETWORK_TYPE_EHRPD:
            case TelephonyManager.NETWORK_TYPE_HSPAP:
                Log.e("NetworkManager" , "3G");
                return "3G";
            case TelephonyManager.NETWORK_TYPE_LTE:
                Log.e("NetworkManager" , "4G");
                return "4G";
            default:
                return "No Internet";
        }
    }

    public static double getBandwidth(Context context, BandwidthListener listener){
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        if(cm.getActiveNetworkInfo().isConnected()) {
            downloadInfo(context, listener);  // call downloadInfo to perform the download request
        }
        double bw = bandwidth;
        return bw;
    }


    private static void downloadInfo(Context context, final  BandwidthListener listener){
        Request request = new Request.Builder()
                .url("https://avatars2.githubusercontent.com/u/17764098?v=3&s=400") // replace image url
                .build();


        final long startTime = System.currentTimeMillis();

        OkHttpClient client = new OkHttpClient();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                e.printStackTrace();
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

                Headers responseHeaders = response.headers();
                for (int i = 0, size = responseHeaders.size(); i < size; i++) {
                    Log.d("NetworkManager", responseHeaders.name(i) + ": " + responseHeaders.value(i));
                }

                InputStream input = response.body().byteStream();
                long fileSize = 0;
                try {
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    byte[] buffer = new byte[1024];

                    while (input.read(buffer) != -1) {
                        bos.write(buffer);
                    }
                    byte[] docBuffer = bos.toByteArray();
                    fileSize = bos.size();

                }catch (Exception e) {
                }finally {
                    input.close();
                }

                long endTime = System.currentTimeMillis();

                // calculate how long it took by subtracting endtime from starttime

                final double timeTakenMills = Math.floor(endTime - startTime);  // time taken in milliseconds
                final double timeTakenInSecs = timeTakenMills / 1000;  // divide by 1000 to get time in seconds
                final int kilobytePerSec = (int) Math.round(1024 / timeTakenInSecs);
                final double speed = Math.round(fileSize / timeTakenMills);
                listener.onBandwidthCalcuated((float) speed);
            }
        });
    }

}
