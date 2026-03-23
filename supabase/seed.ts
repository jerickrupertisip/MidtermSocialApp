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
import { hashSync } from "bcrypt";

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
  const HASHED_PASSWORD = hashSync("password", 10);

  const { users } = await seed.users((x) =>
    x(count.users, (ctx) => ({
      instance_id: "00000000-0000-0000-0000-000000000000",
      aud: "authenticated",
      role: "authenticated",
      email: copycat.email(ctx.seed, { domain: "email.com" }).toLowerCase(),
      encrypted_password: HASHED_PASSWORD,
      email_confirmed_at: new Date().toISOString(), // marks email as verified
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      invited_at: null,
      confirmation_sent_at: null,
      // recovery_token: "",
      recovery_sent_at: null,
      email_change: "",
      email_change_sent_at: null,
      last_sign_in_at: null,
      raw_app_meta_data: {
        provider: "email",
        providers: ["email"],
      },
      raw_user_meta_data: {
        email_verified: true,
        username: copycat.fullName(ctx.seed),
      },
      is_super_admin: null,
      // email_change_token_new: "",
      phone: null,
      phone_confirmed_at: null,
      phone_change: "",
      phone_change_token: "",
      phone_change_sent_at: null,
      // email_change_token_current: "",
      email_change_confirm_status: 0,
      banned_until: null,
      // reauthentication_token: "",
      reauthentication_sent_at: null,
      is_sso_user: false,
      deleted_at: null,
      is_anonymous: false,
    }))
  );

  const { profiles } = await seed.profiles((x) =>
    x(count.users, ({ seed: s }) => ({
      username: copycat.username(s),
    }))
  );

  const { unions } = await seed.unions((x) =>
    x(count.unions, ({ seed: s }) => ({
      name: communityName(s),
    }))
  );

  const { union_members } = await seed.union_members(
    (x) => x(count.members),
    { connect: { profiles, unions } }
  );

  const startDate = new Date(Date.UTC(2025, 0, 1, 0, 0, 0));

  await seed.public_messages((x) =>
    x(count.messages, ({ index }) => {
      const membership = union_members[index % union_members.length];

      return {
        content: `Message #${index + 1}`,
        created_at: new Date(
          startDate.getTime() + index * 60_000
        ).toISOString(),
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
