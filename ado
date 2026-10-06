--[[
    Painel para o AdoptMe Farm
    Motor: AdoptMe Farm v1.4, de victimoffate_ (codigo aberto e comentado)

    Por que este painel existe: no padrao do motor 52 opcoes vem LIGADAS e so 5
    desligadas, inclusive a telemetria, que envia seu nome e seu ID do Roblox ao
    autor a cada 30 minutos. Aqui tudo fica visivel e sob seu controle.

    Sem bibliotecas externas: a interface e construida aqui mesmo.

    SEGURANCA: o motor e baixado UMA vez, verificado e gravado localmente.
    Depois disso o painel usa sempre a copia local, entao uma troca do arquivo
    no repositorio nao muda o que roda na sua maquina. Use "Atualizar motor"
    quando quiser buscar uma versao nova de proposito.

    Abrir e fechar o painel: tecla  RightControl
]]

--==========================================================================
-- 0. Constantes
--==========================================================================
local ENGINE_URL  = "https://raw.githubusercontent.com/leandrocrynow/adopt/refs/heads/main/farmpublic.txt"
local ENGINE_MARK = "AdoptMe Farm  v"            -- assinatura verificada no download
local DIR         = "AdoptMeFarm"
local ENGINE_FILE = DIR .. "/engine_fixado.lua"  -- copia local fixada
local CFG_FILE    = DIR .. "/painel_config.json"
local TOGGLE_KEY  = Enum.KeyCode.RightControl

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local Http     = game:GetService("HttpService")
local LP       = Players.LocalPlayer

local function env()
    return (type(getgenv) == "function" and getgenv()) or _G
end

local canWrite  = type(writefile) == "function"
local canRead   = type(readfile) == "function" and type(isfile) == "function"
local canFolder = type(makefolder) == "function" and type(isfolder) == "function"

--==========================================================================
-- 1. Configuracao
--    Mesma forma que o motor espera. Chaves desconhecidas sao recusadas por
--    ele, entao nada aqui pode ser inventado.
--==========================================================================
local function defaults()
    return {
        Farm = {
            Enabled    = true,
            BabyMode   = true,
            FastTravel = true,
            Tasks = {
                pet_me = true, salon = true, bored = true, cat_cafe = true,
                sleepy = true, dirty = true, toilet = true, hungry = true,
                thirsty = true, play = true, pizza_party = true, school = true,
                sick = true, camping = true, beach_party = true, mystery = true,
                walk = true, ride = true,
            },
            BuyWater  = true,
            BuyFood   = true,
            MaxBuysPerSession = 0,
            AutoAcceptMenu  = true,
            CollectCashback = true,
            SpotTravel      = "teleport",
            KeepPetEquipped = true,
            GameTravel      = true,
            HomeByRespawn   = true,
            HouseDoorExit   = false,
            SkipFullGrown   = true,
            BuyEgg          = true,
            EggToBuy        = "cracked_egg",
            MaxEggBuysPerSession = 0,
            AntiAfk     = true,
            AutoPotions = { Enabled = true },
            AutoOpen    = { Enabled = true },
            Event = {
                Enabled      = true,
                GhostGallery = true,
                Crypt        = true,
                MummySpider  = true,
                Quests       = true,
                HouseVisits  = true,
                PigeonNest   = true,
                StrayCat     = true,
                PetPen       = true,
                PetPenMinutes = 15,
                PetPenSlots   = 4,
                PetPenStock   = true,
            },
        },
        Logging = {
            ConsoleLevel = "OFF",
            FileEnabled  = false,
            SessionFile  = false,
        },
        -- Trocado para false de proposito: no motor vem true e envia seu nome
        -- e seu ID do Roblox ao autor. Ligue aqui se quiser ajudar nos bugs.
        Telemetry = { Enabled = false },
        Notifications = {
            Enabled = false,
            Webhooks = { Summary = "", Alerts = "" },
            SummaryIntervalMinutes = 30,
            SendOnStartStop = true,
            SendOnError     = true,
            SendOnKick      = true,
            SendOnTaskComplete = false,
            SendTestMessageOnStart = false,
            PingDiscordUserId = "",
            IncludeUsername = true,
        },
    }
end

local Cfg = defaults()

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end
    return copy
end

