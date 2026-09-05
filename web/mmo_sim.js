// mmo_sim.js
// Chronicles of Midgard - 50-100 Concurrent Player Simulator & MMO Ecosystem Engine (JS Edition)

import { Element, SkillDatabase, getSkill, getMultiplier } from './skill_database.js';
import {
  CLASS_PROFILES,
  createDefaultAttributes,
  computeDerivedStats,
  calculatePhysicalDamage,
  calculateMagicDamage,
  calculateHealAmount,
  MAX_BASE_LEVEL,
  MAX_JOB_LEVEL
} from './stat_engine.js';

export const AIState = Object.freeze({
  CITY_CHATTING: 'CITY_CHATTING',
  SOLO_GRINDING: 'SOLO_GRINDING',
  PARTY_DUNGEON: 'PARTY_DUNGEON',
  MVP_HUNTING: 'MVP_HUNTING',
  DEAD_RESPAWNING: 'DEAD_RESPAWNING'
});

export const DEFAULT_PLAYER_COUNT = 65;
export const MAX_PLAYER_COUNT = 100;
export const SPATIAL_CELL_SIZE = 128.0;

export const FIRST_NAMES = [
  "Valkyrie", "Shadow", "Grand", "Loki", "Saint", "Sniper", "Katar", "Zeny",
  "Lord", "Frost", "Cart", "Arcane", "Holy", "Iron", "Elven", "Crimson",
  "Silver", "Rune", "Mystic", "Ares", "Diana", "Zero", "Nova", "Vesper",
  "Chrono", "Aegis", "Klaus", "Freya", "Thor", "Odin", "Gwen", "Sora"
];

export const LAST_NAMES = [
  "Rose", "Striker", "Templar", "Dagger", "Maiden", "Wolf", "Master", "Merchant",
  "Ares", "Mage", "Drifter", "Sage", "Blade", "Forgemaster", "Marksman", "Theresa",
  "Knight", "Healer", "Sniper", "Hunter", "Cross", "Walker", "Bane", "Heart",
  "Storm", "Gale", "Shadow", "Soul", "Fang", "Seeker", "Shield", "Falcon"
];

export const GUILD_NAMES = [
  "[Valhalla]", "[Prontera Knights]", "[Shadow Syndicate]", "[Morroc Assassins]",
  "[Geffen Arcana]", "[Midgard Crusaders]", "[Payon Rangers]", "[Alberta Merchants]",
  "[Einbroch Guild]", "[Niflheim Phantoms]", "[Sanctuary of Light]", "[Odin's Oath]"
];

export const HEADGEARS = [
  "Angel Wings", "Majestic Goat", "Crown of Glory", "Elven Ears", "Wizard Hat",
  "Corsair", "Bunny Band", "Pirate Bandana", "Sakkat", "Gossip Raven", "None"
];

export const CHAT_BANTER_CITY = [
  "Need Priest for Catacombs dungeon run!",
  "Buying Elunium and Oridecon PM me!",
  "Selling +8 Infiltrator and +7 Gakkung Bow!",
  "Looking for active Guild [Valhalla] rec!",
  "Where does the MVP boss spawn next?",
  "AFK vending in Prontera center ^^",
  "Trading Lv.70 Knight for High Priest gear!",
  "/sit enjoying the fountain vibes~",
  "Congrats to guild for winning Emperium castle!"
];

export const CHAT_BANTER_COMBAT = [
  "Tank pull 3 more mobs, I got AOE ready!",
  "Level UP! Stat points into DEX & INT!",
  "Storm Gust freezing the mob pack!",
  "Mammonite smash!! $$$ spent!",
  "Out of Blue Potions, Priest bless please!",
  "Sonic Blow burst is insane!",
  "Sanctuary carpet placed, stay inside!",
  "Falcon auto-blitz procced!",
  "Grand Cross holy light purify them!"
];

export const CHAT_BANTER_MVP = [
  "MVP Baphomet is casting Earthquake, dodge!",
  "Taunting MVP, dps go all out!",
  "Healers focus tank! Keep Sanctuary up!",
  "Storm Gust the MVP adds!",
  "Falcon Assault DEF-ignore dpsing!",
  "MVP is at 10% HP! Execute!!"
];

export const CHAT_BANTER_DEATH = [
  "Oof, lagged right into the mob train x_x",
  "Resurrection please or running back...",
  "Respawning at Prontera Cathedral!",
  "Don't release, Priest has Yggdrasil Leaf!"
];

