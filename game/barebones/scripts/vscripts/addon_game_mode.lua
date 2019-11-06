-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode.lua for more information
  ]]

  DebugPrint("[BAREBONES] Performing pre-load precache")

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
  PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
  PrecacheResource("particle_folder", "particles/test_particle", context)

  -- Models can also be precached by folder or individually
  -- PrecacheModel should generally used over PrecacheResource for individual models
  PrecacheResource("model_folder", "particles/heroes/antimage", context)
  PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
  PrecacheModel("models/heroes/viper/viper.vmdl", context)
  --PrecacheModel("models/props_gameplay/treasure_chest001.vmdl", context)
  --PrecacheModel("models/props_debris/merchant_debris_chest001.vmdl", context)
  --PrecacheModel("models/props_debris/merchant_debris_chest002.vmdl", context)

  -- Sounds can precached here like anything else
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

  -- Entire items can be precached by name
  -- Abilities can also be precached in this way despite the name
  PrecacheItemByNameSync("example_ability", context)
  PrecacheItemByNameSync("item_example_item", context)

  -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
  PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
  PrecacheUnitByNameSync("npc_dota_hero_enigma", context)
end

-- Create the game mode when we activate
function Activate()
  GameRules.AddonTemplate = CAddonTemplateGameMode()
  GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
  print("Template addon is loaded.")
  GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
  GameRules:SetPreGameTime( 45 )
  GameRules:SetStartingGold(STARTING_GOLD)
  GameRules:SetGoldPerTick(GOLD_PER_TICK)
  GameRules:SetGoldTickTime(GOLD_TICK_TIME)
  GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 3 )
  GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 3 )
  --GameMode:SetFixedRespawnTime( 25 )
  Convars:SetBool( 'dota_disable_bot_lane', true )
	Convars:SetBool( 'dota_disable_top_lane', true )

  ListenToGameEvent('dota_tower_kill', Dynamic_Wrap(CAddonTemplateGameMode, 'OnTowerKill'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(CAddonTemplateGameMode, 'OnEntityKilled'), self)
  ListenToGameEvent("dota_player_killed", Dynamic_Wrap(CAddonTemplateGameMode, "OnHeroKilled"), self)
 
  self.radiantTowersKilled = 0
  self.direTowersKilled = 0
end

-- Evaluate the state of the game
function CAddonTemplateGameMode:OnThink()
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
      -- print( "Template addon script is running." )
  elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
      return nil
  end
  return 1
end

function CAddonTemplateGameMode:OnEntityKilled(keys)
  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript(keys.entindex_killed)
  -- The Killing entity
  local killerEntity = nil

  if keys.entindex_attacker ~= nil then
      killerEntity = EntIndexToHScript(keys.entindex_attacker)
  end

  if killedUnit:IsRealHero() then
      if GetTeamHeroKills(killerEntity:GetTeam()) >= 2 then
          print(killerEntity:GetTeam())
      end
  end
end

-- An entity died
-- Game ends when a team reaches 20 kills
function CAddonTemplateGameMode:OnEntityKilled(keys)
  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript(keys.entindex_killed)
  -- The Killing entity
  local killerEntity = nil

  if keys.entindex_attacker ~= nil then
      killerEntity = EntIndexToHScript(keys.entindex_attacker)
  end

  if killedUnit:IsRealHero() then
      if GetTeamHeroKills(killerEntity:GetTeam()) >= 20 then
          GameRules:SetSafeToLeave(true)
          GameRules:SetGameWinner(killerEntity:GetTeam())
      end
  end

  -- Show Score
  GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS,
                                                   GetTeamHeroKills(
                                                       DOTA_TEAM_BADGUYS))
  GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,
                                                   GetTeamHeroKills(
                                                       DOTA_TEAM_GOODGUYS))
end

-- This function is called whenever a tower is killed
-- Game ends when 2 towers are killed on either side
function CAddonTemplateGameMode:OnTowerKill(keys)
  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local team = keys.teamnumber

  if team == DOTA_TEAM_GOODGUYS then
      self.radiantTowersKilled = self.radiantTowersKilled + 1
      print("radiant killed tower")
  else
      self.direTowersKilled = self.direTowersKilled + 1
      print("dire killed tower")
  end

  if self.radiantTowersKilled >= 2 or self.direTowersKilled >= 2 then
      GameRules:SetSafeToLeave(true)
      GameRules:SetGameWinner(killerPlayer:GetTeam())
  end
end

function CAddonTemplateGameMode:OnHeroKilled(keys)
  -- The Unit that was Killed
  if not keys then print("ERROR KEYS EMPTY") return end

  local killedPlayer = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)

if killedPlayer:IsRealHero() and not killedPlayer:IsReincarnating() then
      if killedPlayer:UnitCanRespawn() or not killedPlayer:GetRespawnsDisabled() then
          killedPlayer:SetTimeUntilRespawn(math.min(killedPlayer:GetLevel() * 3, 35))
      end
  end
end
