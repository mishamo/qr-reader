import React, { useState, useCallback } from 'react';
import { View, StyleSheet, Alert, Text } from 'react-native';
import { Camera } from 'react-native-camera-kit';
import { Button, Card, Title } from 'react-native-paper';
import type { ContactInfo } from '../types';

export const QRScannerScreen: React.FC = () => {
  const [scannedData, setScannedData] = useState<ContactInfo | null>(null);
  const [isScanning, setIsScanning] = useState(true);

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
          { text: '✅ Add to Sheet', onPress: () => addToSheet(parsed) },
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
  }, [isScanning]);

  const parseQRCode = (data: string): ContactInfo => {
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
      throw new Error('Missing required fields in vCard');
    }
    
    return { name, email, phone };
  };

  const parseSimpleFormat = (data: string): ContactInfo => {
    const parts = data.split(',').map(part => part.trim());
    if (parts.length < 2) {
      throw new Error('Invalid simple format');
    }
    
    return {
      name: parts[0],
      email: parts[1],
      phone: parts[2] || ''
    };
  };

  const addToSheet = async (contact: ContactInfo) => {
    Alert.alert(
      '✅ Success!',
      `Contact "${contact.name}" will be added to your Google Sheet.\n\n📝 Note: Google Sheets integration will be implemented in Phase 3.`,
      [{ text: 'OK', onPress: () => resetScanner() }]
    );
  };

  const resetScanner = () => {
    setScannedData(null);
    setIsScanning(true);
  };

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
});