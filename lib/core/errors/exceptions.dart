class ParseException implements Exception {
final String message;
ParseException(this.message);
@override
String toString() => 'ParseException: $message';
}