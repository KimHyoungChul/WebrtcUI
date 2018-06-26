package com.phemium.sipvideocall.data;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.JsonReader;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by Tom on 2/2/2017.
 */

public class LanguageResource {

    private static LanguageResource instance;
    private Map<String, String> stringMap;

    public static LanguageResource getInstance() {
        if (instance == null) {
            instance = new LanguageResource();
        }
        return instance;
    }

    public void readFromJsonFile(String lang, Context context) {
        String path = "langs/" + lang + ".json";
        AssetManager assManager = context.getApplicationContext().getAssets();
        InputStream inputStream = null;
        stringMap = new HashMap<>();
        try {
            inputStream = assManager.open(path);
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }

        try {
            JsonReader jsonReader = new JsonReader(new InputStreamReader(inputStream, "UTF-8"));
            try {
                jsonReader.beginArray();
                while (jsonReader.hasNext()) {
                    jsonReader.beginObject();
                    stringMap.put(jsonReader.nextName(), jsonReader.nextString());
                    jsonReader.endObject();
                }
                jsonReader.endArray();
            } catch (IOException e) {
                e.printStackTrace();
            }

        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }

    }

    public String getStringValue(String key) {
        if (stringMap != null) {
            if (stringMap.containsKey(key)) {
                return stringMap.get(key);
            }
        }
        return "";
    }
}
