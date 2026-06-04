# Supabase migrations

These SQL files mirror the migrations applied to the hosted project
**Tseng Hei ReWear FYP** (`kuopofvucpnmudtifkho`) via the Supabase MCP server.
They are the version-controlled record of the database schema.

| Version | Migration | What it does |
|---|---|---|
| 20260601122306 | create_core_tables | 5 tables + CHECK constraints + FKs + indexes + updated_at trigger |
| 20260601122343 | enable_rls_policies | RLS on all 5 tables; per-user policies + child-table cross-link guards |
| 20260601122407 | auth_signup_profiles_trigger | auto-create profiles row on auth signup |
| 20260601122430 | storage_bucket_and_policies | private `wardrobe-items` bucket + owner-folder policies |
| 20260601122606 | harden_function_security | pin search_path; revoke public EXECUTE on handle_new_user |

**Already applied** to the hosted DB — do not re-run against it. They exist for
record/portability. To recreate the schema on a fresh project, run them in
version order (e.g. via `supabase db push` once a CLI is linked).

Note: the project also has a Supabase-managed `rls_auto_enable` event trigger
(auto-enables RLS on new public tables) that predates these migrations. It is
infrastructure we did not author and intentionally leave in place.
