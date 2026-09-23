-- RainAPI production settings for the hi-rain deployment.
-- This file intentionally contains no passwords, API keys, user quotas, or logs.

BEGIN;

INSERT INTO options (key, value)
VALUES
  ('SystemName', 'RainAPI'),
  ('DataExportDefaultTime', 'day'),
  ('global.chat_completions_to_responses_policy', '{"enabled":true,"all_channels":false,"channel_ids":[1,4],"model_patterns":["^gpt-5.*$","^gpt-6.*$"]}'),
  ('GroupRatio', '{"All Model":1,"Codex专用":1,"图像生成":0.7,"Preview":1}'),
  ('UserUsableGroups', '{}'),
  ('group_ratio_setting.group_special_usable_group', '{"All Model":{"+:图像生成":"普通与4K图像生成","Preview":"Preview"}}'),
  ('ModelPrice', '{}'),
  ('billing_setting.billing_mode', '{"gpt-6-astra":"tiered_expr","gpt-6-sol":"tiered_expr","gpt-6-luna":"tiered_expr","gpt-5.6-sol":"tiered_expr","gpt-5.6-terra":"tiered_expr","gpt-5.6-luna":"tiered_expr","gpt-5.5":"tiered_expr","gpt-5.5-pro":"tiered_expr","gpt-5.4":"tiered_expr","gpt-5.4-pro":"tiered_expr","gpt-6-sol-openai-compact":"tiered_expr","gpt-6-astra-openai-compact":"tiered_expr","gpt-5.6-sol-openai-compact":"tiered_expr","gpt-5.6-terra-openai-compact":"tiered_expr","gpt-5.6-luna-openai-compact":"tiered_expr","gpt-5.5-openai-compact":"tiered_expr","gpt-5.4-openai-compact":"tiered_expr","gpt-5.6":"tiered_expr","gpt-5.6-openai-compact":"tiered_expr","openai.gpt-5.6-sol":"tiered_expr","openai/gpt-5.6-sol":"tiered_expr","openai.gpt-5.6-terra":"tiered_expr","openai/gpt-5.6-terra":"tiered_expr","openai.gpt-5.6-luna":"tiered_expr","openai/gpt-5.6-luna":"tiered_expr"}'),
  ('billing_setting.billing_expr', '{"gpt-6-astra":"len <= 272000 ? tier(\"standard\", p * 10 + c * 50 + cr * 1 + cc * 12.5) : tier(\"long_context\", p * 20 + c * 75 + cr * 2 + cc * 25)","gpt-6-sol":"len <= 272000 ? tier(\"standard\", p * 2 + c * 10 + cr * 0.2 + cc * 2.5) : tier(\"long_context\", p * 4 + c * 15 + cr * 0.4 + cc * 5)","gpt-6-luna":"len <= 272000 ? tier(\"standard\", p * 0.1 + c * 0.5 + cr * 0.01 + cc * 0.125) : tier(\"long_context\", p * 0.2 + c * 0.75 + cr * 0.02 + cc * 0.25)","gpt-5.6-sol":"len <= 272000 ? tier(\"standard\", p * 4 + c * 20 + cr * 0.4 + cc * 5) : tier(\"long_context\", p * 8 + c * 30 + cr * 0.8 + cc * 10)","gpt-5.6-terra":"len <= 272000 ? tier(\"standard\", p * 2 + c * 12 + cr * 0.2 + cc * 2.5) : tier(\"long_context\", p * 4 + c * 18 + cr * 0.4 + cc * 5)","gpt-5.6-luna":"len <= 272000 ? tier(\"standard\", p * 0.2 + c * 1.2 + cr * 0.02 + cc * 0.25) : tier(\"long_context\", p * 0.4 + c * 1.8 + cr * 0.04 + cc * 0.5)","gpt-5.5":"len <= 272000 ? tier(\"standard\", p * 5 + c * 30 + cr * 0.5) : tier(\"long_context\", p * 10 + c * 45 + cr * 1)","gpt-5.5-pro":"len <= 272000 ? tier(\"standard\", p * 30 + c * 180) : tier(\"long_context\", p * 60 + c * 270)","gpt-5.4":"len <= 272000 ? tier(\"standard\", p * 2.5 + c * 15 + cr * 0.25) : tier(\"long_context\", p * 5 + c * 22.5 + cr * 0.5)","gpt-5.4-pro":"len <= 272000 ? tier(\"standard\", p * 30 + c * 180) : tier(\"long_context\", p * 60 + c * 270)","gpt-6-sol-openai-compact":"len <= 272000 ? tier(\"standard\", p * 2 + c * 10 + cr * 0.2 + cc * 2.5) : tier(\"long_context\", p * 4 + c * 15 + cr * 0.4 + cc * 5)","gpt-6-astra-openai-compact":"len <= 272000 ? tier(\"standard\", p * 10 + c * 50 + cr * 1 + cc * 12.5) : tier(\"long_context\", p * 20 + c * 75 + cr * 2 + cc * 25)","gpt-5.6-sol-openai-compact":"len <= 272000 ? tier(\"standard\", p * 4 + c * 20 + cr * 0.4 + cc * 5) : tier(\"long_context\", p * 8 + c * 30 + cr * 0.8 + cc * 10)","gpt-5.6-terra-openai-compact":"len <= 272000 ? tier(\"standard\", p * 2 + c * 12 + cr * 0.2 + cc * 2.5) : tier(\"long_context\", p * 4 + c * 18 + cr * 0.4 + cc * 5)","gpt-5.6-luna-openai-compact":"len <= 272000 ? tier(\"standard\", p * 0.2 + c * 1.2 + cr * 0.02 + cc * 0.25) : tier(\"long_context\", p * 0.4 + c * 1.8 + cr * 0.04 + cc * 0.5)","gpt-5.5-openai-compact":"len <= 272000 ? tier(\"standard\", p * 5 + c * 30 + cr * 0.5) : tier(\"long_context\", p * 10 + c * 45 + cr * 1)","gpt-5.4-openai-compact":"len <= 272000 ? tier(\"standard\", p * 2.5 + c * 15 + cr * 0.25) : tier(\"long_context\", p * 5 + c * 22.5 + cr * 0.5)","gpt-5.6":"len <= 272000 ? tier(\"standard\", p * 4 + c * 20 + cr * 0.4 + cc * 5) : tier(\"long_context\", p * 8 + c * 30 + cr * 0.8 + cc * 10)","gpt-5.6-openai-compact":"len <= 272000 ? tier(\"standard\", p * 4 + c * 20 + cr * 0.4 + cc * 5) : tier(\"long_context\", p * 8 + c * 30 + cr * 0.8 + cc * 10)","openai.gpt-5.6-sol":"len <= 272000 ? tier(\"standard\", p * 4 + c * 20 + cr * 0.4 + cc * 5) : tier(\"long_context\", p * 8 + c * 30 + cr * 0.8 + cc * 10)","openai/gpt-5.6-sol":"len <= 272000 ? tier(\"standard\", p * 4 + c * 20 + cr * 0.4 + cc * 5) : tier(\"long_context\", p * 8 + c * 30 + cr * 0.8 + cc * 10)","openai.gpt-5.6-terra":"len <= 272000 ? tier(\"standard\", p * 2 + c * 12 + cr * 0.2 + cc * 2.5) : tier(\"long_context\", p * 4 + c * 18 + cr * 0.4 + cc * 5)","openai/gpt-5.6-terra":"len <= 272000 ? tier(\"standard\", p * 2 + c * 12 + cr * 0.2 + cc * 2.5) : tier(\"long_context\", p * 4 + c * 18 + cr * 0.4 + cc * 5)","openai.gpt-5.6-luna":"len <= 272000 ? tier(\"standard\", p * 0.2 + c * 1.2 + cr * 0.02 + cc * 0.25) : tier(\"long_context\", p * 0.4 + c * 1.8 + cr * 0.04 + cc * 0.5)","openai/gpt-5.6-luna":"len <= 272000 ? tier(\"standard\", p * 0.2 + c * 1.2 + cr * 0.02 + cc * 0.25) : tier(\"long_context\", p * 0.4 + c * 1.8 + cr * 0.04 + cc * 0.5)"}'),
  ('ModelRatio', '{"gpt-5.5":2.5,"gpt-5.5-openai-compact":2.5,"gpt-5.6":2.5,"gpt-5.6-luna":0.5,"gpt-5.6-openai-compact":5,"gpt-5.6-sol":2.5,"gpt-5.6-terra":1.25,"image2.0":2.5,"openai.gpt-5.6-luna":0.5,"openai.gpt-5.6-sol":2.5,"openai.gpt-5.6-terra":1.25,"openai/gpt-5.6-luna":0.5,"openai/gpt-5.6-luna-pro":0.5,"openai/gpt-5.6-sol":2.5,"openai/gpt-5.6-sol-pro":2.5,"openai/gpt-5.6-terra":1.25,"openai/gpt-5.6-terra-pro":1.25,"gpt-5.4":1.5,"gpt-image-2":17,"gpt-image-2-4k":17}'),
  ('CompletionRatio', '{"gpt-5.5":6,"gpt-5.5-openai-compact":6,"gpt-5.6":6,"gpt-5.6-luna":6,"gpt-5.6-openai-compact":6,"gpt-5.6-sol":6,"gpt-5.6-terra":6,"openai.gpt-5.6-luna":6,"openai.gpt-5.6-sol":6,"openai.gpt-5.6-terra":6,"openai/gpt-5.6-luna":6,"openai/gpt-5.6-luna-pro":6,"openai/gpt-5.6-sol":6,"openai/gpt-5.6-sol-pro":6,"openai/gpt-5.6-terra":6,"openai/gpt-5.6-terra-pro":6,"gpt-5.4":5.376666666666666,"gpt-image-2":6,"gpt-image-2-4k":6}'),
  ('ImageRatio', '{"gpt-image-2":1.6,"gpt-image-2-4k":1.6}')
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value;