local function getPath(path)
    local node = Cfg
    for part in string.gmatch(path, "[^.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[part]
    end
    return node
end

local function setPath(path, value)
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    local node = Cfg
    for index = 1, #parts - 1 do
        node = node[parts[index]]
    end
    node[parts[#parts]] = value
end

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
    local ok, text = pcall(function()
        return Http:JSONEncode(Cfg)
    end)
    if not ok then
        return false
    end
    return (pcall(writefile, CFG_FILE, text))
end

local function loadConfig()
    if not canRead then
        return
    end
    local ok, text = pcall(function()
        return isfile(CFG_FILE) and readfile(CFG_FILE) or nil
    end)
    if not ok or type(text) ~= "string" then
        return
    end
    local decoded
    ok, decoded = pcall(function()
        return Http:JSONDecode(text)
    end)
    if not ok or type(decoded) ~= "table" then
        return
    end
    -- mescla por cima dos padroes, para novas chaves nao sumirem
    local function merge(target, source)
        for key, value in pairs(source) do
            if type(value) == "table" and type(target[key]) == "table" then
                merge(target[key], value)
            elseif target[key] ~= nil and type(value) == type(target[key]) then
                target[key] = value
            end
        end
    end
    merge(Cfg, decoded)
end

--==========================================================================
-- 2. Motor: carregar, fixar, iniciar, parar
--==========================================================================
local engineSource = nil

local function fetchEngine(force)
    if not force and canRead then
        local ok, text = pcall(function()
            return isfile(ENGINE_FILE) and readfile(ENGINE_FILE) or nil
        end)
        if ok and type(text) == "string" and string.find(text, ENGINE_MARK, 1, true) then
            return text, "copia local fixada"
        end
    end
    local ok, body = pcall(function()
        return game:HttpGet(ENGINE_URL)
    end)
    if not ok or type(body) ~= "string" or body == "" then
        return nil, "o download falhou"
    end
    if not string.find(string.sub(body, 1, 300), ENGINE_MARK, 1, true) then
        return nil, "o arquivo baixado NAO e o AdoptMe Farm: nada foi executado"
    end
    if canWrite then
        ensureFolder()
        pcall(writefile, ENGINE_FILE, body)
    end
    return body, "baixado e fixado"
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

local setStatus -- definido junto da interface

local function startFarm()
    if isRunning() then
        setStatus("ja esta rodando")
        return
    end
    local source, how = engineSource, "em memoria"
    if not source then
        source, how = fetchEngine(false)
    end
    if not source then
        setStatus("erro: " .. tostring(how))
        return
    end
    engineSource = source
    local chunk, compileError = loadstring(source)
    if not chunk then
        setStatus("erro de compilacao: " .. tostring(compileError))
        return
    end
    env().AdoptMeFarmSettings   = deepCopy(Cfg)
    env().AdoptMeFarmLoaderInfo = { Url = ENGINE_URL }
    local ok, runError = pcall(chunk)
    if not ok then
        setStatus("erro ao iniciar: " .. tostring(runError))
        return
    end
    setStatus("iniciado (" .. how .. ")")
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

-- Uma troca de opcao com o farm rodando so vale depois de reiniciar, porque o
-- motor le a configuracao uma vez no inicio.
local restartPending = false
local function markDirty()
    saveConfig()
    if isRunning() then
        restartPending = true
    end
end

local function restartFarm()
    stopFarm()
    task.wait(0.6)
    restartPending = false
    startFarm()
end

--==========================================================================
-- 3. Interface
--==========================================================================
local COR = {
    fundo    = Color3.fromRGB(22, 23, 28),
    painel   = Color3.fromRGB(30, 32, 39),
    linha    = Color3.fromRGB(45, 48, 58),
    texto    = Color3.fromRGB(228, 230, 236),
    fraco    = Color3.fromRGB(140, 146, 160),
    ligado   = Color3.fromRGB(78, 186, 120),
    desligado = Color3.fromRGB(70, 74, 86),
    aviso    = Color3.fromRGB(226, 160, 70),
    perigo   = Color3.fromRGB(220, 88, 88),
    destaque = Color3.fromRGB(96, 132, 232),
}

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

-- destino da interface: CoreGui quando o executor deixa, senao PlayerGui
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
    Size = UDim2.fromOffset(680, 430),
    Position = UDim2.new(0.5, -340, 0.5, -215),
    BackgroundColor3 = COR.fundo,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
}, tela)
canto(janela, 10)

-- cabecalho -----------------------------------------------------------------
local cabecalho = novo("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = COR.painel,
    BorderSizePixel = 0,
}, janela)
canto(cabecalho, 10)
novo("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = COR.painel,
    BorderSizePixel = 0,
}, cabecalho)

