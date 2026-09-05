// skill_database.js
// Chronicles of Midgard - Ragnarok Online x Final Fantasy Multi-Class Skill Tree Database (JS Edition)

export const TargetType = Object.freeze({
  SINGLE_ENEMY: 'SINGLE_ENEMY',
  AOE_ENEMY: 'AOE_ENEMY',
  SINGLE_ALLY: 'SINGLE_ALLY',
  AOE_ALLY: 'AOE_ALLY',
  GROUND: 'GROUND',
  SELF: 'SELF',
  PASSIVE: 'PASSIVE'
});

export const Element = Object.freeze({
  NEUTRAL: 'NEUTRAL',
  FIRE: 'FIRE',
  WATER: 'WATER',
  WIND: 'WIND',
  EARTH: 'EARTH',
  HOLY: 'HOLY',
  SHADOW: 'SHADOW',
  POISON: 'POISON',
  UNDEAD: 'UNDEAD'
});

export const SkillType = Object.freeze({
  PHYSICAL: 'PHYSICAL',
  MAGICAL: 'MAGICAL',
  HYBRID: 'HYBRID',
  SUPPORT_BUFF: 'SUPPORT_BUFF',
  SUPPORT_HEAL: 'SUPPORT_HEAL',
  STATUS_DEBUFF: 'STATUS_DEBUFF',
  PASSIVE: 'PASSIVE',
  TRAP: 'TRAP'
});

