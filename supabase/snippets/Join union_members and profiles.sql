SELECT 
  username,
  avatar_url
FROM union_members
INNER JOIN profiles
    ON profiles.id = union_members.user_id
where union_members.union_id = 'af27c99b-654c-59a0-b77c-06b841517065'
order by username;