novo("TextLabel", {
    Size = UDim2.new(1, -120, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = COR.texto,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "AdoptMe Farm  |  painel de controle",
}, cabecalho)

local btnFechar = novo("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -38, 0, 8),
    BackgroundColor3 = COR.linha,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = COR.texto,
    Text = "X",
    AutoButtonColor = true,
}, cabecalho)
canto(btnFechar, 6)

-- coluna de abas ------------------------------------------------------------
local colunaAbas = novo("Frame", {
    Size = UDim2.new(0, 150, 1, -110),
    Position = UDim2.fromOffset(12, 54),
    BackgroundTransparency = 1,
}, janela)
novo("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, colunaAbas)

local areaConteudo = novo("ScrollingFrame", {
    Size = UDim2.new(1, -186, 1, -110),
    Position = UDim2.fromOffset(174, 54),
    BackgroundColor3 = COR.painel,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COR.linha,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, janela)
canto(areaConteudo, 8)
novo("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, areaConteudo)
novo("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
}, areaConteudo)

-- rodape --------------------------------------------------------------------
local rodape = novo("Frame", {
    Size = UDim2.new(1, -24, 0, 44),
    Position = UDim2.new(0, 12, 1, -50),
    BackgroundTransparency = 1,
}, janela)

local btnPrincipal = novo("TextButton", {
    Size = UDim2.fromOffset(150, 34),
    Position = UDim2.fromOffset(0, 5),
    BackgroundColor3 = COR.ligado,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.new(1, 1, 1),
    Text = "INICIAR",
}, rodape)
canto(btnPrincipal, 7)

local rotuloStatus = novo("TextLabel", {
    Size = UDim2.new(1, -162, 1, 0),
    Position = UDim2.fromOffset(162, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = COR.fraco,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    TextWrapped = true,
    Text = "parado",
}, rodape)

function setStatus(texto)
    rotuloStatus.Text = tostring(texto)
end

--==========================================================================
-- 4. Controles
--==========================================================================
local ordem = 0
local function proximaOrdem()
    ordem = ordem + 1
    return ordem
end

local function tituloSecao(texto)
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)
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
    local altura = item.desc and 52 or 36
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, altura),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)

    novo("TextLabel", {
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.fromOffset(0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = item.alerta and COR.aviso or COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    if item.desc then
        novo("TextLabel", {
            Size = UDim2.new(1, -60, 0, 24),
            Position = UDim2.fromOffset(0, 24),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = COR.fraco,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = item.desc,
        }, frame)
    end

    local trilho = novo("TextButton", {
        Size = UDim2.fromOffset(44, 22),
        Position = UDim2.new(1, -46, 0, 6),
        BackgroundColor3 = COR.desligado,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, frame)
    canto(trilho, 11)

    local bolinha = novo("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, trilho)
    canto(bolinha, 8)

    local function pintar()
        local ligado = getPath(item.path) == true
        trilho.BackgroundColor3 = ligado and COR.ligado or COR.desligado
        bolinha.Position = ligado and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
    end

    trilho.MouseButton1Click:Connect(function()
        setPath(item.path, not (getPath(item.path) == true))
        pintar()
        markDirty()
    end)

    pintar()
    return frame, pintar
end

-- Arraste dos sliders: UMA conexao para todos. Sem isto cada reabertura de aba
-- criaria conexoes novas no UserInputService e elas iriam se acumulando.
local sliderAtivo = nil
UIS.InputEnded:Connect(function(entrada)
    if sliderAtivo and entrada.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderAtivo = nil
        markDirty()
    end
end)
UIS.InputChanged:Connect(function(entrada)
    if sliderAtivo and entrada.UserInputType == Enum.UserInputType.MouseMovement then
        sliderAtivo(entrada.Position.X)
    end
end)

local function criarSlider(item)
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)

    local rotulo = novo("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    local trilho = novo("TextButton", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.fromOffset(0, 32),
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

    local function pintar()
        local valor = tonumber(getPath(item.path)) or item.min
        local fracao = (valor - item.min) / math.max(1, item.max - item.min)
        preenchido.Size = UDim2.new(math.clamp(fracao, 0, 1), 0, 1, 0)
        rotulo.Text = item.label .. "   " .. tostring(valor) .. (item.sufixo or "")
    end

    local function aplicarDoMouse(posX)
        local fracao = math.clamp((posX - trilho.AbsolutePosition.X) / math.max(1, trilho.AbsoluteSize.X), 0, 1)
        local valor = math.floor(item.min + fracao * (item.max - item.min) + 0.5)
        setPath(item.path, valor)
        pintar()
    end

    trilho.MouseButton1Down:Connect(function()
        sliderAtivo = aplicarDoMouse
    end)

    pintar()
    return frame, pintar
end

local function criarCiclo(item)
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)

    novo("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    local botao = novo("TextButton", {
        Size = UDim2.fromOffset(110, 26),
        Position = UDim2.new(1, -112, 0, 5),
        BackgroundColor3 = COR.linha,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = COR.texto,
        Text = "",
    }, frame)
    canto(botao, 6)

    local function pintar()
        botao.Text = tostring(getPath(item.path))
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
        markDirty()
    end)

    pintar()
    return frame, pintar
end

local function criarCampo(item)
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)

    novo("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = COR.texto,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = item.label,
    }, frame)

    local caixa = novo("TextBox", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.fromOffset(0, 22),
        BackgroundColor3 = COR.linha,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = COR.texto,
        PlaceholderText = item.dica or "",
        ClearTextOnFocus = false,
        Text = tostring(getPath(item.path) or ""),
    }, frame)
    canto(caixa, 6)
    novo("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, caixa)

    caixa.FocusLost:Connect(function()
        setPath(item.path, caixa.Text)
        markDirty()
    end)

    local function pintar()
        caixa.Text = tostring(getPath(item.path) or "")
    end
    return frame, pintar
end

local function criarBotao(texto, cor, aoClicar)
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)
    local botao = novo("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, 5),
        BackgroundColor3 = cor,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1),
        Text = texto,
    }, frame)
    canto(botao, 6)
    botao.MouseButton1Click:Connect(aoClicar)
    return frame
