import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MyDialButton extends SpeedDialChild {
  MyDialButton({
    required Icon icon,
    required VoidCallback onTap,
    required BuildContext context}) :
        super(
        child: icon,
        onTap: onTap,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: CircleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      );

}