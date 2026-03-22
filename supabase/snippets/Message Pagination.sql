CREATE OR REPLACE FUNCTION get_messages_paged(item_count int, page_num int)
RETURNS TABLE(content text, created_at timestamptz) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT m.content, m.created_at
  FROM messages m
  ORDER BY m.created_at DESC
  LIMIT item_count
  OFFSET (item_count * page_num);
END;
$$;

-- To use it:
SELECT count(*) FROM get_messages_paged(51, 10);