end

local function criarTexto(texto, cor)
    local frame = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)
    novo("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = cor or COR.fraco,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = texto,
    }, frame)
    return frame
end

--==========================================================================
-- 5. Paginas
--==========================================================================
local TAREFAS = {
    { "pet_me", "Fazer carinho" },
    { "hungry", "Fome" },
    { "thirsty", "Sede" },
    { "dirty", "Banho" },
    { "toilet", "Banheiro" },
    { "sleepy", "Sono" },
    { "play", "Brincar" },
    { "sick", "Doente (hospital)" },
    { "salon", "Salao" },
    { "school", "Escola" },
    { "pizza_party", "Festa de pizza" },
    { "cat_cafe", "Cafe dos gatos" },
    { "camping", "Acampamento" },
    { "beach_party", "Praia" },
    { "bored", "Parquinho (tedio)" },
    { "mystery", "Misterio" },
    { "walk", "Passear" },
    { "ride", "Carrinho" },
}

local paginas = {}
local repintar = {}
-- declaradas aqui para as paginas poderem usar; os corpos vem mais abaixo
local abrirAba
local abaAtiva

local function aba(nome, construir)
    table.insert(paginas, { nome = nome, construir = construir })
end

aba("Farm", function()
    tituloSecao("principal")
    criarToggle({ path = "Farm.Enabled", label = "Farm ligado",
        desc = "Desligado, o script so observa e nao envia nada ao jogo." })
    criarToggle({ path = "Farm.BabyMode", label = "Modo bebe",
        desc = "Entra no time Babies para fazer tambem as necessidades do bebe." })
    criarToggle({ path = "Farm.FastTravel", label = "Viagem rapida" })
    criarToggle({ path = "Farm.GameTravel", label = "Usar as portas do proprio jogo" })
    criarToggle({ path = "Farm.HomeByRespawn", label = "Voltar pra casa renascendo" })
    criarToggle({ path = "Farm.AutoAcceptMenu", label = "Fechar o menu inicial sozinho" })
    criarToggle({ path = "Farm.AntiAfk", label = "Anti-AFK",
        desc = "Clique virtual quando o Roblox avisa que voce esta parado." })

    tituloSecao("pets")
    criarToggle({ path = "Farm.KeepPetEquipped", label = "Manter um pet equipado" })
    criarToggle({ path = "Farm.SkipFullGrown", label = "Pular pets adultos" })
    criarToggle({ path = "Farm.AutoPotions.Enabled", label = "Usar pocoes de idade" })
    criarToggle({ path = "Farm.AutoOpen.Enabled", label = "Abrir presentes e bauzinhos" })

    tituloSecao("compras")
    criarToggle({ path = "Farm.BuyWater", label = "Comprar agua quando faltar", alerta = true })
    criarToggle({ path = "Farm.BuyFood", label = "Comprar comida quando faltar", alerta = true })
    criarToggle({ path = "Farm.BuyEgg", label = "Comprar ovo quando nao houver pet filhote", alerta = true,
        desc = "Gasta Bucks. Nunca compra nada que custe Robux." })
    criarCiclo({ path = "Farm.EggToBuy", label = "Ovo a comprar",
        opcoes = { "cracked_egg", "pet_egg", "fairytale_egg_2026_fairytale_egg" } })
    criarSlider({ path = "Farm.MaxBuysPerSession", label = "Limite de itens por sessao", min = 0, max = 50,
        sufixo = "  (0 = sem limite)" })
    criarSlider({ path = "Farm.MaxEggBuysPerSession", label = "Limite de ovos por sessao", min = 0, max = 20,
        sufixo = "  (0 = sem limite)" })

    tituloSecao("outros")
    criarToggle({ path = "Farm.CollectCashback", label = "Coletar cashback" })
    criarCiclo({ path = "Farm.SpotTravel", label = "Como chegar aos pontos do mapa",
        opcoes = { "teleport", "door" } })
end)

