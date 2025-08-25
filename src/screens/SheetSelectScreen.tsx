import React from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Card, Title, Text, Button, Divider } from 'react-native-paper';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { RootStackParamList } from '../types';

type SheetSelectScreenProps = {
  navigation: StackNavigationProp<RootStackParamList, 'SheetSelect'>;
};

export const SheetSelectScreen: React.FC<SheetSelectScreenProps> = ({ navigation }) => {
  const handleContinueToScanner = () => {
    Alert.alert(
      'Test Mode',
      'Proceeding to QR scanner for testing. In Phase 3, you\'ll select an actual Google Sheet here.',
      [{ text: 'Continue', onPress: () => navigation.navigate('Scanner') }]
    );
  };

  const handleCreateMockSheet = () => {
    Alert.alert(
      'Mock Sheet Created',
      'Created "Conference Attendees 2025" test sheet. Now proceeding to QR scanner.',
      [{ text: 'Start Scanning', onPress: () => navigation.navigate('Scanner') }]
    );
  };

  return (
    <View style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.title}>📊 Select Google Sheet</Title>
          <Text style={styles.subtitle}>
            Choose a sheet to store your scanned QR code data, or create a new one.
          </Text>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>📝 Test Mode</Text>
            <Text style={styles.sectionText}>
              Google Sheets integration coming in Phase 3. For now, test the QR scanner:
            </Text>
            
            <Button
              mode="contained"
              onPress={handleContinueToScanner}
              style={[styles.button, styles.primaryButton]}
              icon="qrcode-scan"
            >
              🚀 Test QR Scanner
            </Button>
          </View>

          <Divider style={styles.divider} />

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>📋 Quick Setup</Text>
            <Text style={styles.sectionText}>
              Create a mock sheet for testing:
            </Text>
            
            <Button
              mode="outlined"
              onPress={handleCreateMockSheet}
              style={styles.button}
              icon="file-plus"
            >
              Create "Conference Attendees 2025"
            </Button>
          </View>

          <View style={styles.infoBox}>
            <Text style={styles.infoText}>
              💡 The QR scanner supports multiple formats:
              {'\n'}• JSON: {`{"name":"John","email":"john@example.com"}`}
              {'\n'}• Simple: John Doe,john@example.com,+1234567890
              {'\n'}• vCard format
            </Text>
          </View>
        </Card.Content>
      </Card>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  card: {
    marginTop: 20,
    marginBottom: 20,
    elevation: 4,
  },
  title: {
    textAlign: 'center',
    marginBottom: 8,
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1976d2',
  },
  subtitle: {
    textAlign: 'center',
    marginBottom: 24,
    fontSize: 16,
    color: '#666',
    lineHeight: 22,
  },
  section: {
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  sectionText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
    lineHeight: 20,
  },
  button: {
    marginVertical: 8,
  },
  primaryButton: {
    paddingVertical: 4,
  },
  divider: {
    marginVertical: 16,
    backgroundColor: '#e0e0e0',
  },
  infoBox: {
    backgroundColor: '#e3f2fd',
    padding: 16,
    borderRadius: 8,
    marginTop: 16,
    borderLeftWidth: 4,
    borderLeftColor: '#1976d2',
  },
  infoText: {
    fontSize: 13,
    color: '#555',
    lineHeight: 18,
  },
});