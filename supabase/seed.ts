/**
 * Seeding script using @snaplet/seed with high data integrity.
 *
 * Key behaviors:
 *  - Profiles are created first, then unions (groups) with community-appropriate names.
 *  - union_members is populated to establish which profiles belong to which union.
 *  - public_messages are seeded by iterating over every union_member record so that
 *    ONLY profiles already linked to a union can author a message in that union.
 *    This enforces the relational constraint at the seed level.
 *  - created_at timestamps increment by exactly one minute per message, simulating
 *    a chronological conversation history.
 *  - Realistic community/group names replace the previous street-name generator.
 *
 * Run with: npx tsx seed.ts
 */
import { createSeedClient } from "@snaplet/seed";
import { copycat } from "@snaplet/copycat";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Realistic community / group name generator.
 * Combines a descriptor with a community noun so the result reads like a real
 * online community or club (e.g. "Urban Growers Circle", "Night Owl Collective").
 */
const GROUP_DESCRIPTORS = [
  "Urban", "Weekend", "Night Owl", "Mountain", "Coastal",
  "Digital", "Creative", "Open Source", "Local", "Global",
];

const GROUP_NOUNS = [
  "Growers Circle", "Runners Collective", "Makers Guild", "Readers Society",
  "Developers Hub", "Photographers Club", "Gamers League", "Writers Forum",
  "Hikers Alliance", "Coffee Enthusiasts",
];

/**
 * Deterministically picks a community name based on a copycat seed value.
 * Using two independent sub-seeds (_d, _n) avoids the descriptor and noun
 * always being paired at the same index, giving more variety.
 */
function communityName(seed: string): string {
  const descriptor = copycat.oneOf(seed + "_d", GROUP_DESCRIPTORS);
  const noun = copycat.oneOf(seed + "_n", GROUP_NOUNS);
  return `${descriptor} ${noun}`;
}

// ---------------------------------------------------------------------------
// Counts
// ---------------------------------------------------------------------------
const count = {
  users: 60,
  unions: 6,
  messages: 600,
  members: 60,   // total union_member rows (distributed across unions)
} as const;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
const main = async () => {
  const seed = await createSeedClient({ dryRun: true });

  // Wipe and start fresh.
  await seed.$resetDatabase();

  // ------------------------------------------------------------------
  // 1. Profiles
  // ------------------------------------------------------------------
  const { profiles } = await seed.profiles((x) =>
    x(count.users, ({ seed: s }) => ({
      username: copycat.username(s),
    }))
  );

  // ------------------------------------------------------------------
  // 2. Unions (groups) — with community names, NOT street names
  // ------------------------------------------------------------------
  const { unions } = await seed.unions((x) =>
    x(count.unions, ({ seed: s }) => ({
      name: communityName(s),
    }))
  );

  // ------------------------------------------------------------------
  // 3. Union members — links profiles ↔ unions (many-to-many junction).
  //    Snaplet's `connect` option draws from the pools we supply, so
  //    every member row is guaranteed to reference a valid profile and union.
  // ------------------------------------------------------------------
  const { union_members } = await seed.union_members(
    (x) => x(count.members),
    { connect: { profiles, unions } }
  );

  // ------------------------------------------------------------------
  // 4. Public messages — ONLY authored by profiles that are already
  //    members of the target union.
  //
  //    Strategy: iterate over the seeded `union_members` rows in a
  //    round-robin fashion. Each message is authored by the profile from
  //    that membership row and posted in the matching union. This
  //    guarantees the business rule "author must be a member of the union"
  //    holds for every single row without any extra lookups.
  //
  //    Sequential created_at: starts at 2025-01-01 00:00 UTC and advances
  //    by one minute per message, giving a clean chronological history.
  // ------------------------------------------------------------------
  const startDate = new Date(Date.UTC(2025, 0, 1, 0, 0, 0));

  await seed.public_messages((x) =>
    x(count.messages, ({ index }) => {
      // Pick a membership row round-robin — every message maps to a
      // verified (profile, union) pair that exists in union_members.
      const membership = union_members[index % union_members.length];

      return {
        // Human-readable sequential content; easy to sort / debug.
        content: `Message #${index + 1}`,

        // Monotonically increasing timestamp — exactly one minute per message.
        created_at: new Date(
          startDate.getTime() + index * 60_000
        ).toISOString(),

        // Field-level connect: wire FK columns directly to the validated
        // membership row, ensuring referential integrity at the column level.
        user_id: membership.user_id,
        union_id: membership.union_id,
      };
    })
  );

  process.exit(0);
};

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
