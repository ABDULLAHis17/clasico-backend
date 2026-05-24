import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SmartLogo extends StatelessWidget {
  final String logo;
  final double size;
  final bool isBackground;
  final Color? color;

  const SmartLogo({
    super.key,
    required this.logo,
    required this.size,
    this.isBackground = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cleanLogo = logo.trim();

    if (cleanLogo.startsWith('/static') || cleanLogo.startsWith('http')) {
      // spacer.gif is a placeholder — show fallback icon instead of blank image
      if (cleanLogo.contains('spacer.gif')) {
        return Container(
          width: size,
          height: size,
          decoration: isBackground ? BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ) : null,
          child: Icon(
            Icons.sports_soccer_rounded,
            size: size * 0.7,
            color: color ?? (isDark ? Colors.white30 : Colors.grey[300]),
          ),
        );
      }

      String imageUrl = cleanLogo.startsWith('/static')
          ? '${ApiService.baseUrl}$cleanLogo'
          : cleanLogo;

      // --- Intercept failing Wikipedia / broken URLs ---
      final lowerImg = imageUrl.toLowerCase();
      if (lowerImg.contains('bundesliga')) {
        imageUrl = 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png';
      } else if (lowerImg.contains('laliga') || lowerImg.contains('la_liga') || lowerImg.contains('primera_division')) {
        imageUrl = 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png';
      } else if (lowerImg.contains('serie_a')) {
        imageUrl = 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png';
      } else if (lowerImg.contains('ligue1') || lowerImg.contains('ligue_1')) {
        imageUrl = 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png';
      } else if (lowerImg.contains('champions_league')) {
        imageUrl = 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
      } else if (lowerImg.contains('world_cup')) {
        imageUrl = 'https://a.espncdn.com/i/leaguelogos/soccer/500/4.png';
      } else if (lowerImg.contains('bayer_04') || lowerImg.contains('bayer_leverkusen')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/131.png';
      } else if (lowerImg.contains('paris_saint-germain') || lowerImg.contains('psg')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/160.png';
      } else if (lowerImg.contains('olympique_lyon') || lowerImg.contains('lyon')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/164.png';
      } else if (lowerImg.contains('fenerbah') || lowerImg.contains('fenerbahçe')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/438.png';
      } else if (lowerImg.contains('trabzonspor')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/439.png';
      } else if (lowerImg.contains('chelsea')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/363.png';
      } else if (lowerImg.contains('aston_villa') || lowerImg.contains('aston villa') || lowerImg.contains('a villa')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/362.png';
      } else if (lowerImg.contains('juventus')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/111.png';
      } else if (lowerImg.contains('argentina')) {
        imageUrl = 'https://api.sofascore.app/api/v1/team/4821/image';
      } else if (lowerImg.contains('galatasaray')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/437.png';
      } else if (lowerImg.contains('manchester_united') || lowerImg.contains('manchester united')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/360.png';
      } else if (lowerImg.contains('liverpool')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/364.png';
      } else if (lowerImg.contains('arsenal')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/359.png';
      } else if (lowerImg.contains('manchester_city') || lowerImg.contains('manchester city')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/382.png';
      } else if (lowerImg.contains('newcastle')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/361.png';
      } else if (lowerImg.contains('tottenham')) {
        imageUrl = 'https://a.espncdn.com/i/teamlogos/soccer/500/367.png';
      }

      // --- CORS Mitigation & Image Proxying ---
      // Bypass CORS by routing external images through Images.weserv.nl
      if (imageUrl.startsWith('http') &&
          !imageUrl.contains(ApiService.baseUrl) &&
          !imageUrl.contains('wsrv.nl')) {
        
        final decodedUrl = Uri.decodeFull(imageUrl);
        final cleanedUrl = decodedUrl.replaceFirst(RegExp(r'^https?://'), '');
        imageUrl = 'https://wsrv.nl/?url=$cleanedUrl&default=1&output=png';
      }

      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: isBackground ? BoxFit.cover : BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback sequence: Logo -> Placeholder Icon -> Transparent
          return Container(
            width: size,
            height: size,
            decoration: isBackground ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ) : null,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: size * 0.7,
              color: color ?? (isDark ? Colors.white30 : Colors.grey[300]),
            ),
          );
        },
      );
    }

    // Fallback to text if it's an emoji
    return Text(
      cleanLogo,
      style: TextStyle(fontSize: size, color: color),
    );
  }
}

