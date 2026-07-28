import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/route_args.dart';
import '../widgets/game_scaffold.dart';

class NewsItemScreen extends StatelessWidget {
  const NewsItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as NewsItemArgs?;

    if (args == null) {
      return const GameScaffold(
        screenNum: '10.2',
        screenName: 'NEWS ARTICLE',
        body: Center(
          child: Text('Invalid arguments'),
        ),
      );
    }

    final article = args.article;

    return GameScaffold(
      screenNum: '10.2',
      screenName: 'NEWS ARTICLE',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    article.category,
                    style: AppTextStyles.caption(color: AppColors.warning),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  article.time,
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              article.title,
              style: AppTextStyles.displayTitle(color: AppColors.text).copyWith(
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const Divider(height: 24),
            Text(
              article.body,
              style: AppTextStyles.body(color: AppColors.textHigh).copyWith(
                height: 1.7,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
