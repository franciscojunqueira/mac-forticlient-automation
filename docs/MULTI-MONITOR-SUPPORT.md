# 🖥️ Suporte Multi-Monitor e Coordenadas Dinâmicas

## ✅ Funcionamento em Múltiplos Monitores

### Garantia de Funcionamento
O sistema de clique automático funciona **100%** independente de:
- ✅ Qual monitor a janela está
- ✅ Posição da janela na tela
- ✅ Resolução do monitor
- ✅ Escala/DPI do monitor
- ✅ Arranjo de monitores (lado a lado, empilhados, etc.)

### Como Funciona

#### 1. Detecção Dinâmica da Posição
A cada execução, o script obtém a posição atual da janela:

```bash
# Pega posição e tamanho DA JANELA (não hardcoded)
WINDOW_INFO=$(osascript <<'EOF'
tell application "System Events"
    tell process "FortiClient"
        position of window "FortiClient -- Zero Trust Fabric Agent"
        size of window "FortiClient -- Zero Trust Fabric Agent"
    end tell
end tell
EOF
)
```

#### 2. Cálculo Relativo
As coordenadas do botão são calculadas **relativas à posição da janela**:

```bash
# WIN_X e WIN_Y são obtidos dinamicamente
BUTTON_X = WIN_X + (WIN_WIDTH × 62%)
BUTTON_Y = WIN_Y + (WIN_HEIGHT × 72%)
```

#### 3. Não Usa Coordenadas Absolutas Fixas
❌ **NÃO fazemos isto:**
```bash
# ERRADO - Coordenadas fixas só funcionam em uma posição
BUTTON_X=768
BUTTON_Y=591
```

✅ **Fazemos isto:**
```bash
# CORRETO - Sempre relativo à janela atual
BUTTON_X=$((WIN_X + WIN_WIDTH * 62 / 100))
```

## 🎯 Exemplos de Funcionamento

### Exemplo 1: Janela no Monitor Principal
```
Monitor 1 (principal): 0,0 → 1920x1080
FortiClient em: (212, 61)
Botão em: (212 + 554, 61 + 528) = (766, 589) ✅
```

### Exemplo 2: Janela em Monitor Secundário à Direita
```
Monitor 1: 0,0 → 1920x1080
Monitor 2: 1920,0 → 3840x1080 (à direita)
FortiClient em: (2500, 100)
Botão em: (2500 + 554, 100 + 528) = (3054, 628) ✅
```

### Exemplo 3: Janela em Monitor Acima
```
Monitor 1: 0,0 → 1920x1080
Monitor 2: 0,-1080 → 1920,0 (acima)
FortiClient em: (300, -800)
Botão em: (300 + 554, -800 + 528) = (854, -272) ✅
```

### Exemplo 4: Janela Movida Durante Execução
```
Primeira execução:
  Janela em: (100, 100) → Clica em: (654, 628) ✅

Usuário move janela para: (1500, 500)

Segunda execução:
  Janela em: (1500, 500) → Clica em: (2054, 1028) ✅
```

## 🔄 Restauração Completa do Contexto

### 🖱️ Restauração da Posição do Mouse

#### Por Que É Importante
Se o usuário está trabalhando e o mouse move automaticamente:
- ❌ Pode interromper o trabalho
- ❌ Pode causar cliques acidentais
- ❌ Pode ser confuso/irritante

#### Solução Implementada

```bash
# 1. Salva posição atual
ORIG_MOUSE_POS=$(cliclick p)
# Exemplo: "1234,567"

# 2. Faz o trabalho
cliclick m:766,589  # Move
cliclick c:766,589  # Clica

# 3. Restaura posição original
cliclick m:$ORIG_MOUSE_POS
# Mouse volta para (1234, 567)
```

### 🎯 Restauração do Foco da Aplicação

#### Por Que É Importante
Quando o FortiClient é ativado para clicar:
- ❌ Tira foco da aplicação em que usuário estava trabalhando
- ❌ Usuário precisa clicar manualmente para voltar
- ❌ Quebra o fluxo de trabalho

#### Solução Implementada

```bash
# 1. Salva aplicação atualmente em foco
ORIG_APP=$(osascript <<'EOF'
tell application "System Events"
    name of first application process whose frontmost is true
end tell
EOF
)
# Exemplo: "Google Chrome", "Cursor", "Slack", etc.

# 2. Ativa FortiClient e faz o clique
tell application "FortiClient" to activate
# ... clica no botão ...

# 3. Restaura foco para aplicação original
if [ "$ORIG_APP" != "FortiClient" ]; then
    tell application "$ORIG_APP" to activate
fi
# Usuário volta exatamente onde estava
```

#### Cenários Cobertos

**Cenário 1: Editando Documento**
```
Usuário em: Google Docs
Script ativa: FortiClient → clica → restaura Google Docs
Resultado: Usuário continua editando ✅
```

**Cenário 2: Codificando**
```
Usuário em: VS Code / Cursor
Script ativa: FortiClient → clica → restaura VS Code
Resultado: Cursor volta para o editor ✅
```

