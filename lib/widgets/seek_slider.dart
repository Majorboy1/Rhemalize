import 'package:flutter/material.dart';

/// A progress slider that only seeks when the user releases the thumb.
///
/// While the user drags, the thumb follows their finger using a local value
/// instead of calling `seek()` on every tick. Seeking on every drag update
/// makes streamed audio repeatedly interrupt and re-buffer, so skipping feels
/// slow and stuttery. `[onSeek]` is invoked exactly once, on release.
class SeekSlider extends StatefulWidget {
  const SeekSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  /// The current playback position.
  final Duration position;

  /// The total duration of the current track.
  final Duration duration;

  /// Called once with the target position when the user finishes dragging.
  final ValueChanged<Duration> onSeek;

  @override
  State<SeekSlider> createState() => _SeekSliderState();
}

class _SeekSliderState extends State<SeekSlider> {
  /// Local position (in seconds) while the user is dragging, else null.
  double? _dragValue;

  double get _maxSeconds {
    final d = widget.duration.inSeconds.toDouble();
    return d > 0 ? d : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final value = (_dragValue ??
            widget.position.inSeconds.toDouble())
        .clamp(0.0, _maxSeconds);

    return Slider(
      value: value,
      max: _maxSeconds,
      onChanged: (v) => setState(() => _dragValue = v),
      onChangeEnd: (v) {
        setState(() => _dragValue = null);
        widget.onSeek(Duration(seconds: v.round()));
      },
    );
  }
}
