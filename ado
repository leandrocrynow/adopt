--[[
    Painel para o AdoptMe Farm  -  v2
    Motor: AdoptMe Farm v1.4 (codigo aberto e comentado)

    Novidades desta versao:
      - motor vindo do seu proprio repositorio
      - animacoes em tudo: abertura, abas, interruptores, botoes, minimizar
      - botao de minimizar que encolhe a janela ate a barra de titulo
      - 7 abas e muito mais opcoes, incluindo a tabela de prioridades das tarefas
      - arraste proprio, funciona com mouse e com toque
      - iniciar automatico opcional

    Abrir e fechar: tecla RightControl

    SEGURANCA: o motor e baixado UMA vez, verificado e gravado localmente.
    Depois o painel usa sempre a copia local, entao uma troca do arquivo no
    repositorio nao muda o que roda aqui. Use "Atualizar motor" para buscar
    uma versao nova de proposito.
]]

--==========================================================================
-- 0. Constantes
--==========================================================================
local ENGINE_URL  = "https://raw.githubusercontent.com/leandrocrynow/adopt/refs/heads/main/farmpublic"
local ENGINE_MARK = "AdoptMe Farm  v"
local DIR         = "AdoptMeFarm"
local ENGINE_FILE = DIR .. "/engine_fixado.lua"
local CFG_FILE    = DIR .. "/painel_v2.json"
local TOGGLE_KEY  = Enum.KeyCode.RightControl

local LARG, ALT   = 740, 486
local ALT_BARRA   = 46

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Http    = game:GetService("HttpService")
local Tween   = game:GetService("TweenService")
local LP      = Players.LocalPlayer

local function env()
    return (type(getgenv) == "function" and getgenv()) or _G
end

local canWrite  = type(writefile) == "function"
local canRead   = type(readfile) == "function" and type(isfile) == "function"
local canFolder = type(makefolder) == "function" and type(isfolder) == "function"

--==========================================================================
-- 1. Configuracao do motor (mesma forma que ele espera)
--==========================================================================
local function defaults()
    return {
        General = { TickSeconds = 0.5 },
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
            CollectCashback = true,
            CashbackMinutes = 10,
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
            PetMeFocusSeconds      = 7,
            FailureCooldownSeconds = 30,
            MaxConsecutiveFailures = 3,
        },
        Logging = {
            ConsoleLevel = "OFF",
            FileLevel    = "DEBUG",
            FileEnabled  = false,
            SessionFile  = false,
            FlushSeconds = 5,
            MaxLinesPerSession = 20000,
        },
        -- No motor vem true e envia seu nome e seu ID do Roblox ao autor.
        -- Aqui comeca desligada de proposito.
        Telemetry = { Enabled = false, SummaryMinutes = 30 },
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
            PingOn = {
                Kick = true, Error = false, Summary = false,
                TaskCompleted = false, SessionStopped = false, PreviousSession = false,
            },
            IncludeUsername = true,
            AlertCooldownSeconds = 60,
            MinSecondsBetweenMessages = 2.5,
        },
    }
end

-- Preferencias do PAINEL. Nunca vao para o motor: ele recusa chaves que nao conhece.
local function prefsPadrao()
    return { AutoIniciar = false, AbrirMinimizado = false, Animacoes = true }
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

