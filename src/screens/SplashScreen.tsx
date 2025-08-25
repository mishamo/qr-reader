import React from 'react';
import { View, StyleSheet } from 'react-native';
import { ActivityIndicator, Card, Title, Text } from 'react-native-paper';

export const SplashScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.title}>Scan2Sheets</Title>
          <ActivityIndicator 
            size="large" 
            style={styles.loader}
          />
          <Text style={styles.loadingText}>
            Checking authentication...
          </Text>
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
    alignItems: 'center',
  },
  title: {
    textAlign: 'center',
    marginBottom: 32,
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1976d2',
  },
  loader: {
    marginBottom: 16,
  },
  loadingText: {
    textAlign: 'center',
    fontSize: 16,
    color: '#666',
  },
});