from typing import List, Optional
from datetime import date

class QuizItem:
    def __init__(
        self,
        subject: str,
        question: str,
        answer_list: List[str],
        answer_correct: List[str],
        mix_choice: str,
        unit: Optional[str] = None,
        number_of_quiz: Optional[int] = None,
        lecturer: Optional[str] = None,
        quiz_date: Optional[date] = None,
        images: Optional[str] = None
    ):
        if not subject:
            raise ValueError("Subject is required")
        if not question:
            raise ValueError("Question is required")
        if not answer_list or len(answer_list) < 2:
            raise ValueError("Answer_List must have at least 2 items")
        if not answer_correct or len(answer_correct) < 1:
            raise ValueError("Answer_Correct must have at least 1 item")
        if mix_choice not in ["Yes", "No"]:
            raise ValueError("Mix_choise must be 'Yes' or 'No'")

        self.subject = subject
        self.unit = unit
        self.number_of_quiz = number_of_quiz
        self.lecturer = lecturer
        self.date = quiz_date
        self.question = question
        self.images = images
        self.answer_list = answer_list
        self.answer_correct = answer_correct
        self.mix_choice = mix_choice