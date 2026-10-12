--[[
    Painel para o AdoptMe Farm  -  v5
    Motor: AdoptMe Farm v2.1.2 (Shxdrag Hub Edition)

    TODAS AS OPCOES DO MOTOR ESTAO AQUI
      Cada chave do Config.Defaults do motor tem um controle, e tambem as que o
      motor so le sem declarar (Focus, Auto Skelicorn, o jeito de andar no
      Hauntlet, esquadrao). As que estao incompletas no 2.1.2 aparecem em
      LARANJA, com o motivo, e comecam desligadas. Ligar e decisao sua.

      - Mudancas valem NA HORA com o farm rodando: o motor 2.1 le a propria
        configuracao a cada passo. Pedem reinicio so: intervalo do laco, nome,
        arquivo de log, telemetria e a janela do proprio motor.
      - As opcoes que o motor nao declara (Farm.Focus, Event.AutoSkelicorn,
        Event.Hauntlet*) nao vao na partida, para ele nao reclamar de chave
        desconhecida: entram na configuracao viva logo depois que ele sobe.
      - Predefinicoes do proprio motor e a janela dele podem ser acionadas
        pela aba Status.

    REMENDO NO MOTOR 2.1.2
      O motor chama GameConstants.focusKind e focusOf sem definir nenhuma das
      duas: com pocoes ou neon ligados, o laco de tarefas quebrava e era
      desligado pelo motor em 2,5 s. O painel acrescenta as duas funcoes ao
      motor, em memoria, antes de rodar.

    SEGURANCA
      O motor e baixado UMA vez, verificado e gravado localmente. Nenhum motor
      roda se for anterior ao v2 ou se contiver TradeAPI, getgc, hookfunction,
      hookmetamethod, queue_on_teleport ou ROBLOSECURITY.

    Abrir e fechar: tecla RightControl
]]

--==========================================================================
-- 0. Constantes
--==========================================================================
local ENGINE_URL   = "https://raw.githubusercontent.com/leandrocrynow/adopt/refs/heads/main/farmpublic"
local ENGINE_MARK  = "AdoptMe Farm  v"
local ENGINE_MAJOR = 2
local DIR          = "AdoptMeFarm"
local ENGINE_FILE  = DIR .. "/engine_v2_fixado.lua"
local CFG_FILE     = DIR .. "/painel_v2.json"
local TOGGLE_KEY   = Enum.KeyCode.RightControl

-- Um farm nao precisa de nada disto. Achou, nao roda.
local PROIBIDO = { "TradeAPI", "getgc", "hookfunction", "hookmetamethod", "queue_on_teleport", "ROBLOSECURITY" }

local LARG, ALT   = 740, 486
local ALT_BARRA   = 46
local MARGEM      = 8     -- folga minima entre a janela e a borda da tela
local VISIVEL_MIN = 150   -- quanto da barra de titulo precisa ficar na tela

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Http    = game:GetService("HttpService")
local Tween   = game:GetService("TweenService")
local LP      = Players.LocalPlayer

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local function env()
    return ENV
end

local canWrite  = type(writefile) == "function"
local canRead   = type(readfile) == "function" and type(isfile) == "function"
local canFolder = type(makefolder) == "function" and type(isfolder) == "function"

--==========================================================================
-- 1. Configuracao do motor: TODAS as chaves do 2.1.2
--==========================================================================
local function defaults()
    return {
        General = { ScriptName = "Shxdrag Hub", TickSeconds = 0.5 },
        Farm = {
            Enabled  = true,
            BabyMode = true,
            FastTravel = true,
            AutoNeeds = { Enabled = true, Skip = {} },
            Tasks = {
                pet_me = true, salon = true, bored = true, cat_cafe = true,
                sleepy = true, dirty = true, toilet = true, hungry = true,
                thirsty = true, play = true, pizza_party = true, school = true,
                sick = true, camping = true, beach_party = true, mystery = true,
                walk = true, ride = true,
            },
            MultiNeed = { Enabled = true, Kinds = { "pet_me", "hungry", "thirsty", "play" }, GapSeconds = 1 },
            SmartPriority = true,
            Priority = {
                mystery = 51, pet_me = 50, hungry = 49, thirsty = 48, sick = 47,
                dirty = 46, toilet = 45, sleepy = 44, play = 42, salon = 40,
                school = 39, pizza_party = 38, cat_cafe = 35, camping = 34,
                beach_party = 33, walk = 32, ride = 31, bored = 30,
            },
            BuyWater = true,
            BuyFood  = true,
            MaxBuysPerSession = 0,
            AutoAcceptMenu  = true,
            AntiAfk         = true,
            CameraGuard     = true,
            CollectCashback = true,
            CashbackMinutes = 10,
            SpotTravel      = "teleport",
            KeepPetEquipped = true,
            GameTravel      = true,
            HomeByRespawn   = true,
            HouseDoorExit   = false,
            FoodBowlTrip    = false,
            SkipFullGrown   = true,
            PetOrder        = "youngest",
            PreferNeon      = true,
            FarmPetKinds    = {},
            Focus           = "",   -- o motor le, mas nao declara (ver EXTRAS)
            BuyEgg          = true,
            EggToBuy        = "cracked_egg",
            MaxEggBuysPerSession = 0,
            AutoPotions = {
                Enabled = true,
                Potions = { "pet_age_potion", "tiny_pet_age_potion", "pet_bonus_bucks_potion" },
                Skip = {},
                PetKinds = {},
            },
            AutoNeon    = { Enabled = false, Mega = false, Exclude = {} },
            AutoOpen    = { Enabled = true, Exclude = {} },
            AutoRejoin  = false,
            StuckRejoinSeconds = 180,
            StuckRecovery = { Enabled = true, Seconds = 240 },
            Event = {
                Enabled         = true,
                GhostGallery    = true,
                GhostJoinByZone = true,
                Hauntlet        = false,
                HauntletMove        = "tween", -- EXTRA
                HauntletMoveSeconds = 0.5,     -- EXTRA
                HauntletFirst       = true,    -- EXTRA
                HauntletSquad       = true,    -- EXTRA
                HauntletSquadKey    = "",      -- EXTRA
                AutoSkelicorn       = false,   -- EXTRA
                Crypt           = true,
                MummySpider     = true,
                CryptOpen       = { "ladder" },
                Quests          = true,
                HouseVisits     = true,
                PigeonNest      = true,
                AutoNest        = true,
                StrayCat        = true,
                PetPen          = true,
                PetPenMinutes   = 15,
                PetPenSlots     = 4,
                PetPenStock     = true,
                PetPenStockMinBucks = 750,
                CandyPets = {
                    Enabled = false,
                    Pick = {},
                    KeepCandy = 0,
                    Buy = {
                        { id = "halloween_2026_jump_scare", price = 40000, max = 1 },
                        { id = "halloween_2026_jacobean_pigeon", price = 4000, max = 4 },
                    },
                },
            },
            PetMeFocusSeconds = 7,
            FailureCooldownSeconds = 30,
            MaxConsecutiveFailures = 3,
            DisableMinutes = 15,
        },
        Interface = {
            Enabled = false,
            Keybind = "RightShift",
            Toasts = true,
            RememberSettings = true,
            Theme = "Halloween",
            Descriptions = false,
            Autoload = "",
            StartHidden = false,
            UIScale = "Auto",
            Language = "Auto",
        },
        Logging = {
            ConsoleLevel = "OFF",
            FileLevel    = "DEBUG",
            FileEnabled  = false,
            SessionFile  = false,
            Folder       = "ShxdragHub/logs",
            FlushSeconds = 5,
            DuplicateWindowSeconds = 10,
            MaxLinesPerSession = 20000,
        },
        Telemetry = {
            Enabled = false,
            Url = "",
            Owner = "",
            SummaryMinutes = 30,
            IncludeInventory = false,
        },
        Notifications = {
            Enabled = false,
            Webhooks = { Summary = "", Alerts = "" },
            SummaryIntervalMinutes = 30,
            SendSummary     = true,
            SendOnStartStop = true,
            SendOnError     = true,
            SendOnKick      = true,
            SendOnTaskComplete = false,
            SendTestMessageOnStart = false,
            PingDiscordUserId = "",
            Ping = true,
            PingOn = {
                Kick = true, Error = false, Summary = false,
                TaskCompleted = false, SessionStopped = false, PreviousSession = false,
            },
            IncludeUsername = true,
            AlertCooldownSeconds = 60,
            MinSecondsBetweenMessages = 2.5,
            MaxQueueSize = 50,
            MaxRetries = 3,
        },
    }
end

-- O motor 2.1.2 LE estas chaves mas nao as declara no Config.Defaults: na
-- partida ele as descartaria como "Unknown setting". Saem da partida e entram
-- na configuracao viva logo depois.
local EXTRAS = {
    ["Farm.Focus"] = true,
    ["Farm.Event.AutoSkelicorn"] = true,
    ["Farm.Event.HauntletMove"] = true,
    ["Farm.Event.HauntletMoveSeconds"] = true,
    ["Farm.Event.HauntletFirst"] = true,
    ["Farm.Event.HauntletSquad"] = true,
    ["Farm.Event.HauntletSquadKey"] = true,
}

-- Preferencias do PAINEL. Nunca vao para o motor.
local function prefsPadrao()
    return {
        AutoIniciar = false,
        AbrirMinimizado = false,
        Animacoes = true,
        JanelaX = -1,
        JanelaY = -1,
    }
end

local Cfg  = defaults()
local Pref = prefsPadrao()

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copia = {}
    for chave, item in pairs(value) do
        copia[chave] = deepCopy(item)
    end
    return copia
end

-- Lista = tabela so com indices 1..n (uma tabela vazia tambem conta).
local function ehLista(valor)
    if type(valor) ~= "table" then
        return false
    end
    local n = 0
    for _ in pairs(valor) do
        n = n + 1
    end
    return n == #valor
end

local function listaContem(lista, valor)
    for _, item in ipairs(type(lista) == "table" and lista or {}) do
        if item == valor then
            return true
        end
    end
    return false
end