export class MMOEngine {
  constructor(options = {}) {
    this.playerCount = options.playerCount || DEFAULT_PLAYER_COUNT;
    this.simulatedPlayers = [];
    this.parties = new Map();
    this.spatialGrid = new Map();
    this.chatLog = [];
    this.mvpBoss = null;
    this.cityCenter = { x: 300, y: 300 };
    this.dungeonCenter = { x: 1150, y: 850 };
    this.cathedralPos = { x: 180, y: 180 };
    this.mapBounds = { minX: 32, minY: 32, maxX: 1536, maxY: 1216 };
    this.listeners = [];

    this.initializeEcosystem(this.playerCount);
  }

  onEvent(callback) {
    this.listeners.push(callback);
  }

  emitEvent(type, message, data = {}) {
    for (const cb of this.listeners) {
      try {
        cb({ type, message, data });
      } catch (err) {
        console.error("MMO Event Callback Error:", err);
      }
    }
  }

  initializeEcosystem(playerCount = DEFAULT_PLAYER_COUNT) {
    this.simulatedPlayers = [];
    this.parties.clear();
    this.spatialGrid.clear();
    this.chatLog = [];

    const count = Math.max(20, Math.min(playerCount, MAX_PLAYER_COUNT));
    const classKeys = Object.keys(CLASS_PROFILES);

    for (let i = 0; i < count; i++) {
      const fn = FIRST_NAMES[Math.floor(Math.random() * FIRST_NAMES.length)];
      const ln = LAST_NAMES[Math.floor(Math.random() * LAST_NAMES.length)];
      const classId = classKeys[i % classKeys.length];
      const guild = GUILD_NAMES[Math.floor(Math.random() * GUILD_NAMES.length)];
      const headgear = HEADGEARS[Math.floor(Math.random() * HEADGEARS.length)];
      const weaponRefine = Math.floor(Math.random() * 7) + 4; // +4 to +10

      const baseLevel = Math.floor(Math.random() * 71) + 25; // 25 to 95
      const jobLevel = Math.max(10, Math.min(50, Math.floor(baseLevel * 0.55)));
      const gold = Math.floor(Math.random() * 245000) + 5000;

      const player = {
        id: `player_${String(i + 1).padStart(3, '0')}`,
        name: `${fn}_${ln}`,
        guild,
        class_id: classId,
        headgear,
        weapon_refine: weaponRefine,
        is_bot: true,
        position: { x: 0, y: 0 },
        target_position: { x: 0, y: 0 },
        facing_dir: { x: 0, y: 1 },
        base_level: baseLevel,
        job_level: jobLevel,
        xp: 0,
        xp_to_next: 100,
        gold,
        state: AIState.SOLO_GRINDING,
        state_timer: 0.0,
        party_id: "",
        attack_cooldown_timer: 0.0,
        skill_cooldown_timer: 0.0,
        active_buffs: {},
        current_chat_text: "",
        chat_bubble_timer: 0.0,
        chat_channel: "Local",
        is_alive: true,
        hp: 100,
        max_hp: 100,
        sp: 50,
        max_sp: 50,
        stats: {}
      };

      this.setupPlayerStats(player);

      const stateRoll = Math.random();
      if (stateRoll < 0.25) {
        player.state = AIState.CITY_CHATTING;
        player.position = {
          x: this.cityCenter.x + (Math.random() * 280 - 140),
          y: this.cityCenter.y + (Math.random() * 280 - 140)
        };
      } else if (stateRoll < 0.70) {
        player.state = AIState.SOLO_GRINDING;
        player.position = {
          x: Math.random() * 1200 + 200,
          y: Math.random() * 900 + 200
        };
      } else {
        player.state = AIState.PARTY_DUNGEON;
        player.position = {
          x: this.dungeonCenter.x + (Math.random() * 400 - 200),
          y: this.dungeonCenter.y + (Math.random() * 400 - 200)
        };
      }

      player.target_position = { ...player.position };
      player.hp = player.max_hp;
      player.sp = player.max_sp;

      this.simulatedPlayers.push(player);
    }

    this.formInitialParties();
    this.spawnWorldBoss();
    this.broadcastChat("Server", `Chronicles of Midgard MMO Server initialized with ${count} simulated adventurers!`, "World");
  }

