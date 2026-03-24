select m.id, m.media_url, m.created_at, p.username as author_name, p.avatar_url, u.id as union_id from messages m
join
  unions u on u.id = m.union_id
join
  profiles p on p.id = m.user_id
where m.message_type = 'media'
limit 3
OFFSET (6 * 2)