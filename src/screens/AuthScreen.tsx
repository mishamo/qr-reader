import React from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Button, Card, Title, Text } from 'react-native-paper';
import { AuthService } from '../services/auth';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { GoogleUserInfo, RootStackParamList } from '../types';

type AuthScreenProps = {
  navigation: StackNavigationProp<RootStackParamList, 'Auth'>;
};

export const AuthScreen: React.FC<AuthScreenProps> = ({ navigation }) => {
  const handleGoogleSignIn = async () => {
    try {
      const user: GoogleUserInfo | null = await AuthService.signIn();
      
      if (user) {
        Alert.alert(
          'Success!',
          `Welcome ${user.name}!\nEmail: ${user.email}`,
          [{ text: 'OK' }]
        );
        console.log('User signed in:', user);
        navigation.navigate('SheetSelect');
      } else {
        Alert.alert('Cancelled', 'Sign in was cancelled');
      }
    } catch (error) {
      console.error('Sign in error:', error);
      Alert.alert(
        'Error',
        'Google OAuth not configured yet. This will work once we set up Google Cloud credentials.',
        [{ text: 'OK' }]
      );
    }
  };

  const handleTestMode = () => {
    Alert.alert(
      'Test Mode',
      'This will simulate successful authentication for testing',
      [{ text: 'OK' }]
    );
    console.log('Test mode activated');
    navigation.navigate('SheetSelect');
  };

  return (
    <View style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.title}>Scan2Sheets</Title>
          <Text style={styles.subtitle}>
            Scan QR codes and add attendee information to Google Sheets
          </Text>
          
          <View style={styles.buttonContainer}>
            <Button
              mode="contained"
              onPress={handleGoogleSignIn}
              style={styles.googleButton}
            >
              Sign in with Google
            </Button>
            
            <Button
              mode="outlined"
              onPress={handleTestMode}
              style={styles.testButton}
            >
              Test Mode (No Auth)
            </Button>
          </View>
        </Card.Content>
      </Card>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  card: {
    padding: 16,
    marginHorizontal: 16,
  },
  title: {
    textAlign: 'center',
    marginBottom: 8,
    fontSize: 28,
    fontWeight: 'bold',
  },
  subtitle: {
    textAlign: 'center',
    marginBottom: 32,
    fontSize: 16,
    color: '#666',
  },
  buttonContainer: {
    gap: 16,
  },
  googleButton: {
    paddingVertical: 8,
  },
  testButton: {
    paddingVertical: 8,
  },
});