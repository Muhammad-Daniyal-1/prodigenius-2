import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

class MLService {
  static Future<File> downloadModel() async {
    final model = await FirebaseModelDownloader.instance.getModel(
      "task_prioritization_model",
      FirebaseModelDownloadType.localModelUpdateInBackground,
    );
    return File(model.file.path);
  }

  static Future<double> runInference(List<double> input) async {
    File modelFile = await downloadModel();
    final interpreter = Interpreter.fromFile(modelFile);

    var output = List.filled(1, 0.0).reshape([1, 1]);
    interpreter.run([input], output);

    interpreter.close();
    return output[0][0];
  }
}
