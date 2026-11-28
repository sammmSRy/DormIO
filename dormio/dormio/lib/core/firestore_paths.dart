/// Single source of truth for collection names.
/// Never type a collection name as a raw string anywhere else in the app.
class FirestorePaths {
  static const users = 'users';
  static const dormitories = 'dormitories';
  static const reservations = 'reservations';
  static const expenses = 'expenses';
  static const chores = 'chores';
  static const conversations = 'conversations';
  static const messages = 'messages'; // sub-collection of conversations
}
