import React from 'react';
import { View, StyleSheet, Text } from 'react-native';
import { Button, Card, Title, Paragraph, Divider } from 'react-native-paper';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { RootStackParamList } from '../types';

type SheetSelectScreenProps = {
  navigation: StackNavigationProp<RootStackParamList, 'SheetSelect'>;
};

export const SheetSelectScreen: React.FC<SheetSelectScreenProps> = ({ navigation }) => {
  const handleContinueToScanner = () => {
    console.log('Button pressed - navigating to Scanner');
    navigation.navigate('Scanner');
  };

  return (
    <View style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.title}>🚀 QR Code Scanner Ready</Title>
          <Paragraph style={styles.subtitle}>
            Your QR code scanner is ready to use! Click below to start scanning QR codes containing contact information.
          </Paragraph>
          
          <Divider style={styles.divider} />
          
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Supported QR Formats:</Text>
            <Text style={styles.sectionText}>
              • Simple format: John Doe,john@example.com{'\n'}
              • JSON format: {`{"name":"John Doe","email":"john@example.com"}`}{'\n'}
              • vCard format (contact cards)
            </Text>
          </View>
          
          <Button
            mode="contained"
            onPress={handleContinueToScanner}
            style={styles.primaryButton}
            contentStyle={styles.buttonContent}
          >
            Start QR Scanner
          </Button>
          
          <Text style={styles.infoText}>
            📄 Google Sheets integration will be added in Phase 3
          </Text>
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
    elevation: 4,
  },
  title: {
    textAlign: 'center',
    marginBottom: 12,
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1976d2',
  },
  subtitle: {
    textAlign: 'center',
    marginBottom: 20,
    fontSize: 16,
    color: '#666',
    lineHeight: 24,
  },
  divider: {
    marginVertical: 16,
    backgroundColor: '#e0e0e0',
  },
  section: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  sectionText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
    lineHeight: 20,
  },
  primaryButton: {
    marginVertical: 16,
    paddingVertical: 4,
  },
  buttonContent: {
    paddingVertical: 8,
  },
  infoText: {
    textAlign: 'center',
    fontSize: 12,
    color: '#888',
    marginTop: 12,
    fontStyle: 'italic',
  },
});