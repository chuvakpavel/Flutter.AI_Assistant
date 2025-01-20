import 'package:flutter/material.dart';

class CustomExceptionWidget extends StatelessWidget {
  final Function() function;
  final String message;

  const CustomExceptionWidget({
    super.key,
    required this.function,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(fontSize: 20.0)),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: function,
            child: const Text('Repeat'),
          ),
        ],
      ),
    );
  }
}