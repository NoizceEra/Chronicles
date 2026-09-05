// stat_engine.js
// Chronicles of Midgard - 6-Stat Attribute Formula Engine (JS Edition)

import { Element, SkillDatabase, getSkill, getMultiplier } from './skill_database.js';

export const MAX_BASE_LEVEL = 99;
export const MAX_JOB_LEVEL = 50;
export const MAX_STAT_VAL = 99;

export const CLASS_PROFILES = Object.freeze({
  knight: {
    name: "Knight",
    title: "Lord Knight",
    base_aspd: 145.0,
    hp_mod: 1.5,
    sp_mod: 0.6,
    is_ranged: false,
    primary_stat: "str",
    job_bonuses_lv50: { str: 8, agi: 2, vit: 10, int: 0, dex: 6, luk: 4 }
  },
  wizard: {
    name: "Wizard",
    title: "High Wizard",
    base_aspd: 130.0,
    hp_mod: 0.7,
    sp_mod: 1.8,
    is_ranged: false,
    primary_stat: "int",
    job_bonuses_lv50: { str: 1, agi: 3, vit: 1, int: 12, dex: 10, luk: 3 }
  },
  assassin: {
    name: "Assassin",
    title: "Assassin Cross",
    base_aspd: 155.0,
    hp_mod: 1.1,
    sp_mod: 0.8,
    is_ranged: false,
    primary_stat: "agi",
    job_bonuses_lv50: { str: 6, agi: 10, vit: 2, int: 0, dex: 8, luk: 4 }
  },
  high_priest: {
    name: "High Priest",
    title: "Arch-Bishop",
    base_aspd: 135.0,
    hp_mod: 0.9,
    sp_mod: 1.6,
    is_ranged: false,
    primary_stat: "int",
    job_bonuses_lv50: { str: 2, agi: 2, vit: 5, int: 10, dex: 8, luk: 3 }
  },
  hunter: {
    name: "Hunter",
    title: "Sniper",
    base_aspd: 150.0,
    hp_mod: 0.95,
    sp_mod: 0.9,
    is_ranged: true,
    primary_stat: "dex",
    job_bonuses_lv50: { str: 2, agi: 9, vit: 2, int: 2, dex: 12, luk: 3 }
  },
  blacksmith: {
    name: "Blacksmith",
    title: "Mastersmith",
    base_aspd: 140.0,
    hp_mod: 1.25,
    sp_mod: 0.8,
    is_ranged: false,
    primary_stat: "str",
    job_bonuses_lv50: { str: 9, agi: 3, vit: 6, int: 2, dex: 8, luk: 2 }
  }
});

export const ELEMENT_TABLE = Object.freeze({
  [Element.NEUTRAL]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 1.0, [Element.WATER]: 1.0, [Element.WIND]: 1.0, [Element.EARTH]: 1.0,
    [Element.HOLY]: 1.0, [Element.SHADOW]: 1.0, [Element.POISON]: 1.0, [Element.UNDEAD]: 1.0
  },
  [Element.FIRE]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 0.25, [Element.WATER]: 0.50, [Element.WIND]: 1.0, [Element.EARTH]: 1.75,
    [Element.HOLY]: 1.0, [Element.SHADOW]: 1.0, [Element.POISON]: 1.0, [Element.UNDEAD]: 1.50
  },
  [Element.WATER]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 1.75, [Element.WATER]: 0.25, [Element.WIND]: 0.50, [Element.EARTH]: 1.0,
    [Element.HOLY]: 1.0, [Element.SHADOW]: 1.0, [Element.POISON]: 1.0, [Element.UNDEAD]: 1.0
  },
  [Element.WIND]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 1.0, [Element.WATER]: 1.75, [Element.WIND]: 0.25, [Element.EARTH]: 0.50,
    [Element.HOLY]: 1.0, [Element.SHADOW]: 1.0, [Element.POISON]: 1.0, [Element.UNDEAD]: 1.0
  },
  [Element.EARTH]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 0.50, [Element.WATER]: 1.0, [Element.WIND]: 1.75, [Element.EARTH]: 0.25,
    [Element.HOLY]: 1.0, [Element.SHADOW]: 1.0, [Element.POISON]: 1.25, [Element.UNDEAD]: 1.0
  },
  [Element.HOLY]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 1.0, [Element.WATER]: 1.0, [Element.WIND]: 1.0, [Element.EARTH]: 1.0,
    [Element.HOLY]: 0.0, [Element.SHADOW]: 1.75, [Element.POISON]: 1.0, [Element.UNDEAD]: 2.0
  },
  [Element.SHADOW]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 1.0, [Element.WATER]: 1.0, [Element.WIND]: 1.0, [Element.EARTH]: 1.0,
    [Element.HOLY]: 1.75, [Element.SHADOW]: 0.0, [Element.POISON]: 0.5, [Element.UNDEAD]: 0.0
  },
  [Element.POISON]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 1.0, [Element.WATER]: 1.0, [Element.WIND]: 1.0, [Element.EARTH]: 1.0,
    [Element.HOLY]: 0.75, [Element.SHADOW]: 0.75, [Element.POISON]: 0.0, [Element.UNDEAD]: 0.5
  },
  [Element.UNDEAD]: {
    [Element.NEUTRAL]: 1.0, [Element.FIRE]: 0.5, [Element.WATER]: 1.0, [Element.WIND]: 1.0, [Element.EARTH]: 1.0,
    [Element.HOLY]: 0.0, [Element.SHADOW]: 0.0, [Element.POISON]: 0.0, [Element.UNDEAD]: 0.0
  }
});

