import 'dart:math';

List<double> preprocessData(
  List<String> dates,
  List<String> times,
  List<int> priorities,
) {
  // Validate input lengths
  if (dates.length != times.length || dates.length != priorities.length) {
    throw ArgumentError('Input lists must have the same length');
  }

  // Filter out NaN values
  List<int> validIndices = [];
  for (int i = 0; i < dates.length; i++) {
    if (dates[i] != 'NaN' && times[i] != 'NaN' && !priorities[i].isNaN) {
      validIndices.add(i);
    }
  }

  // If no valid data, return empty list
  if (validIndices.isEmpty) {
    return [];
  }

  // Process only valid data
  List<int> timestamps = List.generate(validIndices.length, (i) {
    int index = validIndices[i];
    try {
      DateTime dt = DateTime.parse("${dates[index]} ${times[index]}");
      return dt.millisecondsSinceEpoch;
    } on FormatException {
      return 0; // Default value for invalid dates
    }
  });

  int minTimestamp = timestamps.reduce(min);
  int maxTimestamp = timestamps.reduce(max);
  List<double> normalizedTimestamps =
      timestamps
          .map(
            (t) =>
                maxTimestamp != minTimestamp
                    ? (t - minTimestamp) / (maxTimestamp - minTimestamp)
                    : 0.5,
          ) // Handle case where all timestamps are equal
          .toList();

  List<int> validPriorities = validIndices.map((i) => priorities[i]).toList();
  int minPriority = validPriorities.reduce(min);
  int maxPriority = validPriorities.reduce(max);
  List<double> normalizedPriorities =
      validPriorities
          .map(
            (p) =>
                maxPriority != minPriority
                    ? (p - minPriority) / (maxPriority - minPriority)
                    : 0.5,
          ) // Handle case where all priorities are equal
          .toList();

  List<double> result = [];
  for (int i = 0; i < validIndices.length; i++) {
    result.add(normalizedTimestamps[i]);
    result.add(normalizedPriorities[i]);
  }
  return result;
}
