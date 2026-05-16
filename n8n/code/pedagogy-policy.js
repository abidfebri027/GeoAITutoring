const data = $input.first().json;

const message = (data.message_text || '').toLowerCase();
const mastery = Number(data.mastery_score ?? 0);
const hintsInSession = Number(data.hints_in_session ?? 0);
const misconceptionCount = Number(data.misconception_count ?? 0);
const attempts = Number(data.attempts_total ?? 0);

const asksDirectAnswer =
  message.includes('answer') ||
  message.includes('tell me') ||
  message.includes('what is') ||
  message.includes('why') ||
  message.includes('explain');

const expressesConfusion =
  message.includes("don't understand") ||
  message.includes('dont understand') ||
  message.includes('confused') ||
  message.includes('stuck') ||
  message.includes('help');

let allowedAction = 'ask_guiding_question';
let reason = 'default_socratic_turn';

if (misconceptionCount > 0 && attempts > 0) {
  allowedAction = 'correct_misconception';
  reason = 'active_misconception';
} else if (mastery >= 0.78 && attempts >= 2) {
  allowedAction = 'assess';
  reason = 'mastery_ready_for_check';
} else if (expressesConfusion && hintsInSession < 2) {
  allowedAction = 'give_hint';
  reason = 'student_confused_low_hint_count';
} else if (expressesConfusion && hintsInSession >= 2) {
  allowedAction = 'micro_explain';
  reason = 'student_stuck_after_multiple_hints';
} else if (asksDirectAnswer && mastery < 0.70) {
  allowedAction = 'ask_guiding_question';
  reason = 'prevent_full_answer_too_early';
} else if (mastery >= 0.60 && mastery < 0.78) {
  allowedAction = 'give_hint';
  reason = 'moderate_mastery_prompt_next_step';
}

return [{
  json: {
    ...data,
    allowed_action: allowedAction,
    policy_reason: reason,
    tutor_constraints: {
      max_questions: 1,
      reveal_full_answer: ['micro_explain', 'final_explain'].includes(allowedAction),
      telegram_concise: true
    }
  }
}];

