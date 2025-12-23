# 🔒 Modo de Privacidade

## Visão Geral

O VPN Monitor oferece **dois modos** de operação para localizar o botão Connect do FortiClient:

1. **🔍 Detecção Automática** (padrão) - Com screenshot
2. **🔒 Modo Privacidade** - Sem screenshot

## 🔍 Detecção Automática (Padrão)

### Como Funciona
- Captura screenshot da janela FortiClient
- Analisa pixels via visão computacional (Python + Pillow)
- Detecta automaticamente a posição do botão Connect
- Adapta-se a diferentes tamanhos e posições de janela

### Vantagens
✅ **Mais preciso** - Encontra o botão automaticamente  
✅ **Adaptável** - Funciona com qualquer tamanho de janela  
✅ **Robusto** - Se adapta a mudanças na UI do FortiClient  
✅ **Zero configuração** - Não precisa calibrar manualmente

### Desvantagens
⚠️ **Captura screenshot** da janela FortiClient  
⚠️ **Requer permissão** "Screen Recording" no macOS  
⚠️ **Requer Python 3** + biblioteca Pillow  

### Quando Usar
- Para máxima conveniência e precisão
- Quando você move/redimensiona a janela FortiClient frequentemente
- Se não tem preocupações com permissões de screen recording

---

## 🔒 Modo Privacidade

### Como Funciona
- Usa coordenadas fixas calibradas
- Calcula posição do botão baseado na posição da janela
- **NÃO captura screenshots**
- Não requer permissão "Screen Recording"

### Vantagens
✅ **SEM screenshots** - Privacidade total  
✅ **SEM permissão** "Screen Recording"  
✅ **Mais leve** - Não requer Python/Pillow  
✅ **Mais seguro** - Menos permissões = menor superfície de ataque

### Desvantagens
⚠️ **Coordenadas fixas** - Calibrado para janela 894x714  
⚠️ **Pode precisar recalibração** se você redimensionar a janela  
⚠️ **Menos flexível** - Não se adapta automaticamente

### Quando Usar
- **Privacidade é prioridade** 🔒
- Você não quer dar permissão de "Screen Recording"
- Janela FortiClient sempre no mesmo tamanho
- Preocupações com segurança/compliance

---

## 📝 Como Ativar o Modo Privacidade

### Método 1: Editar config.sh (Recomendado)

```bash
# 1. Abrir o arquivo de configuração
nano ~/GitHub/mac-Forticlient-automation/config.sh

# 2. Alterar a linha:
export PRIVACY_MODE=true

# 3. Salvar (Ctrl+O, Enter, Ctrl+X)
```

### Método 2: Variável de ambiente

```bash
# Definir antes de executar
export PRIVACY_MODE=true
./scripts/auto-click-connect.sh
```

---

## ⚙️ Calibração de Coordenadas

Se o modo privacidade **não acertar o botão**, você precisa recalibrar:

### 1. Verificar tamanho da janela

Execute o script e veja o output:
```
📏 Janela: 894x714 em (273, 93)
```

### 2. Ajustar coordenadas

Edite `config.sh`:

```bash
# Se o clique está errando:

# Muito à esquerda? Aumente X
export BUTTON_OFFSET_X=560  # Era 552

# Muito à direita? Diminua X
export BUTTON_OFFSET_X=545  # Era 552

# Muito acima? Aumente Y
export BUTTON_OFFSET_Y=535  # Era 525

# Muito abaixo? Diminua Y
export BUTTON_OFFSET_Y=515  # Era 525
```

### 3. Valores padrão

Para janela **894x714**:
- `BUTTON_OFFSET_X=552`
- `BUTTON_OFFSET_Y=525`

---

## 🔐 Comparação de Permissões

| Permissão | Detecção Automática | Modo Privacidade |
|-----------|---------------------|------------------|
| **Acessibilidade** | ✅ Obrigatório | ✅ Obrigatório |
| **Screen Recording** | ⚠️ **Obrigatório** | ❌ **NÃO necessário** |

### Como Configurar Permissões

#### Acessibilidade (Ambos os modos)
1. Abra: **Configurações → Privacidade e Segurança → Acessibilidade**
2. Clique no **+** ou **ative** seu terminal
3. Exemplos: Terminal.app, iTerm2, Warp, etc.

#### Screen Recording (Apenas Detecção Automática)
1. Abra: **Configurações → Privacidade e Segurança → Gravação de Tela**
2. Clique no **+** ou **ative** seu terminal
3. ⚠️ **Reinicie o terminal** após habilitar

---

## 🛡️ Considerações de Segurança

### Detecção Automática
**Riscos:**
- Permissão de screen recording permite capturar **toda a tela**
- Aplicações com essa permissão podem gravar você o tempo todo
- Maior superfície de ataque se terminal for comprometido

**Mitigações:**
- Screenshots são **temporários** (`/tmp/`)
- Apenas a **janela FortiClient** é capturada
- Arquivos deletados após uso
- Script é **open source** - você pode auditar

### Modo Privacidade
**Benefícios:**
- ✅ Zero screenshots
- ✅ Zero permissões adicionais
- ✅ Menor superfície de ataque
- ✅ Ideal para ambientes corporativos com políticas rígidas

---

## 📊 Qual Modo Escolher?

### Use **Detecção Automática** se:
- ✅ Você prioriza **conveniência**
- ✅ Confia no código (é open source!)
- ✅ Não tem restrições de compliance
- ✅ Muda tamanho/posição da janela frequentemente

### Use **Modo Privacidade** se:
- 🔒 Privacidade é **prioridade máxima**
- 🔒 Não quer dar permissão de screen recording
- 🔒 Trabalha em ambiente corporativo restrito
- 🔒 Janela FortiClient sempre no mesmo tamanho

---

## 🔄 Mudando Entre Modos

Você pode alternar a qualquer momento:

```bash
# 1. Editar configuração
nano ~/GitHub/mac-Forticlient-automation/config.sh

# 2. Trocar o valor
export PRIVACY_MODE=true   # ou false

# 3. Reiniciar o monitor
~/bin/restart-monitor.sh
```

Não é necessário reinstalar! 🎉

---

## ❓ FAQ

### 1. O modo privacidade é menos preciso?
Não, desde que a janela tenha o mesmo tamanho calibrado. Funciona **perfeitamente**.

### 2. Posso usar detecção automática sem Python?
Não. A detecção automática requer Python 3 + Pillow. Use o modo privacidade nesse caso.

### 3. O screenshot fica salvo?
Não permanentemente. Fica em `/tmp/` e é sobrescrito a cada execução. Desaparece ao reiniciar o Mac.

### 4. Posso ver o screenshot?
Sim! Está em `/tmp/forticlient-window.png` após cada execução com detecção automática.

### 5. O modo privacidade funciona em multi-monitor?
Sim! Ambos os modos suportam multi-monitor perfeitamente.

---

## 🎓 Recomendação

**Para usuários normais:** Use **Detecção Automática** (padrão)  
**Para paranóicos (como eu 😄):** Use **Modo Privacidade**

Ambos funcionam muito bem! A escolha é sua. 🚀