export const SKILLS = Object.freeze({
  // ==========================================
  // KNIGHT (LORD KNIGHT / PALADIN)
  // ==========================================
  bash: {
    id: "bash",
    name: "Bash",
    class_id: "knight",
    type: SkillType.PHYSICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: [8, 9, 10, 11, 12, 13, 14, 15, 15, 15],
    cast_time: 0.0,
    cooldown: 0.35,
    range: 48.0,
    area_radius: 0.0,
    base_multiplier: [1.3, 1.6, 1.9, 2.2, 2.5, 2.8, 3.1, 3.4, 3.7, 4.0],
    stun_chance: [0.0, 0.0, 0.0, 0.0, 0.0, 0.05, 0.10, 0.15, 0.20, 0.25],
    hit_bonus: 20,
    description: "Deals massive single-target burst physical damage. Level 6+ adds a chance to stun the target.",
    animation: "bash_slash",
    sfx: "sfx_bash"
  },
  magnum_break: {
    id: "magnum_break",
    name: "Magnum Break",
    class_id: "knight",
    type: SkillType.PHYSICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.FIRE,
    max_level: 10,
    sp_cost: [15, 16, 17, 18, 19, 20, 21, 22, 23, 25],
    hp_cost: 20,
    cast_time: 0.0,
    cooldown: 1.2,
    range: 0.0,
    area_radius: 96.0,
    knockback_force: 120.0,
    base_multiplier: [1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.7, 2.9, 3.1, 3.5],
    buff_duration: 10.0,
    buff_effect: { fire_bonus_atk_percent: 20 },
    description: "Consumes 20 HP to release an explosive ring of fire damage, knocking back all surrounding enemies and granting +20% Fire weapon ATK for 10s.",
    animation: "magnum_explosion",
    sfx: "sfx_explosion"
  },
  provoke: {
    id: "provoke",
    name: "Provoke",
    class_id: "knight",
    type: SkillType.STATUS_DEBUFF,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: [4, 5, 6, 7, 8, 9, 10, 11, 12, 15],
    cast_time: 0.0,
    cooldown: 0.5,
    range: 160.0,
    area_radius: 0.0,
    def_reduction_percent: [10, 15, 20, 25, 30, 35, 40, 45, 50, 55],
    atk_increase_percent: [5, 8, 11, 14, 17, 20, 23, 26, 29, 32],
    threat_multiplier: 5.0,
    duration: 30.0,
    description: "Enrages target monster, forcing aggro onto the Knight. Lowers target DEF while increasing their ATK.",
    animation: "provoke_shout",
    sfx: "sfx_taunt"
  },
  grand_cross: {
    id: "grand_cross",
    name: "Grand Cross",
    class_id: "knight",
    type: SkillType.HYBRID,
    target_type: TargetType.AOE_ENEMY,
    element: Element.HOLY,
    max_level: 10,
    sp_cost: [37, 44, 51, 58, 65, 72, 79, 86, 93, 100],
    hp_cost_percent: 20,
    cast_time: 1.5,
    cooldown: 2.5,
    range: 0.0,
    area_radius: 140.0,
    hits: 3,
    base_multiplier: [1.4, 1.8, 2.2, 2.6, 3.0, 3.4, 3.8, 4.2, 4.6, 5.0],
    blind_chance_undead: 1.0,
    description: "Summons a sacred cross of holy light that deals massive 3-hit hybrid (ATK + MATK) holy damage to surrounding enemies. Drains 20% max HP.",
    animation: "grand_cross_burst",
    sfx: "sfx_holy_cross"
  },
  two_hand_quicken: {
    id: "two_hand_quicken",
    name: "Two-Hand Quicken",
    class_id: "knight",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.SELF,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: [14, 18, 22, 26, 30, 34, 38, 42, 46, 50],
    cast_time: 0.0,
    cooldown: 1.0,
    duration: 180.0,
    buff_effect: { aspd_percent: 30 },
    description: "Temporarily increases physical attack speed (ASPD) by +30% for 3 minutes.",
    animation: "quicken_aura",
    sfx: "sfx_buff"
  },

  // ==========================================
  // WIZARD (HIGH WIZARD / ARCH-MAGE)
  // ==========================================
  fireball: {
    id: "fireball",
    name: "Fireball",
    class_id: "wizard",
    type: SkillType.MAGICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.FIRE,
    max_level: 10,
    sp_cost: [10, 10, 10, 10, 10, 15, 15, 15, 15, 15],
    cast_time: 1.0,
    cooldown: 0.6,
    range: 220.0,
    area_radius: 64.0,
    base_multiplier: [1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8, 3.2],
    description: "Launches a flaming orb at target location, causing a fiery splash explosion damaging the target and nearby enemies.",
    animation: "fireball_projectile",
    sfx: "sfx_fireball"
  },
  frost_nova: {
    id: "frost_nova",
    name: "Frost Nova",
    class_id: "wizard",
    type: SkillType.MAGICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.WATER,
    max_level: 10,
    sp_cost: [20, 22, 24, 26, 28, 30, 32, 34, 36, 40],
    cast_time: 0.4,
    cooldown: 1.2,
    range: 0.0,
    area_radius: 110.0,
    base_multiplier: [1.1, 1.3, 1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.7, 3.0],
    freeze_chance: [0.38, 0.43, 0.48, 0.53, 0.58, 0.63, 0.68, 0.73, 0.78, 0.83],
    freeze_duration: 5.0,
    description: "Emits an instant freezing shockwave around the caster, dealing Water magic damage and freezing targets solid.",
    animation: "frost_ring",
    sfx: "sfx_ice_shatter"
  },
  storm_gust: {
    id: "storm_gust",
    name: "Storm Gust",
    class_id: "wizard",
    type: SkillType.MAGICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.WATER,
    max_level: 10,
    sp_cost: [40, 45, 50, 55, 60, 65, 70, 75, 80, 85],
    cast_time: 3.0,
    cooldown: 3.0,
    range: 220.0,
    area_radius: 160.0,
    hits: 10,
    base_multiplier: [1.0, 1.4, 1.8, 2.2, 2.6, 3.0, 3.4, 3.8, 4.2, 5.0],
    knockback_force: 90.0,
    auto_freeze_hit_count: 3,
    description: "Summons a devastating glacial blizzard over a massive area. Hits enemies up to 10 times, knocking them back and freezing them on the 3rd hit.",
    animation: "blizzard_vortex",
    sfx: "sfx_storm_gust"
  },
  thunderstorm: {
    id: "thunderstorm",
    name: "Thunderstorm",
    class_id: "wizard",
    type: SkillType.MAGICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.WIND,
    max_level: 10,
    sp_cost: [29, 34, 39, 44, 49, 54, 59, 64, 69, 74],
    cast_time: 2.2,
    cooldown: 1.8,
    range: 200.0,
    area_radius: 100.0,
    hits: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    base_multiplier: 0.8,
    description: "Calls down consecutive lightning bolts from the heavens onto target area, dealing multi-hit Wind magic damage.",
    animation: "lightning_barrage",
    sfx: "sfx_thunder"
  },
  safety_wall: {
    id: "safety_wall",
    name: "Safety Wall",
    class_id: "wizard",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.GROUND,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: [30, 30, 30, 35, 35, 35, 40, 40, 40, 40],
    cast_time: 1.2,
    cooldown: 1.0,
    range: 180.0,
    duration: 25.0,
    max_hits_blocked: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    description: "Creates a protective barrier on the ground that completely absorbs physical melee and ranged hits for standing allies.",
    animation: "magic_pillar",
    sfx: "sfx_barrier"
  },

  // ==========================================
  // ASSASSIN (ASSASSIN CROSS / SHADOW BLADE)
  // ==========================================
  double_attack: {
    id: "double_attack",
    name: "Double Attack",
    class_id: "assassin",
    type: SkillType.PASSIVE,
    target_type: TargetType.PASSIVE,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: 0,
    cast_time: 0.0,
    cooldown: 0.0,
    trigger_chance: [0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50],
    second_hit_multiplier: 1.0,
    description: "Passive skill that grants up to a 50% chance to immediately strike a second time on every physical attack.",
    animation: "double_strike_fx",
    sfx: "sfx_double_slash"
  },
  sonic_blow: {
    id: "sonic_blow",
    name: "Sonic Blow",
    class_id: "assassin",
    type: SkillType.PHYSICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: [16, 18, 20, 22, 24, 26, 28, 30, 32, 34],
    cast_time: 0.0,
    cooldown: 1.5,
    range: 52.0,
    area_radius: 0.0,
    hits: 8,
    base_multiplier: [3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 8.0],
    stun_chance: [0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30],
    description: "Unleashes a blinding flurry of 8 continuous strikes on target with high burst physical damage and stun chance.",
    animation: "sonic_rapid_flurry",
    sfx: "sfx_sonic_blow"
  },
  cloaking: {
    id: "cloaking",
    name: "Cloaking",
    class_id: "assassin",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.SELF,
    element: Element.SHADOW,
    max_level: 10,
    sp_cost: 15,
    sp_drain_per_sec: 1,
    cast_time: 0.0,
    cooldown: 0.5,
    speed_modifier: [0.75, 0.80, 0.85, 0.90, 0.95, 1.0, 1.05, 1.10, 1.15, 1.25],
    duration: 300.0,
    description: "Blends into shadows, rendering the Assassin completely invisible to monsters and other players. Attacking breaks cloaking.",
    animation: "smoke_poof",
    sfx: "sfx_stealth"
  },
  poison_slash: {
    id: "poison_slash",
    name: "Poison Slash",
    class_id: "assassin",
    type: SkillType.PHYSICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.POISON,
    max_level: 10,
    sp_cost: [12, 13, 14, 15, 16, 17, 18, 19, 20, 22],
    cast_time: 0.0,
    cooldown: 0.8,
    range: 52.0,
    base_multiplier: [1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.7, 2.9, 3.1, 3.5],
    poison_chance: 0.75,
    poison_duration: 15.0,
    poison_tick_percent: 0.03,
    description: "Strikes target with venomous daggers, dealing Poison damage and poisoning target to lose 3% Max HP per tick and reduce VIT DEF.",
    animation: "poison_drip_slash",
    sfx: "sfx_poison"
  },
  katar_mastery: {
    id: "katar_mastery",
    name: "Katar Mastery",
    class_id: "assassin",
    type: SkillType.PASSIVE,
    target_type: TargetType.PASSIVE,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: 0,
    atk_bonus_flat: [3, 6, 9, 12, 15, 18, 21, 24, 27, 30],
    crit_rate_bonus: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    description: "Increases weapon physical ATK and Critical Rate when equipped with Katars.",
    animation: "",
    sfx: ""
  },

  // ==========================================
  // HIGH PRIEST (CLERIC / BISHOP)
  // ==========================================
  heal: {
    id: "heal",
    name: "Heal",
    class_id: "high_priest",
    type: SkillType.SUPPORT_HEAL,
    target_type: TargetType.SINGLE_ALLY,
    element: Element.HOLY,
    max_level: 10,
    sp_cost: [13, 16, 19, 22, 25, 28, 31, 34, 37, 40],
    cast_time: 0.0,
    cooldown: 0.4,
    range: 220.0,
    heal_level_mult: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    description: "Restores target ally's HP based on (BaseLevel + INT) / 8 * SkillLevel * 10. Deals direct Holy damage if targeted at Undead monsters.",
    animation: "holy_heal_pillar",
    sfx: "sfx_heal"
  },
  blessing: {
    id: "blessing",
    name: "Blessing",
    class_id: "high_priest",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.SINGLE_ALLY,
    element: Element.HOLY,
    max_level: 10,
    sp_cost: [28, 32, 36, 40, 44, 48, 52, 56, 60, 64],
    cast_time: 0.0,
    cooldown: 0.5,
    range: 220.0,
    duration: 240.0,
    stat_bonus: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    cures_curse_stone: true,
    description: "Grants target ally +1 to +10 STR, INT, and DEX for 4 minutes. Cures Curse and Stone Curse status ailments.",
    animation: "golden_aura",
    sfx: "sfx_blessing"
  },
  increase_agi: {
    id: "increase_agi",
    name: "Increase AGI",
    class_id: "high_priest",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.SINGLE_ALLY,
    element: Element.HOLY,
    max_level: 10,
    sp_cost: [18, 21, 24, 27, 30, 33, 36, 39, 42, 45],
    hp_cost: 15,
    cast_time: 0.0,
    cooldown: 0.5,
    range: 220.0,
    duration: 240.0,
    agi_bonus: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    move_speed_percent: 25.0,
    description: "Consumes 15 HP to increase target ally's AGI by up to +12 and increases movement speed by +25% for 4 minutes.",
    animation: "wind_wings",
    sfx: "sfx_speed_buff"
  },
  sanctuary: {
    id: "sanctuary",
    name: "Sanctuary",
    class_id: "high_priest",
    type: SkillType.SUPPORT_HEAL,
    target_type: TargetType.GROUND,
    element: Element.HOLY,
    max_level: 10,
    sp_cost: [15, 18, 21, 24, 27, 30, 33, 36, 39, 42],
    gemstone_cost: 1,
    cast_time: 2.0,
    cooldown: 2.0,
    range: 180.0,
    area_radius: 120.0,
    duration: 30.0,
    heal_per_second: [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000],
    max_targets: [4, 6, 8, 10, 12, 14, 16, 18, 20, 24],
    description: "Creates a consecrated holy zone on the ground that continuously heals all standing allies and deals holy damage to Undead.",
    animation: "sanctuary_carpet",
    sfx: "sfx_sanctuary"
  },
  holy_light: {
    id: "holy_light",
    name: "Holy Light",
    class_id: "high_priest",
    type: SkillType.MAGICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.HOLY,
    max_level: 1,
    sp_cost: 15,
    cast_time: 0.8,
    cooldown: 0.3,
    range: 220.0,
    base_multiplier: 1.25,
    description: "Fires a concentrated beam of divine holy energy at target, dealing 125% Holy magic attack damage.",
    animation: "holy_beam",
    sfx: "sfx_holy_beam"
  },

  // ==========================================
  // HUNTER (SNIPER / RANGER)
  // ==========================================
  double_strafe: {
    id: "double_strafe",
    name: "Double Strafe",
    class_id: "hunter",
    type: SkillType.PHYSICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: 12,
    ammo_cost: 2,
    cast_time: 0.0,
    cooldown: 0.35,
    range: 260.0,
    hits: 2,
    base_multiplier: [2.0, 2.2, 2.4, 2.6, 2.8, 3.0, 3.2, 3.4, 3.6, 3.8],
    hit_bonus: 15,
    description: "Fires two rapid arrows at target with pinpoint accuracy dealing high burst ranged physical damage.",
    animation: "arrow_double_shot",
    sfx: "sfx_arrow_double"
  },
  arrow_shower: {
    id: "arrow_shower",
    name: "Arrow Shower",
    class_id: "hunter",
    type: SkillType.PHYSICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: 15,
    ammo_cost: 5,
    cast_time: 0.0,
    cooldown: 0.8,
    range: 240.0,
    area_radius: 90.0,
    knockback_force: 64.0,
    base_multiplier: [1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1, 2.2, 2.5],
    description: "Volleys an arrow volley into a target area, dealing ranged damage to all enemies within and knocking them back.",
    animation: "arrow_rain",
    sfx: "sfx_arrow_rain"
  },
  falcon_assault: {
    id: "falcon_assault",
    name: "Falcon Assault",
    class_id: "hunter",
    type: SkillType.PHYSICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 5,
    sp_cost: [30, 34, 38, 42, 46],
    cast_time: 0.5,
    cooldown: 1.0,
    range: 260.0,
    hits: 5,
    falcon_mult: [2.2, 2.8, 3.4, 4.0, 5.0],
    ignores_def: true,
    description: "Commands the trained hunting falcon to relentlessly dive-bomb the enemy, dealing 5 rapid hits that completely bypass target DEF (scales with DEX & INT).",
    animation: "falcon_dive",
    sfx: "sfx_falcon_screech"
  },
  ankle_snare: {
    id: "ankle_snare",
    name: "Ankle Snare",
    class_id: "hunter",
    type: SkillType.TRAP,
    target_type: TargetType.GROUND,
    element: Element.EARTH,
    max_level: 5,
    sp_cost: 12,
    trap_item_cost: 1,
    cast_time: 0.0,
    cooldown: 0.5,
    range: 160.0,
    trigger_radius: 24.0,
    snare_duration: [5.0, 10.0, 15.0, 20.0, 25.0],
    max_active_traps: 3,
    description: "Lays a concealed steel trap on the ground. Any monster or enemy walking over it is completely rooted in place.",
    animation: "trap_snap",
    sfx: "sfx_trap_snap"
  },
  blitz_beat: {
    id: "blitz_beat",
    name: "Blitz Beat",
    class_id: "hunter",
    type: SkillType.PHYSICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 5,
    sp_cost: [10, 13, 16, 19, 22],
    cast_time: 0.0,
    cooldown: 0.8,
    range: 260.0,
    area_radius: 60.0,
    hits: [1, 2, 3, 4, 5],
    auto_proc_luk_scaling: true,
    description: "Falcon flies out and strikes target area. Can trigger automatically during standard bow attacks based on LUK.",
    animation: "falcon_swoop",
    sfx: "sfx_falcon_screech"
  },

  // ==========================================
  // BLACKSMITH (MASTERSMITH / FORGEMASTER)
  // ==========================================
  mammonite: {
    id: "mammonite",
    name: "Mammonite",
    class_id: "blacksmith",
    type: SkillType.PHYSICAL,
    target_type: TargetType.SINGLE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 10,
    sp_cost: 5,
    gold_cost: [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000],
    cast_time: 0.0,
    cooldown: 0.3,
    range: 48.0,
    base_multiplier: [1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0],
    description: "Sacrifices Zeny (gold) to deliver an earth-shattering blow with the blacksmith's heavy hammer dealing up to 600% damage.",
    animation: "coin_explosion_slam",
    sfx: "sfx_coin_smash"
  },
  cart_revolution: {
    id: "cart_revolution",
    name: "Cart Revolution",
    class_id: "blacksmith",
    type: SkillType.PHYSICAL,
    target_type: TargetType.AOE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 1,
    sp_cost: 12,
    cast_time: 0.0,
    cooldown: 0.6,
    range: 0.0,
    area_radius: 80.0,
    knockback_force: 128.0,
    base_multiplier: 2.5,
    cart_weight_scaling: true,
    description: "Swings the heavy merchant cart 360 degrees, damaging and knocking back all surrounding enemies based on cart weight.",
    animation: "cart_spin",
    sfx: "sfx_heavy_swing"
  },
  weapon_perfection: {
    id: "weapon_perfection",
    name: "Weapon Perfection",
    class_id: "blacksmith",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.AOE_ALLY,
    element: Element.NEUTRAL,
    max_level: 5,
    sp_cost: [18, 22, 26, 30, 34],
    cast_time: 0.0,
    cooldown: 1.0,
    range: 0.0,
    area_radius: 200.0,
    duration: [30.0, 60.0, 90.0, 120.0, 150.0],
    party_buff: true,
    buff_effect: { ignore_size_penalty: true, size_mod_100: true },
    description: "Grants the party perfect weapon balance, nullifying all weapon size penalties against Small, Medium, and Large monsters (100% damage).",
    animation: "weapon_glow_ring",
    sfx: "sfx_buff_anvil"
  },
  adrenaline_rush: {
    id: "adrenaline_rush",
    name: "Adrenaline Rush",
    class_id: "blacksmith",
    type: SkillType.SUPPORT_BUFF,
    target_type: TargetType.AOE_ALLY,
    element: Element.NEUTRAL,
    max_level: 5,
    sp_cost: [20, 23, 26, 29, 32],
    cast_time: 0.0,
    cooldown: 1.0,
    range: 0.0,
    area_radius: 200.0,
    duration: [30.0, 60.0, 90.0, 120.0, 150.0],
    party_buff: true,
    buff_effect: { aspd_percent: 30, axe_mace_only: true },
    description: "Pumps adrenaline into the Blacksmith and party members, increasing attack speed (ASPD) by +30% for axe and mace weapons.",
    animation: "red_steam_aura",
    sfx: "sfx_adrenaline"
  },
  hammer_fall: {
    id: "hammer_fall",
    name: "Hammer Fall",
    class_id: "blacksmith",
    type: SkillType.STATUS_DEBUFF,
    target_type: TargetType.AOE_ENEMY,
    element: Element.NEUTRAL,
    max_level: 5,
    sp_cost: 10,
    cast_time: 0.0,
    cooldown: 0.5,
    range: 120.0,
    area_radius: 80.0,
    stun_chance: [0.30, 0.40, 0.50, 0.60, 0.70],
    stun_duration: 5.0,
    description: "Slams the blacksmith hammer onto the ground, unleashing a shockwave with up to 70% chance to stun all targets in area.",
    animation: "ground_fracture",
    sfx: "sfx_hammer_slam"
  }
});

