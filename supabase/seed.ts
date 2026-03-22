/**
 * ! Executing this script will delete all data in your database and seed it with 10 buckets_vectors.
 * ! Make sure to adjust the script to your needs.
 * Use any TypeScript runner to run this script, for example: `npx tsx seed.ts`
 * Learn more about the Seed Client by following our guide: https://docs.snaplet.dev/seed/getting-started
 */
import { createSeedClient, SeedClient } from "@snaplet/seed";
import { copycat } from "@snaplet/copycat";

function getRandomInt(min: number, max: number) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

const count = {
  users: 100,
  unions: 200,
  messages: 500,
}

// const full = async (seed: SeedClient) => {
//   const { profiles } = await seed.profiles((x) => x(count.users, {
//     username: (x) => copycat.username(x.seed)
//   }));

//   const { unions } = await seed.unions((x) =>
//     x(count.unions, ({ index }) => ({
//       name: (x) => copycat.streetName(x.seed),
//       creator_id: profiles[index % profiles.length].id,
//     }))
//   );

//   await seed.union_members((x) =>
//     x(20, ({ index }) => ({
//       union_id: unions[index % unions.length].id,
//       user_id: profiles[index % profiles.length].id,
//     }))
//   );

//   await seed.public_messages((x) =>
//     x(count.messages, ({ index }) => ({
//       union_id: unions[index % unions.length].id,
//       user_id: profiles[index % profiles.length].id,
//       content: (x) => copycat.sentence(x.seed, { min: 4, max: getRandomInt(6, 20) }),
//     }))
//   );
// }


const main = async () => {
  const seed = await createSeedClient({ dryRun: true });

  await seed.$resetDatabase();
  let messageCount = 0;
  await seed.public_messages((ctx) => ctx(count.messages, {
    // content: (x) => copycat.sentence(x.seed, { min: 4, max: getRandomInt(6, 20) }),
    content: () => {
      messageCount++;
      return `Message number ${messageCount}`;
    },
    created_at: (x) => copycat.dateString(x.seed, {
      min: new Date(2025, 0),
      max: new Date(2026, 0)
    }),
  }))


  process.exit();
};

main();
