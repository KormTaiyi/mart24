import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';

class AuthBackground extends StatelessWidget {
  final String titlePrefix;
  final String titleHighlight;
  final String description;
  final Widget child;
  final bool isFormScrollable;

  const AuthBackground({
    super.key,
    required this.titlePrefix,
    required this.titleHighlight,
    required this.description,
    required this.child,
    this.isFormScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF257CA2), Color(0xFF103E54)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardOpen = bottomInset > 0;
                    final panelBottomPadding = 0.0;
                    final phoneWidth = constraints.maxWidth * 0.54;
                    final phoneHeight = phoneWidth * (780 / 372);
                    final phoneTop = 36.0;
                    final defaultPanelTop = phoneTop + (phoneHeight * 0.67);
                    final keyboardPanelTop = (constraints.maxHeight * 0.18)
                        .clamp(88.0, 150.0);
                    final nonScrollablePanelTop = keyboardOpen
                        ? 16.0
                        : (constraints.maxHeight * 0.14).clamp(72.0, 124.0);
                    final panelTop = isFormScrollable
                        ? (keyboardOpen ? keyboardPanelTop : defaultPanelTop)
                        : nonScrollablePanelTop;
                    final panelBottom = isFormScrollable && keyboardOpen
                        ? (bottomInset - 6).clamp(0.0, double.infinity)
                        : 0.0;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 0,
                          left: 12,
                          child: _BackButton(
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                        Positioned(
                          top: 106,
                          left: 20,
                          right: constraints.maxWidth * 0.50,
                          child: IgnorePointer(
                            ignoring: keyboardOpen,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: keyboardOpen ? 0 : 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              fontSize: 31,
                                              height: 1.02,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                        children: [
                                          TextSpan(text: '$titlePrefix\n'),
                                          TextSpan(
                                            text: titleHighlight,
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFFDCEBF2),
                                          fontSize: 15,
                                          height: 1.28,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        children: _buildDescriptionSpans(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          top: keyboardOpen ? 18 : phoneTop,
                          right: keyboardOpen
                              ? -phoneWidth * 0.08
                              : -phoneWidth * 0.14,
                          child: IgnorePointer(
                            ignoring: true,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: keyboardOpen ? 0.32 : 1,
                              child: SizedBox(
                                width: phoneWidth,
                                height: phoneHeight,
                                child: _AuthPhonePreview(width: phoneWidth),
                              ),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          left: 0,
                          right: 0,
                          top: panelTop,
                          bottom: panelBottom,
                          child: LayoutBuilder(
                            builder: (context, panelConstraints) {
                              final panelContent = ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: panelConstraints.maxHeight,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: _GlassPanel(
                                    isFormScrollable: isFormScrollable,
                                    child: child,
                                  ),
                                ),
                              );

                              if (!isFormScrollable) {
                                return panelContent;
                              }

                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.only(
                                  bottom: panelBottomPadding,
                                ),
                                child: panelContent,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildDescriptionSpans() {
    if (titleHighlight.isEmpty || !description.contains(titleHighlight)) {
      return [TextSpan(text: description)];
    }

    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final matchIndex = description.indexOf(titleHighlight, start);
      if (matchIndex == -1) {
        if (start < description.length) {
          spans.add(TextSpan(text: description.substring(start)));
        }
        break;
      }

      if (matchIndex > start) {
        spans.add(TextSpan(text: description.substring(start, matchIndex)));
      }

      spans.add(
        TextSpan(
          text: titleHighlight,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

      start = matchIndex + titleHighlight.length;
    }

    return spans;
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final bool isFormScrollable;

  const _GlassPanel({required this.child, required this.isFormScrollable});

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final double effectiveSafeBottom = isFormScrollable
        ? safeBottom
        : safeBottom.clamp(0.0, 12.0);
    final double bottomBasePadding = keyboardOpen
        ? 8.0
        : (isFormScrollable ? 20.0 : 14.0);
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(36),
      topRight: Radius.circular(36),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            10,
            20,
            10,
            bottomBasePadding + effectiveSafeBottom,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF6AA3BE).withValues(alpha: 0.26),
                const Color(0xFF1C6B88).withValues(alpha: 0.22),
                const Color(0xFF14516B).withValues(alpha: 0.20),
              ],
            ),
            borderRadius: borderRadius,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AuthPhonePreview extends StatelessWidget {
  final double width;

  const _AuthPhonePreview({required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(width * 0.12),
      child: AspectRatio(
        aspectRatio: 372 / 780,
        child: Image.asset(
          'assets/images/front_screen.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
