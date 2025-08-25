import React, { useState, useEffect } from 'react';
import { View, StyleSheet, Alert, Text, PermissionsAndroid, Platform } from 'react-native';
import { Button, Card, Title } from 'react-native-paper';
import QRCodeScanner from 'react-native-qrcode-scanner';
import type { ContactInfo } from '../types';

export const ScannerScreen: React.FC = () => {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scannedData, setScannedData] = useState<ContactInfo | null>(null);

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

  const onSuccess = (e: any) => {
    handleQRCodeScanned(e.data);
  };

  if (scannedData) {
    return (
      <View style={styles.container}>
        <Card style={styles.card}>
          <Card.Content>
            <Title>Scanned Successfully!</Title>
            <Text style={styles.message}>
              Name: {scannedData.name}{'\n'}
              Email: {scannedData.email}
              {scannedData.phone && `\nPhone: ${scannedData.phone}`}
            </Text>
            <Button mode="contained" onPress={() => addToSheet(scannedData)} style={styles.button}>
              Add to Sheet
            </Button>
            <Button mode="outlined" onPress={() => setScannedData(null)} style={styles.button}>
              Scan Another
            </Button>
          </Card.Content>
        </Card>
      </View>
    );
  }

  return (
    <QRCodeScanner
      onRead={onSuccess}
      flashMode={false}
      topContent={
        <Text style={styles.centerText}>
          <Text style={styles.textBold}>Scan2Sheets</Text>{'\n'}
          Position QR code in the center of the screen
        </Text>
      }
      bottomContent={
        <View>
          <Text style={styles.formatText}>
            Supported formats:{'\n'}
            • JSON: {`{"name":"John Doe","email":"john@example.com"}`}{'\n'}
            • Simple: John Doe,john@example.com,+1234567890{'\n'}
            • vCard format
          </Text>
        </View>
      }
    />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  centerText: {
    flex: 1,
    fontSize: 18,
    padding: 32,
    color: '#777',
    textAlign: 'center',
  },
  textBold: {
    fontWeight: '500',
    color: '#000',
    fontSize: 20,
  },
  formatText: {
    fontSize: 12,
    textAlign: 'center',
    padding: 20,
    color: '#666',
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
  },
  card: {
    margin: 16,
    padding: 16,
  },
  message: {
    marginBottom: 16,
    textAlign: 'left',
    fontSize: 16,
  },
  button: {
    marginTop: 8,
  },
});