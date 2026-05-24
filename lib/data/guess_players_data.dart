import '../models/guess_player.dart';

class GuessPlayersData {
  // المرحلة 1 - لاعبون مشهورون جداً (جميع المراكز)
  static List<GuessPlayer> getLevel1Players() {
    return [
      // مهاجمين
      GuessPlayer(name: 'Cristiano Ronaldo', nationality: 'Portugal', league: 'Saudi Pro League', club: 'Al-Nassr', position: 'Forward', age: 39, level: 1),
      GuessPlayer(name: 'Lionel Messi', nationality: 'Argentina', league: 'MLS', club: 'Inter Miami', position: 'Forward', age: 37, level: 1),
      GuessPlayer(name: 'Kylian Mbappé', nationality: 'France', league: 'La Liga', club: 'Real Madrid', position: 'Forward', age: 25, level: 1),
      GuessPlayer(name: 'Erling Haaland', nationality: 'Norway', league: 'Premier League', club: 'Manchester City', position: 'Forward', age: 24, level: 1),
      GuessPlayer(name: 'Mohamed Salah', nationality: 'Egypt', league: 'Premier League', club: 'Liverpool', position: 'Forward', age: 32, level: 1),
      GuessPlayer(name: 'Vinicius Junior', nationality: 'Brazil', league: 'La Liga', club: 'Real Madrid', position: 'Forward', age: 24, level: 1),
      GuessPlayer(name: 'Harry Kane', nationality: 'England', league: 'Bundesliga', club: 'Bayern Munich', position: 'Forward', age: 31, level: 1),
      GuessPlayer(name: 'Neymar Jr', nationality: 'Brazil', league: 'Saudi Pro League', club: 'Al-Hilal', position: 'Forward', age: 32, level: 1),
      GuessPlayer(name: 'Karim Benzema', nationality: 'France', league: 'Saudi Pro League', club: 'Al-Ittihad', position: 'Forward', age: 36, level: 1),
      GuessPlayer(name: 'Robert Lewandowski', nationality: 'Poland', league: 'La Liga', club: 'Barcelona', position: 'Forward', age: 36, level: 1),
      
      // لاعبي وسط
      GuessPlayer(name: 'Kevin De Bruyne', nationality: 'Belgium', league: 'Premier League', club: 'Manchester City', position: 'Midfielder', age: 33, level: 1),
      GuessPlayer(name: 'Luka Modric', nationality: 'Croatia', league: 'La Liga', club: 'Real Madrid', position: 'Midfielder', age: 39, level: 1),
      GuessPlayer(name: 'Jude Bellingham', nationality: 'England', league: 'La Liga', club: 'Real Madrid', position: 'Midfielder', age: 21, level: 1),
      
      // مدافعين
      GuessPlayer(name: 'Virgil van Dijk', nationality: 'Netherlands', league: 'Premier League', club: 'Liverpool', position: 'Defender', age: 33, level: 1),
      GuessPlayer(name: 'Sergio Ramos', nationality: 'Spain', league: 'La Liga', club: 'Sevilla', position: 'Defender', age: 38, level: 1),
      GuessPlayer(name: 'Antonio Rüdiger', nationality: 'Germany', league: 'La Liga', club: 'Real Madrid', position: 'Defender', age: 31, level: 1),
      
      // حراس مرمى
      GuessPlayer(name: 'Thibaut Courtois', nationality: 'Belgium', league: 'La Liga', club: 'Real Madrid', position: 'Goalkeeper', age: 32, level: 1),
      GuessPlayer(name: 'Alisson Becker', nationality: 'Brazil', league: 'Premier League', club: 'Liverpool', position: 'Goalkeeper', age: 32, level: 1),
      GuessPlayer(name: 'Ederson', nationality: 'Brazil', league: 'Premier League', club: 'Manchester City', position: 'Goalkeeper', age: 31, level: 1),
    ];
  }

