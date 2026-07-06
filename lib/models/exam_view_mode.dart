enum ExamViewMode { currentExam, arrearExam }

extension ExamViewModeX on ExamViewMode {
  String get label {
    switch (this) {
      case ExamViewMode.currentExam:
        return 'Current Exam';
      case ExamViewMode.arrearExam:
        return 'Arrear Exam';
    }
  }

  String get passLabel {
    switch (this) {
      case ExamViewMode.currentExam:
        return 'Current Pass';
      case ExamViewMode.arrearExam:
        return 'Arrear Exam Pass';
    }
  }

  String get passSectionTitle {
    switch (this) {
      case ExamViewMode.currentExam:
        return 'Current Pass Students';
      case ExamViewMode.arrearExam:
        return 'Arrear Exam Pass Students';
    }
  }
}
