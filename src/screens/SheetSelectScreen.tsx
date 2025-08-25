import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Card, Title, Text, Button } from 'react-native-paper';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { RootStackParamList } from '../types';

type SheetSelectScreenProps = {
  navigation: StackNavigationProp<RootStackParamList, 'SheetSelect'>;
};

export const SheetSelectScreen: React.FC<SheetSelectScreenProps> = ({ navigation }) => {
  const handleContinueToScanner = () => {
    navigation.navigate('Scanner');
  };

  return (
    <View style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.title}>Select Google Sheet</Title>
          <Text style={styles.subtitle}>
            Google Sheets integration will be implemented in Phase 3.
            For now, you can proceed directly to the QR code scanner.
          </Text>
          
          <View style={styles.buttonContainer}>
            <Button
              mode="contained"
              onPress={handleContinueToScanner}
              style={styles.button}
            >
              Continue to Scanner
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
    fontSize: 24,
    fontWeight: 'bold',
  },
  subtitle: {
    textAlign: 'center',
    marginBottom: 32,
    fontSize: 16,
    color: '#666',
  },
  buttonContainer: {
    alignItems: 'center',
  },
  button: {
    paddingVertical: 8,
    paddingHorizontal: 32,
  },
});