UPDATE users
SET "group" = CASE username
  WHEN 'admin' THEN 'All Model'
  WHEN 'mgfly' THEN 'All Model'
  WHEN 'anshuo' THEN 'All Model'
  WHEN 'rain' THEN 'Codex专用'
  WHEN 'joe' THEN 'Codex专用'
  WHEN 'nick' THEN 'Codex专用'
  WHEN 'hao' THEN 'Codex专用'
  WHEN 'weili' THEN 'Codex专用'
  WHEN 'poppy' THEN 'Codex专用'
  ELSE "group"
END
WHERE username IN (
  'admin', 'mgfly', 'anshuo', 'rain', 'joe', 'nick', 'hao', 'weili', 'poppy'
);

-- Preserve channel credentials, upstream URLs, names, balances, and usage.
-- Only reconcile the non-sensitive routing fields maintained by RainAPI.
UPDATE channels
SET "group" = 'All Model,Codex专用',
    models = 'gpt-5.5-openai-compact,gpt-5.5,gpt-5.6-sol,gpt-5.6-openai-compact,gpt-5.6-terra,gpt-5.6-luna,gpt-5.6,gpt-5.4,gpt-5.4-openai-compact,gpt-6-sol,gpt-6-sol-openai-compact'
WHERE id = 1;

