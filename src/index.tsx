import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'keycommandlib' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const Keycommandlib = NativeModules.Keycommandlib
  ? NativeModules.Keycommandlib
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function registerKeyCommand(a: number): Promise<number> {
  // return Keycommandlib.registerKeyCommand(a);
}

export const eventEmitter = new NativeEventEmitter(Keycommandlib);

export const constants = Keycommandlib.getConstants();

eventEmitter.addListener('onKeyCommand', (event) => {
  console.log(event)
});
