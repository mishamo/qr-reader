import React, { useState, useCallback, useEffect } from 'react';
import { View, StyleSheet, Alert, Text, PermissionsAndroid, Platform } from 'react-native';
import { Camera } from 'react-native-camera-kit';
import { Button, Card, Title } from 'react-native-paper';
import type { RouteProp } from '@react-navigation/native';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { ContactInfo, RootStackParamList } from '../types';
import { GoogleSheetsService } from '../services/googleSheets';

type QRScannerScreenProps = {
  navigation: StackNavigationProp<RootStackParamList, 'Scanner'>;
  route: RouteProp<RootStackParamList, 'Scanner'>;
};

export const QRScannerScreen: React.FC<QRScannerScreenProps> = ({ navigation, route }) => {
  const [scannedData, setScannedData] = useState<ContactInfo | null>(null);
  const [isScanning, setIsScanning] = useState(true);
  const [addingToSheet, setAddingToSheet] = useState(false);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  
  const selectedSheet = route.params?.selectedSheet;

  useEffect(() => {
    checkCameraPermission();
  }, []);

  const checkCameraPermission = async () => {
    try {
      if (Platform.OS === 'android') {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.CAMERA,
          {
            title: 'Camera Permission',
            message: 'Scan2Sheets needs access to your camera to scan QR codes.',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
        setHasPermission(granted === PermissionsAndroid.RESULTS.GRANTED);
      } else {
        // iOS permissions are handled by the library automatically
        setHasPermission(true);
      }
    } catch (error) {
      console.error('Camera permission error:', error);
      setHasPermission(false);
    }
  };

  const parseVCard = useCallback((vcard: string): ContactInfo => {
    const lines = vcard.split('\n');
    let name = '';
    let email = '';
    let phone = '';
    
    for (const line of lines) {
      if (line.startsWith('FN:')) {
        name = line.substring(3).trim();
      } else if (line.startsWith('EMAIL:')) {
        email = line.substring(6).trim();
      } else if (line.startsWith('TEL:')) {
        phone = line.substring(4).trim();
      }
    }
    
    if (!name || !email) {
      throw new Error('Missing required fields in vCard');
    }
    
    return { name, email, phone };
  }, []);

  const parseSimpleFormat = useCallback((data: string): ContactInfo => {
    const parts = data.split(',').map(part => part.trim());
    if (parts.length < 2) {
      throw new Error('Invalid simple format');
    }
    
    return {
      name: parts[0],
      email: parts[1],
      phone: parts[2] || ''
    };
  }, []);

  const parseQRCode = useCallback((data: string): ContactInfo => {
    // Try JSON format first
    if (data.trim().startsWith('{')) {
      try {
        const parsed = JSON.parse(data);
        if (parsed.name && parsed.email) {
          return {
            name: parsed.name,
            email: parsed.email,
            phone: parsed.phone || ''
          };
        }
      } catch (e) {
        // Continue to next format
      }
    }
    
    // Try vCard format
    if (data.startsWith('BEGIN:VCARD')) {
      return parseVCard(data);
    }
    
    // Try simple comma-separated format
    if (data.includes('@') && data.includes(',')) {
      return parseSimpleFormat(data);
    }
    
    throw new Error('Unsupported QR code format');
  }, [parseVCard, parseSimpleFormat]);

  const resetScanner = useCallback(() => {
    setScannedData(null);
    setIsScanning(true);
  }, []);

  const addToSheet = useCallback(async (contact: ContactInfo) => {
    if (!selectedSheet) {
      Alert.alert(
        'No Sheet Selected',
        'Please go back and select a Google Sheet first.',
        [{ text: 'OK', onPress: () => navigation.goBack() }]
      );
      return;
    }

    try {
      setAddingToSheet(true);
      
      await GoogleSheetsService.addContactToSheet(selectedSheet.id, contact);
      
      Alert.alert(
        '✅ Contact Added!',
        `${contact.name} has been successfully added to "${selectedSheet.title}".`,
        [
          { text: '📊 View Sheet', onPress: () => {
            // TODO: Open sheet URL in browser
            console.log('Would open:', selectedSheet.url);
          }},
          { text: '🔄 Scan Another', onPress: () => resetScanner() }
        ]
      );
    } catch (error) {
      console.error('Failed to add contact to sheet:', error);
      
      Alert.alert(
        '❌ Failed to Add Contact',
        error instanceof Error ? error.message : 'Failed to add contact to Google Sheet. Please check your connection and try again.',
        [
          { text: '🔄 Try Again', onPress: () => addToSheet(contact) },
          { text: '📱 Scan Another', onPress: () => resetScanner() }
        ]
      );
    } finally {
      setAddingToSheet(false);
    }
  }, [selectedSheet, navigation, resetScanner]);

  const onReadCode = useCallback((event: any) => {
    if (!isScanning) return;
    
    const qrValue = event.nativeEvent.codeStringValue;
    if (!qrValue) return;
    
    setIsScanning(false);
    
    try {
      const parsed = parseQRCode(qrValue);
      setScannedData(parsed);
      
      Alert.alert(
        '🎉 QR Code Scanned!',
        `Name: ${parsed.name}\nEmail: ${parsed.email}${parsed.phone ? `\nPhone: ${parsed.phone}` : ''}`,
        [
          { 
            text: addingToSheet ? '⏳ Adding...' : '✅ Add to Sheet', 
            onPress: addingToSheet ? undefined : () => addToSheet(parsed) 
          },
          { text: '🔄 Scan Another', onPress: () => resetScanner() }
        ]
      );
    } catch (error) {
      Alert.alert(
        '❌ Invalid QR Code',
        'Could not parse contact information from this QR code.\n\nSupported formats:\n• JSON: {"name":"John","email":"john@email.com"}\n• Simple: John Doe,john@email.com\n• vCard format',
        [{ text: 'Try Again', onPress: () => setIsScanning(true) }]
      );
    }
  }, [isScanning, addingToSheet, parseQRCode, addToSheet, resetScanner]);

  // Show permission request if camera permission not granted
  if (hasPermission === false) {
    return (
      <View style={styles.permissionContainer}>
        <Card style={styles.permissionCard}>
          <Card.Content>
            <Title style={styles.permissionTitle}>📱 Camera Permission Required</Title>
            <Text style={styles.permissionText}>
              Scan2Sheets needs camera access to scan QR codes containing contact information.
            </Text>
            <Button
              mode="contained"
              onPress={checkCameraPermission}
              style={styles.permissionButton}
            >
              Grant Camera Permission
            </Button>
          </Card.Content>
        </Card>
      </View>
    );
  }

  // Show loading state while checking permissions
  if (hasPermission === null) {
    return (
      <View style={styles.permissionContainer}>
        <Card style={styles.permissionCard}>
          <Card.Content>
            <Title style={styles.permissionTitle}>📱 Checking Camera Access...</Title>
          </Card.Content>
        </Card>
      </View>
    );
  }

  if (scannedData) {
    return (
      <View style={styles.container}>
        <Card style={styles.card}>
          <Card.Content>
            <Title style={styles.successTitle}>✅ Contact Scanned!</Title>
            <View style={styles.contactInfo}>
              <Text style={styles.contactField}>
                <Text style={styles.fieldLabel}>Name:</Text> {scannedData.name}
              </Text>
              <Text style={styles.contactField}>
                <Text style={styles.fieldLabel}>Email:</Text> {scannedData.email}
              </Text>
              {scannedData.phone && (
                <Text style={styles.contactField}>
                  <Text style={styles.fieldLabel}>Phone:</Text> {scannedData.phone}
                </Text>
              )}
            </View>
            <Button
              mode="contained"
              onPress={() => addToSheet(scannedData)}
              style={styles.primaryButton}
            >
              📊 Add to Google Sheet
            </Button>
            <Button
              mode="outlined"
              onPress={resetScanner}
              style={styles.button}
            >
              📱 Scan Another QR Code
            </Button>
          </Card.Content>
        </Card>
      </View>
    );
  }

  return (
    <View style={styles.cameraContainer}>
      <Camera
        style={StyleSheet.absoluteFill}
        scanBarcode={true}
        onReadCode={onReadCode}
        showFrame={true}
        laserColor='#FF3D00'
        frameColor='#FFFFFF'
        surfaceHolderBackground='#000000'
        focusMode='on'
        zoomMode='on'
        ratioOverlay='1:1'
        ratioOverlayColor='#00000077'
      />
      
      <View style={styles.overlay}>
        <View style={styles.topOverlay}>
          <Text style={styles.instructionText}>
            📱 Position the QR code within the frame
          </Text>
        </View>
        
        <View style={styles.scanningArea}>
          {/* Frame is shown by Camera Kit */}
        </View>
        
        <View style={styles.bottomOverlay}>
          <Text style={styles.formatText}>
            📋 Supported formats: JSON • Simple (name,email) • vCard
          </Text>
        </View>
      </View>
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
  cameraContainer: {
    flex: 1,
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'space-between',
  },
  topOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    justifyContent: 'flex-end',
    alignItems: 'center',
    paddingBottom: 20,
  },
  scanningArea: {
    height: 300,
    justifyContent: 'center',
    alignItems: 'center',
  },
  bottomOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    justifyContent: 'flex-start',
    alignItems: 'center',
    paddingTop: 20,
  },
  instructionText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
  },
  formatText: {
    color: '#ccc',
    fontSize: 14,
    textAlign: 'center',
    paddingHorizontal: 20,
  },
  card: {
    elevation: 4,
  },
  message: {
    marginBottom: 16,
    fontSize: 16,
    lineHeight: 24,
    color: '#666',
  },
  button: {
    marginTop: 12,
  },
  primaryButton: {
    marginBottom: 8,
  },
  successTitle: {
    textAlign: 'center',
    color: '#2e7d32',
    marginBottom: 20,
  },
  contactInfo: {
    backgroundColor: '#f0f9ff',
    padding: 16,
    borderRadius: 8,
    marginBottom: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#1976d2',
  },
  contactField: {
    fontSize: 16,
    marginBottom: 8,
    color: '#333',
  },
  fieldLabel: {
    fontWeight: '600',
    color: '#1976d2',
  },
  permissionContainer: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  permissionCard: {
    elevation: 4,
    padding: 20,
  },
  permissionTitle: {
    textAlign: 'center',
    marginBottom: 16,
    color: '#1976d2',
  },
  permissionText: {
    textAlign: 'center',
    fontSize: 16,
    lineHeight: 24,
    color: '#666',
    marginBottom: 20,
  },
  permissionButton: {
    paddingVertical: 4,
  },
});