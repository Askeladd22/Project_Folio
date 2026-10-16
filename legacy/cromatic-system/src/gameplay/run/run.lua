local FolioModule = require("src.gameplay.folio.model")
local Folio = FolioModule.Folio or FolioModule
local Commissions = require("src.content.commissions")
local RunSchema = require("src.data.run_schema")

local Run = {}
Run.__index = Run
Run.SAVE_VERSION = 1

local GAMEPLAY_SCHEMA = RunSchema.gameplay or {}
local DEFAULT_CAMPAIGN_ID = GAMEPLAY_SCHEMA.default_campaign_id or "commission_1"
local DEFAULT_FOLIO_SET = GAMEPLAY_SCHEMA.default_folio_set or "BIFOLIO"
local FOLIO_SEED_STEP = tonumber(GAMEPLAY_SCHEMA.folio_seed_step) or 9973
local STARTING_REPUTATION = tonumber(GAMEPLAY_SCHEMA.starting_reputation) or 20
local STARTING_COINS = tonumber(GAMEPLAY_SCHEMA.starting_coins) or 0
local BASE_FOLIO_REWARD = GAMEPLAY_SCHEMA.base_folio_reward or {}
local BASE_FOLIO_REWARD_COINS = tonumber(BASE_FOLIO_REWARD.coins) or 30
local BASE_FOLIO_REWARD_REPUTATION = tonumber(BASE_FOLIO_REWARD.reputation) or 0
local CLEAN_FINISH_BONUS_REPUTATION = tonumber(GAMEPLAY_SCHEMA.clean_finish_bonus_reputation) or 1
local DIRTY_FINISH_PENALTY = GAMEPLAY_SCHEMA.dirty_finish_penalty or {}
local DIRTY_FINISH_COINS_PENALTY = tonumber(DIRTY_FINISH_PENALTY.coins) or 20
local DIRTY_FINISH_REPUTATION_PENALTY = tonumber(DIRTY_FINISH_PENALTY.reputation) or 2
local BUST_REPUTATION_LOSS = tonumber(GAMEPLAY_SCHEMA.bust_reputation_loss) or 3

local function build_default_run_setup()
    return {
        cards = {},
        effects = {},
    }
end

local function deep_copy_serializable(value, seen)
    local value_type = type(value)
    if value_type == "number" or value_type == "string" or value_type == "boolean" then
        return value
    end
    if value_type ~= "table" then
        return nil
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local out = {}
    seen[value] = out
    for key, nested in pairs(value) do
        local key_type = type(key)
        if key_type == "string" or key_type == "number" then
            local copied = deep_copy_serializable(nested, seen)
            if copied ~= nil then
                out[key] = copied
            end
        end
    end
    return out
end

local function sanitize_seed(seed)
    local n = tonumber(seed) or os.time()
    n = math.floor(n)
    if n == 0 then
        n = os.time()
    end
    return n
end

local function resolve_commission(campaign_id)
    local default_id = (Commissions.getDefaultId and Commissions.getDefaultId()) or DEFAULT_CAMPAIGN_ID
    local preferred_id = campaign_id or default_id
    local commission = Commissions.getById and Commissions.getById(preferred_id) or nil
    if commission then
        return commission
    end
    commission = Commissions.getById and Commissions.getById(default_id) or nil
    if commission then
        return commission
    end
    local all = Commissions.getAll and Commissions.getAll() or {}
    local fallback_data = RunSchema.fallback_commission or {}
    local fallback_folio = fallback_data.folio or {}
    return all[1] or {
        id = default_id,
        title = fallback_data.title_default or "Fallback Commission",
        subtitle = fallback_data.subtitle_default or "",
        folios = {
            {
                id = fallback_folio.id or "fallback_folio",
                pattern_name = fallback_folio.pattern_name_default or "Fallback Pattern",
                token = fallback_folio.token or 3,
                objective_rows = fallback_folio.objective_rows or 2,
                required_guided_rows = fallback_folio.required_guided_rows or 2,
                max_open_rows = fallback_folio.max_open_rows or 2,
                bust_choice_count = fallback_folio.bust_choice_count or 2,
                reroll_max = fallback_folio.reroll_max or 2,
            },
        },
    }
end

Run.DEFAULT_CAMPAIGN_ID = DEFAULT_CAMPAIGN_ID
Run.DEFAULT_FOLIO_SET = DEFAULT_FOLIO_SET
Run.FOLIO_SET_SIZES = GAMEPLAY_SCHEMA.folio_set_sizes or {
    BIFOLIO = 1,
    DUERNO = 1,
    TERNIONE = 1,
    QUATERNIONE = 1,
    QUINTERNO = 1,
    SESTERNO = 1,
}

