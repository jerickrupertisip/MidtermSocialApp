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
start:
  supabase start

[linux]
stop:
  supabase stop

show-db-url:
  #!/usr/bin/env bash
  eval $(cat ./supabase/docker/.env | grep --extended-regexp '(POSTGRES_PASSWORD|POSTGRES_EXTERNAL_PORT)')
  echo "postgresql://postgres:${POSTGRES_PASSWORD}@localhost:${POSTGRES_EXTERNAL_PORT}/postgres?sslmode=disable"

show-studio-access:
  #!/usr/bin/env bash
  cat ./supabase/docker/.env | grep --extended-regexp '(DASHBOARD_USERNAME|DASHBOARD_PASSWORD)'
