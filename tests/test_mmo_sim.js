// test_mmo_sim.js
// Node.js Verification Test Suite for Chronicles of Midgard MMO Web Edition

import { SKILLS, getSkillsForClass, getSkill, calculateCastTime, Element } from '../web/skill_database.js';
import {
  CLASS_PROFILES,
  createDefaultAttributes,
  computeDerivedStats,
  calculatePhysicalDamage,
  calculateMagicDamage,
  calculateHealAmount,
  getElementalMultiplier
} from '../web/stat_engine.js';
import { MMOEngine, AIState } from '../web/mmo_sim.js';

console.log("=================================================================");
console.log("   CHRONICLES OF MIDGARD: JAVASCRIPT SIMULATION TEST SUITE       ");
console.log("=================================================================");

let allPassed = true;

function assert(condition, message) {
  if (!condition) {
    console.error(`  [FAIL] ${message}`);
    allPassed = false;
  } else {
    console.log(`  [OK] ${message}`);
  }
}

// 1. Test Skills
console.log("\n[TEST 1] Verifying JS Skill Database...");
const totalSkills = Object.keys(SKILLS).length;
assert(totalSkills >= 24, `Total skills registered: ${totalSkills} (>= 24)`);

const classes = ["knight", "wizard", "assassin", "high_priest", "hunter", "blacksmith"];
for (const c of classes) {
  const cSkills = getSkillsForClass(c);
  assert(cSkills.length >= 4, `Class ${c} has ${cSkills.length} skills (>= 4)`);
}

const cast0 = calculateCastTime("storm_gust", 0);
const cast75 = calculateCastTime("storm_gust", 75);
const cast150 = calculateCastTime("storm_gust", 150);
assert(Math.abs(cast0 - 3.0) < 0.01, `Storm Gust Cast @ 0 DEX = ${cast0}s`);
assert(Math.abs(cast75 - 1.5) < 0.01, `Storm Gust Cast @ 75 DEX = ${cast75}s`);
assert(Math.abs(cast150 - 0.0) < 0.01, `Storm Gust Cast @ 150 DEX = ${cast150}s (Instant Cast)`);

// 2. Test Stat Engine
console.log("\n[TEST 2] Verifying JS Stat Engine...");
const knightRaw = createDefaultAttributes({
  class_id: "knight",
  base_level: 99,
  job_level: 50,
  str: 99,
  agi: 50,
  vit: 80,
  int: 10,
  dex: 60,
  luk: 20,
  weapon_atk: 180,
  refine_atk: 70,
  armor_def: 45,
  shield_def: 15
});

const knightStats = computeDerivedStats(knightRaw);
assert(knightStats.max_hp > 5000, `Knight Max HP = ${knightStats.max_hp} (> 5000)`);
assert(knightStats.avg_atk > 300, `Knight Avg ATK = ${knightStats.avg_atk} (> 300)`);
assert(knightStats.hit > 300, `Knight Hit = ${knightStats.hit} (> 300)`);

const wizRaw = createDefaultAttributes({
  class_id: "wizard",
  base_level: 99,
  job_level: 50,
  str: 10,
  agi: 40,
  vit: 40,
  int: 99,
  dex: 85,
  luk: 20,
  weapon_matk: 120
});
const wizStats = computeDerivedStats(wizRaw);
assert(wizStats.min_matk > 300, `Wizard Min MATK = ${wizStats.min_matk} (> 300)`);
assert(wizStats.max_sp > 1500, `Wizard Max SP = ${wizStats.max_sp} (> 1500)`);

const fireVsEarth = getElementalMultiplier(Element.FIRE, Element.EARTH);
const holyVsUndead = getElementalMultiplier(Element.HOLY, Element.UNDEAD);
assert(Math.abs(fireVsEarth - 1.75) < 0.01, `Fire vs Earth = ${fireVsEarth}x`);
assert(Math.abs(holyVsUndead - 2.00) < 0.01, `Holy vs Undead = ${holyVsUndead}x`);

// 3. Test MMO Engine
console.log("\n[TEST 3] Verifying JS MMO Engine (80 Concurrent Simulated Players)...");
const mmo = new MMOEngine({ playerCount: 80 });
assert(mmo.simulatedPlayers.length === 80, `Spawned ${mmo.simulatedPlayers.length} simulated adventurers`);
assert(mmo.parties.size > 0, `Formed ${mmo.parties.size} raid parties`);

const nearby = mmo.queryNearbyPlayers(mmo.cityCenter, 250);
console.log(`  - City center query found ${nearby.length} players nearby`);

const start = performance.now();
for (let i = 0; i < 120; i++) {
  mmo.updateSimulation(0.0166);
}
const elapsed = performance.now() - start;
console.log(`  - 120 ticks executed in ${elapsed.toFixed(2)} ms (${(elapsed / 120).toFixed(3)} ms/tick)`);
assert(elapsed < 500, `Performance benchmark passed (< 500ms for 120 ticks with 80 players)`);

assert(mmo.chatLog.length > 0, `Dynamic chat generated: ${mmo.chatLog.length} entries`);

console.log("=================================================================");
if (allPassed) {
  console.log("   >>> ALL JAVASCRIPT TESTS PASSED SUCCESSFULLY! <<<             ");
  process.exit(0);
} else {
  console.error("   >>> TEST FAILURES DETECTED! <<<                              ");
  process.exit(1);
}
