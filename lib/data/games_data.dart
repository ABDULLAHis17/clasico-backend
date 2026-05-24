import '../models/game.dart';

class GamesData {
  static List<Game> getGames() {
    return [
      // Challenge of Thirty
      Game(
        id: 'challenge_thirty',
        title: 'Challenge of Thirty',
        description: 'Multiple football mini-games',
        icon: '🎯',
        color: '#EF4444',
        availableOnline: true,
        availableOffline: true,
        subGames: [
          SubGame(
            id: 'what_do_you_know',
            title: 'What Do You Know?',
            description: 'Test your football knowledge',
            icon: '🧠',
          ),
          SubGame(
            id: 'the_auction',
            title: 'The Auction',
            description: 'Bid for the best players',
            icon: '💰',
          ),
          SubGame(
            id: 'the_bell',
            title: 'The Bell',
            description: 'Quick reaction game',
            icon: '🔔',
          ),
          SubGame(
            id: 'guess_transfers',
            title: 'Guess the Player from His Transfers',
            description: 'Identify players by their career',
            icon: '🔄',
          ),
        ],
      ),
      
      // Guess the Player
      Game(
        id: 'guess_player',
        title: 'Guess the Player',
        description: 'Identify football stars',
        icon: '⚽',
        color: '#3B82F6',
        availableOnline: true,
        availableOffline: true,
      ),
      
      // Football Questions (Quiz)
      Game(
        id: 'football_quiz',
        title: 'Football Questions',
        description: 'Answer riddles about clubs, players & more',
        icon: '❓',
        color: '#10B981',
        availableOnline: false,
        availableOffline: true,
      ),
      
      // Who's the Outsider (Find the Wrong Player)
      Game(
        id: 'whos_the_outsider',
        title: 'Find the Wrong Player',
        description: 'Find the player who never played for the team',
        icon: '🕵️',
        color: '#F59E0B',
        availableOnline: false,
        availableOffline: true,
      ),
      
      // Common Club
      Game(
        id: 'common_club',
        title: 'Common Club',
        description: 'Find the club these players played for together',
        icon: '⚽',
        color: '#8B5CF6',
        availableOnline: false,
        availableOffline: true,
      ),
      
      // Jersey Number
      Game(
        id: 'jersey_number',
        title: 'Identify by Jersey Number',
        description: 'Guess the player from their jersey number',
        icon: '🎽',
        color: '#EC4899',
        availableOnline: false,
        availableOffline: true,
      ),
    ];
  }
}
