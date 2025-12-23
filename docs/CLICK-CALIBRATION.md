# 📐 Calibração de Coordenadas do Botão Connect

## 🎯 Coordenadas Atuais (Calibradas)

### Medição Real
- **Canto superior esquerdo da janela:** (216, 66)
- **Botão "Connect":** (768, 591)

### Cálculo de Offsets
```
Offset X = 768 - 216 = 552 pixels
Offset Y = 591 - 66 = 525 pixels
```

### Proporções Relativas
Com janela de tamanho 894x734:
- **Posição X:** 552/894 = **61.7%** da largura
- **Posição Y:** 525/734 = **71.5%** da altura

## 🔧 Implementação no Script

### Fórmula Usada
```bash
BUTTON_X = WIN_X + (WIN_WIDTH * 62 / 100)   # 62% da largura
BUTTON_Y = WIN_Y + (WIN_HEIGHT * 72 / 100)  # 72% da altura
```

### Fórmula Alternativa (Offsets Fixos)
```bash
BUTTON_X = WIN_X + 552  # Offset fixo de 552 pixels
BUTTON_Y = WIN_Y + 525  # Offset fixo de 525 pixels
```

**Nota:** A fórmula de porcentagem é preferível porque se adapta se a janela for redimensionada.

## 🧪 Verificação

Para a janela na posição (212, 61) com tamanho 894x734:

### Cálculo
```
BUTTON_X = 212 + (894 × 62 ÷ 100) = 212 + 554 = 766
BUTTON_Y = 61 + (734 × 72 ÷ 100) = 61 + 528 = 589
```

### Resultado
- **Calculado:** (766, 589)
- **Real (medido):** (768, 591)
- **Diferença:** 2 pixels em X, 2 pixels em Y
- **Precisão:** 99.7% ✅

## 🔍 Como Recalibrar (se necessário)

### Método 1: Script Interativo
```bash
./scripts/debug-click-position.sh
```
O script testa automaticamente diferentes posições.

### Método 2: Manual
1. **Posicione o mouse sobre o botão "Connect"**
2. **Execute:**
   ```bash
   cliclick p
   ```
   Anote as coordenadas (ex: 768,591)

3. **Meça o canto da janela:**
   - Posicione mouse no canto superior esquerdo da janela
   - Execute: `cliclick p`
   - Anote as coordenadas (ex: 216,66)

4. **Calcule offsets:**
   ```
   Offset X = Botão X - Janela X
   Offset Y = Botão Y - Janela Y
   ```

5. **Calcule porcentagens:**
   ```bash
   # Obtenha tamanho da janela
   osascript <<'EOF'
   tell application "System Events"
       tell process "FortiClient"
           size of window "FortiClient -- Zero Trust Fabric Agent"
       end tell
   end tell
   EOF
   
   # Calcule
   Percent X = (Offset X / Largura) × 100
   Percent Y = (Offset Y / Altura) × 100
   ```

6. **Atualize o script:**
   Edite `scripts/auto-click-connect.sh` linhas 54-55:
   ```bash
   BUTTON_X=$((WIN_X + WIN_WIDTH * [PERCENT_X] / 100))
   BUTTON_Y=$((WIN_Y + WIN_HEIGHT * [PERCENT_Y] / 100))
   ```

### Método 3: Teste com Coordenadas Específicas
```bash
./scripts/click-at-coords.sh X Y
```
Testa clique em coordenadas absolutas específicas.

## 📊 Histórico de Calibrações

### v1.0 - Primeira tentativa (Incorreta)
```bash
BUTTON_X = WIN_X + WIN_WIDTH / 2        # 50% - centro
BUTTON_Y = WIN_Y + WIN_HEIGHT * 85 / 100  # 85%
```
**Resultado:** (659, 684) - ERRADO ❌

### v1.1 - Após calibração (Correta)
```bash
BUTTON_X = WIN_X + WIN_WIDTH * 62 / 100   # 62%
BUTTON_Y = WIN_Y + WIN_HEIGHT * 72 / 100  # 72%
```
**Resultado:** (766, 589) - CORRETO ✅

## 🖥️ Considerações Multi-Monitor

### Coordenadas Absolutas
O macOS usa coordenadas absolutas na tela principal como referência:
- **(0, 0)** = Canto superior esquerdo do monitor principal
- Monitores secundários podem ter coordenadas negativas ou muito altas

### Janela em Diferentes Monitores
As coordenadas do script são **relativas à posição da janela**, então funcionam em qualquer monitor:
```bash
# Sempre funciona, independente do monitor:
BUTTON_X = WIN_X + (WIN_WIDTH * 62 / 100)
```

### Verificação
Para ver onde sua janela está:
```bash
osascript <<'EOF'
tell application "System Events"
    tell process "FortiClient"
        position of window "FortiClient -- Zero Trust Fabric Agent"
    end tell
end tell
EOF
```

## 🎯 Precisão do Clique

### Área do Botão
O botão "Connect" tem aproximadamente:
- **Largura:** ~120 pixels
- **Altura:** ~40 pixels

### Margem de Erro Aceitável
- **±10 pixels** em qualquer direção ainda acerta o botão
- **Precisão atual:** ±2 pixels = excelente!

### Fallback
Se o clique falhar:
1. O monitor detecta que não conectou
2. Mantém flag `RECONNECT_ATTEMPTED=false`
3. Não tenta clicar novamente automaticamente
4. Alerta usuário para clicar manualmente

## 🔄 Manutenção

### Quando Recalibrar
- ❌ **NÃO necessário:** Mover janela entre monitores
- ❌ **NÃO necessário:** Fechar e reabrir FortiClient
- ✅ **Necessário:** Atualização do FortiClient que mude o layout da UI
- ✅ **Necessário:** Mudar tema/escala do macOS que afete o tamanho da janela

### Teste Periódico
Recomenda-se testar após:
- Atualização do FortiClient
- Atualização do macOS
- Mudança de resolução/escala de tela

```bash
# Teste rápido
./scripts/auto-click-connect.sh
```

---

**Última calibração:** 23/12/2025  
**Versão FortiClient:** 7.x  
**macOS:** 14.x  
**Precisão:** 99.7%
