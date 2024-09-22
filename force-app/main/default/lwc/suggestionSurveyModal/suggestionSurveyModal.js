import { api, track } from "lwc";
import SurveyQuestion from "c/surveyQuestion";
import LightningModal from "lightning/modal";

export default class SuggestionSurveyModal extends LightningModal {

    @api title;
    @api cancelLabel;
    @api submitLabel;
    @api survey;

    @track surveyQuestions = [];

    connectedCallback() {
        const survey = this.survey || { surveyQuestions: [] };
        this.surveyQuestions = this.getSurveyQuestions(survey);
    }


    getSurveyQuestions(survey) {
        const surveyQuestions = [];
        let questionNumber = 1;
        survey.surveyQuestions.forEach(question => {
            const surveyQuestion = new SurveyQuestion(question);
            if (!surveyQuestion.isDescription) {
                surveyQuestion.number = questionNumber;
                questionNumber++;
            }
            surveyQuestions.push(surveyQuestion);
        });
        return surveyQuestions;
    }

    handleModalSubmitted() {
        // We will check for survey questions that are falsy and required
        const requiredQuestionsWithNoValue = this.surveyQuestions
            .filter(question => question.required && !question.value);
        if (requiredQuestionsWithNoValue.length === 0) {
            // Check for "truthy" values, this means non-null, not undefined and not empty
            const populatedSurveyQuestions = this.surveyQuestions
                .filter(question => question.value)
                .map(question => ({
                    id: question.id,
                    value: question.value
                }));
            this.close({
                submit: true,
                populatedSurveyQuestions,
                });
        }
    }

    handleModalClose() {
        this.close();
    }

    handleQuestionUpdate(event) {
        const { questionId, value } = event.detail;
        const matchingQuestion = this.surveyQuestions.find(question => question.id === questionId);
        matchingQuestion.value = value;
    }

}