aba("Tarefas", function()
    criarTexto("Cada chave e um tipo de necessidade que o farm resolve sozinho. "
        .. "Desligue as que voce nao quer que ele faca.")
    tituloSecao("rapidas, feitas em casa")
    for _, tarefa in ipairs(TAREFAS) do
        local lentas = { salon = true, school = true, pizza_party = true, cat_cafe = true,
            camping = true, beach_party = true, bored = true, walk = true, ride = true }
        if not lentas[tarefa[1]] then
            criarToggle({ path = "Farm.Tasks." .. tarefa[1], label = tarefa[2] })
        end
    end
    tituloSecao("lentas, exigem viagem ou caminhada")
    for _, tarefa in ipairs(TAREFAS) do
        local lentas = { salon = true, school = true, pizza_party = true, cat_cafe = true,
            camping = true, beach_party = true, bored = true, walk = true, ride = true }
        if lentas[tarefa[1]] then
            criarToggle({ path = "Farm.Tasks." .. tarefa[1], label = tarefa[2] })
        end
    end
end)

aba("Evento", function()
    criarTexto("Tarefas do Halloween 2026 e do Pet Pen. A chave principal precisa "
        .. "estar ligada para qualquer uma das outras rodar.")
    criarToggle({ path = "Farm.Event.Enabled", label = "Evento ligado (chave principal)" })
    tituloSecao("halloween")
    criarToggle({ path = "Farm.Event.GhostGallery", label = "Ghost Gallery" })
    criarToggle({ path = "Farm.Event.Crypt", label = "Cripta" })
    criarToggle({ path = "Farm.Event.MummySpider", label = "Aranha Mumia" })
    criarToggle({ path = "Farm.Event.Quests", label = "Missoes diarias" })
    criarToggle({ path = "Farm.Event.HouseVisits", label = "Visitar casas (missao)" })
    criarToggle({ path = "Farm.Event.PigeonNest", label = "Ninho do pombo" })
    criarToggle({ path = "Farm.Event.StrayCat", label = "Gato de rua" })
    tituloSecao("pet pen")
    criarToggle({ path = "Farm.Event.PetPen", label = "Gerenciar o Pet Pen" })
    criarToggle({ path = "Farm.Event.PetPenStock", label = "Manter o Pet Pen cheio",
        desc = "Compra ovos para encher as vagas. Precisa de Comprar ovo ligado." })
    criarSlider({ path = "Farm.Event.PetPenSlots", label = "Vagas do Pet Pen", min = 1, max = 5 })
    criarSlider({ path = "Farm.Event.PetPenMinutes", label = "Checar o Pet Pen a cada", min = 1, max = 60,
        sufixo = " min" })
end)

