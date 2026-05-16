const data = $input.first().json;

function extractText(payload) {
  if (typeof payload === 'string') return payload;
  if (payload?.choices?.[0]?.message?.content) return payload.choices[0].message.content;
  if (payload?.output_text) return payload.output_text;
  if (payload?.text) return payload.text;
  return JSON.stringify(payload);
}

function clamp01(value) {
  const n = Number(value);
  if (Number.isNaN(n)) return 0;
  return Math.min(1, Math.max(0, n));
}

const raw = extractText(data);
let parsed;

try {
  parsed = JSON.parse(raw);
} catch (error) {
  parsed = {
    concept_code: data.target_concept || 'natural_hazards',
    conceptual_accuracy: 0,
    reasoning_quality: 0,
    use_of_evidence: 0,
    confidence_calibration: 0,
    independence: 0,
    improvement: 0,
    hints_used: data.hint_level || 0,
    misconceptions_detected: data.misconception_detected ? 1 : 0,
    confidence_estimate: data.confidence_estimate || 0.5,
    final_score: 0,
    misconception_type: data.misconception_detected || null,
    short_feedback: 'Unable to parse scoring output.'
  };
}

const hintsUsed = Number(parsed.hints_used || data.hint_level || 0);
const misconceptionsDetected = Number(parsed.misconceptions_detected || (data.misconception_detected ? 1 : 0));

let finalScore = parsed.final_score;
if (finalScore === undefined || finalScore === null) {
  finalScore =
    0.35 * clamp01(parsed.conceptual_accuracy) +
    0.20 * clamp01(parsed.reasoning_quality) +
    0.15 * clamp01(parsed.use_of_evidence) +
    0.10 * clamp01(parsed.confidence_calibration) +
    0.10 * clamp01(parsed.independence) +
    0.10 * clamp01(parsed.improvement) -
    0.05 * Math.min(hintsUsed, 3) / 3 -
    0.10 * Math.min(misconceptionsDetected, 2) / 2;
}

return [{
  json: {
    ...data,
    scoring_raw_output: raw,
    score: {
      concept_code: parsed.concept_code || data.target_concept || 'natural_hazards',
      conceptual_accuracy: clamp01(parsed.conceptual_accuracy),
      reasoning_quality: clamp01(parsed.reasoning_quality),
      use_of_evidence: clamp01(parsed.use_of_evidence),
      confidence_calibration: clamp01(parsed.confidence_calibration),
      independence: clamp01(parsed.independence),
      improvement: clamp01(parsed.improvement),
      hints_used: hintsUsed,
      misconceptions_detected: misconceptionsDetected,
      confidence_estimate: clamp01(parsed.confidence_estimate ?? data.confidence_estimate ?? 0.5),
      final_score: clamp01(finalScore),
      misconception_type: parsed.misconception_type || data.misconception_detected || null,
      short_feedback: parsed.short_feedback || null
    }
  }
}];

