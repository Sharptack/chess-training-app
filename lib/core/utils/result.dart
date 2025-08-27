class Result<T> {
final T? data;
final Failure? failure;


const Result._({this.data, this.failure});


factory Result.success(T data) => Result._(data: data);
factory Result.error(Failure failure) => Result._(failure: failure);


bool get isSuccess => data != null;
bool get isError => failure != null;
}


abstract class Failure {
final String message;
final String? details;
const Failure(this.message, {this.details});


@override
String toString() => details == null ? message : '$message — $details';
}