local function getPath(caminho)
    local node = Cfg
    for parte in string.gmatch(caminho, "[^.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[parte]
    end
    return node
end

local function setPath(caminho, valor)
    local partes = {}
    for parte in string.gmatch(caminho, "[^.]+") do
        table.insert(partes, parte)
    end
    local node = Cfg
    for indice = 1, #partes - 1 do
        node = node[partes[indice]]
    end
    node[partes[#partes]] = valor
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

local function mesclar(alvo, fonte)
    for chave, valor in pairs(fonte) do
        if type(valor) == "table" and type(alvo[chave]) == "table" then
            mesclar(alvo[chave], valor)
        elseif alvo[chave] ~= nil and type(valor) == type(alvo[chave]) then
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

local function fetchEngine(forcar)
    if not forcar and canRead then
        local ok, texto = pcall(function()
            return isfile(ENGINE_FILE) and readfile(ENGINE_FILE) or nil
        end)
        if ok and type(texto) == "string" and string.find(texto, ENGINE_MARK, 1, true) then
            return texto, "copia local fixada"
        end
    end
    local ok, corpo = pcall(function()
        return game:HttpGet(ENGINE_URL)
    end)
    if not ok or type(corpo) ~= "string" or corpo == "" then
        return nil, "o download falhou"
    end
    if not string.find(string.sub(corpo, 1, 300), ENGINE_MARK, 1, true) then
        return nil, "o arquivo baixado NAO e o AdoptMe Farm: nada foi executado"
    end
    if canWrite then
        ensureFolder()
        pcall(writefile, ENGINE_FILE, corpo)
    end
    return corpo, "baixado e fixado"
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
    engineSource = fonte
    local chunk, erroCompilacao = loadstring(fonte)
    if not chunk then
        setStatus("erro de compilacao: " .. tostring(erroCompilacao))
        return
    end
    env().AdoptMeFarmSettings   = deepCopy(Cfg)
    env().AdoptMeFarmLoaderInfo = { Url = ENGINE_URL }
    local ok, erroExecucao = pcall(chunk)
    if not ok then
        setStatus("erro ao iniciar: " .. tostring(erroExecucao))
        return
    end
    setStatus("iniciado (" .. como .. ")")
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

-- O motor le a configuracao uma vez no inicio, entao mudar com ele rodando
-- so vale depois de reiniciar.
local precisaReiniciar = false
local function marcarSujo()
    saveConfig()
    if isRunning() then
        precisaReiniciar = true
    end
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

local function animar(objeto, tempo, props, estilo, direcao)
    if not Pref.Animacoes then
        for chave, valor in pairs(props) do
            pcall(function()
                objeto[chave] = valor
            end)
        end
        return nil
    end
    local info = TweenInfo.new(tempo or 0.18, estilo or Enum.EasingStyle.Quad,
        direcao or Enum.EasingDirection.Out)
    local t = Tween:Create(objeto, info, props)
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

-- realce suave ao passar o mouse
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
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
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

local tituloJanela = novo("TextLabel", {
    Size = UDim2.new(1, -150, 1, 0),
    Position = UDim2.fromOffset(30, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = COR.texto,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "AdoptMe Farm  |  painel",
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

local POS_CONTEUDO = UDim2.fromOffset(176, 10)
local areaConteudo = novo("ScrollingFrame", {
    Size = UDim2.new(1, -188, 1, -62),
    Position = POS_CONTEUDO,
    BackgroundColor3 = COR.painel,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COR.linha,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, corpo)
canto(areaConteudo, 8)
novo("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, areaConteudo)
novo("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
}, areaConteudo)

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

--==========================================================================
-- 5. Arraste proprio (mouse e toque)
--==========================================================================
do
    local arrastando, inicioEntrada, inicioPos
    local function ehArraste(entrada)
        return entrada.UserInputType == Enum.UserInputType.MouseButton1
            or entrada.UserInputType == Enum.UserInputType.Touch
    end
    barra.InputBegan:Connect(function(entrada)
        if ehArraste(entrada) then
            arrastando = true
            inicioEntrada = entrada.Position
            inicioPos = janela.Position
        end
    end)
    UIS.InputChanged:Connect(function(entrada)
        if arrastando and (entrada.UserInputType == Enum.UserInputType.MouseMovement
            or entrada.UserInputType == Enum.UserInputType.Touch) then
            local delta = entrada.Position - inicioEntrada
            janela.Position = UDim2.new(inicioPos.X.Scale, inicioPos.X.Offset + delta.X,
                inicioPos.Y.Scale, inicioPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(entrada)
        if ehArraste(entrada) then
            arrastando = false
        end
    end)
end

--==========================================================================
-- 6. Minimizar
--==========================================================================
local minimizado = false

local function aplicarMinimizar(animado)
    local alvoAltura = minimizado and ALT_BARRA or ALT
    btnMinimizar.Text = minimizado and "+" or "-"
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
    -- sem animacao a altura fica para quem chamou, para nao brigar com o
    -- tween de abertura da janela
    if animado then
        animar(janela, 0.22, { Size = UDim2.fromOffset(LARG, alvoAltura) }, Enum.EasingStyle.Quint)
    end
end

btnMinimizar.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    Pref.AbrirMinimizado = minimizado
    saveConfig()
    aplicarMinimizar(true)
end)

--==========================================================================
-- 7. Controles
--==========================================================================
local ordem = 0
local function proximaOrdem()
    ordem = ordem + 1
    return ordem
end

local function linhaBase(altura)
    return novo("Frame", {
        Size = UDim2.new(1, 0, 0, altura),
        BackgroundTransparency = 1,
        LayoutOrder = proximaOrdem(),
    }, areaConteudo)
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
        local ligado = getPath(item.path) == true
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
        setPath(item.path, not (getPath(item.path) == true))
        pintar(true)
        marcarSujo()
    end)

    pintar(false)
    return frame, function()
        pintar(false)
    end
end

-- Arraste dos sliders: UMA conexao para todos, nunca por slider criado.
local sliderAtivo = nil
UIS.InputEnded:Connect(function(entrada)
    if sliderAtivo and (entrada.UserInputType == Enum.UserInputType.MouseButton1
        or entrada.UserInputType == Enum.UserInputType.Touch) then
        sliderAtivo = nil
        marcarSujo()
    end
end)
UIS.InputChanged:Connect(function(entrada)
    if sliderAtivo and (entrada.UserInputType == Enum.UserInputType.MouseMovement
        or entrada.UserInputType == Enum.UserInputType.Touch) then
        sliderAtivo(entrada.Position.X)
    end
end)

local function criarSlider(item)
    local frame = linhaBase(52)
    local passo = item.passo or 1

    local rotulo = novo("TextLabel", {
        Size = UDim2.new(1, -8, 0, 20),
        Position = UDim2.fromOffset(8, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = COR.texto,
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

    local function aplicarDoMouse(posX)
        local fracao = math.clamp((posX - trilho.AbsolutePosition.X)
            / math.max(1, trilho.AbsoluteSize.X), 0, 1)
        local bruto = item.min + fracao * (item.max - item.min)
        local valor = math.floor(bruto / passo + 0.5) * passo
        valor = tonumber(string.format("%.2f", valor)) or item.min
        setPath(item.path, valor)
        pintar(false)
    end

    trilho.MouseButton1Down:Connect(function()
        sliderAtivo = aplicarDoMouse
        animar(pino, 0.1, { Size = UDim2.fromOffset(18, 18) })
    end)
    trilho.MouseButton1Up:Connect(function()
        animar(pino, 0.1, { Size = UDim2.fromOffset(14, 14) })
    end)

    pintar(false)
    return frame, function()
        pintar(true)
    end
end

local function criarCiclo(item)
    local frame = linhaBase(38)

    novo("TextLabel", {
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = COR.texto,
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
        botao.TextTransparency = 1
        animar(botao, 0.2, { TextTransparency = 0 })
        marcarSujo()
    end)

    pintar()
    return frame, pintar
end

local function criarCampo(item)
    local frame = linhaBase(54)

    novo("TextLabel", {
        Size = UDim2.new(1, -8, 0, 20),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = COR.texto,
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
        Text = tostring(getPath(item.path) or ""),
    }, frame)
    canto(caixa, 6)
    novo("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, caixa)
    local traco = novo("UIStroke", { Color = COR.linha, Thickness = 1 }, caixa)

    caixa.Focused:Connect(function()
        animar(traco, 0.15, { Color = COR.destaque })
    end)
    caixa.FocusLost:Connect(function()
        animar(traco, 0.15, { Color = COR.linha })
        setPath(item.path, caixa.Text)
        marcarSujo()
    end)

    return frame, function()
        caixa.Text = tostring(getPath(item.path) or "")
    end
end

-- toggle de preferencia do painel (nao vai para o motor)
local function criarPref(chave, label, desc)
    local frame = criarToggle({ path = "__pref__" .. chave, label = label, desc = desc })
    return frame
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

--==========================================================================
-- 8. Suporte a preferencias dentro de getPath/setPath
--==========================================================================
do
    local getOriginal, setOriginal = getPath, setPath
    getPath = function(caminho)
        local chave = string.match(caminho, "^__pref__(.+)$")
        if chave then
            return Pref[chave]
        end
        return getOriginal(caminho)
    end
    setPath = function(caminho, valor)
        local chave = string.match(caminho, "^__pref__(.+)$")
        if chave then
            Pref[chave] = valor
            return
        end
        return setOriginal(caminho, valor)
    end
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

local paginas = {}
local repintar = {}
local abrirAba, abaAtiva

local function aba(nome, construir)
    table.insert(paginas, { nome = nome, construir = construir })
end

-------------------------------------------------------------------- Farm
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
    criarToggle({ path = "Farm.BuyEgg", label = "Comprar ovo quando nao houver filhote", alerta = true,
        desc = "Gasta Bucks. Nunca compra nada que custe Robux." })
    criarCiclo({ path = "Farm.EggToBuy", label = "Ovo a comprar",
        opcoes = { "cracked_egg", "pet_egg", "fairytale_egg_2026_fairytale_egg" } })
    criarSlider({ path = "Farm.MaxBuysPerSession", label = "Limite de itens por sessao",
        min = 0, max = 50, sufixo = "   0 = sem limite" })
    criarSlider({ path = "Farm.MaxEggBuysPerSession", label = "Limite de ovos por sessao",
        min = 0, max = 20, sufixo = "   0 = sem limite" })

    tituloSecao("outros")
    criarToggle({ path = "Farm.CollectCashback", label = "Coletar cashback" })
    criarSlider({ path = "Farm.CashbackMinutes", label = "Coletar cashback a cada",
        min = 1, max = 60, sufixo = " min" })
    criarCiclo({ path = "Farm.SpotTravel", label = "Chegar aos pontos do mapa",
        opcoes = { "teleport", "door" } })
end)

----------------------------------------------------------------- Tarefas
aba("Tarefas", function()
    criarTexto("Cada chave e um tipo de necessidade que o farm resolve sozinho. "
        .. "Desligue as que voce nao quer que ele faca.", COR.fraco, 40)

    criarBotao("LIGAR TODAS AS TAREFAS", COR.linha, function()
        for _, tarefa in ipairs(TAREFAS) do
            Cfg.Farm.Tasks[tarefa[1]] = true
        end
        marcarSujo()
        abrirAba(abaAtiva)
        setStatus("todas as tarefas ligadas")
    end)
    criarBotao("SO AS RAPIDAS", COR.linha, function()
        for _, tarefa in ipairs(TAREFAS) do
            Cfg.Farm.Tasks[tarefa[1]] = not LENTAS[tarefa[1]]
        end
        marcarSujo()
        abrirAba(abaAtiva)
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
end)

------------------------------------------------------------- Prioridades
aba("Prioridades", function()
    criarTexto("Numero maior roda primeiro quando varias necessidades estao abertas "
        .. "ao mesmo tempo. Mexa so se souber o que quer: o padrao poe as rapidas na frente.",
        COR.fraco, 54)
    criarBotao("RESTAURAR PRIORIDADES PADRAO", COR.linha, function()
        Cfg.Farm.Priority = defaults().Farm.Priority
        marcarSujo()
        abrirAba(abaAtiva)
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
    criarTexto("Tarefas do Halloween 2026 e do Pet Pen. A chave principal precisa estar "
        .. "ligada para qualquer uma das outras rodar.", COR.fraco, 42)
    criarToggle({ path = "Farm.Event.Enabled", label = "Evento ligado, chave principal" })

    tituloSecao("halloween")
    criarToggle({ path = "Farm.Event.GhostGallery", label = "Ghost Gallery" })
    criarToggle({ path = "Farm.Event.Crypt", label = "Cripta" })
    criarToggle({ path = "Farm.Event.MummySpider", label = "Aranha Mumia" })
    criarToggle({ path = "Farm.Event.Quests", label = "Missoes diarias" })
    criarToggle({ path = "Farm.Event.HouseVisits", label = "Visitar casas, missao" })
    criarToggle({ path = "Farm.Event.PigeonNest", label = "Ninho do pombo" })
    criarToggle({ path = "Farm.Event.StrayCat", label = "Gato de rua" })

    tituloSecao("pet pen")
    criarToggle({ path = "Farm.Event.PetPen", label = "Gerenciar o Pet Pen" })
    criarToggle({ path = "Farm.Event.PetPenStock", label = "Manter o Pet Pen cheio",
        desc = "Compra ovos para encher as vagas. Precisa de Comprar ovo ligado." })
    criarSlider({ path = "Farm.Event.PetPenSlots", label = "Vagas do Pet Pen", min = 1, max = 5 })
    criarSlider({ path = "Farm.Event.PetPenMinutes", label = "Checar o Pet Pen a cada",
        min = 1, max = 60, sufixo = " min" })
end)

---------------------------------------------------------------- Avancado
aba("Avancado", function()
    criarTexto("Mexer aqui muda o ritmo e a tolerancia a falhas do motor. "
        .. "Os valores padrao foram ajustados pelo autor em testes longos.", COR.aviso, 42)

    tituloSecao("ritmo")
    criarSlider({ path = "General.TickSeconds", label = "Intervalo do laco principal",
        min = 0.1, max = 5, passo = 0.1, sufixo = " s" })
    criarSlider({ path = "Farm.PetMeFocusSeconds", label = "Tempo de carinho no pet",
        min = 3, max = 20, sufixo = " s" })

    tituloSecao("falhas")
    criarSlider({ path = "Farm.FailureCooldownSeconds", label = "Espera apos uma falha",
        min = 5, max = 180, sufixo = " s" })
    criarSlider({ path = "Farm.MaxConsecutiveFailures", label = "Falhas seguidas ate desistir",
        min = 1, max = 10, sufixo = "   depois a tarefa fica desligada na sessao" })

    tituloSecao("experimental")
    criarToggle({ path = "Farm.HouseDoorExit", label = "Sair de casa pela porta", alerta = true,
        desc = "No teste do autor isto nunca funcionou. Deixe desligado." })

    tituloSecao("painel")
    criarPref("AutoIniciar", "Iniciar o farm junto com o painel")
    criarPref("AbrirMinimizado", "Abrir ja minimizado")
    criarPref("Animacoes", "Animacoes ligadas",
        "Desligue se o seu aparelho estiver pesado.")
end)

------------------------------------------------------------- Privacidade
aba("Privacidade", function()
    criarTexto("O MOTOR VEM COM A TELEMETRIA LIGADA. Ela envia seu nome do Roblox, seu ID "
        .. "de usuario e um resumo da sessao ao autor do farm. Este painel comeca com ela "
        .. "DESLIGADA.", COR.aviso, 58)
    criarToggle({ path = "Telemetry.Enabled", label = "Enviar telemetria ao autor", alerta = true,
        desc = "Destino: adoptmelogs.04demirali123.workers.dev, de victimoffate_." })
    criarSlider({ path = "Telemetry.SummaryMinutes", label = "Enviar a cada",
        min = 5, max = 120, sufixo = " min" })

    tituloSecao("webhook do discord, seu")
    criarTexto("Opcional e so para voce. Vazio nao envia nada.", COR.fraco, 26)
    criarToggle({ path = "Notifications.Enabled", label = "Enviar avisos para o meu Discord" })
    criarCampo({ path = "Notifications.Webhooks.Summary", label = "Webhook de resumo",
        dica = "https://discord.com/api/webhooks/..." })
    criarCampo({ path = "Notifications.Webhooks.Alerts", label = "Webhook de alertas",
        dica = "vazio usa o de resumo" })
    criarCampo({ path = "Notifications.PingDiscordUserId", label = "Meu ID do Discord para mencao",
        dica = "so numeros" })
    criarToggle({ path = "Notifications.IncludeUsername", label = "Incluir meu nome nas mensagens" })

    tituloSecao("quando avisar")
    criarToggle({ path = "Notifications.SendOnStartStop", label = "Ao iniciar e parar" })
    criarToggle({ path = "Notifications.SendOnError", label = "Em erro" })
    criarToggle({ path = "Notifications.SendOnKick", label = "Ao ser desconectado" })
    criarToggle({ path = "Notifications.SendOnTaskComplete", label = "A cada tarefa concluida",
        desc = "Gera muitas mensagens." })
    criarToggle({ path = "Notifications.SendTestMessageOnStart", label = "Mensagem de teste ao iniciar" })
    criarSlider({ path = "Notifications.SummaryIntervalMinutes", label = "Resumo a cada",
        min = 0, max = 120, sufixo = " min   0 = nunca" })

    tituloSecao("mencionar meu id em")
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

    tituloSecao("registro")
    criarCiclo({ path = "Logging.ConsoleLevel", label = "Mensagens no console",
        opcoes = { "OFF", "INFO", "DEBUG", "SUCCESS", "WARN", "ERROR" } })
    criarToggle({ path = "Logging.FileEnabled", label = "Gravar arquivo de log" })
    criarCiclo({ path = "Logging.FileLevel", label = "Nivel do arquivo",
        opcoes = { "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR" } })
    criarToggle({ path = "Logging.SessionFile", label = "Gravar estado da sessao" })
    criarSlider({ path = "Logging.FlushSeconds", label = "Gravar em disco a cada",
        min = 1, max = 60, sufixo = " s" })
    criarSlider({ path = "Logging.MaxLinesPerSession", label = "Maximo de linhas por sessao",
        min = 1000, max = 50000, passo = 1000 })
end)

------------------------------------------------------------------ Status
aba("Status", function()
    local _, rotulo = criarTexto("", COR.texto, 170)
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
            table.insert(pets, tostring(pet.kind) .. " idade " .. tostring(pet.age or "?"))
        end
        rotulo.Text = table.concat({
            "Motor: v" .. tostring(api.Version),
            string.format("Tempo de sessao: %02d:%02d:%02d", math.floor(segundos / 3600),
                math.floor(segundos % 3600 / 60), segundos % 60),
            "Tarefa agora: " .. tostring(ler("farm.currentTask", "nenhuma")),
            "Lugar: " .. tostring(ler("player.interior", "?")),
            "Time: " .. tostring(ler("player.team", "?")),
            "Bucks: " .. tostring(ler("player.bucks", "?")),
            "Necessidades concluidas: " .. tostring(ler("stats.needsCompleted", 0)),
            "Bucks ganhos: " .. tostring(ler("stats.bucksEarned", 0)),
            "Tarefas: " .. tostring(ler("farm.tasksSucceeded", 0)) .. " ok, "
                .. tostring(ler("farm.tasksFailed", 0)) .. " falhas",
            "Pets: " .. (#pets > 0 and table.concat(pets, ", ") or "nenhum"),
        }, "\n")
    end)

    tituloSecao("predefinicoes")
    criarBotao("LIGAR TUDO", COR.linha, function()
        local function ligar(node)
            for chave, valor in pairs(node) do
                if type(valor) == "table" then
                    ligar(valor)
                elseif type(valor) == "boolean" and chave ~= "HouseDoorExit" then
                    node[chave] = true
                end
            end
        end
        ligar(Cfg.Farm)
        marcarSujo()
        abrirAba(abaAtiva)
        setStatus("tudo ligado, telemetria segue desligada")
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
        Cfg = novoCfg
        marcarSujo()
        abrirAba(abaAtiva)
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
        abrirAba(abaAtiva)
        setStatus("tudo desligado")
    end)

    tituloSecao("motor")
    criarBotao("ATUALIZAR MOTOR, baixa de novo e fixa", COR.destaque, function()
        setStatus("baixando...")
        task.spawn(function()
            local fonte, como = fetchEngine(true)
            if fonte then
                engineSource = fonte
                setStatus("motor atualizado: " .. como .. ", " .. #fonte .. " bytes")
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
            setStatus("configuracao copiada para a area de transferencia")
        else
            setStatus("nao deu para codificar a configuracao")
        end
    end)
    criarBotao("RESTAURAR PADROES DO PAINEL", COR.perigo, function()
        Cfg = defaults()
        marcarSujo()
        abrirAba(abaAtiva)
        setStatus("padroes restaurados")
    end)

    tituloSecao("origem")
    criarTexto("Motor: " .. ENGINE_URL, COR.fraco, 42)
end)

--==========================================================================
-- 10. Montagem das abas
--==========================================================================
local botoesAba = {}

function abrirAba(indice)
    abaAtiva = indice
    for posicao, botao in ipairs(botoesAba) do
        local ativo = posicao == indice
        animar(botao, 0.15, {
            BackgroundColor3 = ativo and COR.destaque or COR.painel,
            TextColor3 = ativo and Color3.new(1, 1, 1) or COR.fraco,
        })
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
    -- entrada deslizando
    areaConteudo.Position = POS_CONTEUDO + UDim2.fromOffset(16, 0)
    animar(areaConteudo, 0.18, { Position = POS_CONTEUDO }, Enum.EasingStyle.Quint)
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
    if mostrar then
        janela.Visible = true
        janela.Size = UDim2.fromOffset(LARG - 60, (minimizado and ALT_BARRA or ALT) - 40)
        animar(janela, 0.24, {
            Size = UDim2.fromOffset(LARG, minimizado and ALT_BARRA or ALT),
        }, Enum.EasingStyle.Quint)
    else
        local t = animar(janela, 0.16, { Size = UDim2.fromOffset(LARG - 60, 0) })
        if t then
            t.Completed:Connect(function()
                janela.Visible = false
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
    if not capturado and entrada.KeyCode == TOGGLE_KEY then
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

-- rodape, ponto de estado e aba Status
task.spawn(function()
    local ultimoTexto = nil
    while tela.Parent do
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
            animar(pontoEstado, 0.2, { BackgroundColor3 = rodando and COR.ligado or COR.desligado })
        end
        if abaAtiva == #paginas then
            for _, funcao in ipairs(repintar) do
                pcall(funcao)
            end
        end
        task.wait(1)
    end
end)

-- pulsar o ponto enquanto o farm roda
task.spawn(function()
    while tela.Parent do
        if isRunning() and Pref.Animacoes then
            animar(pontoEstado, 0.6, { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -94, 0, 17) })
            task.wait(0.6)
            animar(pontoEstado, 0.6, { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(1, -92, 0, 19) })
            task.wait(0.6)
        else
            task.wait(1)
        end
    end
end)

--==========================================================================
-- 12. Inicio
--==========================================================================
loadConfig()
minimizado = Pref.AbrirMinimizado == true
abrirAba(1)
aplicarMinimizar(false)
janela.Size = UDim2.fromOffset(LARG - 60, (minimizado and ALT_BARRA or ALT) - 40)
animar(janela, 0.3, {
    Size = UDim2.fromOffset(LARG, minimizado and ALT_BARRA or ALT),
}, Enum.EasingStyle.Quint)

setStatus(canWrite and ("pronto. configuracao em " .. CFG_FILE)
    or "pronto. seu executor nao grava arquivos: a configuracao nao sera salva.")

if Pref.AutoIniciar then
    task.spawn(function()
        task.wait(1)
        startFarm()
    end)
end
