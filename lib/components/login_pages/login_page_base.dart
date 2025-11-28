import 'package:flutter/material.dart';

import '../../entity/button_state.dart';

abstract class LoginPageBase extends StatefulWidget {
  const LoginPageBase({
    super.key,
    required this.sc,
    required this.onStateChange,
    required this.onComplete,
    required this.onlyThis,
  });

  final ButtonStateContainer sc;
  final Function(ButtonStateContainer sc) onStateChange;
  final Function({bool toEnd}) onComplete;
  final bool onlyThis;
}