aba("Privacidade", function()
    criarTexto("O MOTOR VEM COM A TELEMETRIA LIGADA. Ela envia seu nome do Roblox, "
        .. "seu ID de usuario e um resumo da sessao ao autor do farm a cada 30 minutos. "
        .. "Este painel comeca com ela DESLIGADA.", COR.aviso)
    criarToggle({ path = "Telemetry.Enabled", label = "Enviar telemetria ao autor", alerta = true,
        desc = "Destino: adoptmelogs.04demirali123.workers.dev, de victimoffate_." })

    tituloSecao("webhook do discord (seu)")
    criarTexto("Opcional e so para voce. Deixe vazio para nao enviar nada.")
    criarToggle({ path = "Notifications.Enabled", label = "Enviar avisos para o meu Discord" })
    criarCampo({ path = "Notifications.Webhooks.Summary", label = "Webhook de resumo",
        dica = "https://discord.com/api/webhooks/..." })
    criarCampo({ path = "Notifications.Webhooks.Alerts", label = "Webhook de alertas",
        dica = "vazio usa o de resumo" })
    criarCampo({ path = "Notifications.PingDiscordUserId", label = "Meu ID do Discord para mencao",
        dica = "so numeros" })
    criarToggle({ path = "Notifications.IncludeUsername", label = "Incluir meu nome do Roblox nas mensagens" })
    criarToggle({ path = "Notifications.SendOnStartStop", label = "Avisar ao iniciar e parar" })
    criarToggle({ path = "Notifications.SendOnError", label = "Avisar em erro" })
    criarToggle({ path = "Notifications.SendOnKick", label = "Avisar ao ser desconectado" })
    criarSlider({ path = "Notifications.SummaryIntervalMinutes", label = "Resumo a cada", min = 0, max = 120,
        sufixo = " min  (0 = nunca)" })

    tituloSecao("registro")
    criarCiclo({ path = "Logging.ConsoleLevel", label = "Mensagens no console",
        opcoes = { "OFF", "INFO", "DEBUG", "WARN", "ERROR" } })
    criarToggle({ path = "Logging.FileEnabled", label = "Gravar arquivo de log" })
end)

