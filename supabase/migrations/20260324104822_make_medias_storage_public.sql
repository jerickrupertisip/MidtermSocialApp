
  create policy "Disable RLS for specific bucket"
  on "storage"."objects"
  as permissive
  for all
  to public
using ((bucket_id = 'medias'::text))
with check ((bucket_id = 'medias'::text));



