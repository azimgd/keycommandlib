package com.example.keycommandlib;

import android.view.KeyEvent;
import com.facebook.react.ReactActivity;
import com.keycommandlib.KeycommandlibModule;

public class MainActivity extends ReactActivity {
  @Override
  public boolean onKeyDown(int keyCode, KeyEvent event) {
    KeycommandlibModule.getInstance().onKeyDownEvent(keyCode, event);
    return super.onKeyDown(keyCode, event);
  }

  @Override
  public boolean onKeyMultiple(int keyCode, int repeatCount, KeyEvent event) {
    KeycommandlibModule.getInstance().onKeyMultipleEvent(keyCode, repeatCount, event);
    return super.onKeyMultiple(keyCode, repeatCount, event);
  }

  @Override
  public boolean onKeyUp(int keyCode, KeyEvent event) {
    KeycommandlibModule.getInstance().onKeyUpEvent(keyCode, event);
    return super.onKeyUp(keyCode, event);
  }

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  @Override
  protected String getMainComponentName() {
    return "KeycommandlibExample";
  }
}
