import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<String> {
  LanguageCubit() : super('bn'); // Default App Language is Bangla

  void toggleLanguage() {
    emit(state == 'bn' ? 'en' : 'bn');
  }
}