function Run.configure(opts)
    if Folio and Folio.configure then
        Folio.configure(opts)
    end
end

---@param folio_set_type string Folio set type
---@param seed number Seed for reproducible RNG (optional)
---@param options? table Additional run options
function Run.new(folio_set_type, seed, options)
    local opts = type(options) == "table" and options or {}
    local self = setmetatable({}, Run)

    self.folio_set = (type(folio_set_type) == "string" and folio_set_type)
        or (type(opts.folio_set) == "string" and opts.folio_set)
        or DEFAULT_FOLIO_SET
    self.seed = sanitize_seed(opts.seed or seed)
    math.randomseed(self.seed)
    if love and love.math then
        love.math.setRandomSeed(self.seed)
    end

    self.campaign_id = opts.campaign_id
        or opts.commission_id
        or (Commissions.getDefaultId and Commissions.getDefaultId())
        or DEFAULT_CAMPAIGN_ID
    self.commission = resolve_commission(self.campaign_id)
    self.campaign_id = self.commission.id or self.campaign_id
    self.commission_title = self.commission.title or self.campaign_id
    self.commission_subtitle = self.commission.subtitle or ""
    self.total_folios = math.max(1, #(self.commission.folios or {}))

    self.rule_setup = build_default_run_setup()
    self.current_folio_index = 1
    self.current_scenario = nil
    self.current_folio = nil
    self.completed_folios = {}

    self.reputation = STARTING_REPUTATION
    self.coins = STARTING_COINS

    self.inventory = {
        pigments = {},
        binders = {},
    }

    self.game_over = false
    self.victory = false
    self.commission_result = nil

    self.current_folio = self:_createFolio(self.current_folio_index)

    return self
end

function Run:_getScenarioForIndex(index)
    local folios = self.commission and self.commission.folios or {}
    local target = math.max(1, math.floor(tonumber(index) or 1))
    local scenario = folios[target]
    if type(scenario) == "table" then
        return scenario
    end
    if #folios > 0 then
        return folios[#folios]
    end
    local fallback_folio = (RunSchema.fallback_commission and RunSchema.fallback_commission.folio) or {}
    return {
        id = fallback_folio.id or "fallback_folio",
        pattern_name = fallback_folio.pattern_name_default or "Fallback Pattern",
        token = fallback_folio.token or 3,
        objective_rows = fallback_folio.objective_rows or 2,
        required_guided_rows = fallback_folio.required_guided_rows or 2,
        max_open_rows = fallback_folio.max_open_rows or 2,
        bust_choice_count = fallback_folio.bust_choice_count or 2,
        reroll_max = fallback_folio.reroll_max or 2,
    }
end

function Run:_createFolio(index)
    local scenario = self:_getScenarioForIndex(index)
    self.current_scenario = scenario
    local folio_seed = self.seed + (math.max(1, math.floor(tonumber(index) or 1)) * FOLIO_SEED_STEP)
    local setup = build_default_run_setup()
    setup.scenario = scenario
    return Folio.new(self.folio_set, folio_seed, setup, scenario)
end

function Run:getCurrentScenario()
    return self.current_scenario or self:_getScenarioForIndex(self.current_folio_index)
end

function Run:evaluateCommissionOutcome()
    local threshold = tonumber(self.commission and self.commission.dirty_stains_threshold)
    local stains = tonumber(self.current_folio and self.current_folio.stain_count) or 0
    if not threshold then
        return {
            dirty = false,
            stains = stains,
            threshold = nil,
            coins_penalty = 0,
            reputation_penalty = 0,
        }
    end

    threshold = math.max(1, math.floor(threshold))
    local dirty = stains >= threshold
    return {
        dirty = dirty,
        stains = stains,
        threshold = threshold,
        coins_penalty = dirty and DIRTY_FINISH_COINS_PENALTY or 0,
        reputation_penalty = dirty and DIRTY_FINISH_REPUTATION_PENALTY or 0,
    }
end

function Run:nextFolio()
    if self.current_folio and self.current_folio.completed then
        local reward = self:calculateFolioReward()
        self.coins = self.coins + reward.coins
        self.reputation = self.reputation + reward.reputation

        table.insert(self.completed_folios, {
            scenario = self.current_scenario,
            reward = reward,
            folio = self.current_folio,
        })

        if self.current_folio_index < self.total_folios then
            self.current_folio_index = self.current_folio_index + 1
            self.current_folio = self:_createFolio(self.current_folio_index)
            return true, "next"
        end

        local outcome = self:evaluateCommissionOutcome()
        self.commission_result = outcome
        if outcome.dirty then
            self.coins = math.max(0, self.coins - (outcome.coins_penalty or 0))
            self.reputation = math.max(0, self.reputation - (outcome.reputation_penalty or 0))
        end

        self.victory = true
        return true, "victory"
    elseif self.current_folio and self.current_folio.busted then
        local rep_loss = BUST_REPUTATION_LOSS
        self.reputation = self.reputation - rep_loss

        self.game_over = true
        return false, "game_over"
    end

    return false, "in_progress"
end

function Run:calculateFolioReward()
    local reward = {
        coins = BASE_FOLIO_REWARD_COINS,
        reputation = BASE_FOLIO_REWARD_REPUTATION,
    }
    local folio = self.current_folio
    if folio and folio.elements and folio.elements.TEXT and folio.elements.TEXT.completed then
        local bonus = Folio.BONUS.TEXT or {}
        reward.coins = reward.coins + (bonus.coins or 0)
        reward.reputation = reward.reputation + (bonus.reputation or 0)
    end
    if folio and folio.stain_count <= 1 then
        reward.reputation = reward.reputation + CLEAN_FINISH_BONUS_REPUTATION
    end
    return reward
end

function Run:getStatus()
    local scenario = self:getCurrentScenario()
    return {
        folio_set = self.folio_set,
        folio = string.format("%d/%d", self.current_folio_index, self.total_folios),
        folio_index = self.current_folio_index,
        total_folios = self.total_folios,
        campaign_id = self.campaign_id,
        commission = self.commission_title,
        commission_subtitle = self.commission_subtitle,
        scenario_id = scenario and scenario.id or nil,
        pattern_name = scenario and scenario.pattern_name or nil,
        token = scenario and scenario.token or nil,
        reputation = self.reputation,
        coins = self.coins,
        seed = self.seed,
        game_over = self.game_over,
        victory = self.victory,
    }
end

function Run:toSaveData()
    return {
        kind = "run_state",
        version = Run.SAVE_VERSION,
        data = deep_copy_serializable(self),
    }
end

function Run.fromSaveData(payload)
    local source = payload
    if type(payload) == "table" and type(payload.data) == "table" then
        source = payload.data
    end
    if type(source) ~= "table" then
        return nil
    end

    local run = deep_copy_serializable(source) or {}
    setmetatable(run, Run)

    run.folio_set = (type(run.folio_set) == "string" and run.folio_set) or DEFAULT_FOLIO_SET
    run.seed = sanitize_seed(run.seed)
    run.campaign_id = run.campaign_id
        or run.commission_id
        or (Commissions.getDefaultId and Commissions.getDefaultId())
        or DEFAULT_CAMPAIGN_ID
    run.commission = resolve_commission(run.campaign_id)
    run.campaign_id = run.commission.id or run.campaign_id
    run.commission_title = run.commission.title or run.campaign_id
    run.commission_subtitle = run.commission.subtitle or ""
    run.total_folios = math.max(1, #(run.commission.folios or {}))
    run.current_folio_index = math.max(
        1,
        math.min(run.total_folios, math.floor(tonumber(run.current_folio_index) or 1))
    )

    run.rule_setup = type(run.rule_setup) == "table" and run.rule_setup or build_default_run_setup()
    run.completed_folios = type(run.completed_folios) == "table" and run.completed_folios or {}
    run.reputation = tonumber(run.reputation) or STARTING_REPUTATION
    run.coins = tonumber(run.coins) or STARTING_COINS
    run.inventory = type(run.inventory) == "table" and run.inventory or {pigments = {}, binders = {}}
    if type(run.inventory.pigments) ~= "table" then
        run.inventory.pigments = {}
    end
    if type(run.inventory.binders) ~= "table" then
        run.inventory.binders = {}
    end
    run.game_over = run.game_over and true or false
    run.victory = run.victory and true or false
    run.commission_result = type(run.commission_result) == "table" and run.commission_result or nil

    if type(run.current_folio) == "table" then
        setmetatable(run.current_folio, Folio)
    else
        run.current_folio = run:_createFolio(run.current_folio_index)
    end
    run.current_scenario = run.current_scenario or run:_getScenarioForIndex(run.current_folio_index)

    for _, entry in ipairs(run.completed_folios) do
        if type(entry) == "table" and type(entry.folio) == "table" then
            setmetatable(entry.folio, Folio)
        end
    end

    return run
end

return Run
