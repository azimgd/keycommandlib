import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { registerKeyCommand, constants, eventEmitter } from 'keycommandlib';

export default function App() {
  const [history, setHistory] = React.useState([]);

  React.useEffect(() => {
    registerKeyCommand([
      {
        input: 'k',
        modifierFlags: constants.keyModifierCommand,
      },
    ]);

    const eventListener = eventEmitter.addListener('onKeyCommand', (event) => {
      console.log(321)
      setHistory(state => [event, ...state].slice(0, 20));
    });

    return eventListener.remove;
  }, []);

  return (
    <View style={styles.container}>
      {history.map((item, key) => (
        <Text key={key}>{JSON.stringify(item)}</Text>
      ))}
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
