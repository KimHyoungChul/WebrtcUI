package com.phemium.sipvideocall.data;

import com.phemium.sipvideocall.Utils;
import com.phemium.sipvideocall.constant.Constant;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by Tom on 1/5/2017.
 */

public class CallData extends Object {
    public String username;
    public String password;
    public String domain;
    public String proxy;
    public String turnServer0; // Turn Server #0 configuration
    public String turnDomain0;
    public String turnUsername0;
    public String turnPassword0;
    public String turnServer1; // Turn Server #1 configuration
    public String turnDomain1;
    public String turnUsername1;
    public String turnPassword1;
    public String toAddress;

    public Boolean onlyAudio;
    public Integer downloadBandwidth;
    public Integer uploadBandwidth;
    public Integer framerate;

    public String language;
    public String mainColor;
    public String secondaryColor;
    public int fontSize;
    public String fontColor;
    public String consultantName;
    public String displayTopViewMode;
    public int displayButtonTime;
    public String callRecordingNotificationVisible;

    public String transportMode;
    public String encryptionMode;
    public String videoSize;
    public String chatMode = "";
    public String zoomMode = "";
    public String videoCallPluginVersion;
    public String enduserPluginVersion;
    public String consultationId;
    public boolean logEnable;
    public String toEmail;

    public String permission;

    public CallData() {
        downloadBandwidth = -1;
        uploadBandwidth = -1;
        framerate = -1;
    }

    public int setCredentialValues(JSONObject credentialValues) {
        try {
            username = credentialValues.getString("username");
            password = credentialValues.getString("password");
            domain = credentialValues.getString("domain");

            proxy = credentialValues.getString("proxy");
            turnServer0 = credentialValues.getString("turnServer0");
            turnDomain0 = credentialValues.getString("turnDomain0");
            turnUsername0 = credentialValues.getString("turnUsername0");
            turnPassword0 = credentialValues.getString("turnPassword0");
            turnServer1 = credentialValues.getString("turnServer1");
            turnDomain1 = credentialValues.getString("turnDomain1");
            turnUsername1 = credentialValues.getString("turnUsername1");
            turnPassword1 = credentialValues.getString("turnPassword1");
        } catch (JSONException e) {
            e.printStackTrace();
            return Constant.DATA_PARSING_ERROR;
        }
        return Constant.NO_ERROR;
    }

    public int setCallSettingValues(JSONObject settingValues) {
        try {
            transportMode = settingValues.getString("transport_mode");
        } catch (JSONException e) {
            transportMode = "tls";
        }
        try {
            encryptionMode = settingValues.getString("encryption_mode");
        } catch (JSONException e) {
            encryptionMode = "none";
        }
        try {
            videoSize = settingValues.getString("video_size");
        } catch (JSONException e) {
            videoSize = "vga";
        }
        try {
            onlyAudio = settingValues.getBoolean("only_audio");
            downloadBandwidth = settingValues.getInt("download_bandwidth");
            uploadBandwidth = settingValues.getInt("upload_bandwidth");
            framerate = settingValues.getInt("framerate");
        } catch (JSONException e) {
            e.printStackTrace();
            return Constant.DATA_PARSING_ERROR;
        }
        return Constant.NO_ERROR;
    }

    public int setGUISettingValues(JSONObject guiSettingValues) {
        try {
            language = guiSettingValues.getString("language");
            mainColor = guiSettingValues.getString("main_color");
            secondaryColor = guiSettingValues.getString("secondary_color");
            fontSize = guiSettingValues.getInt("font_size");
            fontColor = guiSettingValues.getString("font_color");
            consultantName = guiSettingValues.getString("consultant_name");
            displayTopViewMode = guiSettingValues.getString("display_topview_mode");
            callRecordingNotificationVisible = guiSettingValues.getString("call_recording_notification_visible");
            chatMode = guiSettingValues.getString("chat_mode");
            zoomMode = guiSettingValues.getString("zoom_mode");
            logEnable =  guiSettingValues.getBoolean("log_mode");
        } catch (JSONException e) {
            e.printStackTrace();
        }
        this.checkGUIValues();
        return Constant.NO_ERROR;
    }

    public int setExtraSettingValues(JSONObject extraSettingValues) {

        try {
            toEmail = extraSettingValues.getString("extra_toemail");
            videoCallPluginVersion = extraSettingValues.getString("videocall_version");
            enduserPluginVersion = extraSettingValues.getString("enduser_version");
            consultationId = extraSettingValues.getString("consultation_id");
        } catch (JSONException e) {
        }
        return Constant.NO_ERROR;
    }
    public void setToAddress(String toAddressValue) {
        toAddress = toAddressValue;
    }

    public void checkGUIValues() {
        if (displayButtonTime <= 0) {
            displayButtonTime = 3;
        }
        if (Utils.isStringEmpty(mainColor)) {
            mainColor = "#0a79c7";
        }
        if (!mainColor.startsWith("#")) {
            mainColor = "#" + mainColor;
        }
        if (Utils.isStringEmpty(secondaryColor)) {
            secondaryColor = "#70c8e1";
        }
        if (!secondaryColor.startsWith("#")) {
            secondaryColor = "#" + secondaryColor;
        }
        if (Utils.isStringEmpty(displayTopViewMode)) {
            displayTopViewMode = "atScreenTouch";
        }
        if (Utils.isStringEmpty(fontColor)) {
            fontColor = "#ffffff";
        }
        if (!fontColor.startsWith("#")) {
            fontColor = "#" + fontColor;
        }
        if (fontSize <= 0) {
            fontSize = 17;
        }
        if (Utils.isStringEmpty(language)) {
            language = "es";
        }
        if (Utils.isStringEmpty(callRecordingNotificationVisible)) {
            callRecordingNotificationVisible = "no";
        }
        if (Utils.isStringEmpty(consultantName)) {
            consultantName = Constant.CONSULTANT_DEFAULT_NAME;
        }

        if (Utils.isStringEmpty(chatMode)) {
            chatMode = "WithChat";
        }
        if (Utils.isStringEmpty(zoomMode)) {
            zoomMode = "zoom";
        }
    }
}