  setupPlayerStats(player) {
    const totalPoints = player.base_level * 5 + 40;
    let p_str = 5, p_agi = 5, p_vit = 5, p_int = 5, p_dex = 5, p_luk = 5;

    switch (player.class_id) {
      case 'knight':
        p_str += Math.floor(totalPoints * 0.45);
        p_vit += Math.floor(totalPoints * 0.35);
        p_dex += Math.floor(totalPoints * 0.15);
        p_agi += Math.floor(totalPoints * 0.05);
        break;
      case 'wizard':
        p_int += Math.floor(totalPoints * 0.55);
        p_dex += Math.floor(totalPoints * 0.35);
        p_vit += Math.floor(totalPoints * 0.10);
        break;
      case 'assassin':
        p_agi += Math.floor(totalPoints * 0.45);
        p_str += Math.floor(totalPoints * 0.30);
        p_luk += Math.floor(totalPoints * 0.15);
        p_dex += Math.floor(totalPoints * 0.10);
        break;
      case 'high_priest':
        p_int += Math.floor(totalPoints * 0.45);
        p_vit += Math.floor(totalPoints * 0.35);
        p_dex += Math.floor(totalPoints * 0.20);
        break;
      case 'hunter':
        p_dex += Math.floor(totalPoints * 0.55);
        p_agi += Math.floor(totalPoints * 0.30);
        p_luk += Math.floor(totalPoints * 0.15);
        break;
      case 'blacksmith':
        p_str += Math.floor(totalPoints * 0.45);
        p_dex += Math.floor(totalPoints * 0.30);
        p_vit += Math.floor(totalPoints * 0.20);
        p_agi += Math.floor(totalPoints * 0.05);
        break;
    }

    const raw = createDefaultAttributes({
      class_id: player.class_id,
      base_level: player.base_level,
      job_level: player.job_level,
      str: p_str,
      agi: p_agi,
      vit: p_vit,
      int: p_int,
      dex: p_dex,
      luk: p_luk,
      refine_atk: player.weapon_refine * 7,
      armor_def: 15 + player.weapon_refine * 2
    });

    player.raw_attributes = raw;
    player.stats = computeDerivedStats(raw);
    player.max_hp = player.stats.max_hp;
    player.max_sp = player.stats.max_sp;
  }

  formInitialParties() {
    let partyIndex = 1;
    const dungeonPlayers = this.simulatedPlayers.filter(p => p.state === AIState.PARTY_DUNGEON);

    while (dungeonPlayers.length >= 3) {
      const partyId = `party_${String(partyIndex).padStart(2, '0')}`;
      const leader = dungeonPlayers.shift();
      const party = {
        party_id: partyId,
        name: `${leader.guild} Raid Team ${partyIndex}`,
        leader_id: leader.id,
        member_ids: [leader.id],
        target_zone: "Catacombs",
        exp_share: true,
        getExpBonus() {
          return 1.0 + Math.max(0, this.member_ids.length - 1) * 0.20;
        }
      };
      leader.party_id = partyId;

      const size = Math.min(dungeonPlayers.length, Math.floor(Math.random() * 3) + 2);
      for (let j = 0; j < size; j++) {
        const mem = dungeonPlayers.shift();
        mem.party_id = partyId;
        party.member_ids.push(mem.id);
      }

      this.parties.set(partyId, party);
      partyIndex++;
    }
  }

  spawnWorldBoss() {
    this.mvpBoss = {
      id: "mvp_baphomet",
      name: "Baphomet [MVP]",
      position: { ...this.dungeonCenter },
      hp: 15000,
      max_hp: 15000,
      base_level: 88,
      hard_def: 35,
      hard_mdef: 40,
      element: Element.SHADOW,
      is_alive: true,
      aggro_table: new Map(),
      attack_cooldown: 0.0
    };
    this.emitEvent("mvp_spawned", `MVP ${this.mvpBoss.name} spawned!`, { position: this.mvpBoss.position });
    this.broadcastChat("MVP Broadcaster", `Warning: [MVP] ${this.mvpBoss.name} has spawned in the Magma Caverns!`, "World");
  }

  updateSimulation(delta) {
    this.rebuildSpatialGrid();

    for (const player of this.simulatedPlayers) {
      this.updatePlayer(player, delta);
    }

    if (this.mvpBoss && this.mvpBoss.is_alive) {
      this.updateMvpBoss(delta);
    }
  }