export function createDefaultAttributes(options = {}) {
  return {
    class_id: options.class_id || "knight",
    base_level: Math.max(1, Math.min(options.base_level || 1, MAX_BASE_LEVEL)),
    job_level: Math.max(1, Math.min(options.job_level || 1, MAX_JOB_LEVEL)),
    str: Math.max(1, Math.min(options.str || 1, MAX_STAT_VAL)),
    agi: Math.max(1, Math.min(options.agi || 1, MAX_STAT_VAL)),
    vit: Math.max(1, Math.min(options.vit || 1, MAX_STAT_VAL)),
    int: Math.max(1, Math.min(options.int || 1, MAX_STAT_VAL)),
    dex: Math.max(1, Math.min(options.dex || 1, MAX_STAT_VAL)),
    luk: Math.max(1, Math.min(options.luk || 1, MAX_STAT_VAL)),
    bonus_str: options.bonus_str || 0,
    bonus_agi: options.bonus_agi || 0,
    bonus_vit: options.bonus_vit || 0,
    bonus_int: options.bonus_int || 0,
    bonus_dex: options.bonus_dex || 0,
    bonus_luk: options.bonus_luk || 0,
    weapon_atk: options.weapon_atk || 25,
    weapon_matk: options.weapon_matk || 10,
    refine_atk: options.refine_atk || 0,
    armor_def: options.armor_def || 10,
    shield_def: options.shield_def || 5,
    gear_mdef: options.gear_mdef || 5,
    bonus_hit: options.bonus_hit || 0,
    bonus_flee: options.bonus_flee || 0,
    bonus_crit: options.bonus_crit || 0,
    aspd_buff_percent: options.aspd_buff_percent || 0.0,
    cast_reduc_percent: options.cast_reduc_percent || 0.0,
    element: options.element || Element.NEUTRAL
  };
}

