import NitroGoogleSSO from 'react-native-nitro-google-sso';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { GoogleUserInfo } from '../types';

// Configuration - these will need to be replaced with actual values from Google Cloud Console
const GOOGLE_CONFIG = {
  iosClientId: 'YOUR_IOS_CLIENT_ID_HERE', // TODO: Replace with actual iOS client ID
  webClientId: 'YOUR_WEB_CLIENT_ID_HERE', // TODO: Replace with actual web client ID
  // hostedDomain: 'example.com', // Optional: restrict to specific domain
};

// Storage keys
const STORAGE_KEYS = {
  USER_INFO: 'userInfo',
  ACCESS_TOKEN: 'accessToken',
  REFRESH_TOKEN: 'refreshToken',
} as const;

export class AuthService {
  private static initialized = false;

  static async initialize(): Promise<void> {
    if (!this.initialized) {
      try {
        NitroGoogleSSO.configure(GOOGLE_CONFIG);
        this.initialized = true;
        console.log('Google SSO configured successfully');
      } catch (error) {
        console.error('Failed to configure Google SSO:', error);
        throw error;
      }
    }
  }

  static async signIn(): Promise<GoogleUserInfo | null> {
    try {
      await this.initialize();
      const user = await NitroGoogleSSO.signIn();
      
      if (user) {
        // Store user info and tokens securely
        await AsyncStorage.multiSet([
          [STORAGE_KEYS.USER_INFO, JSON.stringify(user)],
          [STORAGE_KEYS.ACCESS_TOKEN, user.accessToken],
        ]);
        console.log('User signed in and tokens stored');
      }
      
      return user;
    } catch (error) {
      console.error('Sign in failed:', error);
      throw error;
    }
  }

  static async signOut(): Promise<void> {
    try {
      await NitroGoogleSSO.signOut();
      
      // Clear stored user data
      await AsyncStorage.multiRemove([
        STORAGE_KEYS.USER_INFO,
        STORAGE_KEYS.ACCESS_TOKEN,
        STORAGE_KEYS.REFRESH_TOKEN,
      ]);
      
      console.log('User signed out successfully');
    } catch (error) {
      console.error('Sign out failed:', error);
      throw error;
    }
  }

  static async getCurrentUser(): Promise<GoogleUserInfo | null> {
    try {
      // Try to get from NitroGoogleSSO first
      const user = await NitroGoogleSSO.getCurrentUser();
      if (user) {
        return user;
      }

      // Fallback to stored user info
      const userInfoString = await AsyncStorage.getItem(STORAGE_KEYS.USER_INFO);
      return userInfoString ? JSON.parse(userInfoString) : null;
    } catch (error) {
      console.error('Failed to get current user:', error);
      return null;
    }
  }

  static async getAccessToken(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
    } catch (error) {
      console.error('Failed to get access token:', error);
      return null;
    }
  }

  static async isSignedIn(): Promise<boolean> {
    const user = await this.getCurrentUser();
    return user !== null;
  }
}