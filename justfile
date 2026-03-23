[linux]
open-studio:
  #!/usr/bin/env bash
  eval $(supabase status -o env | grep STUDIO_URL)
  xdg-open "$STUDIO_URL"

[windows]
open-studio:
  #!/usr/bin/env bash
  eval $(supabase status -o env | grep STUDIO_URL)
  start "$STUDIO_URL"

[linux]
gen-env:
  supabase status -o env > supabase/.env

[linux]
gen-types-local:
  mkdir supabase/src
  supabase gen types --local > supabase/src/database.ts

[linux]
start:
  supabase start

[linux]
stop:
  supabase stop

[linux]
sync-db:
  #!/usr/bin/env bash
  cd supabase
  pnpm sync

[linux]
seed-reset-db:
  #!/usr/bin/env bash
  cd supabase
  pnpm seed && supabase db reset

[linux]
migrate-db name:
  #!/usr/bin/env bash
  cd supabase
  supabase db diff -f {{name}}

push-db-with-seed:
  #!/usr/bin/env bash
  cd supabase
  supabase db push --include-all --include-seed --include-roles

show-db-url:
  #!/usr/bin/env bash
  eval $(cat ./supabase/docker/.env | grep --extended-regexp '(POSTGRES_PASSWORD|POSTGRES_EXTERNAL_PORT)')
  echo "postgresql://postgres:${POSTGRES_PASSWORD}@localhost:${POSTGRES_EXTERNAL_PORT}/postgres?sslmode=disable"

show-studio-access:
  #!/usr/bin/env bash
  cat ./supabase/docker/.env | grep --extended-regexp '(DASHBOARD_USERNAME|DASHBOARD_PASSWORD)'
