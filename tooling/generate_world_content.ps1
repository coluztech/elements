$ErrorActionPreference = 'Stop'
$levelsPath = Join-Path $PSScriptRoot '..\assets\levels'
$elements = @('fire', 'water', 'earth', 'wood')
for ($world = 1; $world -le 4; $world++) {
  for ($index = 1; $index -le 15; $index++) {
    if ($world -eq 1 -and $index -le 10) { continue }
    $id = 'level_w{0}_{1:d2}' -f $world, $index
    $kind = ($index + $world) % 5
    $terrain = @(
      @{ x=0; y=560; width=1280; height=176 },
      @{ x=0; y=0; width=40; height=560 },
      @{ x=1240; y=0; width=40; height=560 }
    )
    $hazards = @(); $interactables = @(); $required = @(); $available = @($elements)
    $hint = 'Read the obstacle ahead and choose the element that can cross it.'
    switch ($kind) {
      0 {
        $interactables += @{ type='burnableVine'; x=400; y=464; width=36; height=96 }
        $required = @('fire'); $available = @('fire','water')
        $hint = 'Fire burns the green vine. Approach it while Fire is active.'
      }
      1 {
        $terrain = @(
          @{ x=0; y=560; width=380; height=176 },
          @{ x=620; y=560; width=660; height=176 },
          @{ x=0; y=0; width=40; height=560 },
          @{ x=1240; y=0; width=40; height=560 },
          @{ x=380; y=640; width=240; height=96 }
        )
        $hazards += @{ type='waterHazard'; x=380; y=520; width=240; height=120 }
        $interactables += @{ type='waterVolume'; x=380; y=520; width=240; height=120 }
        $required = @('water'); $available = @('fire','water')
        $hint = 'Switch to Water before entering the flooded gap. Jump to swim upward.'
      }
      2 {
        $hazards += @{ type='fireHazard'; x=500; y=536; width=120; height=24 }
        $required = @('fire','water')
        $hint = 'Fire can cross the flame. Water is the safe choice for water hazards.'
      }
      3 {
        $interactables += @{ type='crate'; x=420; y=524; width=40; height=36 }
        $interactables += @{ type='earthSwitch'; x=760; y=544; width=48; height=16 }
        $required = @('earth'); $available = @('fire','earth')
        $hint = 'Use Earth to push the stone crate onto the pressure switch.'
      }
      4 {
        $terrain = @(
          @{ x=0; y=560; width=420; height=176 },
          @{ x=780; y=560; width=500; height=176 },
          @{ x=0; y=0; width=40; height=560 },
          @{ x=1240; y=0; width=40; height=560 }
        )
        $interactables += @{ type='woodAnchor'; x=420; y=520; width=360; height=24; durationSeconds=10 }
        $required = @('wood'); $available = @('fire','wood')
        $hint = 'Stand near the seed anchor as Wood and tap ABILITY to grow a bridge.'
      }
    }
    $required = @($required | Select-Object -Unique)
    $content = [ordered]@{
      levelId=$id; world=$world; index=$index
      gridSize=@{ rows=23; cols=40; tileSize=32 }
      requiredElements=$required; availableElements=$available
      tutorialHint=$hint; parTimeMs=(60000 + ($world * 5000) + ($index * 1000))
      playerStart=@{ x=96; y=512 }; checkpoints=@()
      goal=@{ x=1160; y=488; width=64; height=72 }
      terrain=$terrain; hazards=$hazards; interactables=$interactables
      shards=@(@{ x=300; y=500 })
      stars=@(@{ x=250; y=532 }, @{ x=640; y=532 }, @{ x=1000; y=532 })
    }
    $json = $content | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath (Join-Path $levelsPath "$id.json") -Value $json -Encoding utf8
  }
}