**Cenário 3: Video Conference**
```
Usuário em: Zoom / Teams
Script ativa: FortiClient → clica → restaura Zoom
Resultado: Volta para reunião sem interrupção ✅
```

**Cenário 4: FortiClient Já em Foco**
```
Usuário já em: FortiClient
Script: Não tenta restaurar foco
Resultado: FortiClient permanece em foco ✅
```

### Cenários Cobertos

#### Cenário 1: Mouse em Outro Monitor
```
Mouse original: (-1262, -301) - Monitor à esquerda
Script move para: (766, 589) - Monitor principal
Script restaura: (-1262, -301) ✅
```

#### Cenário 2: Usuário Editando Documento
```
Mouse sobre texto: (850, 450)
Script clica VPN: (766, 589)
Script restaura: (850, 450)
Usuário continua editando sem interrupção ✅
```

#### Cenário 3: Mouse em Movimento
```
Usuário está movendo mouse quando script executa
Script salva posição no momento: (400, 300)
Script faz clique
Script restaura: (400, 300)
Usuário pode continuar de onde parou ✅
```

## 📐 Sistema de Coordenadas do macOS

### Origem (0, 0)
- Canto superior esquerdo do **monitor principal**
- Definido em Preferências → Monitores

### Monitores Secundários

#### À Direita
```
Monitor 1: (0, 0) ────────────┐
          │     1920x1080      │
          └────────────────────┘
                               Monitor 2: (1920, 0) ────────────┐
                                         │     1920x1080        │
                                         └──────────────────────┘
```

#### À Esquerda (Coordenadas Negativas)
```
                    Monitor 2: (-1920, 0) ────────────┐
                              │     1920x1080        │
                              └──────────────────────┘
                                                     Monitor 1: (0, 0) ────────────┐
                                                               │     1920x1080      │
                                                               └────────────────────┘
```

#### Acima (Coordenadas Negativas em Y)
```
Monitor 2: (0, -1080) ────────────┐
          │     1920x1080         │
          └───────────────────────┘
Monitor 1: (0, 0) ────────────────┐
          │     1920x1080         │
          └───────────────────────┘
```

### Por Que Funciona Sempre

O AppleScript retorna a posição **absoluta** da janela:
- Usa o mesmo sistema de coordenadas do macOS
- Funciona com coordenadas negativas
- Funciona em qualquer arranjo de monitores

Então calculamos o botão **relativo** a essa posição:
```bash
# Se janela está em (-500, -300) [monitor à esquerda/acima]
WIN_X=-500
WIN_Y=-300

# Botão será em:
BUTTON_X = -500 + 554 = 54
BUTTON_Y = -300 + 528 = 228

# cliclick entende coordenadas negativas perfeitamente ✅
```

## 🧪 Testes Recomendados

### Teste 1: Mover Entre Monitores
1. Conecte-se à VPN
2. Mova janela FortiClient para monitor secundário
3. Desconecte VPN manualmente
4. Verifique se clique funciona no monitor secundário ✅

### Teste 2: Diferentes Posições
1. Coloque janela no canto superior esquerdo
2. Desconecte VPN → deve funcionar ✅
3. Mova janela para centro
4. Desconecte VPN → deve funcionar ✅
5. Mova janela para canto inferior direito
6. Desconecte VPN → deve funcionar ✅

### Teste 3: Restauração do Mouse
1. Posicione mouse em local específico
2. Desconecte VPN
3. Script clica no botão
4. Verifique se mouse volta para posição original ✅

## 🔧 Manutenção

### O Que NÃO Precisa Ajustar
- ❌ Coordenadas ao mover janela
- ❌ Coordenadas ao trocar de monitor
- ❌ Coordenadas ao mudar resolução

### O Que PODE Precisar Ajustar
- ✅ Porcentagens (62%, 72%) se layout da UI do FortiClient mudar
- ✅ Nome da janela se FortiClient atualizar título
- ✅ Delays se sistema ficar mais lento/rápido

### Como Verificar Se Está Funcionando

```bash
# Execute e veja coordenadas detectadas
./scripts/auto-click-connect.sh

# Output mostrará:
# "Janela detectada: 894x734 na posição (X, Y)"
# "Clicando na posição: (BX, BY)"

# Se X, Y mudam quando você move a janela = ✅ Funcionando
# Se BX, BY calculam corretamente a partir de X, Y = ✅ Funcionando
```

## ✨ Benefícios da Implementação

1. **Zero configuração** - Funciona imediatamente
2. **Portável** - Funciona em qualquer Mac com múltiplos monitores
3. **Robusto** - Não quebra ao mover janela
4. **Não-intrusivo** - Restaura posição do mouse
5. **Adaptável** - Se adapta a diferentes resoluções automaticamente

---

**Testado em:**
- ✅ Monitor único (built-in MacBook)
- ✅ Monitor externo único
- ✅ Dual monitor (horizontal)
- ✅ Triple monitor
- ✅ Monitores com diferentes resoluções
- ✅ Arranjos não-padrão (vertical, escalonado, etc.)

**Compatibilidade:** macOS 11+ com suporte a múltiplos monitores
