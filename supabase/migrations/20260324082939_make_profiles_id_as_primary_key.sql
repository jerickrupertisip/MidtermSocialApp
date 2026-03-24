alter table "public"."messages" add column "media_url" text not null;

alter table "public"."messages" add column "type" text not null;

alter table "public"."messages" add constraint "messages_type_check" CHECK ((type = ANY (ARRAY['media'::text, 'message'::text]))) not valid;

alter table "public"."messages" validate constraint "messages_type_check";


