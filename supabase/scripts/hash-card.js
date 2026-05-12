#!/usr/bin/env node

const {createHash} = require("crypto");

const [, , uid, pepper] = process.argv;

if (!uid || !pepper) {
  console.error("Usage: node scripts/hash-card.js \"04:82:62:72:4A:1C:90\" \"TON_CARD_HASH_PEPPER\"");
  process.exit(1);
}

const hash = createHash("sha256")
  .update(`${pepper}:${uid.toUpperCase()}`)
  .digest("hex");

console.log(hash);
