module PublicSlack
  # Selects the 'English question for the day' and triggers a job to send it to all founders.
  class PostEnglishQuestionService
    def post
      # Do nothing if we are out of questions.
      # TODO: Fallback to posting individual questions if so.
      return if question_for_the_day.blank?

      PublicSlack::PostEnglishQuestionJob.perform_later(attachments: question_as_slack_attachment, channels: channels)
    end

    private

    # The target audience is all founders with a slack_user_id.
    def channels
      Founder.where.not(slack_user_id: nil).pluck(:slack_user_id)
    end

    # The oldest question without any user submissions yet.
    def question_for_the_day
      @question_for_the_day ||= begin
        attempted_questions = EnglishQuizQuestion.joins(:english_quiz_submissions)
        EnglishQuizQuestion.where.not(id: attempted_questions).order(created_at: :asc).first
      end
    end

    # Format the question as valid slack message attachments.
    def question_as_slack_attachment
      [question_section, options_section].to_json
    end

    # The question details.
    def question_section
      {
        color: '#0F9D58',
        author_name: 'Manoj Mohan',
        author_link: 'https://www.sv.co/faculty/manoj-mohan',
        title: 'Daily English Quiz',
        text: 'Good Morning! Here is your question for today:',
        image_url: question_for_the_day.question_url,
        footer: Date.today.strftime('%b %d, %Y')
      }
    end

    # The answer options section.
    def options_section
      {
        callback_id: "english_quiz_#{question_for_the_day.id}",
        color: '#008AC1',
        text: 'Select your answer',
        actions: options_as_buttons
      }
    end

    # The answer options formatted as slack message buttons.
    def options_as_buttons
      question_for_the_day.answer_options.each_with_object([]) do |answer_option, buttons|
        buttons << { name: 'answer_option', type: 'button', text: answer_option.value, value: answer_option.id }
      end
    end
  end
end