  rebuildSpatialGrid() {
    this.spatialGrid.clear();
    for (const p of this.simulatedPlayers) {
      if (!p.is_alive) continue;
      const cx = Math.floor(p.position.x / SPATIAL_CELL_SIZE);
      const cy = Math.floor(p.position.y / SPATIAL_CELL_SIZE);
      const key = `${cx},${cy}`;
      if (!this.spatialGrid.has(key)) {
        this.spatialGrid.set(key, []);
      }
      this.spatialGrid.get(key).push(p);
    }
  }

  queryNearbyPlayers(pos, radius) {
    const result = [];
    const minCx = Math.floor((pos.x - radius) / SPATIAL_CELL_SIZE);
    const maxCx = Math.floor((pos.x + radius) / SPATIAL_CELL_SIZE);
    const minCy = Math.floor((pos.y - radius) / SPATIAL_CELL_SIZE);
    const maxCy = Math.floor((pos.y + radius) / SPATIAL_CELL_SIZE);
    const rSq = radius * radius;

    for (let cx = minCx; cx <= maxCx; cx++) {
      for (let cy = minCy; cy <= maxCy; cy++) {
        const key = `${cx},${cy}`;
        const cell = this.spatialGrid.get(key);
        if (cell) {
          for (const other of cell) {
            const dx = pos.x - other.position.x;
            const dy = pos.y - other.position.y;
            if (dx * dx + dy * dy <= rSq) {
              result.push(other);
            }
          }
        }
      }
    }
    return result;
  }

  updatePlayer(player, delta) {
    player.state_timer -= delta;
    player.attack_cooldown_timer = Math.max(0, player.attack_cooldown_timer - delta);
    player.skill_cooldown_timer = Math.max(0, player.skill_cooldown_timer - delta);

    if (player.chat_bubble_timer > 0) {
      player.chat_bubble_timer -= delta;
      if (player.chat_bubble_timer <= 0) {
        player.current_chat_text = "";
      }
    }

    for (const buff in player.active_buffs) {
      player.active_buffs[buff] -= delta;
      if (player.active_buffs[buff] <= 0) {
        delete player.active_buffs[buff];
        this.applyBuffModifiers(player);
      }
    }

    switch (player.state) {
      case AIState.CITY_CHATTING:
        this.processCityChatting(player, delta);
        break;
      case AIState.SOLO_GRINDING:
        this.processSoloGrinding(player, delta);
        break;
      case AIState.PARTY_DUNGEON:
        this.processPartyDungeon(player, delta);
        break;
      case AIState.MVP_HUNTING:
        this.processMvpHunting(player, delta);
        break;
      case AIState.DEAD_RESPAWNING:
        this.processDeadRespawning(player, delta);
        break;
    }
  }

  processCityChatting(player, delta) {
    player.hp = Math.min(player.max_hp, player.hp + Math.floor(player.stats.hp_regen * delta * 2.0));
    player.sp = Math.min(player.max_sp, player.sp + Math.floor(player.stats.sp_regen * delta * 2.0));

    const dx = player.target_position.x - player.position.x;
    const dy = player.target_position.y - player.position.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (dist < 10 || player.state_timer <= 0) {
      player.target_position = {
        x: this.cityCenter.x + (Math.random() * 240 - 120),
        y: this.cityCenter.y + (Math.random() * 240 - 120)
      };
      player.state_timer = Math.random() * 10 + 8;

      if (Math.random() < 0.40) {
        const banter = CHAT_BANTER_CITY[Math.floor(Math.random() * CHAT_BANTER_CITY.length)];
        this.setPlayerChat(player, banter, "Local");
      }

      if (Math.random() < 0.15) {
        player.state = AIState.SOLO_GRINDING;
        player.target_position = {
          x: Math.random() * 900 + 400,
          y: Math.random() * 700 + 300
        };
      }
    }

    this.moveTowards(player, player.target_position, player.stats.move_speed * 0.4, delta);
  }

