const update = $json;
const message = update.message || update.edited_message || {};
const from = message.from || {};
const chat = message.chat || {};

const rawText = message.text || message.caption || '';
const text = rawText.trim().slice(0, 2000);

if (!text) {
  return [{
    json: {
      ignore: true,
      reason: 'empty_or_non_text_message',
      telegram_update_id: update.update_id || null,
      telegram_chat_id: chat.id ? String(chat.id) : null
    }
  }];
}

return [{
  json: {
    ignore: false,
    telegram_update_id: update.update_id || null,
    telegram_message_id: message.message_id ? String(message.message_id) : null,
    telegram_user_id: from.id ? String(from.id) : null,
    telegram_chat_id: chat.id ? String(chat.id) : null,
    telegram_username: from.username || null,
    first_name: from.first_name || null,
    last_name: from.last_name || null,
    student_display_name: [from.first_name, from.last_name].filter(Boolean).join(' ') || from.username || 'Telegram Student',
    message_text: text,
    is_start: text === '/start',
    received_at: new Date().toISOString()
  }
}];

