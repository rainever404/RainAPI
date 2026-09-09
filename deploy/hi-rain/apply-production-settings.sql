-- RainAPI production settings for the hi-rain deployment.
-- This file intentionally contains no passwords, API keys, user quotas, or logs.

BEGIN;

INSERT INTO options (key, value)
VALUES
  ('SystemName', 'RainAPI'),
  ('DataExportDefaultTime', 'day'),
  ('GroupRatio', '{"All Model":1,"Codex专用":1,"图像生成":0.7}'),
  ('UserUsableGroups', '{}'),
  ('ModelPrice', '{}'),
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
    models = 'gpt-5.5-openai-compact,gpt-5.5,gpt-5.6-sol,gpt-5.6-openai-compact,gpt-5.6-terra,gpt-5.6-luna,gpt-5.6,gpt-5.4,gpt-5.4-openai-compact'
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

COMMIT;