  processSoloGrinding(player, delta) {
    player.hp = Math.min(player.max_hp, player.hp + Math.floor(player.stats.hp_regen * delta * 0.3));
    player.sp = Math.min(player.max_sp, player.sp + Math.floor(player.stats.sp_regen * delta * 0.3));

    if (player.class_id === 'high_priest') {
      this.handleHealerAi(player);
    } else if (player.class_id === 'knight') {
      this.handleTankAi(player);
    }

    const dx = player.target_position.x - player.position.x;
    const dy = player.target_position.y - player.position.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (dist < 20 || player.state_timer <= 0) {
      player.target_position = {
        x: Math.random() * 1200 + 200,
        y: Math.random() * 900 + 200
      };
      player.state_timer = Math.random() * 6 + 4;

      if (Math.random() < 0.60) {
        this.executeClassCombatAction(player);
      }

      if (Math.random() < 0.12) {
        const banter = CHAT_BANTER_COMBAT[Math.floor(Math.random() * CHAT_BANTER_COMBAT.length)];
        this.setPlayerChat(player, banter, "Party");
      }
    }

    this.moveTowards(player, player.target_position, player.stats.move_speed, delta);
  }

  processPartyDungeon(player, delta) {
    if (player.class_id === 'high_priest') {
      this.handleHealerAi(player);
    } else if (player.class_id === 'knight') {
      this.handleTankAi(player);
    }

    const party = this.parties.get(player.party_id);
    if (party) {
      const leader = this.getPlayerById(party.leader_id);
      if (leader && leader.id !== player.id) {
        let offset = { x: 0, y: 0 };
        switch (player.class_id) {
          case 'knight': offset = { x: 0, y: -32 }; break;
          case 'assassin':
          case 'blacksmith': offset = { x: 32, y: 0 }; break;
          case 'hunter':
          case 'wizard': offset = { x: -32, y: 32 }; break;
          case 'high_priest': offset = { x: 0, y: 48 }; break;
        }
        player.target_position = {
          x: leader.position.x + offset.x,
          y: leader.position.y + offset.y
        };
      } else {
        const dx = player.target_position.x - player.position.x;
        const dy = player.target_position.y - player.position.y;
        if (Math.sqrt(dx * dx + dy * dy) < 25 || player.state_timer <= 0) {
          player.target_position = {
            x: this.dungeonCenter.x + (Math.random() * 300 - 150),
            y: this.dungeonCenter.y + (Math.random() * 300 - 150)
          };
          player.state_timer = Math.random() * 7 + 5;
        }
      }
    }

    if (player.skill_cooldown_timer <= 0) {
      this.executeClassCombatAction(player);
    }

    this.moveTowards(player, player.target_position, player.stats.move_speed, delta);
  }

  processMvpHunting(player, delta) {
    if (!this.mvpBoss || !this.mvpBoss.is_alive) {
      player.state = AIState.PARTY_DUNGEON;
      return;
    }

    const dx = this.mvpBoss.position.x - player.position.x;
    const dy = this.mvpBoss.position.y - player.position.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const optimalRange = ['knight', 'assassin', 'blacksmith'].includes(player.class_id) ? 48 : 180;

    if (dist > optimalRange) {
      this.moveTowards(player, this.mvpBoss.position, player.stats.move_speed, delta);
    } else {
      if (player.attack_cooldown_timer <= 0) {
        this.executeMvpAttack(player);
      }
    }

    if (player.class_id === 'high_priest') {
      this.handleHealerAi(player);
    } else if (player.class_id === 'knight') {
      this.handleTankAi(player, true);
    }
  }

  processDeadRespawning(player, delta) {
    if (player.state_timer > 0) {
      player.hp = Math.min(player.max_hp, player.hp + Math.floor(player.max_hp * delta * 0.35));
      if (player.hp >= player.max_hp * 0.8) {
        player.is_alive = true;
        player.state = AIState.SOLO_GRINDING;
        player.target_position = {
          x: this.cityCenter.x + (Math.random() * 200 - 100),
          y: this.cityCenter.y + (Math.random() * 200 - 100)
        };
      }
    } else {
      player.position = {
        x: this.cathedralPos.x + (Math.random() * 80 - 40),
        y: this.cathedralPos.y + (Math.random() * 80 - 40)
      };
      player.state_timer = 5.0;
      const banter = CHAT_BANTER_DEATH[Math.floor(Math.random() * CHAT_BANTER_DEATH.length)];
      this.setPlayerChat(player, banter, "Party");
    }
  }

