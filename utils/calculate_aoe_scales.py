#!/usr/bin/env python3
"""
Calcular los sprite_scale correctos para que los AOE ocupen 90% del hitbox.
"""

import re

# Leer el archivo WeaponDatabase.gd
with open(r'C:\git\spellloop\project\scripts\data\WeaponDatabase.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Armas AOE y sus frame_size actuales
aoe_weapons = {
    'void_pulse': 184,
    'steam_cannon': 208,
    'rift_quake': 120,
    'void_storm': 184,
    'glacier': 176,
    'absolute_zero': 224,
    'volcano': 200,
    'dark_flame': 152,
    'seismic_bolt': 224,
    'gaia': 176,
    'decay': 208,
    'radiant_stone': 120,
}

print("="*70)
print("CÁLCULO DE SPRITE_SCALE PARA 90% DEL HITBOX")
print("="*70)
print(f"{'Arma':<16} {'area':<6} {'radius':<8} {'diameter':<10} {'frame_size':<12} {'scale_90%':<10}")
print("-"*70)

results = {}

for weapon, frame_size in aoe_weapons.items():
    # Buscar el bloque del arma
    pattern = rf'"id":\s*"{weapon}".*?"area":\s*([0-9.]+)'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        area = float(match.group(1))
        radius = area * 80
        diameter = radius * 2
        # Para que el sprite ocupe 90% del diámetro:
        # sprite_size_visual = diameter * 0.9
        # sprite_size_actual = frame_size * sprite_scale
        # frame_size * sprite_scale = diameter * 0.9
        # sprite_scale = (diameter * 0.9) / frame_size
        sprite_scale = round((diameter * 0.9) / frame_size, 2)
        print(f'{weapon:<16} {area:<6} {radius:<8.0f} {diameter:<10.0f} {frame_size:<12} {sprite_scale:<10}')
        results[weapon] = sprite_scale
    else:
        print(f'{weapon:<16} NO ENCONTRADO')

print("\n" + "="*70)
print("CÓDIGO PARA ProjectileVisualManager.gd")
print("="*70)
for weapon, scale in results.items():
    print(f'"{weapon}": sprite_scale={scale},')