  // المرحلة 2 - لاعبون معروفون (جميع المراكز)
  static List<GuessPlayer> getLevel2Players() {
    return [
      // مهاجمين
      GuessPlayer(name: 'Sadio Mané', nationality: 'Senegal', league: 'Saudi Pro League', club: 'Al-Nassr', position: 'Forward', age: 32, level: 2),
      GuessPlayer(name: 'Son Heung-min', nationality: 'South Korea', league: 'Premier League', club: 'Tottenham', position: 'Forward', age: 32, level: 2),
      GuessPlayer(name: 'Bukayo Saka', nationality: 'England', league: 'Premier League', club: 'Arsenal', position: 'Forward', age: 23, level: 2),
      GuessPlayer(name: 'Rodrygo', nationality: 'Brazil', league: 'La Liga', club: 'Real Madrid', position: 'Forward', age: 23, level: 2),
      GuessPlayer(name: 'Lautaro Martínez', nationality: 'Argentina', league: 'Serie A', club: 'Inter Milan', position: 'Forward', age: 27, level: 2),
      GuessPlayer(name: 'Victor Osimhen', nationality: 'Nigeria', league: 'Süper Lig', club: 'Galatasaray', position: 'Forward', age: 25, level: 2),
      
      // لاعبي وسط
      GuessPlayer(name: 'Bruno Fernandes', nationality: 'Portugal', league: 'Premier League', club: 'Manchester United', position: 'Midfielder', age: 30, level: 2),
      GuessPlayer(name: 'Toni Kroos', nationality: 'Germany', league: 'La Liga', club: 'Real Madrid', position: 'Midfielder', age: 34, level: 2),
      GuessPlayer(name: 'Joshua Kimmich', nationality: 'Germany', league: 'Bundesliga', club: 'Bayern Munich', position: 'Midfielder', age: 29, level: 2),
      GuessPlayer(name: 'N\'Golo Kanté', nationality: 'France', league: 'Saudi Pro League', club: 'Al-Ittihad', position: 'Midfielder', age: 33, level: 2),
      GuessPlayer(name: 'Phil Foden', nationality: 'England', league: 'Premier League', club: 'Manchester City', position: 'Midfielder', age: 24, level: 2),
      GuessPlayer(name: 'Bernardo Silva', nationality: 'Portugal', league: 'Premier League', club: 'Manchester City', position: 'Midfielder', age: 30, level: 2),
      
      // مدافعين
      GuessPlayer(name: 'Ruben Dias', nationality: 'Portugal', league: 'Premier League', club: 'Manchester City', position: 'Defender', age: 27, level: 2),
      GuessPlayer(name: 'Marquinhos', nationality: 'Brazil', league: 'Ligue 1', club: 'Paris Saint-Germain', position: 'Defender', age: 30, level: 2),
      GuessPlayer(name: 'Jules Koundé', nationality: 'France', league: 'La Liga', club: 'Barcelona', position: 'Defender', age: 25, level: 2),
      
      // حراس مرمى
      GuessPlayer(name: 'Marc-André ter Stegen', nationality: 'Germany', league: 'La Liga', club: 'Barcelona', position: 'Goalkeeper', age: 32, level: 2),
      GuessPlayer(name: 'Jan Oblak', nationality: 'Slovenia', league: 'La Liga', club: 'Atlético Madrid', position: 'Goalkeeper', age: 31, level: 2),
    ];
  }

  // المرحلة 3 - لاعبون جيدون
  static List<GuessPlayer> getLevel3Players() {
    return [
      GuessPlayer(name: 'Declan Rice', nationality: 'England', league: 'Premier League', club: 'Arsenal', position: 'Midfielder', age: 25, level: 3),
      GuessPlayer(name: 'Jude Bellingham', nationality: 'England', league: 'La Liga', club: 'Real Madrid', position: 'Midfielder', age: 21, level: 3),
      GuessPlayer(name: 'Rodri', nationality: 'Spain', league: 'Premier League', club: 'Manchester City', position: 'Midfielder', age: 28, level: 3),
      GuessPlayer(name: 'Pedri', nationality: 'Spain', league: 'La Liga', club: 'Barcelona', position: 'Midfielder', age: 22, level: 3),
      GuessPlayer(name: 'Gavi', nationality: 'Spain', league: 'La Liga', club: 'Barcelona', position: 'Midfielder', age: 20, level: 3),
      GuessPlayer(name: 'Jamal Musiala', nationality: 'Germany', league: 'Bundesliga', club: 'Bayern Munich', position: 'Midfielder', age: 21, level: 3),
      GuessPlayer(name: 'Rafael Leão', nationality: 'Portugal', league: 'Serie A', club: 'AC Milan', position: 'Forward', age: 25, level: 3),
      GuessPlayer(name: 'Khvicha Kvaratskhelia', nationality: 'Georgia', league: 'Serie A', club: 'Napoli', position: 'Forward', age: 23, level: 3),
      GuessPlayer(name: 'Zaha Youssef En-Nesyri', nationality: 'Morocco', league: 'La Liga', club: 'Sevilla', position: 'Forward', age: 27, level: 3),
      GuessPlayer(name: 'Salem Al-Dawsari', nationality: 'Saudi Arabia', league: 'Saudi Pro League', club: 'Al-Hilal', position: 'Forward', age: 33, level: 3),
    ];
  }

