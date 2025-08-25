import React, { useState, useEffect, useCallback } from 'react';
import { View, StyleSheet, Text, FlatList, Alert } from 'react-native';
import { Button, Card, Title, Paragraph, ActivityIndicator, TextInput, Modal, Portal } from 'react-native-paper';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { StackNavigationProp } from '@react-navigation/stack';
import type { RootStackParamList, GoogleSheetInfo } from '../types';
import { GoogleSheetsService } from '../services/googleSheets';

type SheetSelectScreenProps = {
  navigation: StackNavigationProp<RootStackParamList, 'SheetSelect'>;
};

export const SheetSelectScreen: React.FC<SheetSelectScreenProps> = ({ navigation }) => {
  const [sheets, setSheets] = useState<GoogleSheetInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSheet, setSelectedSheet] = useState<GoogleSheetInfo | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newSheetTitle, setNewSheetTitle] = useState('');
  const [creating, setCreating] = useState(false);

  // Load sheets on component mount
  useEffect(() => {
    loadSheets();
  }, [loadSheets]);

  // Load stored sheet selection
  useEffect(() => {
    loadStoredSelection();
  }, [loadStoredSelection]);

  const loadStoredSelection = useCallback(async () => {
    try {
      const storedSheetId = await AsyncStorage.getItem('selectedSheetId');
      if (storedSheetId && sheets.length > 0) {
        const sheet = sheets.find(s => s.id === storedSheetId);
        if (sheet) {
          setSelectedSheet(sheet);
        }
      }
    } catch (error) {
      console.log('No stored sheet selection');
    }
  }, [sheets]);

  const loadSheets = useCallback(async () => {
    try {
      setLoading(true);
      const userSheets = await GoogleSheetsService.listSheets();
      setSheets(userSheets);
    } catch (error) {
      console.error('Failed to load sheets:', error);
      Alert.alert(
        'Error Loading Sheets',
        'Failed to load your Google Sheets. Please check your connection and try again.',
        [{ text: 'Retry', onPress: () => loadSheets() }, { text: 'Cancel' }]
      );
    } finally {
      setLoading(false);
    }
  }, []);

  const handleSelectSheet = async (sheet: GoogleSheetInfo) => {
    setSelectedSheet(sheet);
    // Store selection for next time
    try {
      await AsyncStorage.setItem('selectedSheetId', sheet.id);
    } catch (error) {
      console.log('Failed to store sheet selection');
    }
  };

  const handleCreateSheet = async () => {
    if (!newSheetTitle.trim()) {
      Alert.alert('Error', 'Please enter a sheet title');
      return;
    }

    try {
      setCreating(true);
      const newSheet = await GoogleSheetsService.createSheet(newSheetTitle.trim());
      setSheets([newSheet, ...sheets]);
      setSelectedSheet(newSheet);
      setShowCreateModal(false);
      setNewSheetTitle('');
      
      Alert.alert(
        'Sheet Created!',
        `"${newSheet.title}" has been created and is ready for contact scanning.`,
        [{ text: 'OK' }]
      );
    } catch (error) {
      console.error('Failed to create sheet:', error);
      Alert.alert(
        'Creation Failed',
        error instanceof Error ? error.message : 'Failed to create Google Sheet. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setCreating(false);
    }
  };

  const handleStartScanning = () => {
    if (!selectedSheet) {
      Alert.alert('Select a Sheet', 'Please select or create a Google Sheet first');
      return;
    }

    // Pass selected sheet info to scanner
    navigation.navigate('Scanner', { selectedSheet });
  };

  const renderSheetItem = ({ item }: { item: GoogleSheetInfo }) => (
    <Card 
      style={[
        styles.sheetCard, 
        selectedSheet?.id === item.id && styles.selectedSheetCard
      ]}
      onPress={() => handleSelectSheet(item)}
    >
      <Card.Content>
        <Title style={styles.sheetTitle}>{item.title}</Title>
        <Text style={styles.sheetDate}>
          Last modified: {new Date(item.lastModified).toLocaleDateString()}
        </Text>
        {selectedSheet?.id === item.id && (
          <Text style={styles.selectedText}>✅ Selected</Text>
        )}
      </Card.Content>
    </Card>
  );

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" />
        <Text style={styles.loadingText}>Loading your Google Sheets...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Card style={styles.headerCard}>
        <Card.Content>
          <Title style={styles.title}>📊 Select Google Sheet</Title>
          <Paragraph style={styles.subtitle}>
            Choose a Google Sheet to store your scanned contacts, or create a new one.
          </Paragraph>
        </Card.Content>
      </Card>

      {sheets.length > 0 ? (
        <FlatList
          data={sheets}
          renderItem={renderSheetItem}
          keyExtractor={(item) => item.id}
          style={styles.sheetsList}
          contentContainerStyle={styles.sheetsListContent}
        />
      ) : (
        <Card style={styles.emptyCard}>
          <Card.Content>
            <Text style={styles.emptyText}>
              No Google Sheets found. Create your first sheet to get started!
            </Text>
          </Card.Content>
        </Card>
      )}

      <View style={styles.buttonContainer}>
        <Button
          mode="outlined"
          onPress={() => setShowCreateModal(true)}
          style={styles.createButton}
        >
          📄 Create New Sheet
        </Button>

        <Button
          mode="contained"
          onPress={handleStartScanning}
          style={styles.primaryButton}
          disabled={!selectedSheet}
        >
          📱 Start QR Scanner
        </Button>

        <Button
          mode="text"
          onPress={async () => {
            try {
              const { AuthService } = await import('../services/auth');
              await AuthService.signOut();
              navigation.navigate('Auth');
            } catch (error) {
              console.error('Sign out failed:', error);
            }
          }}
          style={styles.signOutButton}
        >
          🚪 Sign Out
        </Button>
      </View>

      {selectedSheet && (
        <Text style={styles.selectedSheetText}>
          Selected: {selectedSheet.title}
        </Text>
      )}

      {/* Create Sheet Modal */}
      <Portal>
        <Modal 
          visible={showCreateModal} 
          onDismiss={() => setShowCreateModal(false)}
          contentContainerStyle={styles.modalContent}
        >
          <Title style={styles.modalTitle}>Create New Sheet</Title>
          <TextInput
            label="Sheet Title"
            value={newSheetTitle}
            onChangeText={setNewSheetTitle}
            style={styles.textInput}
            placeholder="e.g., Conference Contacts 2024"
          />
          <View style={styles.modalButtons}>
            <Button 
              mode="outlined" 
              onPress={() => setShowCreateModal(false)}
              style={styles.modalButton}
            >
              Cancel
            </Button>
            <Button 
              mode="contained" 
              onPress={handleCreateSheet}
              style={styles.modalButton}
              loading={creating}
              disabled={creating}
            >
              Create
            </Button>
          </View>
        </Modal>
      </Portal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  headerCard: {
    marginBottom: 16,
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
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
  sheetsList: {
    flex: 1,
  },
  sheetsListContent: {
    paddingBottom: 16,
  },
  sheetCard: {
    marginBottom: 12,
    elevation: 2,
  },
  selectedSheetCard: {
    borderColor: '#1976d2',
    borderWidth: 2,
  },
  sheetTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  sheetDate: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  selectedText: {
    fontSize: 14,
    color: '#1976d2',
    fontWeight: '600',
    marginTop: 8,
  },
  emptyCard: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  emptyText: {
    textAlign: 'center',
    fontSize: 16,
    color: '#666',
    lineHeight: 24,
  },
  buttonContainer: {
    marginTop: 16,
  },
  createButton: {
    marginBottom: 12,
  },
  primaryButton: {
    paddingVertical: 4,
  },
  selectedSheetText: {
    textAlign: 'center',
    fontSize: 12,
    color: '#1976d2',
    marginTop: 8,
    fontWeight: '600',
  },
  modalContent: {
    backgroundColor: 'white',
    padding: 20,
    margin: 20,
    borderRadius: 8,
  },
  modalTitle: {
    textAlign: 'center',
    marginBottom: 16,
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1976d2',
  },
  textInput: {
    marginBottom: 16,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  modalButton: {
    flex: 1,
    marginHorizontal: 8,
  },
  signOutButton: {
    marginTop: 12,
  },
});