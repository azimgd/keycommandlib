import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { registerKeyCommand, constants, eventEmitter } from 'keycommandlib';

export default function App() {
  React.useEffect(() => {
    registerKeyCommand([
      {
        input: 'k',
        modifierFlags: constants.keyModifierCommand,
      },
    ]);

    const eventListener = eventEmitter.addListener('onKeyCommand', (event) => {
      console.log(event);
    });

    return eventListener.remove;
  }, []);

  return (
    <View style={styles.container}>
      <Text>KeyCommandLib</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