  // المرحلة 4 - لاعبون متوسطون
  static List<GuessPlayer> getLevel4Players() {
    return [
      GuessPlayer(name: 'Milik', nationality: 'Poland', league: 'Serie A', club: 'Juventus', position: 'Forward', age: 30, level: 4),
      GuessPlayer(name: 'Zaniolo', nationality: 'Italy', league: 'Süper Lig', club: 'Galatasaray', position: 'Midfielder', age: 25, level: 4),
      GuessPlayer(name: 'Talisca', nationality: 'Brazil', league: 'Saudi Pro League', club: 'Al-Nassr', position: 'Midfielder', age: 30, level: 4),
      GuessPlayer(name: 'Malcolm', nationality: 'Brazil', league: 'Saudi Pro League', club: 'Al-Hilal', position: 'Forward', age: 27, level: 4),
      GuessPlayer(name: 'Brozovic', nationality: 'Croatia', league: 'Saudi Pro League', club: 'Al-Nassr', position: 'Midfielder', age: 32, level: 4),
      GuessPlayer(name: 'Fabinho', nationality: 'Brazil', league: 'Saudi Pro League', club: 'Al-Ittihad', position: 'Midfielder', age: 31, level: 4),
      GuessPlayer(name: 'Mahrez', nationality: 'Algeria', league: 'Saudi Pro League', club: 'Al-Ahli', position: 'Forward', age: 33, level: 4),
      GuessPlayer(name: 'Mitrovic', nationality: 'Serbia', league: 'Saudi Pro League', club: 'Al-Hilal', position: 'Forward', age: 30, level: 4),
      GuessPlayer(name: 'Ivan Toney', nationality: 'England', league: 'Saudi Pro League', club: 'Al-Ahli', position: 'Forward', age: 28, level: 4),
      GuessPlayer(name: 'Ziyech', nationality: 'Morocco', league: 'Süper Lig', club: 'Galatasaray', position: 'Forward', age: 31, level: 4),
    ];
  }

