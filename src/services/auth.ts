import { GoogleSignin } from '@react-native-google-signin/google-signin';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { GoogleUserInfo } from '../types';

// Configuration - Google OAuth client IDs from Google Cloud Console
const GOOGLE_CONFIG = {
  webClientId: '589666129777-bfe64ev2l8h2r5fu4btv6gk4c1apfsuc.apps.googleusercontent.com', // Web OAuth client ID
  scopes: [
    'https://www.googleapis.com/auth/spreadsheets', // Full access to Google Sheets
    'https://www.googleapis.com/auth/drive.readonly', // Read access to Google Drive (to list sheets)
  ],
  offlineAccess: true, // Required for getting access tokens
  forceCodeForRefreshToken: true, // Required for refresh tokens
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
        GoogleSignin.configure(GOOGLE_CONFIG);
        this.initialized = true;
        console.log('Google Sign-In configured successfully');
      } catch (error) {
        console.error('Failed to configure Google Sign-In:', error);
        throw error;
      }
    }
  }

  static async signIn(): Promise<GoogleUserInfo | null> {
    try {
      await this.initialize();
      
      // Check if user is already signed in
      await GoogleSignin.hasPlayServices();
      const response = await GoogleSignin.signIn();
      
      if (response && response.type === 'success') {
        console.log('Google sign-in response:', JSON.stringify(response, null, 2));
        
        // Get tokens separately
        const tokens = await GoogleSignin.getTokens();
        console.log('Google tokens:', JSON.stringify(tokens, null, 2));
        console.log('Access token exists?', !!tokens.accessToken);
        console.log('ID token exists?', !!tokens.idToken);
        
        // Debug: Check response structure
        console.log('Response data exists?', !!response.data);
        console.log('Response data user exists?', !!(response.data && response.data.user));
        console.log('User email exists?', !!(response.data && response.data.user && response.data.user.email));
        
        // Safely access user data with null checks
        if (!response.data || !response.data.user) {
          throw new Error('Invalid response structure from Google Sign-In');
        }
        
        // Transform to our GoogleUserInfo format using correct 2025 API structure
        const user: GoogleUserInfo = {
          email: response.data.user.email,
          name: response.data.user.name || '',
          givenName: response.data.user.givenName || '',
          familyName: response.data.user.familyName || '',
          photoUrl: response.data.user.photo || '',
          accessToken: tokens.accessToken,
          idToken: tokens.idToken || response.data.idToken || '',
        };
        
        // Store user info and tokens securely
        const storageItems: [string, string][] = [
          [STORAGE_KEYS.USER_INFO, JSON.stringify(user)],
          [STORAGE_KEYS.ACCESS_TOKEN, tokens.accessToken],
        ];
        
        if (tokens.idToken) {
          // Note: We don't need to store refresh token as GoogleSignin handles it internally
        }
        
        await AsyncStorage.multiSet(storageItems);
        console.log('User signed in and tokens stored successfully');
        console.log('Access token preview:', tokens.accessToken.substring(0, 20) + '...');
        
        return user;
      }
      
      return null;
    } catch (error) {
      console.error('Sign in failed:', error);
      throw error;
    }
  }

  static async signOut(): Promise<void> {
    try {
      await GoogleSignin.signOut();
      
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
      // Try to get current user from GoogleSignin
      try {
        const userInfo = await GoogleSignin.getCurrentUser();
        if (userInfo) {
          // Get fresh tokens
          const tokens = await GoogleSignin.getTokens();
          
          // Transform to our GoogleUserInfo format (getCurrentUser returns User object directly)
          return {
            email: userInfo.user.email,
            name: userInfo.user.name || '',
            givenName: userInfo.user.givenName || '',
            familyName: userInfo.user.familyName || '',
            photoUrl: userInfo.user.photo || '',
            accessToken: tokens.accessToken,
            idToken: tokens.idToken || userInfo.idToken || '',
          };
        }
      } catch (googleError) {
        console.log('No current Google user, using stored info');
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
      // Try to get fresh token from GoogleSignin first
      try {
        const tokens = await GoogleSignin.getTokens();
        if (tokens && tokens.accessToken) {
          return tokens.accessToken;
        }
      } catch (tokenError) {
        console.log('No fresh tokens available, using stored token');
      }
      
      // Fallback to stored token
      return await AsyncStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
    } catch (error) {
      console.error('Failed to get access token:', error);
      return null;
    }
  }

  static async isSignedIn(): Promise<boolean> {
    try {
      // Try to get current user - if successful, user is signed in
      const userInfo = await GoogleSignin.getCurrentUser();
      return !!userInfo;
    } catch (error) {
      // If getCurrentUser fails, check stored user info
      try {
        const userInfoString = await AsyncStorage.getItem(STORAGE_KEYS.USER_INFO);
        return !!userInfoString;
      } catch (storageError) {
        console.error('Failed to check sign-in status:', error);
        return false;
      }
    }
  }
}