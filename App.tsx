/**
 * Scan2Sheets Mobile App
 * Conference lead collection with Google Sheets integration
 */

import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { PaperProvider, MD3LightTheme } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthScreen } from './src/screens/AuthScreen';
import { SheetSelectScreen } from './src/screens/SheetSelectScreen';
import { QRScannerScreen } from './src/screens/QRScannerScreen';
import { SplashScreen } from './src/screens/SplashScreen';
import { AuthService } from './src/services/auth';
import type { RootStackParamList } from './src/types';

const Stack = createStackNavigator<RootStackParamList>();

function App(): React.JSX.Element {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    checkAuthenticationStatus();
  }, []);

  const checkAuthenticationStatus = async () => {
    try {
      await AuthService.initialize();
      const isSignedIn = await AuthService.isSignedIn();
      setIsAuthenticated(isSignedIn);
      
      // Small delay to prevent flash
      setTimeout(() => {
        setIsLoading(false);
      }, 500);
    } catch (error) {
      console.error('Auth check failed:', error);
      setIsAuthenticated(false);
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <SafeAreaProvider>
        <PaperProvider theme={MD3LightTheme}>
          <SplashScreen />
        </PaperProvider>
      </SafeAreaProvider>
    );
  }

  return (
    <SafeAreaProvider>
      <PaperProvider theme={MD3LightTheme}>
        <NavigationContainer>
          <Stack.Navigator
            initialRouteName={isAuthenticated ? "SheetSelect" : "Auth"}
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
                headerShown: false,
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
              component={QRScannerScreen}
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
