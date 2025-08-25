/**
 * Scan2Sheets Mobile App
 * Conference lead collection with Google Sheets integration
 */

import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { PaperProvider, MD3LightTheme } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthScreen } from './src/screens/AuthScreen';
import type { RootStackParamList } from './src/types';

const Stack = createStackNavigator<RootStackParamList>();

// Placeholder screens for navigation structure
const SheetSelectScreen = () => {
  return null; // TODO: Implement sheet selection screen
};

const ScannerScreen = () => {
  return null; // TODO: Implement QR scanner screen  
};

function App(): React.JSX.Element {
  return (
    <SafeAreaProvider>
      <PaperProvider theme={MD3LightTheme}>
        <NavigationContainer>
          <Stack.Navigator
            initialRouteName="Auth"
            screenOptions={{
              headerStyle: {
                backgroundColor: MD3LightTheme.colors.primaryContainer,
              },
              headerTintColor: MD3LightTheme.colors.onPrimaryContainer,
            }}
          >
            <Stack.Screen
              name="Auth"
              component={AuthScreen}
              options={{
                title: 'Sign In',
                headerShown: false, // Hide header for auth screen
              }}
            />
            <Stack.Screen
              name="SheetSelect"
              component={SheetSelectScreen}
              options={{
                title: 'Select Sheet',
              }}
            />
            <Stack.Screen
              name="Scanner"
              component={ScannerScreen}
              options={{
                title: 'QR Scanner',
              }}
            />
          </Stack.Navigator>
        </NavigationContainer>
      </PaperProvider>
    </SafeAreaProvider>
  );
}

export default App;