export function computeDerivedStats(attr) {
  const classId = attr.class_id || "knight";
  const profile = CLASS_PROFILES[classId] || CLASS_PROFILES.knight;

  const baseLv = attr.base_level || 1;
  const jobLv = attr.job_level || 1;

  const jobBonusRatio = jobLv / MAX_JOB_LEVEL;
  const jobBonuses = profile.job_bonuses_lv50 || {};

  const totalStr = (attr.str || 1) + (attr.bonus_str || 0) + Math.floor((jobBonuses.str || 0) * jobBonusRatio);
  const totalAgi = (attr.agi || 1) + (attr.bonus_agi || 0) + Math.floor((jobBonuses.agi || 0) * jobBonusRatio);
  const totalVit = (attr.vit || 1) + (attr.bonus_vit || 0) + Math.floor((jobBonuses.vit || 0) * jobBonusRatio);
  const totalInt = (attr.int || 1) + (attr.bonus_int || 0) + Math.floor((jobBonuses.int || 0) * jobBonusRatio);
  const totalDex = (attr.dex || 1) + (attr.bonus_dex || 0) + Math.floor((jobBonuses.dex || 0) * jobBonusRatio);
  const totalLuk = (attr.luk || 1) + (attr.bonus_luk || 0) + Math.floor((jobBonuses.luk || 0) * jobBonusRatio);

  // 1. Max HP
  const hpMod = profile.hp_mod || 1.0;
  const baseHp = 60.0 + (baseLv * hpMod * 22.0);
  const maxHp = Math.floor(baseHp * (1.0 + totalVit * 0.01));

  // 2. Max SP
  const spMod = profile.sp_mod || 1.0;
  const baseSp = 15.0 + (baseLv * spMod * 8.0);
  const maxSp = Math.floor(baseSp * (1.0 + totalInt * 0.01));

  // 3. Status ATK
  const isRanged = !!profile.is_ranged;
  let statusAtk = 0;
  if (isRanged) {
    statusAtk = totalDex + Math.floor(Math.pow(totalDex / 10.0, 2)) + Math.floor(totalStr / 5.0) + Math.floor(totalLuk / 5.0);
  } else {
    statusAtk = totalStr + Math.floor(Math.pow(totalStr / 10.0, 2)) + Math.floor(totalDex / 5.0) + Math.floor(totalLuk / 5.0);
  }

  const weaponAtk = attr.weapon_atk || 0;
  const refineAtk = attr.refine_atk || 0;
  const minAtk = statusAtk + Math.floor(weaponAtk * 0.8) + refineAtk;
  const maxAtk = statusAtk + Math.floor(weaponAtk * 1.2) + refineAtk;
  const avgAtk = Math.floor((minAtk + maxAtk) / 2);

  // 4. MATK
  const weaponMatk = attr.weapon_matk || 0;
  const minMatk = totalInt + Math.floor(Math.pow(totalInt / 7.0, 2)) + weaponMatk;
  const maxMatk = totalInt + Math.floor(Math.pow(totalInt / 5.0, 2)) + weaponMatk;
  const avgMatk = Math.floor((minMatk + maxMatk) / 2);

  // 5. Hit & Flee
  const hit = 175 + baseLv + totalDex + Math.floor(totalLuk / 5.0) + (attr.bonus_hit || 0);
  const flee = 100 + baseLv + totalAgi + Math.floor(totalLuk / 5.0) + (attr.bonus_flee || 0);
  const perfectDodge = 1.0 + (totalLuk * 0.1);

  // 6. Crit Rate
  const critRate = 1.0 + (totalLuk * 0.3) + (attr.bonus_crit || 0);

  // 7. ASPD
  const baseAspd = profile.base_aspd || 140.0;
  const aspdBuff = attr.aspd_buff_percent || 0.0;
  let aspd = 200.0 - (200.0 - baseAspd) * (1.0 - (totalAgi * 4.0 + totalDex) / 1000.0) * (1.0 - aspdBuff / 100.0);
  aspd = Math.max(100.0, Math.min(195.0, aspd));
  const attacksPerSec = 50.0 / Math.max(1.0, 200.0 - aspd);
  const attackDelay = 1.0 / attacksPerSec;

  // 8. DEF & MDEF
  const hardDef = (attr.armor_def || 0) + (attr.shield_def || 0);
  const softDef = Math.floor(totalVit * 0.8) + Math.floor(baseLv / 20.0);
  const hardMdef = attr.gear_mdef || 0;
  const softMdef = totalInt + Math.floor(totalVit / 2.0);

  // 9. Regen & Speed
  const hpRegen = Math.max(1, Math.floor(maxHp * 0.02) + Math.floor(totalVit / 5.0));
  const spRegen = Math.max(1, Math.floor(maxSp * 0.02) + Math.floor(totalInt / 6.0) + 1);
  const moveSpeed = 110.0 + (totalAgi * 0.4);
  const weightLimit = 2000 + (totalStr * 30);

  return {
    class_id: classId,
    base_level: baseLv,
    job_level: jobLv,
    total_str: totalStr,
    total_agi: totalAgi,
    total_vit: totalVit,
    total_int: totalInt,
    total_dex: totalDex,
    total_luk: totalLuk,
    max_hp: maxHp,
    max_sp: maxSp,
    min_atk: minAtk,
    max_atk: maxAtk,
    avg_atk: avgAtk,
    min_matk: minMatk,
    max_matk: maxMatk,
    avg_matk: avgMatk,
    hit,
    flee,
    perfect_dodge: perfectDodge,
    crit_rate: critRate,
    aspd,
    attacks_per_sec: attacksPerSec,
    attack_delay: attackDelay,
    hard_def: hardDef,
    soft_def: softDef,
    hard_mdef: hardMdef,
    soft_mdef: softMdef,
    hp_regen: hpRegen,
    sp_regen: spRegen,
    move_speed: moveSpeed,
    weight_limit: weightLimit,
    element: attr.element || Element.NEUTRAL
  };
}

