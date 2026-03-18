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