  // المرحلة الخاصة - اللاعبون المعتزلون (أساطير من جميع المراكز)
  static List<GuessPlayer> getRetiredPlayers() {
    return [
      // مهاجمين
      GuessPlayer(name: 'Thierry Henry', nationality: 'France', league: 'Retired', club: 'Arsenal', position: 'Forward', age: 47, isRetired: true, level: 5),
      GuessPlayer(name: 'Wayne Rooney', nationality: 'England', league: 'Retired', club: 'Manchester United', position: 'Forward', age: 39, isRetired: true, level: 5),
      GuessPlayer(name: 'Ronaldo Nazário', nationality: 'Brazil', league: 'Retired', club: 'Real Madrid', position: 'Forward', age: 48, isRetired: true, level: 5),
      GuessPlayer(name: 'Zlatan Ibrahimović', nationality: 'Sweden', league: 'Retired', club: 'AC Milan', position: 'Forward', age: 43, isRetired: true, level: 5),
      GuessPlayer(name: 'Samuel Eto\'o', nationality: 'Cameroon', league: 'Retired', club: 'Barcelona', position: 'Forward', age: 43, isRetired: true, level: 5),
      GuessPlayer(name: 'Didier Drogba', nationality: 'Ivory Coast', league: 'Retired', club: 'Chelsea', position: 'Forward', age: 46, isRetired: true, level: 5),
      
      // لاعبي وسط
      GuessPlayer(name: 'Zinedine Zidane', nationality: 'France', league: 'Retired', club: 'Real Madrid', position: 'Midfielder', age: 52, isRetired: true, level: 5),
      GuessPlayer(name: 'Ronaldinho', nationality: 'Brazil', league: 'Retired', club: 'Barcelona', position: 'Midfielder', age: 44, isRetired: true, level: 5),
      GuessPlayer(name: 'Andrea Pirlo', nationality: 'Italy', league: 'Retired', club: 'Juventus', position: 'Midfielder', age: 45, isRetired: true, level: 5),
      GuessPlayer(name: 'Xavi Hernandez', nationality: 'Spain', league: 'Retired', club: 'Barcelona', position: 'Midfielder', age: 44, isRetired: true, level: 5),
      GuessPlayer(name: 'Andrés Iniesta', nationality: 'Spain', league: 'Retired', club: 'Barcelona', position: 'Midfielder', age: 40, isRetired: true, level: 5),
      GuessPlayer(name: 'Steven Gerrard', nationality: 'England', league: 'Retired', club: 'Liverpool', position: 'Midfielder', age: 44, isRetired: true, level: 5),
      GuessPlayer(name: 'Frank Lampard', nationality: 'England', league: 'Retired', club: 'Chelsea', position: 'Midfielder', age: 46, isRetired: true, level: 5),
      GuessPlayer(name: 'Kaka', nationality: 'Brazil', league: 'Retired', club: 'AC Milan', position: 'Midfielder', age: 42, isRetired: true, level: 5),
      GuessPlayer(name: 'Paul Scholes', nationality: 'England', league: 'Retired', club: 'Manchester United', position: 'Midfielder', age: 50, isRetired: true, level: 5),
      GuessPlayer(name: 'Mesut Özil', nationality: 'Germany', league: 'Retired', club: 'Arsenal', position: 'Midfielder', age: 36, isRetired: true, level: 5),
      
      // مدافعين
      GuessPlayer(name: 'Paolo Maldini', nationality: 'Italy', league: 'Retired', club: 'AC Milan', position: 'Defender', age: 56, isRetired: true, level: 5),
      GuessPlayer(name: 'Carles Puyol', nationality: 'Spain', league: 'Retired', club: 'Barcelona', position: 'Defender', age: 46, isRetired: true, level: 5),
      GuessPlayer(name: 'John Terry', nationality: 'England', league: 'Retired', club: 'Chelsea', position: 'Defender', age: 44, isRetired: true, level: 5),
      GuessPlayer(name: 'Philipp Lahm', nationality: 'Germany', league: 'Retired', club: 'Bayern Munich', position: 'Defender', age: 41, isRetired: true, level: 5),
      GuessPlayer(name: 'Rio Ferdinand', nationality: 'England', league: 'Retired', club: 'Manchester United', position: 'Defender', age: 46, isRetired: true, level: 5),
      GuessPlayer(name: 'Dani Alves', nationality: 'Brazil', league: 'Retired', club: 'Barcelona', position: 'Defender', age: 41, isRetired: true, level: 5),
      
      // حراس مرمى
      GuessPlayer(name: 'Gianluigi Buffon', nationality: 'Italy', league: 'Retired', club: 'Juventus', position: 'Goalkeeper', age: 46, isRetired: true, level: 5),
      GuessPlayer(name: 'Iker Casillas', nationality: 'Spain', league: 'Retired', club: 'Real Madrid', position: 'Goalkeeper', age: 43, isRetired: true, level: 5),
      GuessPlayer(name: 'Petr Čech', nationality: 'Czech Republic', league: 'Retired', club: 'Chelsea', position: 'Goalkeeper', age: 42, isRetired: true, level: 5),
      GuessPlayer(name: 'Edwin van der Sar', nationality: 'Netherlands', league: 'Retired', club: 'Manchester United', position: 'Goalkeeper', age: 54, isRetired: true, level: 5),
    ];
  }

  // الحصول على لاعبين حسب المستوى
  static List<GuessPlayer> getPlayersByLevel(int level) {
    switch (level) {
      case 1:
        return getLevel1Players();
      case 2:
        return getLevel2Players();
      case 3:
        return getLevel3Players();
      case 4:
        return getLevel4Players();
      case 5:
        return getRetiredPlayers();
      default:
        return getLevel1Players();
    }
  }

  // الحصول على جميع اللاعبين
  static List<GuessPlayer> getAllPlayers() {
    return [
      ...getLevel1Players(),
      ...getLevel2Players(),
      ...getLevel3Players(),
      ...getLevel4Players(),
      ...getRetiredPlayers(),
    ];
  }
  
  // الحصول على لاعبين متنوعين (من جميع المراكز والمستويات)
  static List<GuessPlayer> getMixedPlayers() {
    final allPlayers = getAllPlayers();
    allPlayers.shuffle();
    return allPlayers;
  }
  
  // إحصائيات اللاعبين
  static Map<String, int> getPlayerStats() {
    final all = getAllPlayers();
    return {
      'total': all.length,
      'forwards': all.where((p) => p.position == 'Forward').length,
      'midfielders': all.where((p) => p.position == 'Midfielder').length,
      'defenders': all.where((p) => p.position == 'Defender').length,
      'goalkeepers': all.where((p) => p.position == 'Goalkeeper').length,
      'retired': all.where((p) => p.isRetired).length,
      'active': all.where((p) => !p.isRetired).length,
    };
  }
}