UPDATE channels
SET "group" = 'All Model',
    models = 'gpt-image-2,gpt-5.5-openai-compact,gpt-5.4-mini,gpt-5.4,gpt-5.2-openai-compact,gpt-5.4-openai-compact,gpt-5.3-codex,gpt-5.2,gpt-5.5,gpt-5.3-codex-openai-compact,image2.0'
WHERE id = 2;

UPDATE channels
SET name = '图像生成渠道',
    "group" = '图像生成',
    models = 'gpt-image-2,gpt-image-2-4k'
WHERE id = 3;

-- Preview reuses the existing Codex account as requested. Credentials remain
-- production-managed data and are intentionally absent from this file.
UPDATE channels
SET "group" = 'All Model,Preview',
    models = 'gpt-6-astra,gpt-6-astra-openai-compact'
WHERE id = 4 AND type = 57;

-- Keep the model catalog and database routing consistent with the channels.
DELETE FROM abilities WHERE channel_id IN (1, 4);
INSERT INTO abilities ("group", model, channel_id, enabled, priority, weight, tag)
SELECT group_name, model_name, id, status = 1, priority, weight, tag
FROM channels
CROSS JOIN unnest(string_to_array("group", ',')) AS group_name
CROSS JOIN unnest(string_to_array(models, ',')) AS model_name
WHERE id IN (1, 4)
ON CONFLICT ("group", model, channel_id) DO NOTHING;

COMMIT;
