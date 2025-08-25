import React, { useState, useEffect } from 'react';
import { View, StyleSheet, Alert, Text } from 'react-native';
import { Button, Card, Title } from 'react-native-paper';
import { Camera, useCameraDevices } from 'react-native-vision-camera';
import type { ContactInfo } from '../types';

export const ScannerScreen: React.FC = () => {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scannedData, setScannedData] = useState<ContactInfo | null>(null);
  const devices = useCameraDevices();
  const device = devices.back;

  useEffect(() => {
    checkCameraPermission();
  }, []);

  const checkCameraPermission = async () => {
    try {
      const permission = await Camera.getCameraPermissionStatus();
      if (permission === 'granted') {
        setHasPermission(true);
      } else {
        const newPermission = await Camera.requestCameraPermission();
        setHasPermission(newPermission === 'granted');
      }
    } catch (error) {
      console.error('Permission error:', error);
      setHasPermission(false);
    }
  };

  const handleQRCodeScanned = (data: string) => {
    try {
      const parsed = parseQRCode(data);
      setScannedData(parsed);
      
      Alert.alert(
        'QR Code Scanned!',
        `Name: ${parsed.name}\nEmail: ${parsed.email}\nPhone: ${parsed.phone || 'Not provided'}`,
        [
          { text: 'Add to Sheet', onPress: () => addToSheet(parsed) },
          { text: 'Scan Another', onPress: () => setScannedData(null) }
        ]
      );
    } catch (error) {
      Alert.alert(
        'Invalid QR Code',
        'Could not parse contact information from this QR code. Expected format with name and email.',
        [{ text: 'OK' }]
      );
    }
  };

  const parseQRCode = (data: string): ContactInfo => {
    if (data.startsWith('BEGIN:VCARD')) {
      return parseVCard(data);
    }
    
    if (data.includes('email') || data.includes('@')) {
      return parseJSON(data);
    }
    
    return parseSimpleFormat(data);
  };

  const parseVCard = (vcard: string): ContactInfo => {
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
      throw new Error('Missing required fields');
    }
    
    return { name, email, phone };
  };

  const parseJSON = (data: string): ContactInfo => {
    const parsed = JSON.parse(data);
    if (!parsed.name || !parsed.email) {
      throw new Error('Missing required fields');
    }
    return {
      name: parsed.name,
      email: parsed.email,
      phone: parsed.phone || ''
    };
  };

  const parseSimpleFormat = (data: string): ContactInfo => {
    const parts = data.split(',').map(part => part.trim());
    if (parts.length < 2) {
      throw new Error('Invalid format');
    }
    
    return {
      name: parts[0],
      email: parts[1],
      phone: parts[2] || ''
    };
  };

  const addToSheet = async (contact: ContactInfo) => {
    Alert.alert(
      'Success!',
      `Contact ${contact.name} will be added to your Google Sheet.\n\n(Sheet integration coming in Phase 3)`,
      [{ text: 'OK', onPress: () => setScannedData(null) }]
    );
  };

  if (hasPermission === null) {
    return (
      <View style={styles.container}>
        <Text>Checking camera permission...</Text>
      </View>
    );
  }

  if (hasPermission === false) {
    return (
      <View style={styles.container}>
        <Card style={styles.card}>
          <Card.Content>
            <Title>Camera Permission Required</Title>
            <Text style={styles.message}>
              Please grant camera permission to scan QR codes.
            </Text>
            <Button mode="contained" onPress={checkCameraPermission} style={styles.button}>
              Grant Permission
            </Button>
          </Card.Content>
        </Card>
      </View>
    );
  }

  if (!device) {
    return (
      <View style={styles.container}>
        <Text>No camera device found</Text>
      </View>
    );
  }

  const handleCodeScanned = (codes: any[]) => {
    if (codes.length > 0) {
      handleQRCodeScanned(codes[0].value || '');
    }
  };

  return (
    <View style={styles.container}>
      <Camera
        style={styles.camera}
        device={device}
        isActive={!scannedData}
        codeScanner={{
          codeTypes: ['qr', 'ean-13'],
          onCodeScanned: handleCodeScanned,
        }}
      />
      
      <View style={styles.overlay}>
        <View style={styles.scanFrame} />
        <Text style={styles.instructionText}>
          Position QR code within the frame to scan
        </Text>
        
        <Text style={styles.formatText}>
          Supported formats:{'\n'}
          • JSON: {`{"name":"John Doe","email":"john@example.com"}`}{'\n'}
          • Simple: John Doe,john@example.com,+1234567890{'\n'}
          • vCard format
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black',
  },
  camera: {
    flex: 1,
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scanFrame: {
    width: 250,
    height: 250,
    borderWidth: 2,
    borderColor: 'white',
    borderRadius: 10,
    backgroundColor: 'transparent',
  },
  instructionText: {
    color: 'white',
    fontSize: 16,
    textAlign: 'center',
    marginTop: 20,
    paddingHorizontal: 20,
  },
  formatText: {
    color: 'white',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 40,
    paddingHorizontal: 20,
    opacity: 0.8,
  },
  card: {
    margin: 16,
    padding: 16,
  },
  message: {
    marginBottom: 16,
    textAlign: 'center',
  },
  button: {
    marginTop: 8,
  },
});