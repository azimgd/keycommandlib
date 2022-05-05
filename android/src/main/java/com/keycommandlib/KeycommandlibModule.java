package com.keycommandlib;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import android.view.KeyEvent;

@ReactModule(name = KeycommandlibModule.NAME)
public class KeycommandlibModule extends ReactContextBaseJavaModule {
  private static ReactApplicationContext reactContext = null;
  private DeviceEventManagerModule.RCTDeviceEventEmitter mJSModule = null;
  private static KeycommandlibModule instance = null;

  public static final String NAME = "Keycommandlib";

  public KeycommandlibModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  public static KeycommandlibModule initKeycommandlibModule(ReactApplicationContext reactContext) {
    instance = new KeycommandlibModule(reactContext);
    return instance;
  }

  public static KeycommandlibModule getInstance() {
    return instance;
  }

  public void onKeyDownEvent(int keyCode, KeyEvent keyEvent) {
    if (!reactContext.hasActiveCatalystInstance()) {
      return;
    }

    if (mJSModule == null) {
      mJSModule = reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
    }
    mJSModule.emit("onKeyCommand", getJsEventParams(keyCode, keyEvent, null));
  };

  public void onKeyUpEvent(int keyCode, KeyEvent keyEvent) {
    if (!reactContext.hasActiveCatalystInstance()) {
      return;
    }

    if (mJSModule == null) {
      mJSModule = reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
    }
    mJSModule.emit("onKeyCommand", getJsEventParams(keyCode, keyEvent, null));
  };

  public void onKeyMultipleEvent(int keyCode, int repeatCount, KeyEvent keyEvent) {
    if (!reactContext.hasActiveCatalystInstance()) {
      return;
    }

    if (mJSModule == null) {
      mJSModule = reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
    }
    mJSModule.emit("onKeyCommand", getJsEventParams(keyCode, keyEvent, repeatCount));
  };

  private WritableMap getJsEventParams(int keyCode, KeyEvent keyEvent, Integer repeatCount) {
    WritableMap params = new WritableNativeMap();
    int action = keyEvent.getAction();
    char pressedKey = (char) keyEvent.getUnicodeChar();

    if (keyEvent.getAction() == KeyEvent.ACTION_MULTIPLE && keyCode == KeyEvent.KEYCODE_UNKNOWN) {
      String chars = keyEvent.getCharacters();
      if (chars != null) {
        params.putString("characters", chars);
      }
    }

    if (repeatCount != null) {
      params.putInt("repeatcount", repeatCount);
    }

    params.putInt("keyCode", keyCode);
    params.putInt("action", action);
    params.putString("pressedKey", String.valueOf(pressedKey));

    return params;
  }


  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  public void multiply(int a, int b, Promise promise) {
    promise.resolve(a * b);
  }

  public static native int nativeMultiply(int a, int b);
}