aba("Status", function()
    local painelStatus = criarTexto("", COR.texto)
    local rotulo = painelStatus:FindFirstChildOfClass("TextLabel")
    painelStatus.Size = UDim2.new(1, 0, 0, 150)
    rotulo.TextSize = 12

    table.insert(repintar, function()
        local api = farmApi()
        if not api or type(api.State) ~= "table" then
            rotulo.Text = "Farm parado.\n\nUse INICIAR no rodape."
            return
        end
        local estado = api.State
        local function ler(chave, padrao)
            local ok, valor = pcall(function()
                return estado:get(chave, padrao)
            end)
            return ok and valor or padrao
        end
        local inicio = ler("session.startedAt", os.clock())
        local segundos = math.max(0, math.floor(os.clock() - inicio))
        local pets = {}
        for _, pet in ipairs(ler("pets.equipped", {})) do
            table.insert(pets, tostring(pet.kind) .. " (idade " .. tostring(pet.age or "?") .. ")")
        end
        rotulo.Text = table.concat({
            "Versao do motor: " .. tostring(api.Version),
            string.format("Tempo de sessao: %02d:%02d:%02d", math.floor(segundos / 3600),
                math.floor(segundos % 3600 / 60), segundos % 60),
            "Tarefa agora: " .. tostring(ler("farm.currentTask", "nenhuma")),
            "Lugar: " .. tostring(ler("player.interior", "?")),
            "Time: " .. tostring(ler("player.team", "?")),
            "Bucks: " .. tostring(ler("player.bucks", "?")),
            "Necessidades concluidas: " .. tostring(ler("stats.needsCompleted", 0)),
            "Bucks ganhos: " .. tostring(ler("stats.bucksEarned", 0)),
            "Pets: " .. (#pets > 0 and table.concat(pets, ", ") or "nenhum"),
        }, "\n")
    end)

    tituloSecao("predefinicoes")
    criarBotao("LIGAR TUDO", COR.linha, function()
        local function ligarTudo(node)
            for chave, valor in pairs(node) do
                if type(valor) == "table" then
                    ligarTudo(valor)
                elseif type(valor) == "boolean" and chave ~= "HouseDoorExit" then
                    node[chave] = true
                end
            end
        end
        ligarTudo(Cfg.Farm)
        Cfg.Telemetry.Enabled = false -- esta fica por sua conta, na aba Privacidade
        markDirty()
        abrirAba(abaAtiva)
        setStatus("tudo ligado (telemetria segue desligada)")
    end)
    criarBotao("SO O BASICO", COR.linha, function()
        local novo = defaults()
        for tarefa in pairs(novo.Farm.Tasks) do
            novo.Farm.Tasks[tarefa] = false
        end
        for _, rapida in ipairs({ "pet_me", "hungry", "thirsty", "dirty", "toilet", "sleepy", "play", "mystery" }) do
            novo.Farm.Tasks[rapida] = true
        end
        for chave, valor in pairs(novo.Farm.Event) do
            if type(valor) == "boolean" then
                novo.Farm.Event[chave] = false
            end
        end
        Cfg = novo
        markDirty()
        abrirAba(abaAtiva)
        setStatus("predefinicao basica aplicada")
    end)
    criarBotao("DESLIGAR TUDO", COR.linha, function()
        local function desligarTudo(node)
            for chave, valor in pairs(node) do
                if type(valor) == "table" then
                    desligarTudo(valor)
                elseif type(valor) == "boolean" then
                    node[chave] = false
                end
            end
        end
        desligarTudo(Cfg.Farm)
        markDirty()
        abrirAba(abaAtiva)
        setStatus("tudo desligado")
    end)

    tituloSecao("motor")
    criarBotao("ATUALIZAR MOTOR (baixa de novo e fixa)", COR.destaque, function()
        local fonte, como = fetchEngine(true)
        if fonte then
            engineSource = fonte
            setStatus("motor atualizado: " .. como .. " (" .. #fonte .. " bytes)")
        else
            setStatus("falhou: " .. tostring(como))
        end
    end)
    criarBotao("RESTAURAR PADROES DO PAINEL", COR.perigo, function()
        Cfg = defaults()
        markDirty()
        abrirAba(abaAtiva)
        setStatus("padroes restaurados")
    end)
end)

--==========================================================================
-- 6. Montagem das abas
--==========================================================================
local botoesAba = {}

function abrirAba(indice)
    abaAtiva = indice
    for posicao, botao in ipairs(botoesAba) do
        botao.BackgroundColor3 = (posicao == indice) and COR.destaque or COR.painel
        botao.TextColor3 = (posicao == indice) and Color3.new(1, 1, 1) or COR.fraco
    end
    for _, filho in ipairs(areaConteudo:GetChildren()) do
        if not filho:IsA("UIListLayout") and not filho:IsA("UIPadding") then
            filho:Destroy()
        end
    end
    ordem = 0
    table.clear(repintar)
    paginas[indice].construir()
    areaConteudo.CanvasPosition = Vector2.new()
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
    }, colunaAbas)
    canto(botao, 6)
    botao.MouseButton1Click:Connect(function()
        abrirAba(indice)
    end)
    table.insert(botoesAba, botao)
end

--==========================================================================
-- 7. Ligacoes finais
--==========================================================================
btnFechar.MouseButton1Click:Connect(function()
    janela.Visible = false
end)

UIS.InputBegan:Connect(function(entrada, capturado)
    if not capturado and entrada.KeyCode == TOGGLE_KEY then
        janela.Visible = not janela.Visible
    end
end)

btnPrincipal.MouseButton1Click:Connect(function()
    if restartPending then
        setStatus("reiniciando para aplicar as mudancas...")
        task.spawn(restartFarm)
    elseif isRunning() then
        stopFarm()
    else
        task.spawn(startFarm)
    end
end)

-- atualiza rodape e aba Status
task.spawn(function()
    while tela.Parent do
        local rodando = isRunning()
        if restartPending then
            btnPrincipal.Text = "APLICAR E REINICIAR"
            btnPrincipal.BackgroundColor3 = COR.aviso
        elseif rodando then
            btnPrincipal.Text = "PARAR"
            btnPrincipal.BackgroundColor3 = COR.perigo
        else
            btnPrincipal.Text = "INICIAR"
            btnPrincipal.BackgroundColor3 = COR.ligado
        end
        if abaAtiva == #paginas then
            for _, funcao in ipairs(repintar) do
                pcall(funcao)
            end
        end
        task.wait(1)
    end
end)

loadConfig()
abrirAba(1)
setStatus(canWrite and "pronto. configuracao salva em " .. CFG_FILE
    or "pronto. seu executor nao grava arquivos: a configuracao nao sera salva.")