  handleHealerAi(healer) {
    const nearby = this.queryNearbyPlayers(healer.position, 240.0);
    let lowestHpPlayer = null;
    let lowestHpPct = 1.0;

    for (const ally of nearby) {
      if (!ally.is_alive) continue;
      const pct = ally.hp / ally.max_hp;
      if (pct < lowestHpPct) {
        lowestHpPct = pct;
        lowestHpPlayer = ally;
      }
    }

    if (lowestHpPlayer && lowestHpPct < 0.75 && healer.sp >= 25 && healer.skill_cooldown_timer <= 0) {
      const healAmount = calculateHealAmount(healer.stats, 10);
      lowestHpPlayer.hp = Math.min(lowestHpPlayer.max_hp, lowestHpPlayer.hp + healAmount);
      healer.sp -= 25;
      healer.skill_cooldown_timer = 0.5;
      if (Math.random() < 0.25) {
        this.setPlayerChat(healer, `Heal -> ${lowestHpPlayer.name} (+${healAmount} HP)`, "Party");
      }
      return;
    }

    for (const ally of nearby) {
      if (!ally.active_buffs.blessing && healer.sp >= 40 && healer.skill_cooldown_timer <= 0) {
        ally.active_buffs.blessing = 240.0;
        healer.sp -= 40;
        healer.skill_cooldown_timer = 0.4;
        this.applyBuffModifiers(ally);
        return;
      }
      if (!ally.active_buffs.increase_agi && healer.sp >= 30 && healer.skill_cooldown_timer <= 0) {
        ally.active_buffs.increase_agi = 240.0;
        healer.sp -= 30;
        healer.skill_cooldown_timer = 0.4;
        this.applyBuffModifiers(ally);
        return;
      }
    }
  }

  handleTankAi(tank, isMvp = false) {
    if (isMvp && this.mvpBoss && this.mvpBoss.is_alive && tank.skill_cooldown_timer <= 0) {
      if (tank.sp >= 10) {
        tank.sp -= 10;
        tank.skill_cooldown_timer = 1.5;
        const curThreat = this.mvpBoss.aggro_table.get(tank.id) || 0;
        this.mvpBoss.aggro_table.set(tank.id, curThreat + 1500);
        if (Math.random() < 0.35) {
          this.setPlayerChat(tank, "Provoke! Holding MVP aggro!", "Party");
        }
      }
    }
  }

  applyBuffModifiers(player) {
    player.raw_attributes.bonus_str = player.active_buffs.blessing ? 10 : 0;
    player.raw_attributes.bonus_int = player.active_buffs.blessing ? 10 : 0;
    player.raw_attributes.bonus_dex = player.active_buffs.blessing ? 10 : 0;
    player.raw_attributes.bonus_agi = player.active_buffs.increase_agi ? 12 : 0;
    player.raw_attributes.aspd_buff_percent = (player.active_buffs.two_hand_quicken || player.active_buffs.adrenaline_rush) ? 30.0 : 0.0;

    player.stats = computeDerivedStats(player.raw_attributes);
  }

  executeClassCombatAction(player) {
    player.attack_cooldown_timer = player.stats.attack_delay;
    player.skill_cooldown_timer = 1.2;

    let expGained = Math.floor(Math.random() * 55) + 30;
    const party = this.parties.get(player.party_id);
    if (party) {
      expGained = Math.floor(expGained * party.getExpBonus());
    }

    player.xp += expGained;
    player.gold += Math.floor(Math.random() * 40) + 10;

    if (player.xp >= player.xp_to_next) {
      this.levelUpPlayer(player);
    }
  }

  executeMvpAttack(player) {
    player.attack_cooldown_timer = player.stats.attack_delay;

    let skillUsed = "";
    switch (player.class_id) {
      case 'knight': skillUsed = 'bash'; break;
      case 'wizard': skillUsed = 'storm_gust'; break;
      case 'assassin': skillUsed = 'sonic_blow'; break;
      case 'high_priest': skillUsed = 'holy_light'; break;
      case 'hunter': skillUsed = 'falcon_assault'; break;
      case 'blacksmith': skillUsed = 'mammonite'; break;
    }

    let dmgResult;
    if (player.class_id === 'wizard' || player.class_id === 'high_priest') {
      dmgResult = calculateMagicDamage(player.stats, { hard_mdef: this.mvpBoss.hard_mdef, soft_mdef: 30, element: this.mvpBoss.element }, skillUsed, 10);
    } else {
      dmgResult = calculatePhysicalDamage(player.stats, { hard_def: this.mvpBoss.hard_def, soft_def: 40, element: this.mvpBoss.element, perfect_dodge: 5.0, flee: 140 }, skillUsed, 10);
    }

    const dmg = dmgResult.damage || 100;
    this.mvpBoss.hp = Math.max(0, this.mvpBoss.hp - dmg);

    const cur = this.mvpBoss.aggro_table.get(player.id) || 0;
    this.mvpBoss.aggro_table.set(player.id, cur + dmg);

    if (this.mvpBoss.hp <= 0 && this.mvpBoss.is_alive) {
      this.defeatMvpBoss();
    }
  }

