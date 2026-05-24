import '../models/question.dart';

class GameQuestionsData {
  // What Do You Know - Questions
  static List<GameQuestion> getWhatDoYouKnowQuestions() {
    return [
      GameQuestion(
        id: 'wdyk_1',
        question: 'Name a player starting with letter A',
        category: 'players',
        possibleAnswers: [
          'Aguero', 'Alisson', 'Aubameyang', 'Araujo', 'Antony',
          'Alaba', 'Adama', 'Alphonso Davies', 'Ancelotti', 'Arteta'
        ],
      ),
      GameQuestion(
        id: 'wdyk_2',
        question: 'Name a Spanish football club',
        category: 'clubs',
        possibleAnswers: [
          'Real Madrid', 'Barcelona', 'Atletico Madrid', 'Sevilla',
          'Valencia', 'Real Sociedad', 'Athletic Bilbao', 'Villarreal'
        ],
      ),
      GameQuestion(
        id: 'wdyk_3',
        question: 'Name a player who won Ballon d\'Or',
        category: 'players',
        possibleAnswers: [
          'Messi', 'Ronaldo', 'Modric', 'Benzema', 'Kaka',
          'Ronaldinho', 'Cannavaro', 'Nedved', 'Figo', 'Zidane'
        ],
      ),
      GameQuestion(
        id: 'wdyk_4',
        question: 'Name an English Premier League club',
        category: 'clubs',
        possibleAnswers: [
          'Manchester United', 'Liverpool', 'Chelsea', 'Arsenal',
          'Manchester City', 'Tottenham', 'Newcastle', 'Everton'
        ],
      ),
      GameQuestion(
        id: 'wdyk_5',
        question: 'Name a Brazilian footballer',
        category: 'players',
        possibleAnswers: [
          'Neymar', 'Vinicius', 'Casemiro', 'Alisson', 'Ederson',
          'Richarlison', 'Raphinha', 'Militao', 'Rodrygo', 'Gabriel Jesus'
        ],
      ),
    ];
  }

  // The Auction - Questions
  static List<AuctionQuestion> getAuctionQuestions() {
    return [
      AuctionQuestion(
        id: 'auction_1',
        question: 'How many Argentine players have played in the English Premier League?',
        correctAnswer: 45,
      ),
      AuctionQuestion(
        id: 'auction_2',
        question: 'How many teams have won the Champions League?',
        correctAnswer: 23,
      ),
      AuctionQuestion(
        id: 'auction_3',
        question: 'How many goals did Cristiano Ronaldo score for Real Madrid?',
        correctAnswer: 450,
      ),
      AuctionQuestion(
        id: 'auction_4',
        question: 'How many World Cups has Brazil won?',
        correctAnswer: 5,
      ),
      AuctionQuestion(
        id: 'auction_5',
        question: 'How many Ballon d\'Or awards has Lionel Messi won?',
        correctAnswer: 8,
      ),
    ];
  }

  // The Bell - Questions
  static List<GameQuestion> getBellQuestions() {
    return [
      GameQuestion(
        id: 'bell_1',
        question: 'Who was Real Madrid\'s coach in the 2018 Champions League final?',
        category: 'coaches',
        possibleAnswers: ['Zinedine Zidane', 'Zidane'],
      ),
      GameQuestion(
        id: 'bell_2',
        question: 'Which country won the 2022 FIFA World Cup?',
        category: 'tournaments',
        possibleAnswers: ['Argentina'],
      ),
      GameQuestion(
        id: 'bell_3',
        question: 'Who is the all-time top scorer in Champions League history?',
        category: 'players',
        possibleAnswers: ['Cristiano Ronaldo', 'Ronaldo'],
      ),
      GameQuestion(
        id: 'bell_4',
        question: 'Which club is known as "The Red Devils"?',
        category: 'clubs',
        possibleAnswers: ['Manchester United', 'Man United', 'United'],
      ),
      GameQuestion(
        id: 'bell_5',
        question: 'Who won the 2023 Ballon d\'Or?',
        category: 'players',
        possibleAnswers: ['Lionel Messi', 'Messi'],
      ),
    ];
  }

  // Guess Player by Transfers
  static List<PlayerTransferHistory> getTransferHistories() {
    return [
      PlayerTransferHistory(
        playerId: 'player_1',
        playerName: 'Cristiano Ronaldo',
        clubs: [
          'Sporting CP',
          'Manchester United',
          'Real Madrid',
          'Juventus',
          'Manchester United',
          'Al Nassr'
        ],
        clubLogos: ['🟢', '👹', '👑', '⚪⚫', '👹', '🟡'],
      ),
      PlayerTransferHistory(
        playerId: 'player_2',
        playerName: 'Zlatan Ibrahimovic',
        clubs: [
          'Ajax',
          'Juventus',
          'Inter Milan',
          'Barcelona',
          'AC Milan',
          'PSG',
          'Manchester United',
          'LA Galaxy',
          'AC Milan'
        ],
        clubLogos: ['🔴⚪', '⚪⚫', '🔵⚫', '🔵🔴', '🔴⚫', '🔵🔴', '👹', '⭐', '🔴⚫'],
      ),
      PlayerTransferHistory(
        playerId: 'player_3',
        playerName: 'Eden Hazard',
        clubs: [
          'Lille',
          'Chelsea',
          'Real Madrid'
        ],
        clubLogos: ['🔴', '🔵', '👑'],
      ),
      PlayerTransferHistory(
        playerId: 'player_4',
        playerName: 'Luis Suarez',
        clubs: [
          'Nacional',
          'Groningen',
          'Ajax',
          'Liverpool',
          'Barcelona',
          'Atletico Madrid',
          'Gremio'
        ],
        clubLogos: ['⚪🔵🔴', '🟢⚪', '🔴⚪', '🔴', '🔵🔴', '🔴⚪', '🔵⚫🔴'],
      ),
      PlayerTransferHistory(
        playerId: 'player_5',
        playerName: 'Gareth Bale',
        clubs: [
          'Southampton',
          'Tottenham',
          'Real Madrid',
          'Tottenham (Loan)',
          'LAFC'
        ],
        clubLogos: ['🔴⚪', '⚪', '👑', '⚪', '⚫🟡'],
      ),
    ];
  }
}
