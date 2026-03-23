SELECT
  *
FROM union_members
INNER JOIN profiles
    ON profiles.id = union_members.user_id
order by union_members.union_id;