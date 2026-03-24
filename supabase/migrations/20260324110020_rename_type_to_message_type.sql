alter table "public"."messages" drop constraint "messages_type_check";

alter table "public"."messages" drop column "type";

alter table "public"."messages" add column "message_type" text not null;

alter table "public"."messages" add constraint "messages_message_type_check" CHECK ((message_type = ANY (ARRAY['media'::text, 'message'::text]))) not valid;

alter table "public"."messages" validate constraint "messages_message_type_check";


