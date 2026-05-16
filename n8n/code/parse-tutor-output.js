const data = $input.first().json;

function extractText(payload) {
  if (typeof payload === 'string') return payload;
  if (payload?.choices?.[0]?.message?.content) return payload.choices[0].message.content;
  if (payload?.output_text) return payload.output_text;
  if (payload?.text) return payload.text;
  return JSON.stringify(payload);
}

const raw = extractText(data);
let parsed;

try {
  parsed = JSON.parse(raw);
} catch (error) {
  parsed = {
    reply: raw,
    tutor_action: data.allowed_action || 'ask_guiding_question',
    target_concept: data.current_concept_code || 'natural_hazards',
    misconception_detected: null,
    hint_level: 0,
    confidence_estimate: 0.5,
    should_assess_next: false,
    parse_warning: error.message
  };
}

const reply = String(parsed.reply || 'Let us reason through it one step at a time. What do you already know about this hazard?').slice(0, 3500);

return [{
  json: {
    ...data,
    tutor_raw_output: raw,
    tutor_reply: reply,
    tutor_action: parsed.tutor_action || data.allowed_action || 'ask_guiding_question',
    target_concept: parsed.target_concept || data.current_concept_code || 'natural_hazards',
    misconception_detected: parsed.misconception_detected || null,
    hint_level: Number(parsed.hint_level || 0),
    confidence_estimate: Number(parsed.confidence_estimate ?? 0.5),
    should_assess_next: Boolean(parsed.should_assess_next)
  }
}];

