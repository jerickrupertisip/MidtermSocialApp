create table profiles (
 id uuid references auth.users(id) on delete cascade,
 username text unique not null,
 avatar_url text,
 created_at timestamp with time zone default now()
);

create table unions (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  creator_id uuid references profiles(id) on delete set null,
  created_at timestamp with time zone default now()
);

create table union_members (
  union_id uuid references unions(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  joined_at timestamp with time zone default now(),
  primary key (union_id, user_id)
);

create table messages (
  id uuid default gen_random_uuid() primary key,
  content text not null,
  union_id uuid references unions(id) on delete cascade not null,
  user_id uuid references profiles(id) on delete cascade not null,
  created_at timestamp with time zone default now()
);