-- Caminhos como "Farm.Event.PetPen" sao divididos UMA vez e guardados.
local pedacosDe = {}
local function pedacos(caminho)
    local lista = pedacosDe[caminho]
    if not lista then
        lista = {}
        for parte in string.gmatch(caminho, "[^.]+") do
            lista[#lista + 1] = parte
        end
        pedacosDe[caminho] = lista
    end
    return lista
end

-- "Buy.1.price": o "1" de um caminho e o indice 1 de uma lista.
local function chaveReal(node, parte)
    if node[parte] == nil then
        local numero = tonumber(parte)
        if numero and node[numero] ~= nil then
            return numero
        end
    end
    return parte
end

local function raizDe(lista)
    if lista[1] == "__pref__" then
        return Pref, 2
    end
    return Cfg, 1
end

local function getPath(caminho)
    local lista = pedacos(caminho)
    local node, inicio = raizDe(lista)
    for indice = inicio, #lista do
        if type(node) ~= "table" then
            return nil
        end
        node = node[chaveReal(node, lista[indice])]
    end
    return node
end

local function setPath(caminho, valor)
    local lista = pedacos(caminho)
    local node, inicio = raizDe(lista)
    for indice = inicio, #lista - 1 do
        node = node[chaveReal(node, lista[indice])]
        if type(node) ~= "table" then
            return
        end
    end
    node[chaveReal(node, lista[#lista])] = valor
end

--==========================================================================
-- 2. Arquivo de configuracao
--==========================================================================
local function ensureFolder()
    if canFolder then
        pcall(function()
            if not isfolder(DIR) then
                makefolder(DIR)
            end
        end)
    end
end

local function saveConfig()
    if not canWrite then
        return false
    end
    ensureFolder()
    local ok, texto = pcall(function()
        return Http:JSONEncode({ cfg = Cfg, pref = Pref })
    end)
    if not ok then
        return false
    end
    return (pcall(writefile, CFG_FILE, texto))
end

-- So copia o que existe no painel e tem o mesmo tipo. Listas de texto sao
-- trocadas inteiras; listas de tabelas (a loja de doces) sao mescladas item a item.
local function mesclar(alvo, fonte)
    for chave, valor in pairs(fonte) do
        local atual = alvo[chave]
        local soTexto = ehLista(atual) and ehLista(valor)
        if soTexto then
            for _, item in ipairs(valor) do
                if type(item) ~= "string" then
                    soTexto = false
                end
            end
            for _, item in ipairs(atual) do
                if type(item) ~= "string" then
                    soTexto = false
                end
            end
        end
        if soTexto then
            alvo[chave] = deepCopy(valor)
        elseif type(valor) == "table" and type(atual) == "table" then
            mesclar(atual, valor)
        elseif atual ~= nil and type(valor) == type(atual) then
            alvo[chave] = valor
        end
    end
end

local function loadConfig()
    if not canRead then
        return
    end
    local ok, texto = pcall(function()
        return isfile(CFG_FILE) and readfile(CFG_FILE) or nil
    end)
    if not ok or type(texto) ~= "string" then
        return
    end
    local decodificado
    ok, decodificado = pcall(function()
        return Http:JSONDecode(texto)
    end)
    if not ok or type(decodificado) ~= "table" then
        return
    end
    if type(decodificado.cfg) == "table" then
        mesclar(Cfg, decodificado.cfg)
    end
    if type(decodificado.pref) == "table" then
        mesclar(Pref, decodificado.pref)
    end
end

--==========================================================================
-- 3. Motor
--==========================================================================
local engineSource = nil
local setStatus -- definido junto da interface

local function versaoDo(texto)
    local cabeca = string.sub(texto, 1, 300)
    return string.match(cabeca, "AdoptMe Farm%s+v([%d%.]+)"), tonumber(string.match(cabeca, "AdoptMe Farm%s+v(%d+)"))
end

local function verificarMotor(texto)
    if type(texto) ~= "string" or texto == "" then
        return false, "o motor veio vazio"
    end
    if not string.find(string.sub(texto, 1, 300), ENGINE_MARK, 1, true) then
        return false, "o arquivo NAO e o AdoptMe Farm: nada foi executado"
    end
    local versao, maior = versaoDo(texto)
    if not maior or maior < ENGINE_MAJOR then
        return false, "o motor e v" .. tostring(versao or "?") .. " e este painel e para o v2: atualize o farmpublic do seu repositorio"
    end
    for _, palavra in ipairs(PROIBIDO) do
        if string.find(texto, palavra, 1, true) then
            return false, "o motor contem '" .. palavra .. "', que um farm nao precisa: nada foi executado"
        end
    end
    return true
end

local function fetchEngine(forcar)
    if not forcar and canRead then
        local ok, texto = pcall(function()
            return isfile(ENGINE_FILE) and readfile(ENGINE_FILE) or nil
        end)
        if ok and type(texto) == "string" and verificarMotor(texto) then
            return texto, "copia local fixada"
        end
    end
    local ok, corpo = pcall(function()
        return game:HttpGet(ENGINE_URL)
    end)
    if not ok or type(corpo) ~= "string" or corpo == "" then
        return nil, "o download falhou"
    end
    local valido, motivo = verificarMotor(corpo)
    if not valido then
        return nil, motivo
    end
    if canWrite then
        ensureFolder()
        pcall(writefile, ENGINE_FILE, corpo)
    end
    return corpo, "baixado e fixado"
end

-- O motor 2.1.2 chama estas duas funcoes e nao as define.
local REMENDO_FOCO = [[
    function GameConstants.focusOf(farm)
        local focus = type(farm) == "table" and farm.Focus
        if type(focus) ~= "string" or focus == "" then
            return nil
        end
        return { kind = focus }
    end
    function GameConstants.focusKind(farm)
        local focus = GameConstants.focusOf(farm)
        return focus and focus.kind or nil
    end
]]

local function remendarMotor(texto)
    local usa = string.find(texto, "GameConstants.focusKind(", 1, true)
        or string.find(texto, "GameConstants.focusOf(", 1, true)
    local define = string.find(texto, "function GameConstants.focusKind", 1, true)
    if not usa or define then
        return texto, "nao precisou"
    end
    local trocas
    texto, trocas = string.gsub(texto,
        '(%s)(return GameConstants%s+end%s+__moduleSources%["Game/GameData"%])',
        function(espaco, resto)
            return espaco .. REMENDO_FOCO .. resto
        end, 1)
    return texto, trocas == 1 and "aplicado" or "falhou"
end

local function farmApi()
    local api = env().AdoptMeFarm
    if type(api) == "table" and type(api.Stop) == "function" then
        return api
    end
    return nil
end

local function isRunning()
    return farmApi() ~= nil
end

-- A configuracao VIVA do motor rodando.
local function configDoMotor()
    local api = farmApi()
    return api and type(api.Config) == "table" and api.Config or nil
end

local function lerNoMotor(caminho)
    local node = configDoMotor()
    for _, parte in ipairs(pedacos(caminho)) do
        if type(node) ~= "table" then
            return nil
        end
        node = node[chaveReal(node, parte)]
    end
    return node
end

-- Grava um valor na configuracao viva. Nao cria chave nova nem troca o tipo de
-- uma, exceto as EXTRAS, que o motor le sem declarar.
local function gravarNoMotor(caminho, valor)
    local node = configDoMotor()
    if not node then
        return false
    end
    local lista = pedacos(caminho)
    for indice = 1, #lista - 1 do
        node = node[chaveReal(node, lista[indice])]
        if type(node) ~= "table" then
            return false
        end
    end
    local chave = chaveReal(node, lista[#lista])
    if node[chave] == nil and not EXTRAS[caminho] then
        return false
    end
    if node[chave] ~= nil and type(node[chave]) ~= type(valor) then
        return false
    end
    node[chave] = deepCopy(valor)
    return true
end

-- O motor le estas so na partida: mudar com ele rodando pede reinicio.
local function soNoInicio(caminho)
    return caminho == "General.TickSeconds" or caminho == "General.ScriptName"
        or caminho == "Logging.FileEnabled" or caminho == "Logging.FileLevel"
        or caminho == "Logging.SessionFile" or caminho == "Logging.FlushSeconds"
        or caminho == "Logging.MaxLinesPerSession" or caminho == "Logging.Folder"
        or string.sub(caminho, 1, 10) == "Telemetry." or string.sub(caminho, 1, 10) == "Interface."
end

local precisaReiniciar = false

local gravacaoPendente = false
local function agendarGravacao()
    if gravacaoPendente then
        return
    end
    gravacaoPendente = true
    task.delay(1, function()
        gravacaoPendente = false
        saveConfig()
    end)
end

-- Um controle mudou: grava no arquivo e, com o farm rodando, aplica na hora.
local function mudou(caminho)
    agendarGravacao()
    if not isRunning() or type(caminho) ~= "string" or string.sub(caminho, 1, 9) == "__pref__." then
        return
    end
    if soNoInicio(caminho) then
        if lerNoMotor(caminho) ~= getPath(caminho) then
            precisaReiniciar = true
        end
        return
    end
    gravarNoMotor(caminho, getPath(caminho))
end

local function folhas(node, prefixo, saida)
    for chave, valor in pairs(node) do
        local caminho = prefixo == "" and tostring(chave) or (prefixo .. "." .. tostring(chave))
        if type(valor) == "table" and not ehLista(valor) then
            folhas(valor, caminho, saida)
        else
            saida[#saida + 1] = caminho
        end
    end
    return saida
end

-- Depois das predefinicoes, que mexem em muita coisa de uma vez.
local function marcarSujo()
    agendarGravacao()
    if not isRunning() then
        return
    end
    for _, caminho in ipairs(folhas(Cfg, "", {})) do
        if soNoInicio(caminho) then
            if lerNoMotor(caminho) ~= getPath(caminho) then
                precisaReiniciar = true
            end
        else
            gravarNoMotor(caminho, getPath(caminho))
        end
    end
end

-- O caminho inverso: traz para o painel o que esta no motor rodando (depois de
-- uma predefinicao do proprio motor, por exemplo).
local function puxarDoMotor()
    if not configDoMotor() then
        return 0
    end
    local trazidos = 0
    for _, caminho in ipairs(folhas(Cfg, "", {})) do
        local valor = lerNoMotor(caminho)
        if valor ~= nil and type(valor) == type(getPath(caminho)) then
            setPath(caminho, deepCopy(valor))
            trazidos = trazidos + 1
        end
    end
    agendarGravacao()
    return trazidos
end

local function tirar(raiz, caminho)
    local lista = pedacos(caminho)
    local node = raiz
    for indice = 1, #lista - 1 do
        node = type(node) == "table" and node[lista[indice]] or nil
    end
    if type(node) == "table" then
        node[lista[#lista]] = nil
    end
end

local function startFarm()
    if isRunning() then
        setStatus("ja esta rodando")
        return
    end
    local fonte, como = engineSource, "em memoria"
    if not fonte then
        setStatus("buscando o motor...")
        fonte, como = fetchEngine(false)
    end
    if not fonte then
        setStatus("erro: " .. tostring(como))
        return
    end
    local valido, motivo = verificarMotor(fonte)
    if not valido then
        setStatus("erro: " .. tostring(motivo))
        return
    end
    engineSource = fonte
    local remendado, remendo = remendarMotor(fonte)
    local chunk, erroCompilacao = loadstring(remendado)
    if not chunk then
        setStatus("erro de compilacao: " .. tostring(erroCompilacao))
        return
    end

    gravacaoPendente = false
    saveConfig()
    local enviar = deepCopy(Cfg)
    for caminho in pairs(EXTRAS) do
        tirar(enviar, caminho)
    end
    local aviso = ""
    if remendo == "falhou" then
        -- sem o remendo estas quebram o laco inteiro no motor 2.1.2
        enviar.Farm.AutoPotions.Enabled = false
        enviar.Farm.AutoNeon.Enabled = false
        enviar.Farm.AutoNeon.Mega = false
        enviar.Farm.Event.Crypt = false
        enviar.Farm.Event.PetPen = false
        aviso = "; remendo nao entrou: pocoes, neon, cripta e pet pen desligados"
    end
    env().AdoptMeFarmSettings   = enviar
    env().AdoptMeFarmLoaderInfo = { Url = ENGINE_URL }
    setStatus("iniciando o motor, ele espera o jogo carregar...")
    local ok, erroExecucao = pcall(chunk)
    if not ok then
        setStatus("erro ao iniciar: " .. tostring(erroExecucao))
        return
    end
    -- as EXTRAS entram agora, na configuracao viva
    for caminho in pairs(EXTRAS) do
        gravarNoMotor(caminho, getPath(caminho))
    end
    precisaReiniciar = false
    setStatus(string.format("iniciado: motor v%s, %s, remendo %s%s", tostring(versaoDo(fonte) or "?"), como, remendo, aviso))
end

local function stopFarm()
    local api = farmApi()
    if not api then
        setStatus("nao estava rodando")
        return
    end
    pcall(api.Stop, "painel")
    setStatus("parado")
end

local function restartFarm()
    stopFarm()
    task.wait(0.6)
    precisaReiniciar = false
    startFarm()
end

--==========================================================================
-- 4. Base da interface
--==========================================================================
local COR = {
    fundo     = Color3.fromRGB(20, 21, 26),
    painel    = Color3.fromRGB(28, 30, 37),
    cartao    = Color3.fromRGB(34, 37, 45),
    linha     = Color3.fromRGB(46, 50, 60),
    texto     = Color3.fromRGB(230, 232, 238),
    fraco     = Color3.fromRGB(138, 145, 160),
    ligado    = Color3.fromRGB(72, 190, 122),
    desligado = Color3.fromRGB(62, 66, 78),
    aviso     = Color3.fromRGB(230, 164, 72),
    perigo    = Color3.fromRGB(224, 90, 90),
    destaque  = Color3.fromRGB(98, 136, 238),
}

local infosTween = {}
local function infoTween(tempo, estilo, direcao)
    local chave = tostring(tempo) .. "|" .. tostring(estilo) .. "|" .. tostring(direcao)
    local info = infosTween[chave]
    if not info then
        info = TweenInfo.new(tempo, estilo, direcao)
        infosTween[chave] = info
    end
    return info
end

local function animar(objeto, tempo, props, estilo, direcao)
    if not Pref.Animacoes then
        pcall(function()
            for chave, valor in pairs(props) do
                objeto[chave] = valor
            end
        end)
        return nil
    end
    local t = Tween:Create(objeto, infoTween(tempo or 0.18,
        estilo or Enum.EasingStyle.Quad, direcao or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function novo(classe, props, pai)
    local objeto = Instance.new(classe)
    for chave, valor in pairs(props or {}) do
        objeto[chave] = valor
    end
    if pai then
        objeto.Parent = pai
    end
    return objeto
end

local function canto(pai, raio)
    novo("UICorner", { CornerRadius = UDim.new(0, raio or 6) }, pai)
end

local function brilho(botao, corNormal, corHover)
    botao.MouseEnter:Connect(function()
        animar(botao, 0.12, { BackgroundColor3 = corHover })
    end)
    botao.MouseLeave:Connect(function()
        animar(botao, 0.12, { BackgroundColor3 = corNormal })
    end)
end

local telaPai = LP:WaitForChild("PlayerGui")
pcall(function()
    if type(gethui) == "function" then
        telaPai = gethui()
    elseif game:GetService("CoreGui") then
        telaPai = game:GetService("CoreGui")
    end
end)

local antiga = telaPai:FindFirstChild("PainelAdoptMe")
if antiga then
    antiga:Destroy()
end

local tela = novo("ScreenGui", {
    Name = "PainelAdoptMe",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
}, telaPai)

local janela = novo("Frame", {
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(LARG, ALT),
    BackgroundColor3 = COR.fundo,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, tela)
canto(janela, 12)
novo("UIStroke", { Color = COR.linha, Thickness = 1, Transparency = 0.3 }, janela)

--------------------------------------------------------------------- barra
local barra = novo("Frame", {
    Size = UDim2.new(1, 0, 0, ALT_BARRA),
    BackgroundColor3 = COR.painel,
    BorderSizePixel = 0,
}, janela)

novo("Frame", {
    Size = UDim2.fromOffset(4, 20),
    Position = UDim2.fromOffset(16, 13),
    BackgroundColor3 = COR.destaque,
    BorderSizePixel = 0,
}, barra)

novo("TextLabel", {
    Size = UDim2.new(1, -150, 1, 0),
    Position = UDim2.fromOffset(30, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = COR.texto,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "AdoptMe Farm 2.1  |  painel completo",
}, barra)

local pontoEstado = novo("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(1, -92, 0, 19),
    BackgroundColor3 = COR.desligado,
    BorderSizePixel = 0,
}, barra)
canto(pontoEstado, 4)

local btnMinimizar = novo("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -74, 0, 9),
    BackgroundColor3 = COR.linha,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = COR.texto,
    Text = "-",
    AutoButtonColor = false,
}, barra)
canto(btnMinimizar, 6)
brilho(btnMinimizar, COR.linha, COR.destaque)

local btnFechar = novo("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -38, 0, 9),
    BackgroundColor3 = COR.linha,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = COR.texto,
    Text = "X",
    AutoButtonColor = false,
}, barra)
canto(btnFechar, 6)
brilho(btnFechar, COR.linha, COR.perigo)

-------------------------------------------------------------------- corpo
local corpo = novo("Frame", {
    Size = UDim2.new(1, 0, 1, -ALT_BARRA),
    Position = UDim2.fromOffset(0, ALT_BARRA),
    BackgroundTransparency = 1,
}, janela)

local colunaAbas = novo("Frame", {
    Size = UDim2.new(0, 152, 1, -62),
    Position = UDim2.fromOffset(12, 10),
    BackgroundTransparency = 1,
}, corpo)
novo("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, colunaAbas)

local caixaConteudo = novo("Frame", {
    Size = UDim2.new(1, -188, 1, -62),
    Position = UDim2.fromOffset(176, 10),
    BackgroundColor3 = COR.painel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, corpo)
canto(caixaConteudo, 8)

local function criarAreaPagina()
    local area = novo("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.new(),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COR.linha,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, caixaConteudo)
    novo("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, area)
    novo("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    }, area)
    return area
end

------------------------------------------------------------------- rodape
local rodape = novo("Frame", {
    Size = UDim2.new(1, -24, 0, 42),
    Position = UDim2.new(0, 12, 1, -48),
    BackgroundTransparency = 1,
}, corpo)

local btnPrincipal = novo("TextButton", {
    Size = UDim2.fromOffset(152, 34),
    Position = UDim2.fromOffset(0, 4),
    BackgroundColor3 = COR.ligado,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.new(1, 1, 1),
    Text = "INICIAR",
    AutoButtonColor = false,
}, rodape)
canto(btnPrincipal, 8)

local rotuloStatus = novo("TextLabel", {
    Size = UDim2.new(1, -164, 1, 0),
    Position = UDim2.fromOffset(164, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = COR.fraco,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true,
    Text = "parado",
}, rodape)

function setStatus(texto)
    rotuloStatus.Text = tostring(texto)
    rotuloStatus.TextTransparency = 1
    animar(rotuloStatus, 0.25, { TextTransparency = 0 })
end

local abrirAba, abaAtiva, repintarTudo

--==========================================================================
-- 5. Geometria da janela
--==========================================================================
local minimizado = false
local posJanela = Vector2.new(0, 0)

local function alturaAlvo()
    return minimizado and ALT_BARRA or ALT
end

local function tamanhoTela()
    local tamanho = tela.AbsoluteSize
    if tamanho.X < 10 or tamanho.Y < 10 then
        return Vector2.new(1280, 720)
    end
    return tamanho
end

local function ajustarArrasto(x, y)
    local tamanho = tamanhoTela()
    local maiorY = tamanho.Y - ALT_BARRA - MARGEM
    if maiorY < MARGEM then
        maiorY = MARGEM
    end
    return math.clamp(x, VISIVEL_MIN - LARG, tamanho.X - VISIVEL_MIN),
        math.clamp(y, MARGEM, maiorY)
end

local function encaixar(altura)
    local tamanho = tamanhoTela()
    local x, y = ajustarArrasto(posJanela.X, posJanela.Y)
    if y + altura > tamanho.Y - MARGEM then
        y = math.max(MARGEM, tamanho.Y - MARGEM - altura)
    end
    return x, y
end

local function colocar(x, y)
    posJanela = Vector2.new(x, y)
    janela.Position = UDim2.fromOffset(x, y)
end

local function posicaoInicial()
    local tamanho = tamanhoTela()
    if type(Pref.JanelaX) == "number" and Pref.JanelaX >= 0
        and type(Pref.JanelaY) == "number" and Pref.JanelaY >= 0 then
        return ajustarArrasto(Pref.JanelaX, Pref.JanelaY)
    end
    return math.floor((tamanho.X - LARG) / 2), math.floor((tamanho.Y - ALT) / 2)
end

local tweenJanela = nil
local function animarJanela(tempo, props, estilo)
    if tweenJanela then
        pcall(function()
            tweenJanela:Cancel()
        end)
        tweenJanela = nil
    end
    tweenJanela = animar(janela, tempo, props, estilo)
    return tweenJanela
end

tela:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local x, y = encaixar(alturaAlvo())
    colocar(x, y)
end)

--==========================================================================
-- 6. Arraste
--==========================================================================
local arrastoMover = nil
local arrastoFim   = nil
local conexaoMover = nil

local function pararArrasto()
    if conexaoMover then
        conexaoMover:Disconnect()
        conexaoMover = nil
    end
    local fim = arrastoFim
    arrastoMover, arrastoFim = nil, nil
    if fim then
        fim()
    end
end

local function comecarArrasto(mover, fim)
    arrastoMover, arrastoFim = mover, fim
    if not conexaoMover then
        conexaoMover = UIS.InputChanged:Connect(function(entrada)
            if arrastoMover and (entrada.UserInputType == Enum.UserInputType.MouseMovement
                or entrada.UserInputType == Enum.UserInputType.Touch) then
                arrastoMover(entrada.Position)
            end
        end)
    end
end

UIS.InputEnded:Connect(function(entrada)
    if arrastoMover and (entrada.UserInputType == Enum.UserInputType.MouseButton1
        or entrada.UserInputType == Enum.UserInputType.Touch) then
        pararArrasto()
    end
end)

barra.InputBegan:Connect(function(entrada)
    if entrada.UserInputType == Enum.UserInputType.MouseButton1
        or entrada.UserInputType == Enum.UserInputType.Touch then
        if tweenJanela then
            pcall(function()
                tweenJanela:Cancel()
            end)
            tweenJanela = nil
        end
        local inicio = entrada.Position
        local baseX, baseY = posJanela.X, posJanela.Y
        comecarArrasto(function(ponteiro)
            local delta = ponteiro - inicio
            local x, y = ajustarArrasto(baseX + delta.X, baseY + delta.Y)
            colocar(x, y)
        end, function()
            Pref.JanelaX, Pref.JanelaY = posJanela.X, posJanela.Y
            agendarGravacao()
        end)
    end
end)

--==========================================================================
-- 7. Minimizar
--==========================================================================
local function aplicarMinimizar(animado)
    local altura = alturaAlvo()
    btnMinimizar.Text = minimizado and "+" or "-"
    local x, y = encaixar(altura)

    if minimizado then
        if animado then
            animar(corpo, 0.10, { Position = UDim2.fromOffset(0, ALT_BARRA + 14) })
            task.delay(0.10, function()
                corpo.Visible = false
            end)
        else
            corpo.Visible = false
        end
    else
        corpo.Visible = true
        if animado then
            corpo.Position = UDim2.fromOffset(0, ALT_BARRA + 14)
            animar(corpo, 0.22, { Position = UDim2.fromOffset(0, ALT_BARRA) }, Enum.EasingStyle.Quint)
        else
            corpo.Position = UDim2.fromOffset(0, ALT_BARRA)
        end
    end

    if animado then
        posJanela = Vector2.new(x, y)
        animarJanela(0.22, {
            Size = UDim2.fromOffset(LARG, altura),
            Position = UDim2.fromOffset(x, y),
        }, Enum.EasingStyle.Quint)
    else
        janela.Size = UDim2.fromOffset(LARG, altura)
        colocar(x, y)
    end
end

btnMinimizar.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    Pref.AbrirMinimizado = minimizado
    agendarGravacao()
    aplicarMinimizar(true)
    if repintarTudo then
        repintarTudo()
    end
end)

--==========================================================================
-- 8. Controles
--==========================================================================
local ordem = 0
local function proximaOrdem()
    ordem = ordem + 1
    return ordem
end

local areaAtual, listaAtual = nil, nil

local function registrar(funcao)
    if listaAtual and funcao then
        listaAtual[#listaAtual + 1] = funcao
    end
end

local function linhaBase(altura)
    return novo("Frame", {
        Size = UDim2.new(1, 0, 0, altura),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaAtual)
end

local function tituloSecao(texto)
    local frame = linhaBase(32)
    novo("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = COR.destaque,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        Text = string.upper(texto),
    }, frame)
    return frame
end

local function criarToggle(item)
    local ler = item.ler or function()
        return getPath(item.path) == true
    end
    local gravar = item.gravar or function(valor)
        setPath(item.path, valor)
    end
    local altura = item.desc and 54 or 38
    local frame = linhaBase(altura)

    local cartao = novo("Frame", {
        Size = UDim2.new(1, 0, 1, -4),
        BackgroundColor3 = COR.cartao,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, frame)
    canto(cartao, 6)

    novo("TextLabel", {
        Size = UDim2.new(1, -66, 0, 20),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = item.alerta and COR.aviso or COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, cartao)

    if item.desc then
        novo("TextLabel", {
            Size = UDim2.new(1, -66, 0, 26),
            Position = UDim2.fromOffset(8, 24),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = COR.fraco,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = item.desc,
        }, cartao)
    end

    local trilho = novo("TextButton", {
        Size = UDim2.fromOffset(46, 24),
        Position = UDim2.new(1, -54, 0, 6),
        BackgroundColor3 = COR.desligado,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, cartao)
    canto(trilho, 12)

    local bolinha = novo("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, trilho)
    canto(bolinha, 9)

    local function pintar(animado)
        local ligado = ler()
        local posicao = ligado and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
        local cor = ligado and COR.ligado or COR.desligado
        if animado then
            animar(bolinha, 0.16, { Position = posicao }, Enum.EasingStyle.Quint)
            animar(trilho, 0.16, { BackgroundColor3 = cor })
        else
            bolinha.Position = posicao
            trilho.BackgroundColor3 = cor
        end
    end

    cartao.MouseEnter:Connect(function()
        animar(cartao, 0.12, { BackgroundTransparency = 0.5 })
    end)
    cartao.MouseLeave:Connect(function()
        animar(cartao, 0.12, { BackgroundTransparency = 1 })
    end)

    trilho.MouseButton1Click:Connect(function()
        gravar(not ler())
        pintar(true)
        mudou(item.path)
    end)

    pintar(false)
    registrar(function(animado)
        pintar(animado == true)
    end)
    return frame
end

-- Liga ou desliga UM valor dentro de uma lista da configuracao.
-- inverso = ligada quando o valor NAO esta na lista. ordem = ordem certa da lista.
local function criarMembro(item)
    local function ler()
        local dentro = listaContem(getPath(item.path), item.valor)
        if item.inverso then
            return not dentro
        end
        return dentro
    end
    local function gravar(ligado)
        local quer = ligado
        if item.inverso then
            quer = not ligado
        end
        local atual = getPath(item.path)
        atual = type(atual) == "table" and atual or {}
        local presente = {}
        for _, valor in ipairs(atual) do
            presente[valor] = true
        end
        presente[item.valor] = quer or nil
        local nova = {}
        for _, valor in ipairs(item.ordem or {}) do
            if presente[valor] then
                nova[#nova + 1] = valor
                presente[valor] = nil
            end
        end
        for _, valor in ipairs(atual) do
            if presente[valor] then
                nova[#nova + 1] = valor
                presente[valor] = nil
            end
        end
        if presente[item.valor] then
            nova[#nova + 1] = item.valor
        end
        setPath(item.path, nova)
    end
    return criarToggle({ path = item.path, label = item.label, desc = item.desc, alerta = item.alerta,
        ler = ler, gravar = gravar })
end

local function criarSlider(item)
    local frame = linhaBase(52)
    local passo = item.passo or 1

    local rotulo = novo("TextLabel", {
        Size = UDim2.new(1, -8, 0, 20),
        Position = UDim2.fromOffset(8, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = item.alerta and COR.aviso or COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    local trilho = novo("TextButton", {
        Size = UDim2.new(1, -16, 0, 8),
        Position = UDim2.fromOffset(8, 32),
        BackgroundColor3 = COR.desligado,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, frame)
    canto(trilho, 4)

    local preenchido = novo("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COR.destaque,
        BorderSizePixel = 0,
    }, trilho)
    canto(preenchido, 4)

    local pino = novo("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, trilho)
    canto(pino, 7)

    local function pintar(animado)
        local valor = tonumber(getPath(item.path)) or item.min
        local fracao = math.clamp((valor - item.min) / math.max(0.0001, item.max - item.min), 0, 1)
        local texto = (passo < 1) and string.format("%.1f", valor) or tostring(math.floor(valor))
        rotulo.Text = item.label .. "   " .. texto .. (item.sufixo or "")
        if animado then
            animar(preenchido, 0.12, { Size = UDim2.new(fracao, 0, 1, 0) })
            animar(pino, 0.12, { Position = UDim2.fromScale(fracao, 0.5) })
        else
            preenchido.Size = UDim2.new(fracao, 0, 1, 0)
            pino.Position = UDim2.fromScale(fracao, 0.5)
        end
    end

    local function aplicarDoPonteiro(posX)
        local fracao = math.clamp((posX - trilho.AbsolutePosition.X)
            / math.max(1, trilho.AbsoluteSize.X), 0, 1)
        local bruto = item.min + fracao * (item.max - item.min)
        local valor = math.floor(bruto / passo + 0.5) * passo
        valor = tonumber(string.format("%.2f", valor)) or item.min
        if valor ~= getPath(item.path) then
            setPath(item.path, valor)
            pintar(false)
        end
    end

    trilho.InputBegan:Connect(function(entrada)
        if entrada.UserInputType == Enum.UserInputType.MouseButton1
            or entrada.UserInputType == Enum.UserInputType.Touch then
            animar(pino, 0.1, { Size = UDim2.fromOffset(18, 18) })
            aplicarDoPonteiro(entrada.Position.X)
            comecarArrasto(function(ponteiro)
                aplicarDoPonteiro(ponteiro.X)
            end, function()
                animar(pino, 0.1, { Size = UDim2.fromOffset(14, 14) })
                mudou(item.path)
            end)
        end
    end)

    pintar(false)
    registrar(function(animado)
        pintar(animado == true)
    end)
    return frame
end

local function criarCiclo(item)
    local frame = linhaBase(38)

    novo("TextLabel", {
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = item.alerta and COR.aviso or COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    local botao = novo("TextButton", {
        Size = UDim2.fromOffset(124, 28),
        Position = UDim2.new(1, -132, 0, 5),
        BackgroundColor3 = COR.linha,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = COR.texto,
        Text = "",
        AutoButtonColor = false,
    }, frame)
    canto(botao, 6)
    brilho(botao, COR.linha, COR.destaque)

    local function pintar()
        local valor = getPath(item.path)
        botao.Text = tostring(item.nomes and item.nomes[valor] or valor)
    end

    botao.MouseButton1Click:Connect(function()
        local atual = getPath(item.path)
        local indice = 1
        for posicao, opcao in ipairs(item.opcoes) do
            if opcao == atual then
                indice = posicao
            end
        end
        setPath(item.path, item.opcoes[(indice % #item.opcoes) + 1])
        pintar()
        botao.TextTransparency = 1
        animar(botao, 0.2, { TextTransparency = 0 })
        mudou(item.path)
    end)

    pintar()
    registrar(pintar)
    return frame
end

-- Campo de texto. item.lista = lista separada por virgula.
-- item.validar(texto) -> ok, motivo: um valor recusado nao e gravado.
local function criarCampo(item)
    local frame = linhaBase(54)

    local function mostrar()
        local valor = getPath(item.path)
        if type(valor) == "table" then
            return table.concat(valor, ", ")
        end
        return tostring(valor or "")
    end

    novo("TextLabel", {
        Size = UDim2.new(1, -8, 0, 20),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = item.alerta and COR.aviso or COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    local caixa = novo("TextBox", {
        Size = UDim2.new(1, -16, 0, 26),
        Position = UDim2.fromOffset(8, 22),
        BackgroundColor3 = COR.linha,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = COR.texto,
        PlaceholderText = item.dica or "",
        ClearTextOnFocus = false,
        Text = mostrar(),
    }, frame)
    canto(caixa, 6)
    novo("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, caixa)
    local traco = novo("UIStroke", { Color = COR.linha, Thickness = 1 }, caixa)

    caixa.Focused:Connect(function()
        animar(traco, 0.15, { Color = COR.destaque })
    end)
    caixa.FocusLost:Connect(function()
        animar(traco, 0.15, { Color = COR.linha })
        local texto = string.match(caixa.Text, "^%s*(.-)%s*$") or ""
        if item.lista then
            local lista = {}
            for parte in string.gmatch(texto, "[^,]+") do
                parte = string.match(parte, "^%s*(.-)%s*$")
                if parte ~= "" and not listaContem(lista, parte) then
                    lista[#lista + 1] = parte
                end
            end
            setPath(item.path, lista)
        else
            if item.validar then
                local ok, motivo = item.validar(texto)
                if not ok then
                    caixa.Text = mostrar()
                    setStatus(motivo)
                    return
                end
            end
            setPath(item.path, texto)
        end
        caixa.Text = mostrar()
        mudou(item.path)
    end)

    registrar(function()
        if not caixa:IsFocused() then
            caixa.Text = mostrar()
        end
    end)
    return frame
end

local function criarPref(chave, label, desc)
    return criarToggle({ path = "__pref__." .. chave, label = label, desc = desc })
end

local function criarBotao(texto, cor, aoClicar)
    local frame = linhaBase(42)
    local botao = novo("TextButton", {
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.fromOffset(8, 5),
        BackgroundColor3 = cor,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1),
        Text = texto,
        AutoButtonColor = false,
    }, frame)
    canto(botao, 7)
    botao.MouseEnter:Connect(function()
        animar(botao, 0.12, { Size = UDim2.new(1, -10, 0, 34), Position = UDim2.fromOffset(5, 4) })
    end)
    botao.MouseLeave:Connect(function()
        animar(botao, 0.12, { Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 5) })
    end)
    botao.MouseButton1Click:Connect(aoClicar)
    return frame
end

local function criarTexto(texto, cor, altura)
    local frame = linhaBase(altura or 56)
    local rotulo = novo("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = cor or COR.fraco,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = texto,
    }, frame)
    return frame, rotulo
end

local PADROES_WEBHOOK = {
    "^https://discord%.com/api/webhooks/%d+/[%w%-_]+$",
    "^https://discordapp%.com/api/webhooks/%d+/[%w%-_]+$",
    "^https://canary%.discord%.com/api/webhooks/%d+/[%w%-_]+$",
    "^https://ptb%.discord%.com/api/webhooks/%d+/[%w%-_]+$",
}
local function validarWebhook(url)
    if url == "" then
        return true
    end
    for _, padrao in ipairs(PADROES_WEBHOOK) do
        if string.match(url, padrao) then
            return true
        end
    end
    return false, "isso nao e um webhook do Discord: nada foi gravado"
end

local function validarId(id)
    if id == "" or string.match(id, "^%d+$") then
        return true
    end
    return false, "o ID do Discord tem so numeros: nada foi gravado"
end

-- o mesmo padrao do motor: so endereco de Cloudflare Worker
local function validarRelay(url)
    if url == "" or string.match(url, "^https://[%w%-]+%.[%w%-]+%.workers%.dev/[%w%-/]*$") then
        return true
    end
    return false, "o motor so aceita https://<nome>.<conta>.workers.dev/...: nada foi gravado"
end

--==========================================================================
-- 9. Paginas
--==========================================================================
local TAREFAS = {
    { "pet_me", "Fazer carinho" }, { "hungry", "Fome" }, { "thirsty", "Sede" },
    { "dirty", "Banho" }, { "toilet", "Banheiro" }, { "sleepy", "Sono" },
    { "play", "Brincar" }, { "sick", "Doente, hospital" }, { "mystery", "Misterio" },
    { "salon", "Salao" }, { "school", "Escola" }, { "pizza_party", "Festa de pizza" },
    { "cat_cafe", "Cafe dos gatos" }, { "camping", "Acampamento" },
    { "beach_party", "Praia" }, { "bored", "Parquinho" },
    { "walk", "Passear" }, { "ride", "Carrinho" },
}
local LENTAS = {
    salon = true, school = true, pizza_party = true, cat_cafe = true,
    camping = true, beach_party = true, bored = true, walk = true, ride = true,
}
local RAPIDAS_ESPERA = { { "pet_me", "Carinho" }, { "hungry", "Comida" }, { "thirsty", "Agua" }, { "play", "Brinquedo" } }
local POCOES = {
    { "pet_age_potion", "pocao de idade" },
    { "tiny_pet_age_potion", "pocao de idade pequena" },
    { "pet_bonus_bucks_potion", "pocao de Bucks" },
}
local CRIPTA = {
    { "ladder", "Escada para o proximo andar" },
    { "twig", "Graveto" },
    { "candy_corn_pile_ginormous", "Pilha grande de doces" },
    { "candy_corn_pile_small", "Pilha pequena de doces" },
}
local DOCES = {
    { "halloween_2026_jump_scare", "Jump Scare" },
    { "halloween_2026_jacobean_pigeon", "Pombo Jacobino" },
}
local TECLAS = { "RightShift", "LeftShift", "RightControl", "LeftControl", "RightAlt", "LeftAlt", "Insert", "Home",
    "End", "Delete", "PageUp", "PageDown", "F1", "F2", "F3", "F4", "F6", "F7", "F8", "F9", "K", "M", "P" }

local function ids(lista)
    local saida = {}
    for _, par in ipairs(lista) do
        saida[#saida + 1] = par[1]
    end
    return saida
end

local paginas = {}

local function aba(nome, construir)
    table.insert(paginas, { nome = nome, construir = construir })
end

-------------------------------------------------------------------- Farm
aba("Farm", function()
    tituloSecao("principal")
    criarToggle({ path = "Farm.Enabled", label = "Farm ligado",
        desc = "Desligado, o motor so observa: nenhuma acao no jogo." })
    criarToggle({ path = "Farm.AutoNeeds.Enabled", label = "Fazer as necessidades",
        desc = "Chave geral do motor 2.1. Desligada, nenhuma necessidade e feita." })
    criarToggle({ path = "Farm.BabyMode", label = "Modo bebe",
        desc = "Entra no time Babies para fazer tambem as necessidades do bebe." })
    criarToggle({ path = "Farm.GameTravel", label = "Usar as portas do proprio jogo" })
    criarToggle({ path = "Farm.HomeByRespawn", label = "Voltar pra casa renascendo" })
    criarToggle({ path = "Farm.FastTravel", label = "Viagem rapida", alerta = true,
        desc = "O motor 2.1.2 nao le esta chave." })
    criarToggle({ path = "Farm.AutoAcceptMenu", label = "Apertar Play no menu sozinho" })
    criarToggle({ path = "Farm.AntiAfk", label = "Anti-AFK",
        desc = "Clique virtual quando o Roblox avisa que voce esta parado." })
    criarToggle({ path = "Farm.CameraGuard", label = "Protecao da camera",
        desc = "Se a camera entrar no personagem, ela e afastada de novo." })

    tituloSecao("pets")
    criarToggle({ path = "Farm.KeepPetEquipped", label = "Manter um pet equipado" })
    criarToggle({ path = "Farm.SkipFullGrown", label = "Trocar pet adulto por um que cresce" })
    criarToggle({ path = "Farm.PreferNeon", label = "Neons que crescem primeiro" })
    criarCiclo({ path = "Farm.PetOrder", label = "Qual pet cresce primeiro",
        opcoes = { "youngest", "oldest" }, nomes = { youngest = "mais novo", oldest = "mais velho" } })
    criarCampo({ path = "Farm.FarmPetKinds", label = "Tipos de pet com prioridade",
        dica = "ex.: dog, cat   vazio = qualquer um", lista = true })
    criarCampo({ path = "Farm.Focus", label = "Megar um pet (Focus)", alerta = true,
        dica = "um tipo de pet, ex.: dog   vazio = desligado" })
    criarTexto("Focus: incompleto no 2.1.2. Limita pocoes, neon e Pet Pen a esse tipo; o resto da "
        .. "funcao (comprar e chocar ovos em repeticao) nao esta no motor.", COR.aviso, 42)

    tituloSecao("pocoes")
    criarToggle({ path = "Farm.AutoPotions.Enabled", label = "Usar pocoes no pet que cresce" })
    criarTexto("Pocoes que o farm conhece:", COR.fraco, 18)
    for _, pocao in ipairs(POCOES) do
        criarMembro({ path = "Farm.AutoPotions.Potions", valor = pocao[1], label = "Conhece a " .. pocao[2],
            ordem = ids(POCOES) })
    end
    criarTexto("E dessas, quais pode usar:", COR.fraco, 18)
    for _, pocao in ipairs(POCOES) do
        criarMembro({ path = "Farm.AutoPotions.Skip", valor = pocao[1], label = "Pode usar a " .. pocao[2],
            inverso = true })
    end
    criarCampo({ path = "Farm.AutoPotions.PetKinds", label = "Pocoes so nestes tipos",
        dica = "vazio = no pet que o farm estiver cuidando", lista = true })

    tituloSecao("neon")
    criarToggle({ path = "Farm.AutoNeon.Enabled", label = "Fundir 4 adultos em 1 neon", alerta = true,
        desc = "Nao tem volta: 4 pets adultos do mesmo tipo viram 1 neon." })
    criarToggle({ path = "Farm.AutoNeon.Mega", label = "Fundir 4 neons em 1 mega neon", alerta = true,
        desc = "Nao tem volta: 4 neons adultos do mesmo tipo viram 1 mega neon." })
    criarCampo({ path = "Farm.AutoNeon.Exclude", label = "Nunca fundir estes tipos",
        dica = "ex.: dog, cat", lista = true })

    tituloSecao("presentes")
    criarToggle({ path = "Farm.AutoOpen.Enabled", label = "Abrir presentes e bauzinhos" })
    criarCampo({ path = "Farm.AutoOpen.Exclude", label = "Nunca abrir estes",
        dica = "ids separados por virgula", lista = true })

    tituloSecao("compras")
    criarToggle({ path = "Farm.BuyWater", label = "Comprar agua quando faltar", alerta = true })
    criarToggle({ path = "Farm.BuyFood", label = "Comprar comida quando faltar", alerta = true })
    criarToggle({ path = "Farm.BuyEgg", label = "Comprar ovo quando nada crescer", alerta = true,
        desc = "Gasta Bucks. Nunca compra nada que custe Robux." })
    criarCiclo({ path = "Farm.EggToBuy", label = "Ovo a comprar",
        opcoes = { "cracked_egg", "pet_egg", "fairytale_egg_2026_fairytale_egg" },
        nomes = { cracked_egg = "rachado, 350", pet_egg = "de pet, 600", fairytale_egg_2026_fairytale_egg = "de conto" } })
    criarSlider({ path = "Farm.MaxBuysPerSession", label = "Limite de comida e agua por sessao",
        min = 0, max = 50, sufixo = "   0 = sem limite" })
    criarSlider({ path = "Farm.MaxEggBuysPerSession", label = "Limite de ovos por sessao",
        min = 0, max = 20, sufixo = "   0 = sem limite" })

    tituloSecao("outros")
    criarToggle({ path = "Farm.CollectCashback", label = "Coletar cashback" })
    criarSlider({ path = "Farm.CashbackMinutes", label = "Coletar cashback a cada",
        min = 1, max = 60, sufixo = " min" })
    criarCiclo({ path = "Farm.SpotTravel", label = "Acampamento, praia, parquinho",
        opcoes = { "teleport", "door" }, nomes = { teleport = "teleporte", door = "porta da loja" } })
    criarToggle({ path = "Farm.FoodBowlTrip", label = "Ir pra casa pelo pote de comida",
        desc = "Mesmo com comida na mochila. Desligado, alimenta onde estiver." })
end)

----------------------------------------------------------------- Tarefas
aba("Tarefas", function()
    criarTexto("Cada chave e uma necessidade que o farm resolve sozinho. Elas so valem com "
        .. "'Fazer as necessidades' ligado na aba Farm.", COR.fraco, 40)

    criarBotao("LIGAR TODAS AS TAREFAS", COR.linha, function()
        for _, tarefa in ipairs(TAREFAS) do
            Cfg.Farm.Tasks[tarefa[1]] = true
        end
        Cfg.Farm.AutoNeeds.Enabled = true
        Cfg.Farm.AutoNeeds.Skip = {}
        marcarSujo()
        repintarTudo()
        setStatus("todas as tarefas ligadas")
    end)
    criarBotao("SO AS RAPIDAS", COR.linha, function()
        for _, tarefa in ipairs(TAREFAS) do
            Cfg.Farm.Tasks[tarefa[1]] = not LENTAS[tarefa[1]]
        end
        Cfg.Farm.AutoNeeds.Enabled = true
        marcarSujo()
        repintarTudo()
        setStatus("so as tarefas rapidas")
    end)

    tituloSecao("rapidas, feitas em casa")
    for _, tarefa in ipairs(TAREFAS) do
        if not LENTAS[tarefa[1]] then
            criarToggle({ path = "Farm.Tasks." .. tarefa[1], label = tarefa[2] })
        end
    end
    tituloSecao("lentas, exigem viagem ou caminhada")
    for _, tarefa in ipairs(TAREFAS) do
        if LENTAS[tarefa[1]] then
            criarToggle({ path = "Farm.Tasks." .. tarefa[1], label = tarefa[2] })
        end
    end

    tituloSecao("lista de pular do motor")
    criarTexto("Outra forma de desligar uma necessidade: a lista Skip do motor. Ligada aqui = pulada.",
        COR.fraco, 30)
    for _, tarefa in ipairs(TAREFAS) do
        criarMembro({ path = "Farm.AutoNeeds.Skip", valor = tarefa[1], label = "Pular: " .. tarefa[2],
            ordem = ids(TAREFAS) })
    end

    tituloSecao("enquanto espera")
    criarToggle({ path = "Farm.MultiNeed.Enabled", label = "Necessidades rapidas durante a espera",
        desc = "Parado num lugar esperando, faz as rapidas marcadas abaixo." })
    for _, rapida in ipairs(RAPIDAS_ESPERA) do
        criarMembro({ path = "Farm.MultiNeed.Kinds", valor = rapida[1], label = "Durante a espera: " .. rapida[2],
            ordem = ids(RAPIDAS_ESPERA) })
    end
    criarSlider({ path = "Farm.MultiNeed.GapSeconds", label = "Pausa entre duas rapidas",
        min = 0, max = 10, passo = 0.5, sufixo = " s" })
end)

------------------------------------------------------------- Prioridades
aba("Prioridades", function()
    criarToggle({ path = "Farm.SmartPriority", label = "Primeiro o que da pra fazer aqui",
        desc = "Soma pontos para necessidades do lugar onde voce ja esta." })
    criarTexto("Numero maior roda primeiro quando varias necessidades estao abertas. "
        .. "O padrao poe as rapidas na frente.", COR.fraco, 40)
    criarBotao("RESTAURAR PRIORIDADES PADRAO", COR.linha, function()
        Cfg.Farm.Priority = defaults().Farm.Priority
        marcarSujo()
        repintarTudo()
        setStatus("prioridades restauradas")
    end)
    tituloSecao("ordem das tarefas")
    local lista = {}
    for _, tarefa in ipairs(TAREFAS) do
        table.insert(lista, tarefa)
    end
    table.sort(lista, function(a, b)
        return (Cfg.Farm.Priority[a[1]] or 0) > (Cfg.Farm.Priority[b[1]] or 0)
    end)
    for _, tarefa in ipairs(lista) do
        criarSlider({ path = "Farm.Priority." .. tarefa[1], label = tarefa[2], min = 0, max = 60 })
    end
end)

------------------------------------------------------------------ Evento
aba("Evento", function()
    criarTexto("Halloween 2026 e Pet Pen. A chave principal precisa estar ligada.", COR.fraco, 26)
    criarToggle({ path = "Farm.Event.Enabled", label = "Evento ligado, chave principal" })

    tituloSecao("ghost gallery")
    criarToggle({ path = "Farm.Event.GhostGallery", label = "Jogar toda rodada",
        desc = "Aspira os fantasmas. Da doces e chaves enferrujadas." })
    criarToggle({ path = "Farm.Event.GhostJoinByZone", label = "Entrar pelo circulo da Mansao",
        desc = "Como o Sim do aviso do jogo. A forma mais segura de entrar." })

    tituloSecao("hauntlet")
    criarToggle({ path = "Farm.Event.Hauntlet", label = "Jogar o Hauntlet", alerta = true,
        desc = "Incompleto no 2.1.2: faltam as funcoes de andar na corrida. Vai ao Hotel e falha." })
    criarCiclo({ path = "Farm.Event.HauntletMove", label = "Como chega no circulo da porta", alerta = true,
        opcoes = { "tween", "walk", "tp" }, nomes = { tween = "deslizando", walk = "andando", tp = "teleporte" } })
    criarSlider({ path = "Farm.Event.HauntletMoveSeconds", label = "Tempo do deslize", alerta = true,
        min = 0.1, max = 5, passo = 0.1, sufixo = " s" })
    criarToggle({ path = "Farm.Event.HauntletFirst", label = "Hauntlet antes do Ghost Gallery", alerta = true,
        desc = "O motor 2.1.2 nao le esta chave." })
    criarToggle({ path = "Farm.Event.HauntletSquad", label = "Suas contas jogam em equipe", alerta = true,
        desc = "Celular, chaves e varinha por turnos entre as suas contas na mesma corrida." })
    criarCampo({ path = "Farm.Event.HauntletSquadKey", label = "Chave privada do esquadrao", alerta = true,
        dica = "no 2.1.2 nada usa esta chave" })

    tituloSecao("cripta")
    criarToggle({ path = "Farm.Event.Crypt", label = "Usar as chaves enferrujadas" })
    criarToggle({ path = "Farm.Event.MummySpider", label = "Pegar a Aranha Mumia no fundo" })
    criarTexto("O que uma chave abre, nesta ordem:", COR.fraco, 20)
    for _, recompensa in ipairs(CRIPTA) do
        criarMembro({ path = "Farm.Event.CryptOpen", valor = recompensa[1], label = recompensa[2],
            ordem = ids(CRIPTA) })
    end
    criarToggle({ path = "Farm.Event.AutoSkelicorn", label = "Skelicorn automatico", alerta = true,
        desc = "Incompleto no 2.1.2: faltam os ids da alavanca. Ligado, a Cripta falha toda vez." })

    tituloSecao("ninho e gato")
    criarToggle({ path = "Farm.Event.PigeonNest", label = "Levar gravetos ao ninho do Hotel" })
    criarToggle({ path = "Farm.Event.AutoNest", label = "Gravetos primeiro ate o ninho ficar pronto" })
    criarToggle({ path = "Farm.Event.StrayCat", label = "Agua para o gato de rua, 1 por dia" })

    tituloSecao("missoes")
    criarToggle({ path = "Farm.Event.Quests", label = "Resgatar missoes concluidas" })
    criarToggle({ path = "Farm.Event.HouseVisits", label = "Visitar casas para a missao" })

    tituloSecao("pet pen")
    criarToggle({ path = "Farm.Event.PetPen", label = "Gerenciar o Pet Pen" })
    criarToggle({ path = "Farm.Event.PetPenStock", label = "Manter o Pet Pen cheio",
        desc = "Compra ovos para encher as vagas. Precisa de Comprar ovo ligado." })
    criarSlider({ path = "Farm.Event.PetPenSlots", label = "Vagas do Pet Pen", min = 1, max = 5 })
    criarSlider({ path = "Farm.Event.PetPenMinutes", label = "Coletar o Pet Pen a cada",
        min = 1, max = 60, sufixo = " min" })
    criarSlider({ path = "Farm.Event.PetPenStockMinBucks", label = "So compra ovo acima de",
        min = 0, max = 5000, passo = 50, sufixo = " Bucks" })

    tituloSecao("loja de doces")
    criarToggle({ path = "Farm.Event.CandyPets.Enabled", label = "Comprar pets com doces", alerta = true,
        desc = "Gasta doces nos pets marcados abaixo." })
    for indice, pet in ipairs(DOCES) do
        criarMembro({ path = "Farm.Event.CandyPets.Pick", valor = pet[1], label = "Comprar " .. pet[2],
            ordem = ids(DOCES) })
        criarSlider({ path = "Farm.Event.CandyPets.Buy." .. indice .. ".price", label = pet[2] .. ", preco",
            min = 0, max = 200000, passo = 1000, sufixo = " doces" })
        criarSlider({ path = "Farm.Event.CandyPets.Buy." .. indice .. ".max", label = pet[2] .. ", quantos ter",
            min = 0, max = 20, sufixo = "   0 = sem limite" })
    end
    criarSlider({ path = "Farm.Event.CandyPets.KeepCandy", label = "Guardar sempre",
        min = 0, max = 200000, passo = 5000, sufixo = " doces" })
end)

---------------------------------------------------------------- Avancado
aba("Avancado", function()
    criarTexto("Mexer aqui muda o ritmo e a tolerancia a falhas do motor.", COR.aviso, 26)

    tituloSecao("ritmo")
    criarSlider({ path = "General.TickSeconds", label = "Intervalo do laco principal",
        min = 0.1, max = 5, passo = 0.1, sufixo = " s   vale ao reiniciar" })
    criarSlider({ path = "Farm.PetMeFocusSeconds", label = "Tempo de carinho", alerta = true,
        min = 3, max = 20, sufixo = " s   o 2.1.2 nao le" })
    criarCampo({ path = "General.ScriptName", label = "Nome do motor nas mensagens",
        dica = "vale ao reiniciar" })

    tituloSecao("falhas")
    criarSlider({ path = "Farm.FailureCooldownSeconds", label = "Espera apos uma falha",
        min = 5, max = 180, sufixo = " s" })
    criarSlider({ path = "Farm.MaxConsecutiveFailures", label = "Falhas seguidas ate a pausa",
        min = 1, max = 10 })
    criarSlider({ path = "Farm.DisableMinutes", label = "Tempo de pausa",
        min = 0, max = 60, sufixo = " min   0 = a sessao toda" })

    tituloSecao("quando trava")
    criarToggle({ path = "Farm.StuckRecovery.Enabled", label = "Voltar pra casa se travar",
        desc = "Parado no mesmo lugar e falhando tarefas: renasce em casa." })
    criarSlider({ path = "Farm.StuckRecovery.Seconds", label = "Considerar travado apos",
        min = 60, max = 600, passo = 30, sufixo = " s" })
    criarToggle({ path = "Farm.AutoRejoin", label = "Reentrar no jogo se travar", alerta = true,
        desc = "Sem lugar ou personagem: entra num servidor PUBLICO do jogo." })
    criarSlider({ path = "Farm.StuckRejoinSeconds", label = "Reentrar apos",
        min = 60, max = 600, passo = 30, sufixo = " s" })

    tituloSecao("experimental")
    criarToggle({ path = "Farm.HouseDoorExit", label = "Sair de casa pela porta", alerta = true,
        desc = "No teste do autor isto nunca funcionou." })

    tituloSecao("painel")
    criarPref("AutoIniciar", "Iniciar o farm junto com o painel")
    criarPref("AbrirMinimizado", "Abrir ja minimizado")
    criarPref("Animacoes", "Animacoes ligadas", "Desligue se o seu aparelho estiver pesado.")
end)

------------------------------------------------------------- Privacidade
aba("Privacidade", function()
    tituloSecao("telemetria, vale ao reiniciar")
    criarTexto("No 2.1.2 o endereco do autor esta vazio: ligada sem endereco, nada sai. Com um "
        .. "endereco, seu nome do Roblox, seu ID e um resumo da sessao vao para ele.", COR.aviso, 42)
    criarToggle({ path = "Telemetry.Enabled", label = "Enviar telemetria", alerta = true })
    criarCampo({ path = "Telemetry.Url", label = "Endereco do relay", alerta = true,
        dica = "https://nome.conta.workers.dev/log   vazio = nada sai", validar = validarRelay })
    criarCampo({ path = "Telemetry.Owner", label = "Nome do dono do relay", dica = "so aparece no relatorio" })
    criarSlider({ path = "Telemetry.SummaryMinutes", label = "Enviar a cada",
        min = 5, max = 120, sufixo = " min" })
    criarToggle({ path = "Telemetry.IncludeInventory", label = "Incluir resumo do inventario", alerta = true,
        desc = "Contagem de itens e pets no relatorio." })

    tituloSecao("webhook do discord, seu")
    criarTexto("Opcional e so para voce. Vazio nao envia nada. So aceita endereco do Discord.", COR.fraco, 26)
    criarToggle({ path = "Notifications.Enabled", label = "Enviar avisos para o meu Discord" })
    criarCampo({ path = "Notifications.Webhooks.Summary", label = "Webhook de resumo",
        dica = "https://discord.com/api/webhooks/...", validar = validarWebhook })
    criarCampo({ path = "Notifications.Webhooks.Alerts", label = "Webhook de alertas",
        dica = "vazio usa o de resumo", validar = validarWebhook })
    criarCampo({ path = "Notifications.PingDiscordUserId", label = "Meu ID do Discord para mencao",
        dica = "so numeros", validar = validarId })
    criarToggle({ path = "Notifications.IncludeUsername", label = "Incluir meu nome nas mensagens" })

    tituloSecao("quando avisar")
    criarToggle({ path = "Notifications.SendSummary", label = "Resumo periodico" })
    criarSlider({ path = "Notifications.SummaryIntervalMinutes", label = "Resumo a cada",
        min = 0, max = 120, sufixo = " min   0 = nunca" })
    criarToggle({ path = "Notifications.SendOnStartStop", label = "Ao iniciar e parar" })
    criarToggle({ path = "Notifications.SendOnError", label = "Em erro" })
    criarToggle({ path = "Notifications.SendOnKick", label = "Ao ser desconectado" })
    criarToggle({ path = "Notifications.SendOnTaskComplete", label = "A cada tarefa concluida",
        desc = "Gera muitas mensagens." })
    criarToggle({ path = "Notifications.SendTestMessageOnStart", label = "Mensagem de teste ao iniciar" })

    tituloSecao("mencionar meu id")
    criarToggle({ path = "Notifications.Ping", label = "Mencionar, chave geral" })
    criarToggle({ path = "Notifications.PingOn.Kick", label = "Desconexao" })
    criarToggle({ path = "Notifications.PingOn.Error", label = "Erro" })
    criarToggle({ path = "Notifications.PingOn.Summary", label = "Resumo" })
    criarToggle({ path = "Notifications.PingOn.TaskCompleted", label = "Tarefa concluida" })
    criarToggle({ path = "Notifications.PingOn.SessionStopped", label = "Sessao encerrada" })
    criarToggle({ path = "Notifications.PingOn.PreviousSession", label = "Sessao anterior caiu" })

    tituloSecao("limites de envio")
    criarSlider({ path = "Notifications.AlertCooldownSeconds", label = "Espera entre alertas",
        min = 10, max = 600, sufixo = " s" })
    criarSlider({ path = "Notifications.MinSecondsBetweenMessages", label = "Espera entre mensagens",
        min = 1, max = 10, passo = 0.5, sufixo = " s" })
    criarSlider({ path = "Notifications.MaxQueueSize", label = "Mensagens na fila, no maximo",
        min = 5, max = 200, passo = 5 })
    criarSlider({ path = "Notifications.MaxRetries", label = "Tentativas por mensagem",
        min = 0, max = 10 })

    tituloSecao("registro")
    criarCiclo({ path = "Logging.ConsoleLevel", label = "Mensagens no console",
        opcoes = { "OFF", "INFO", "DEBUG", "SUCCESS", "WARN", "ERROR" } })
    criarToggle({ path = "Logging.FileEnabled", label = "Gravar arquivo de log, vale ao reiniciar" })
    criarCiclo({ path = "Logging.FileLevel", label = "Nivel do arquivo",
        opcoes = { "OFF", "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR" } })
    criarToggle({ path = "Logging.SessionFile", label = "Gravar estado da sessao" })
    criarCampo({ path = "Logging.Folder", label = "Pasta do log", dica = "ShxdragHub/logs" })
    criarSlider({ path = "Logging.FlushSeconds", label = "Gravar em disco a cada",
        min = 1, max = 60, sufixo = " s" })
    criarSlider({ path = "Logging.DuplicateWindowSeconds", label = "Juntar linhas repetidas por",
        min = 1, max = 60, sufixo = " s" })
    criarSlider({ path = "Logging.MaxLinesPerSession", label = "Maximo de linhas por sessao",
        min = 1000, max = 50000, passo = 1000 })
end)

-------------------------------------------------------- Janela do motor
aba("Janela motor", function()
    criarTexto("A janela PROPRIA do motor. Baixa a biblioteca WindUI do GitHub ao abrir e, no 2.1.2, "
        .. "chama funcoes de outra biblioteca: o mais provavel e nao abrir. Ligada, ela tambem le "
        .. "AdoptMeFarm/window_settings.txt, que pode passar por cima das opcoes deste painel.",
        COR.aviso, 70)
    criarToggle({ path = "Interface.Enabled", label = "Abrir a janela do motor ao iniciar", alerta = true })
    criarBotao("ABRIR A JANELA DO MOTOR AGORA", COR.linha, function()
        local api = farmApi()
        if not api or type(api.OpenInterface) ~= "function" then
            setStatus("inicie o farm primeiro")
            return
        end
        task.spawn(function()
            local ok, abriu = pcall(api.OpenInterface)
            setStatus((ok and abriu) and "janela do motor aberta"
                or "a janela do motor nao abriu (veja o console, F9)")
        end)
    end)

    tituloSecao("opcoes dela, valem ao reiniciar")
    criarCiclo({ path = "Interface.Keybind", label = "Tecla de mostrar e esconder", opcoes = TECLAS })
    criarToggle({ path = "Interface.Toasts", label = "Avisos de chave, neon, compra e rodada" })
    criarToggle({ path = "Interface.RememberSettings", label = "Lembrar o que mudar nela" })
    criarCiclo({ path = "Interface.Theme", label = "Tema",
        opcoes = { "Halloween", "Default", "Fresh", "Dark Minimal" } })
    criarToggle({ path = "Interface.Descriptions", label = "Linhas de ajuda" })
    criarCampo({ path = "Interface.Autoload", label = "Configuracao salva para carregar",
        dica = "nome de uma config da janela   vazio = nenhuma" })
    criarToggle({ path = "Interface.StartHidden", label = "Comecar escondida" })
    criarCiclo({ path = "Interface.UIScale", label = "Tamanho",
        opcoes = { "Auto", "0.5", "0.6", "0.7", "0.8", "0.9", "1", "1.1", "1.25" } })
    criarCiclo({ path = "Interface.Language", label = "Idioma",
        opcoes = { "Auto", "pt", "en", "es", "tr" } })
end)

------------------------------------------------------------------ Status
local function mmss(segundos)
    segundos = math.max(0, math.floor(tonumber(segundos) or 0))
    return string.format("%02d:%02d", math.floor(segundos / 60), segundos % 60)
end

local function textoStatus(api, s)
    local pets = {}
    for _, pet in ipairs(type(s.pets) == "table" and s.pets or {}) do
        pets[#pets + 1] = tostring(pet.kind) .. " idade " .. tostring(pet.age or "?")
    end
    local abertas = {}
    for _, necessidade in ipairs(type(s.needs) == "table" and s.needs or {}) do
        abertas[#abertas + 1] = (necessidade.owner == "baby" and "bebe " or "") .. tostring(necessidade.kind)
            .. (necessidade.inProgress and "*" or "")
    end
    local pausa = {}
    for _, chave in ipairs(type(s.disabled) == "table" and s.disabled or {}) do
        local minutos = type(s.restMinutes) == "table" and s.restMinutes[chave]
        pausa[#pausa + 1] = tostring(chave) .. (minutos and (" (" .. tostring(minutos) .. " min)") or "")
    end
    local pen = type(s.pen) == "table" and s.pen or nil
    local penTexto = "desligado"
    if s.petPenEnabled ~= false then
        if pen and pen.known then
            penTexto = string.format("%d/%d, coleta %s", tonumber(pen.pets) or 0, tonumber(pen.slots) or 4,
                (tonumber(pen.nextClaimIn) or 0) > 0 and ("em " .. mmss(pen.nextClaimIn)) or "agora")
        else
            penTexto = "sem dados ainda"
        end
    end
    local estado = "rodando"
    if s.stopped then
        estado = "parado"
    elseif not s.farmEnabled then
        estado = "pausado: Farm ligado esta desligado"
    elseif not s.ready then
        estado = "esperando o jogo carregar"
    end
    return table.concat({
        "Motor v" .. tostring(s.version or api.Version) .. "  |  " .. estado
            .. (s.preset and ("  |  predefinicao " .. tostring(s.preset)) or ""),
        string.format("Sessao: %d min  |  necessidades feitas: %s", tonumber(s.minutes) or 0, tostring(s.needsDone or 0)),
        "Tarefa agora: " .. tostring(s.task or "none") .. (s.sideTask and ("  +  " .. tostring(s.sideTask)) or ""),
        "Lugar: " .. tostring(s.place or "?") .. "  |  time: " .. tostring(s.team or "?"),
        string.format("Bucks: %s (+%s)  |  doces: %s (+%s)", tostring(s.bucks or "?"), tostring(s.bucksEarned or 0),
            tostring(s.candy or "?"), tostring(s.candyEarned or 0)),
        string.format("Tarefas: %s ok, %s falhas", tostring(s.tasksSucceeded or 0), tostring(s.tasksFailed or 0)),
        "Pets: " .. (#pets > 0 and table.concat(pets, ", ") or "nenhum"),
        "Necessidades abertas: " .. (#abertas > 0 and table.concat(abertas, ", ") or "nenhuma"),
        "Ghost Gallery: " .. (s.ghostEnabled == false and "desligado"
            or (s.nextRoundIn and ("em " .. mmss(s.nextRoundIn)) or "esperando")),
        "Pet Pen: " .. penTexto,
        string.format("Chaves: %s  |  gravetos: %s  |  ninho: %s/8", tostring(s.rustyKeys or "?"),
            tostring(s.twigs or "?"), tostring(s.nestTwigs or "?")),
        "Em pausa: " .. (#pausa > 0 and table.concat(pausa, ", ") or "nenhuma"),
    }, "\n")
end

local function acaoRapida(nome, rotulo)
    criarBotao(rotulo, COR.linha, function()
        local api = farmApi()
        if not api or type(api[nome]) ~= "function" then
            setStatus("inicie o farm primeiro")
            return
        end
        local ok, feito, mensagem = pcall(api[nome])
        if not ok then
            setStatus("erro: " .. tostring(feito))
        else
            setStatus(tostring(mensagem or (feito and "feito" or "nao deu agora")))
        end
    end)
end

local PREDEF_MOTOR = {
    { "Off", "TUDO DESLIGADO" },
    { "Balanced", "AUTOFARM COMPLETO" },
    { "Speedrun", "SPEEDRUN DA ARANHA MUMIA" },
    { "EventOnly", "SO O EVENTO" },
    { "NeedsOnly", "SO AS NECESSIDADES" },
}

aba("Status", function()
    local _, rotulo = criarTexto("", COR.texto, 210)
    rotulo.TextSize = 12

    registrar(function()
        local api = farmApi()
        if not api then
            rotulo.Text = "Farm parado.\n\nUse INICIAR no rodape."
            return
        end
        local ok, s = pcall(function()
            return type(api.Status) == "function" and api.Status() or nil
        end)
        if ok and type(s) == "table" then
            rotulo.Text = textoStatus(api, s)
        else
            rotulo.Text = "Motor v" .. tostring(api.Version) .. " rodando, sem resumo de estado."
        end
    end)

    tituloSecao("acoes rapidas")
    acaoRapida("GoHome", "IR PARA CASA")
    acaoRapida("SkipTask", "PULAR A TAREFA ATUAL")
    acaoRapida("ClaimPetPen", "COLETAR O PET PEN AGORA")
    acaoRapida("RetryDisabled", "TENTAR DE NOVO O QUE ESTA EM PAUSA")
    acaoRapida("TestWebhook", "ENVIAR TESTE PARA O MEU WEBHOOK")
    criarBotao("RELATORIO DO MOTOR NO CONSOLE (F9)", COR.linha, function()
        local api = farmApi()
        if not api or type(api.Disclosure) ~= "function" then
            setStatus("inicie o farm primeiro")
            return
        end
        pcall(api.Disclosure)
        setStatus("relatorio impresso no console, F9")
    end)

    tituloSecao("predefinicoes do motor")
    criarTexto("As do proprio autor. Aplicam no motor rodando e trazem os valores para este painel.",
        COR.fraco, 30)
    for _, predef in ipairs(PREDEF_MOTOR) do
        criarBotao(predef[2], COR.linha, function()
            local api = farmApi()
            if not api or type(api.ApplyPreset) ~= "function" then
                setStatus("inicie o farm primeiro: as predefinicoes do motor vivem nele")
                return
            end
            local ok, feito, nome = pcall(api.ApplyPreset, predef[1])
            if not ok or not feito then
                setStatus("nao aplicou: " .. tostring(ok and nome or feito))
                return
            end
            local trazidos = puxarDoMotor()
            repintarTudo()
            setStatus(string.format("predefinicao %s aplicada, %d opcoes trazidas para o painel", tostring(nome), trazidos))
        end)
    end

    tituloSecao("predefinicoes do painel")
    criarBotao("LIGAR TUDO", COR.linha, function()
        -- de fora: o que nao tem volta, gasta doces, sai do servidor ou esta incompleto
        local naoLigar = { HouseDoorExit = true, Hauntlet = true, AutoRejoin = true, FoodBowlTrip = true,
            AutoSkelicorn = true, HauntletFirst = true, HauntletSquad = true, FastTravel = true }
        local naoEntrar = { AutoNeon = true, CandyPets = true }
        local function ligar(node)
            for chave, valor in pairs(node) do
                if type(valor) == "table" then
                    if not naoEntrar[chave] then
                        ligar(valor)
                    end
                elseif type(valor) == "boolean" and not naoLigar[chave] then
                    node[chave] = true
                end
            end
        end
        ligar(Cfg.Farm)
        marcarSujo()
        repintarTudo()
        setStatus("tudo ligado, menos o que esta em laranja, fusao neon e compra com doces")
    end)
    criarBotao("SO O BASICO", COR.linha, function()
        local novoCfg = defaults()
        for tarefa in pairs(novoCfg.Farm.Tasks) do
            novoCfg.Farm.Tasks[tarefa] = false
        end
        for _, rapida in ipairs({ "pet_me", "hungry", "thirsty", "dirty", "toilet", "sleepy", "play", "mystery" }) do
            novoCfg.Farm.Tasks[rapida] = true
        end
        for chave, valor in pairs(novoCfg.Farm.Event) do
            if type(valor) == "boolean" then
                novoCfg.Farm.Event[chave] = false
            end
        end
        novoCfg.Notifications = deepCopy(Cfg.Notifications)
        Cfg = novoCfg
        marcarSujo()
        repintarTudo()
        setStatus("predefinicao basica aplicada")
    end)
    criarBotao("DESLIGAR TUDO", COR.linha, function()
        local function desligar(node)
            for chave, valor in pairs(node) do
                if type(valor) == "table" then
                    desligar(valor)
                elseif type(valor) == "boolean" then
                    node[chave] = false
                end
            end
        end
        desligar(Cfg.Farm)
        marcarSujo()
        repintarTudo()
        setStatus("tudo desligado")
    end)

    tituloSecao("motor")
    criarBotao("ATUALIZAR MOTOR, baixa de novo e fixa", COR.destaque, function()
        setStatus("baixando...")
        task.spawn(function()
            local fonte, como = fetchEngine(true)
            if fonte then
                engineSource = fonte
                setStatus(string.format("motor v%s %s, %d bytes: vale no proximo INICIAR",
                    tostring(versaoDo(fonte) or "?"), como, #fonte))
            else
                setStatus("falhou: " .. tostring(como))
            end
        end)
    end)
    criarBotao("COPIAR CONFIGURACAO", COR.linha, function()
        if type(setclipboard) ~= "function" then
            setStatus("seu executor nao tem setclipboard")
            return
        end
        local ok, texto = pcall(function()
            return Http:JSONEncode(Cfg)
        end)
        if ok then
            pcall(setclipboard, texto)
            setStatus("configuracao copiada, com o seu webhook se tiver um")
        else
            setStatus("nao deu para codificar a configuracao")
        end
    end)
    criarBotao("RESTAURAR PADROES DO PAINEL", COR.perigo, function()
        Cfg = defaults()
        marcarSujo()
        repintarTudo()
        setStatus("padroes restaurados")
    end)

    tituloSecao("janela")
    criarBotao("CENTRALIZAR ESTA JANELA", COR.linha, function()
        local tamanho = tamanhoTela()
        local altura = alturaAlvo()
        local x, y = ajustarArrasto(math.floor((tamanho.X - LARG) / 2),
            math.floor((tamanho.Y - altura) / 2))
        posJanela = Vector2.new(x, y)
        animarJanela(0.2, { Position = UDim2.fromOffset(x, y) }, Enum.EasingStyle.Quint)
        Pref.JanelaX, Pref.JanelaY = x, y
        agendarGravacao()
        setStatus("janela centralizada")
    end)

    tituloSecao("origem")
    criarTexto("Motor: " .. ENGINE_URL, COR.fraco, 42)
end)

--==========================================================================
-- 10. Montagem das abas
--==========================================================================
local botoesAba = {}

function abrirAba(indice)
    if abaAtiva == indice then
        return
    end
    abaAtiva = indice
    for posicao, botao in ipairs(botoesAba) do
        local ativo = posicao == indice
        animar(botao, 0.15, {
            BackgroundColor3 = ativo and COR.destaque or COR.painel,
            TextColor3 = ativo and Color3.new(1, 1, 1) or COR.fraco,
        })
    end

    local pagina = paginas[indice]
    if not pagina.area then
        pagina.area = criarAreaPagina()
        pagina.atualizar = {}
        areaAtual, listaAtual = pagina.area, pagina.atualizar
        ordem = 0
        pagina.construir()
        areaAtual, listaAtual = nil, nil
    end
    for _, outra in ipairs(paginas) do
        if outra.area and outra ~= pagina then
            outra.area.Visible = false
        end
    end
    pagina.area.Visible = true
    pagina.area.Position = UDim2.fromOffset(18, 0)
    animar(pagina.area, 0.18, { Position = UDim2.new() }, Enum.EasingStyle.Quint)
end

function repintarTudo()
    for _, pagina in ipairs(paginas) do
        local lista = pagina.atualizar
        if lista then
            local animado = pagina.area ~= nil and pagina.area.Visible
            for _, funcao in ipairs(lista) do
                pcall(funcao, animado)
            end
        end
    end
end

for indice, pagina in ipairs(paginas) do
    local botao = novo("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = COR.painel,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = COR.fraco,
        Text = pagina.nome,
        LayoutOrder = indice,
        AutoButtonColor = false,
    }, colunaAbas)
    canto(botao, 7)
    botao.MouseEnter:Connect(function()
        if abaAtiva ~= indice then
            animar(botao, 0.12, { BackgroundColor3 = COR.cartao })
        end
    end)
    botao.MouseLeave:Connect(function()
        if abaAtiva ~= indice then
            animar(botao, 0.12, { BackgroundColor3 = COR.painel })
        end
    end)
    botao.MouseButton1Click:Connect(function()
        if abaAtiva ~= indice then
            abrirAba(indice)
        end
    end)
    table.insert(botoesAba, botao)
end

--==========================================================================
-- 11. Ligacoes finais
--==========================================================================
local visivel = true

local function mostrarJanela(mostrar)
    visivel = mostrar
    local altura = alturaAlvo()
    if mostrar then
        local x, y = encaixar(altura)
        posJanela = Vector2.new(x, y)
        janela.Visible = true
        local recuo = math.min(20, math.floor((altura - ALT_BARRA) / 2))
        janela.Size = UDim2.fromOffset(LARG - 60, math.max(ALT_BARRA, altura - 40))
        janela.Position = UDim2.fromOffset(x + 30, y + recuo)
        animarJanela(0.24, {
            Size = UDim2.fromOffset(LARG, altura),
            Position = UDim2.fromOffset(x, y),
        }, Enum.EasingStyle.Quint)
    else
        local t = animarJanela(0.16, {
            Size = UDim2.fromOffset(LARG - 60, math.max(0, altura - 40)),
            Position = UDim2.fromOffset(posJanela.X + 30, posJanela.Y + 20),
        })
        if t then
            t.Completed:Connect(function(estado)
                if estado == Enum.PlaybackState.Completed then
                    janela.Visible = false
                    janela.Position = UDim2.fromOffset(posJanela.X, posJanela.Y)
                end
            end)
        else
            janela.Visible = false
        end
    end
end

btnFechar.MouseButton1Click:Connect(function()
    mostrarJanela(false)
end)

UIS.InputBegan:Connect(function(entrada, capturado)
    if not capturado and entrada.KeyCode == TOGGLE_KEY
        and not UIS:GetFocusedTextBox() then
        mostrarJanela(not visivel)
    end
end)

btnPrincipal.MouseEnter:Connect(function()
    animar(btnPrincipal, 0.12, { Size = UDim2.fromOffset(158, 36), Position = UDim2.fromOffset(-3, 3) })
end)
btnPrincipal.MouseLeave:Connect(function()
    animar(btnPrincipal, 0.12, { Size = UDim2.fromOffset(152, 34), Position = UDim2.fromOffset(0, 4) })
end)
btnPrincipal.MouseButton1Click:Connect(function()
    if precisaReiniciar then
        setStatus("reiniciando para aplicar as mudancas...")
        task.spawn(restartFarm)
    elseif isRunning() then
        stopFarm()
    else
        task.spawn(startFarm)
    end
end)

task.spawn(function()
    local ultimoTexto = nil
    local pontoGrande = false
    local passo = 0
    while tela.Parent do
        if visivel then
            local rodando = isRunning()
            local texto, cor
            if precisaReiniciar then
                texto, cor = "APLICAR E REINICIAR", COR.aviso
            elseif rodando then
                texto, cor = "PARAR", COR.perigo
            else
                texto, cor = "INICIAR", COR.ligado
            end
            if texto ~= ultimoTexto then
                ultimoTexto = texto
                btnPrincipal.Text = texto
                animar(btnPrincipal, 0.2, { BackgroundColor3 = cor })
                animar(pontoEstado, 0.2,
                    { BackgroundColor3 = rodando and COR.ligado or COR.desligado })
            end

            if rodando and Pref.Animacoes then
                pontoGrande = not pontoGrande
                if pontoGrande then
                    animar(pontoEstado, 0.55, { Size = UDim2.fromOffset(12, 12),
                        Position = UDim2.new(1, -94, 0, 17) })
                else
                    animar(pontoEstado, 0.55, { Size = UDim2.fromOffset(8, 8),
                        Position = UDim2.new(1, -92, 0, 19) })
                end
            end

            passo = passo + 1
            if passo >= 2 then
                passo = 0
                if not minimizado and abaAtiva == #paginas then
                    local lista = paginas[#paginas].atualizar
                    if lista then
                        for _, funcao in ipairs(lista) do
                            pcall(funcao)
                        end
                    end
                end
            end
        end
        task.wait(0.6)
    end
end)

--==========================================================================
-- 12. Inicio
--==========================================================================
loadConfig()
minimizado = Pref.AbrirMinimizado == true
do
    local x, y = posicaoInicial()
    colocar(x, y)
end
abrirAba(1)
aplicarMinimizar(false)
mostrarJanela(true)

setStatus(canWrite and ("pronto. configuracao em " .. CFG_FILE)
    or "pronto. seu executor nao grava arquivos: a configuracao nao sera salva.")

if Pref.AutoIniciar then
    task.spawn(function()
        task.wait(1)
        startFarm()
    end)
end
