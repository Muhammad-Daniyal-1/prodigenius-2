import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Input
import numpy as np
from datetime import datetime

def preprocess_data(dates, times, priorities):
    # Convert to timestamps
    timestamps = np.array([datetime.strptime(f"{date} {time}", "%Y-%m-%d %H:%M").timestamp() for date, time in zip(dates, times)])
    
    # Normalize timestamps and priorities
    timestamps = (timestamps - timestamps.min()) / (timestamps.max() - timestamps.min())
    priorities = (np.array(priorities) - min(priorities)) / (max(priorities) - min(priorities))
    
    return np.column_stack((timestamps, priorities))

# Define the model architecture
model = Sequential([
    Input(shape=(2,)),  # Input layer for normalized timestamp and priority
    Dense(128, activation='relu'),  # Hidden layer
    Dense(64, activation='relu'),  # Hidden layer
    Dense(32, activation='relu'),  # Hidden layer
    Dense(1, activation='linear')  # Output layer for prioritization score
])

# Compile the model
model.compile(optimizer='adam', loss='mean_squared_error')

# # Example training data (date, time, and priority)
# dates = ["2025-03-20", "2025-03-25", "2025-03-30", "2025-04-01", "2025-04-05", "2025-04-10"]
# times = ["10:00", "14:00", "18:00", "09:00", "12:00", "15:00"]
# priorities = [1, 3, 5, 2, 4, 5]
# X_train = preprocess_data(dates, times, priorities)
# y_train = np.array([1, 2, 3, 1.5, 2.5, 3])  # Example target data

# # Train the model
# model.fit(X_train, y_train, epochs=100, verbose=1)

# # Evaluate the model
# loss = model.evaluate(X_train, y_train, verbose=0)
# print(f"Training Loss (MSE): {loss}")

# # Make predictions
# predictions = model.predict(X_train)

# # Display predictions vs actual values
# for i in range(len(X_train)):
#     print(f"Input: {X_train[i]}, Actual: {y_train[i]}, Predicted: {predictions[i][0]}")

model.export('task_prioritization_model')

# Convert the SavedModel to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_saved_model('task_prioritization_model')
tflite_model = converter.convert()

# Save the TensorFlow Lite model
with open('task_prioritization_model.tflite', 'wb') as f:
    f.write(tflite_model)
