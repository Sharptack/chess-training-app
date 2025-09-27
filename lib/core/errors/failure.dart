// lib/core/errors/failure.dart
import '../utils/result.dart';


class NotFoundFailure extends Failure {
const NotFoundFailure(String message, {String? details}) : super(message, details: details);
}


class ParseFailure extends Failure {
const ParseFailure(String message, {String? details}) : super(message, details: details);
}


class EmptyDataFailure extends Failure {
const EmptyDataFailure(String message, {String? details}) : super(message, details: details);
}


class UnexpectedFailure extends Failure {
const UnexpectedFailure(String message, {String? details}) : super(message, details: details);
}