package com.phemium.sipvideocall.constant;

/**
 * Created by Tom on 1/5/2017.
 */

public class Constant {
    public final static int NO_ERROR = 0;
    public final static int DATA_PARSING_ERROR = 1;
    public final static int PERMISSION_CHECK_MEDIA = 1;
    public final static int PERMISSION_CHECK_MEDIA_BEFORE_CALL = 2;

    public static final int SWIPE_TOP = 1;
    public static final int SWIPE_LEFT = 2;
    public static final int SWIPE_RIGHT = 3;
    public static final int SWIPE_BOTTOM = 4;

    public final static int CALL_RESULT_ERROR_RECORD_PERMISSION_NOT_ALLOWED = 1; //Request permission failed or Microphone permission not allowed.
    public final static int CALL_RESULT_ERROR_REGISTER_FAILURE = 2;
    public final static int CALL_RESULT_ERROR_CONNECTING_TIMEOUT = 3;
    public final static int CALL_RESULT_ERROR_BUSY = 4;
    public final static int CALL_RESULT_ERROR_DECLINED = 5;
    public final static int CALL_RESULT_ERROR_CALLEE_NOT_FOUND = 6;
    public final static int CALL_RESULT_ERROR_INIT_TIMEOUT = 7;
    public final static int CALL_RESULT_ERROR_RINGING_TIMEOUT = 8;
    public final static int CALL_RESULT_ERROR_CALLEE_NOT_EXIST = 9;
    public final static int CALL_RESULT_ERROR_NOINTERNET = 10;
    public final static int CALL_RESULT_ERROR_NETWORK_CHANGED = 12;
    public final static int CALL_RESULT_ERROR_UNKNOWN = 11;

    public final static String CALL_RESULT_DECLINED_MESSAGE = "Call declined.";

    public final static int CALL_EVENT_MICRO_MUTED = 1;
    public final static int CALL_EVENT_MICRO_UNMUTED = 2;
    public final static int CALL_EVENT_CAMERA_MUTED = 3;
    public final static int CALL_EVENT_CAMERA_UNMUTED = 4;

    public final static int CALL_EVENT_MINIMIZE_VIDEO = 5;
    public final static int CALL_EVENT_SEND_QUALITY = 6;

    public final static int CALL_REGISTERING = 1;
    public final static int CALL_REGISTERED = 7;
    public final static int CALL_REGISTER_FAILED = 8;
    public final static int CALL_INITIALISING = 2;
    public final static int CALL_RINGING = 3;
    public final static int CALL_CONNECTING = 4;
    public final static int CALL_CONNECTED = 5;
    public final static int CALL_ENDED = 6;

    public final static int CALL_RETRYING = 7;
    public final static int CALL_ENDING = 8;

    public final static int HIDE_CONTROL_CONTAINER_MSECS = 3000;
    public final static int CALL_RING_MAX_DELAY = 30000;
    public final static int CALL_RINGING_MAX_DELAY = 32000;
    public final static int CALL_INIT_MAX_DELAY = 3000;
    public final static int CALL_REGISTER_MAX_DELAY = 10000;
    public final static int CALL_UNREGISTER_MAX_DELAY = 12000;
    public final static int CALL_CONNECTING_MAX_DELAY = 10000;

    public final static int MAX_FAILED_COUNT = 2;
    public final static int MAX_RETRY_COUNT = 2;

    public final static int FONT_SIZE_OFFSET_BUTTON_LABEL = 4;
    public final static int FONT_SIZE_OFFSET_STATUS_LABEL = 2;

    public final static int VIDEO_CALL_NOTIFICATION_ID = 113;

    public final static String CONSULTANT_DEFAULT_NAME = "John Doe";

    public final static int CALL_HANGUP_BY_CALLEE = 1;
    public final static int CALL_HANGUP_BY_ERROR = 2;
    public final static int CALL_HANGUP_BY_CALLER = 3;

    public final static int CALL_QUALITY_ALERT_VALUE = 1;
    public final static int QUALITY_COUNT_FOR_AVERAGE = 5;
    public final static int QUALITY_COUNT_SEND_PHEMIUM = 10;
}