export function getElementalMultiplier(atkElem, defElem) {
  if (ELEMENT_TABLE[atkElem] && ELEMENT_TABLE[atkElem][defElem] !== undefined) {
    return ELEMENT_TABLE[atkElem][defElem];
  }
  return 1.0;
}

export function calculatePhysicalDamage(attacker, defender, skillId = "", skillLevel = 1, isCrit = false) {
  const defenderPdodge = defender.perfect_dodge || 1.0;
  if (Math.random() * 100.0 < defenderPdodge && !isCrit) {
    return { damage: 0, is_miss: true, is_crit: false, is_perfect_dodge: true, hits: 1 };
  }

  if (!isCrit) {
    const atkHit = attacker.hit || 175;
    const defFlee = defender.flee || 100;
    const rate = Math.max(5.0, Math.min(95.0, 80.0 + (atkHit - defFlee)));
    if (Math.random() * 100.0 > rate) {
      return { damage: 0, is_miss: true, is_crit: false, is_perfect_dodge: false, hits: 1 };
    }
  }

  if (!isCrit && !skillId) {
    const critChance = attacker.crit_rate || 1.0;
    if (Math.random() * 100.0 < critChance) {
      isCrit = true;
    }
  }

  const minA = attacker.min_atk || 20;
  const maxA = attacker.max_atk || 30;
  const rawAtk = Math.floor(Math.random() * (maxA - minA + 1)) + minA;

  let multiplier = 1.0;
  let hits = 1;
  let elem = Element.NEUTRAL;

  if (skillId) {
    const sData = getSkill(skillId);
    if (sData) {
      multiplier = getMultiplier(skillId, skillLevel);
      elem = sData.element || Element.NEUTRAL;
      if (Array.isArray(sData.hits)) {
        const idx = Math.max(0, Math.min(skillLevel - 1, sData.hits.length - 1));
        hits = sData.hits[idx];
      } else if (sData.hits) {
        hits = sData.hits;
      }
    }
  }

  let damageBeforeDef = rawAtk * multiplier;
  const defElem = defender.element || Element.NEUTRAL;
  damageBeforeDef *= getElementalMultiplier(elem, defElem);

  let finalDamage = 0;
  if (isCrit) {
    finalDamage = Math.ceil(damageBeforeDef * 1.4);
  } else {
    const hardDef = defender.hard_def || 0;
    const softDef = defender.soft_def || 0;
    const hardDefMod = Math.max(0.05, (100.0 - hardDef) / 100.0);
    const reduced = (damageBeforeDef * hardDefMod) - softDef;
    finalDamage = Math.max(1, Math.floor(reduced));
  }

  return {
    damage: finalDamage,
    is_miss: false,
    is_crit: isCrit,
    is_perfect_dodge: false,
    hits,
    element: elem
  };
}

export function calculateMagicDamage(attacker, defender, skillId, skillLevel = 1) {
  const sData = getSkill(skillId);
  const elem = sData ? sData.element : Element.NEUTRAL;
  const multiplier = sData ? getMultiplier(skillId, skillLevel) : 1.0;

  let hits = 1;
  if (sData) {
    if (Array.isArray(sData.hits)) {
      const idx = Math.max(0, Math.min(skillLevel - 1, sData.hits.length - 1));
      hits = sData.hits[idx];
    } else if (sData.hits) {
      hits = sData.hits;
    }
  }

  const minM = attacker.min_matk || 30;
  const maxM = attacker.max_matk || 45;
  const rawMatk = Math.floor(Math.random() * (maxM - minM + 1)) + minM;

  let baseDmg = rawMatk * multiplier;
  const defElem = defender.element || Element.NEUTRAL;
  baseDmg *= getElementalMultiplier(elem, defElem);

  const hardMdef = defender.hard_mdef || 0;
  const softMdef = defender.soft_mdef || 0;
  const hardMod = Math.max(0.05, (100.0 - hardMdef) / 100.0);
  const reduced = (baseDmg * hardMod) - softMdef;
  const finalDamage = Math.max(1, Math.floor(reduced));

  return {
    damage: finalDamage,
    is_miss: false,
    is_crit: false,
    hits,
    element: elem
  };
}

export function calculateHealAmount(healer, skillLevel = 10) {
  const baseLv = healer.base_level || 1;
  const intStat = healer.total_int || 1;
  const factor = Math.floor((baseLv + intStat) / 8.0);
  const healVal = factor * (skillLevel * 10);
  return Math.max(50, healVal);
}
