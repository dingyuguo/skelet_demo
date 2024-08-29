import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

final logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('放大镜效果'),
        ),
        body: MagnifyingGlassAnimation(),
      ),
    );
  }
}

class MagnifyingGlassAnimation extends StatefulWidget {
  @override
  _MagnifyingGlassAnimationState createState() =>
      _MagnifyingGlassAnimationState();
}

class _MagnifyingGlassAnimationState extends State<MagnifyingGlassAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  String text = 'Flutter11';  // 初始文字
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    
    _animations = List.generate(text.length, (index) {
      double start = index / (text.length + 4);
      double end = (index + 4) / (text.length + 4);
      return TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 2)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.repeat();
      }
    });

    _controller.repeat();
  }

  void _fetchWord() async {
    // 请求后端服务器获取新的单词
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/get_word/'),headers: {"User-Agent": "Mozilla/5.0"},); 
    logger.i(response.body);  // 添加这一行以检查响应内容
    if (response.statusCode == 200) {
      setState(() {
        text = json.decode(response.body)['word'];
        _controller.reset();
        _animations = List.generate(text.length, (index) {
          double start = index / (text.length + 4);
          double end = (index + 4) / (text.length + 4);
          return TweenSequence([
            TweenSequenceItem(
              tween: Tween<double>(begin: 1.0, end: 2)
                  .chain(CurveTween(curve: Curves.easeInOut)),
              weight: 50,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 2, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut)),
              weight: 50,
            ),
          ]).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeInOut),
            ),
          );
        });
        _controller.repeat();
      });
    } else {
      throw Exception('Failed to load word');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(text.length, (index) {
                double scale = _animations[index].value;
                return Transform(
                  transform: Matrix4.identity()..scale(scale, scale),
                  alignment: Alignment.center,
                  child: Text(
                    text[index],
                    style: TextStyle(
                      fontSize: 40,
                      letterSpacing: (scale - 1) * 10,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _fetchWord,
          child: const Text('请求新单词'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isAnimating) {
              _controller.stop();
            } else {
              _controller.repeat();
            }
            setState(() {
              isAnimating = !isAnimating;
            });
          },
          child: Text(isAnimating ? '暂停' : '播放'),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.reset();
            setState(() {
              isAnimating = false;
            });
          },
          child: const Text('重置'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
