import 'package:flutter/material.dart';

class PostingListTileButton extends StatelessWidget {
  const PostingListTileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 11.8,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.white),
          Text(
            'Create listing',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
