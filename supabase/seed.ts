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
  users: 60,
  unions: 6,
  messages: 600,
}

const main = async () => {
  const seed = await createSeedClient({ dryRun: true });

  await seed.$resetDatabase();

  const { profiles } = await seed.profiles((x) => x(count.users, {
    username: (x) => copycat.username(x.seed)
  }));


  const { unions } = await seed.unions((x) =>
    x(count.unions, () => ({
      name: (x) => copycat.streetName(x.seed),
    }))
  );

  await seed.union_members((x) => x(20), { connect: { profiles, unions } });

  const startDate = new Date(2025, 0, 1, 0, 0);
  let incrementedMinutes = 0;
  await seed.public_messages((ctx) => ctx(count.messages, {
    // Incrementing content number
    content: () => {
      return (incrementedMinutes + 1).toString();
    },
    // Incrementing timestamp by 1 minute per record
    created_at: () => {
      const nextDate = new Date(startDate.getTime() + incrementedMinutes * 60000);
      incrementedMinutes++; // Move to the next minute for the next row
      return nextDate.toISOString();
    },
  }), { connect: { unions, profiles } })

  process.exit();
};

main();
