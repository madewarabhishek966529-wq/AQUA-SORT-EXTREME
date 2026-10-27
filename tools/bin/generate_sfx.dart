// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Procedural Audio Synthesizer in pure Dart.
/// Generates 16-bit mono 44.1kHz WAV files for game sound effects.
void main() {
  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('Generating procedural sound effects in assets/audio/...');

  _writeWav(
    File('assets/audio/select.wav'),
    _generateSelectSound(),
  );

  _writeWav(
    File('assets/audio/pour.wav'),
    _generatePourSound(),
  );

  _writeWav(
    File('assets/audio/invalid.wav'),
    _generateInvalidSound(),
  );

  _writeWav(
    File('assets/audio/undo.wav'),
    _generateUndoSound(),
  );

  _writeWav(
    File('assets/audio/victory.wav'),
    _generateVictorySound(),
  );

  _writeWav(
    File('assets/audio/hint.wav'),
    _generateHintSound(),
  );

  print('Successfully generated 6 procedural sound effects!');
}

const int sampleRate = 44100;

/// Short pleasant high-pitch pop/chirp (880Hz to 1320Hz)
List<double> _generateSelectSound() {
  const duration = 0.09; // 90ms
  final sampleCount = (duration * sampleRate).toInt();
  final samples = <double>[];

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;
    final freq = 880.0 + (1320.0 - 880.0) * progress;
    final envelope = (1.0 - progress) * (1.0 - progress);
    final val = sin(2 * pi * freq * t) * envelope * 0.7;
    samples.add(val);
  }
  return samples;
}

/// Liquid bubbling / water pour sound with frequency modulation
List<double> _generatePourSound() {
  const duration = 0.35; // 350ms
  final sampleCount = (duration * sampleRate).toInt();
  final samples = <double>[];
  final rng = Random(42);

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;

    // Base liquid resonance + bubbling frequency wobble
    final wobble = sin(2 * pi * 14.0 * t) * 60.0;
    final bubbleFreq = 380.0 + wobble + sin(2 * pi * 45.0 * t) * 40.0;
    final carrier = sin(2 * pi * bubbleFreq * t);

    // Subtle water splatter noise
    final noise = (rng.nextDouble() * 2 - 1) * 0.15;

    // Smooth envelope with soft attack and decay
    final attack = (progress / 0.15).clamp(0.0, 1.0);
    final decay = (1.0 - progress);
    final envelope = attack * decay;

    final val = (carrier * 0.75 + noise) * envelope * 0.65;
    samples.add(val);
  }
  return samples;
}

/// Dull low invalid buzz/thud (140Hz to 80Hz)
List<double> _generateInvalidSound() {
  const duration = 0.18; // 180ms
  final sampleCount = (duration * sampleRate).toInt();
  final samples = <double>[];

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;

    // Double pulse buzz
    final pulse = sin(2 * pi * 18.0 * t) > 0 ? 1.0 : -0.5;
    final freq = 140.0 - 60.0 * progress;
    final wave = sin(2 * pi * freq * t);
    final envelope = (1.0 - progress);

    final val = wave * pulse * envelope * 0.6;
    samples.add(val);
  }
  return samples;
}

/// Reverse whoosh sound for undo (pitch sweeps down then snaps up)
List<double> _generateUndoSound() {
  const duration = 0.15; // 150ms
  final sampleCount = (duration * sampleRate).toInt();
  final samples = <double>[];

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;
    final freq = 650.0 - 300.0 * sin(progress * pi);
    final envelope = sin(progress * pi);
    final val = sin(2 * pi * freq * t) * envelope * 0.65;
    samples.add(val);
  }
  return samples;
}

/// Triumphant victory arpeggio: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
List<double> _generateVictorySound() {
  const duration = 1.0; // 1 second
  final sampleCount = (duration * sampleRate).toInt();
  final samples = <double>[];

  final notes = [
    (0.0, 0.22, 523.25), // C5
    (0.18, 0.40, 659.25), // E5
    (0.36, 0.60, 783.99), // G5
    (0.54, 1.00, 1046.50), // C6
  ];

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    var totalVal = 0.0;

    for (final note in notes) {
      final start = note.$1;
      final end = note.$2;
      final freq = note.$3;

      if (t >= start && t <= end) {
        final noteDur = end - start;
        final noteT = (t - start) / noteDur;
        final env = sin(noteT * pi * 0.5) * (1.0 - noteT * 0.7);
        // Rich harmonic with octave overtone
        final sample = (sin(2 * pi * freq * t) * 0.7 +
                sin(2 * pi * freq * 2.0 * t) * 0.3) *
            env;
        totalVal += sample * 0.45;
      }
    }
    samples.add(totalVal.clamp(-1.0, 1.0));
  }
  return samples;
}

/// Magical chime for hints (dual bell harmony)
List<double> _generateHintSound() {
  const duration = 0.4; // 400ms
  final sampleCount = (duration * sampleRate).toInt();
  final samples = <double>[];

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;
    final env = exp(-6.0 * progress); // sharp attack, exponential ring
    final tone1 = sin(2 * pi * 1046.5 * t);
    final tone2 = sin(2 * pi * 1567.98 * t);
    final val = (tone1 * 0.6 + tone2 * 0.4) * env * 0.7;
    samples.add(val);
  }
  return samples;
}

/// Writes floating-point audio samples (-1.0 to 1.0) into a standard 16-bit PCM RIFF WAV file.
void _writeWav(File file, List<double> samples) {
  final numSamples = samples.length;
  final byteRate = sampleRate * 2; // 1 channel * 16 bits = 2 bytes/sample
  final dataSize = numSamples * 2;
  final chunkSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);

  // RIFF header
  _writeString(buffer, 0, 'RIFF');
  buffer.setUint32(4, chunkSize, Endian.little);
  _writeString(buffer, 8, 'WAVE');

  // fmt subchunk
  _writeString(buffer, 12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  buffer.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, 2, Endian.little); // BlockAlign
  buffer.setUint16(34, 16, Endian.little); // BitsPerSample

  // data subchunk
  _writeString(buffer, 36, 'data');
  buffer.setUint32(40, dataSize, Endian.little);

  // Write 16-bit PCM samples
  var offset = 44;
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final intVal = (clamped * 32767).toInt();
    buffer.setInt16(offset, intVal, Endian.little);
    offset += 2;
  }

  file.writeAsBytesSync(buffer.buffer.asUint8List());
}

void _writeString(ByteData buffer, int offset, String str) {
  for (var i = 0; i < str.length; i++) {
    buffer.setUint8(offset + i, str.codeUnitAt(i));
  }
}
