
  create table "public"."union_members" (
    "union_id" uuid not null,
    "user_id" uuid not null,
    "joined_at" timestamp with time zone default now()
      );


alter table "public"."messages" add column "user_id" uuid not null;

alter table "public"."unions" add column "created_at" timestamp with time zone default now();

alter table "public"."unions" add column "creator_id" uuid;

CREATE UNIQUE INDEX union_members_pkey ON public.union_members USING btree (union_id, user_id);

alter table "public"."union_members" add constraint "union_members_pkey" PRIMARY KEY using index "union_members_pkey";

alter table "public"."messages" add constraint "messages_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_user_id_fkey";

alter table "public"."union_members" add constraint "union_members_union_id_fkey" FOREIGN KEY (union_id) REFERENCES public.unions(id) ON DELETE CASCADE not valid;

alter table "public"."union_members" validate constraint "union_members_union_id_fkey";

alter table "public"."union_members" add constraint "union_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."union_members" validate constraint "union_members_user_id_fkey";

alter table "public"."unions" add constraint "unions_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."unions" validate constraint "unions_creator_id_fkey";

grant delete on table "public"."union_members" to "anon";

grant insert on table "public"."union_members" to "anon";

grant references on table "public"."union_members" to "anon";

grant select on table "public"."union_members" to "anon";

grant trigger on table "public"."union_members" to "anon";

grant truncate on table "public"."union_members" to "anon";

grant update on table "public"."union_members" to "anon";

grant delete on table "public"."union_members" to "authenticated";

grant insert on table "public"."union_members" to "authenticated";

grant references on table "public"."union_members" to "authenticated";

grant select on table "public"."union_members" to "authenticated";

grant trigger on table "public"."union_members" to "authenticated";

grant truncate on table "public"."union_members" to "authenticated";

grant update on table "public"."union_members" to "authenticated";

grant delete on table "public"."union_members" to "service_role";

grant insert on table "public"."union_members" to "service_role";

grant references on table "public"."union_members" to "service_role";

grant select on table "public"."union_members" to "service_role";

grant trigger on table "public"."union_members" to "service_role";

grant truncate on table "public"."union_members" to "service_role";

grant update on table "public"."union_members" to "service_role";