export function getSkillsForClass(classId) {
  return Object.values(SKILLS).filter(s => s.class_id === classId);
}

export function getSkill(skillId) {
  return SKILLS[skillId] || null;
}

export function getSpCost(skillId, level = 1) {
  const skill = getSkill(skillId);
  if (!skill) return 0;
  if (Array.isArray(skill.sp_cost)) {
    const idx = Math.max(0, Math.min(level - 1, skill.sp_cost.length - 1));
    return skill.sp_cost[idx];
  }
  return Number(skill.sp_cost) || 0;
}

export function getMultiplier(skillId, level = 1) {
  const skill = getSkill(skillId);
  if (!skill) return 1.0;
  if (Array.isArray(skill.base_multiplier)) {
    const idx = Math.max(0, Math.min(level - 1, skill.base_multiplier.length - 1));
    return skill.base_multiplier[idx];
  }
  return Number(skill.base_multiplier) || 1.0;
}

export function calculateCastTime(skillId, dex = 1, buffCastReducPercent = 0.0) {
  const skill = getSkill(skillId);
  if (!skill || !skill.cast_time || skill.cast_time <= 0) return 0;
  const dexFactor = Math.max(0, 1.0 - (dex / 150.0));
  const buffFactor = Math.max(0, 1.0 - (buffCastReducPercent / 100.0));
  return skill.cast_time * dexFactor * buffFactor;
}

export const SkillDatabase = Object.freeze({
  TargetType,
  Element,
  SkillType,
  SKILLS,
  getSkillsForClass,
  getSkill,
  getSpCost,
  getMultiplier,
  calculateCastTime
});
