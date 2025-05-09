import 'package:zaplab_design/zaplab_design.dart';

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.description,
    this.children = const <Widget>[],
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        AppContainer(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: theme.radius.asBorderRadius().rad16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.h2(title),
              const AppGap(AppGapSize.s4),
              AppText.reg14(
                description,
                color: theme.colors.white66,
              ),
            ],
          ),
        ),
        const AppGap(AppGapSize.s16),
        ...children,
        const AppGap(AppGapSize.s24),
      ],
    );
  }
}
