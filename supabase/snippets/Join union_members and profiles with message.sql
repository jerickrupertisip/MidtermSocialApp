-- This translates to: .from('messages').select(...)
SELECT
  m.id,
  m.content,
  m.created_at,
  p.id AS user_id,
  p.username,
  p.avatar_url
FROM messages AS m
INNER JOIN profiles AS p 
  ON m.user_id = p.id
WHERE m.union_id = 'af27c99b-654c-59a0-b77c-06b841517065'
ORDER BY m.created_at DESC
LIMIT 6
OFFSET (6*0);