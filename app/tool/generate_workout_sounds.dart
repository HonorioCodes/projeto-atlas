import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int _sampleRate = 44100;
const int _bitsPerSample = 16;
const int _numChannels = 1;

void main() {
  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  _generateStepChange('assets/audio/step_change.wav');
  _generateWorkoutComplete('assets/audio/workout_complete.wav');

  for (final fileName in ['step_change.wav', 'workout_complete.wav']) {
    final file = File('assets/audio/$fileName');
    stdout.writeln('Gerado: ${file.path} (${file.lengthSync()} bytes)');
  }
}

void _generateStepChange(String path) {
  const durationSeconds = 0.20;
  const frequency = 880.0;
  const amplitude = 0.35;

  final samples = _generateTone(
    durationSeconds: durationSeconds,
    frequency: frequency,
    amplitude: amplitude,
  );

  _writeWav(path, samples);
}

void _generateWorkoutComplete(String path) {
  final samples = <double>[];

  for (final tone in [
    (frequency: 523.25, duration: 0.18, amplitude: 0.30),
    (frequency: 659.25, duration: 0.18, amplitude: 0.32),
    (frequency: 783.99, duration: 0.24, amplitude: 0.34),
  ]) {
    samples.addAll(
      _generateTone(
        durationSeconds: tone.duration,
        frequency: tone.frequency,
        amplitude: tone.amplitude,
      ),
    );
  }

  _writeWav(path, samples);
}

List<double> _generateTone({
  required double durationSeconds,
  required double frequency,
  required double amplitude,
}) {
  final sampleCount = (durationSeconds * _sampleRate).round();
  final samples = List<double>.filled(sampleCount, 0);

  for (var index = 0; index < sampleCount; index++) {
    final time = index / _sampleRate;
    final progress = index / sampleCount;
    final envelope = sin(pi * progress);
    samples[index] = sin(2 * pi * frequency * time) * amplitude * envelope;
  }

  return samples;
}

void _writeWav(String path, List<double> samples) {
  final pcm = Int16List(samples.length);

  for (var index = 0; index < samples.length; index++) {
    pcm[index] = (samples[index].clamp(-1.0, 1.0) * 32767).round();
  }

  final dataBytes = ByteData(pcm.length * 2);
  for (var index = 0; index < pcm.length; index++) {
    dataBytes.setInt16(index * 2, pcm[index], Endian.little);
  }

  final dataSize = pcm.length * 2;
  final fileSize = 36 + dataSize;
  final header = BytesBuilder();

  header.add('RIFF'.codeUnits);
  header.add(_int32LE(fileSize));
  header.add('WAVE'.codeUnits);
  header.add('fmt '.codeUnits);
  header.add(_int32LE(16));
  header.add(_int16LE(1));
  header.add(_int16LE(_numChannels));
  header.add(_int32LE(_sampleRate));
  header.add(_int32LE(_sampleRate * _numChannels * _bitsPerSample ~/ 8));
  header.add(_int16LE(_numChannels * _bitsPerSample ~/ 8));
  header.add(_int16LE(_bitsPerSample));
  header.add('data'.codeUnits);
  header.add(_int32LE(dataSize));
  header.add(dataBytes.buffer.asUint8List());

  File(path).writeAsBytesSync(header.takeBytes());
}

List<int> _int16LE(int value) {
  return [value & 0xFF, (value >> 8) & 0xFF];
}

List<int> _int32LE(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}
