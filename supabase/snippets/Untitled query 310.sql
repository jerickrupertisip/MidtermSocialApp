SELECT
    u.id,
    u.name
FROM
    unions u
INNER JOIN
    union_members um ON u.id = um.union_id
WHERE
    um.user_id = '71c8f57c-aae5-5ac8-8fc0-a1ff399b17b8';