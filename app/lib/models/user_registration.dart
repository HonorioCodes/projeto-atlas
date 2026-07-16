import 'user_model.dart';

class UserRegistration {
  String? name;
  DateTime? birthDate;
  String? sex;

  double? height;
  double? currentWeight;
  double? targetWeight;

  String? mainGoal;

  bool get isComplete {
    return name != null &&
        birthDate != null &&
        sex != null &&
        height != null &&
        currentWeight != null &&
        mainGoal != null;
  }

  UserModel toUserModel() {
    if (!isComplete) {
      throw StateError('O cadastro do usuário está incompleto.');
    }

    return UserModel(
      name: name!,
      birthDate: birthDate!,
      sex: sex!,
      height: height!,
      currentWeight: currentWeight!,
      targetWeight: targetWeight,
      mainGoal: mainGoal!,
    );
  }
}