  updateMvpBoss(delta) {
    this.mvpBoss.attack_cooldown = Math.max(0, this.mvpBoss.attack_cooldown - delta);

    if (this.mvpBoss.attack_cooldown <= 0) {
      this.mvpBoss.attack_cooldown = 1.0;
      let highestThreat = -1;
      let targetPlayer = null;

      for (const [pid, threat] of this.mvpBoss.aggro_table.entries()) {
        const p = this.getPlayerById(pid);
        if (p && p.is_alive && threat > highestThreat) {
          highestThreat = threat;
          targetPlayer = p;
        }
      }

      if (targetPlayer) {
        const bossDmg = Math.floor(Math.random() * 160) + 120;
        const finalDmg = Math.floor(bossDmg * Math.max(0.1, (100.0 - targetPlayer.stats.hard_def) / 100.0));
        targetPlayer.hp = Math.max(0, targetPlayer.hp - finalDmg);

        if (targetPlayer.hp <= 0) {
          targetPlayer.is_alive = false;
          targetPlayer.state = AIState.DEAD_RESPAWNING;
          this.mvpBoss.aggro_table.delete(targetPlayer.id);
        }
      }
    }
  }

  defeatMvpBoss() {
    this.mvpBoss.is_alive = false;
    let maxThreat = -1;
    let mvpWinner = null;

    for (const [pid, threat] of this.mvpBoss.aggro_table.entries()) {
      if (threat > maxThreat) {
        maxThreat = threat;
        mvpWinner = this.getPlayerById(pid);
      }
    }

    const winnerName = mvpWinner ? mvpWinner.name : "Unknown Hero";
    const winnerGuild = mvpWinner ? mvpWinner.guild : "[Solo]";

    this.emitEvent("mvp_defeated", `${winnerName} defeated ${this.mvpBoss.name}!`, { winner: winnerName, guild: winnerGuild });
    this.broadcastChat("MVP System", `★ MVP! ${winnerName} has slain ${this.mvpBoss.name} for ${winnerGuild}! [Rare Drops: Baphomet Card, +9 Crescent Scythe] ★`, "World");
  }

  levelUpPlayer(player) {
    player.base_level = Math.min(MAX_BASE_LEVEL, player.base_level + 1);
    player.job_level = Math.min(MAX_JOB_LEVEL, player.job_level + 1);
    player.xp = 0;
    player.xp_to_next = Math.floor(player.xp_to_next * 1.25);

    this.setupPlayerStats(player);
    player.hp = player.max_hp;
    player.sp = player.max_sp;

    if (Math.random() < 0.30) {
      this.setPlayerChat(player, `Level UP!! Base Lv.${player.base_level} / Job Lv.${player.job_level}!`, "Party");
    }
  }

  moveTowards(player, target, speed, delta) {
    const dx = target.x - player.position.x;
    const dy = target.y - player.position.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (dist > 4.0) {
      const dirX = dx / dist;
      const dirY = dy / dist;
      player.facing_dir = { x: dirX, y: dirY };
      player.position.x += dirX * speed * delta;
      player.position.y += dirY * speed * delta;

      player.position.x = Math.max(this.mapBounds.minX, Math.min(this.mapBounds.maxX, player.position.x));
      player.position.y = Math.max(this.mapBounds.minY, Math.min(this.mapBounds.maxY, player.position.y));
    }
  }

  setPlayerChat(player, text, channel = "Local") {
    player.current_chat_text = text;
    player.chat_bubble_timer = 4.5;
    player.chat_channel = channel;
    this.broadcastChat(player.name, text, channel);
  }

  broadcastChat(sender, message, channel = "Local") {
    const now = new Date();
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
    const entry = { time: timeStr, sender, message, channel };
    this.chatLog.push(entry);
    if (this.chatLog.length > 100) {
      this.chatLog.shift();
    }
    this.emitEvent("chat", message, entry);
  }

  getPlayerById(id) {
    return this.simulatedPlayers.find(p => p.id === id) || null;
  }
}
