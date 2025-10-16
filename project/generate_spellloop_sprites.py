import os, json, random
from diffusers import StableDiffusionPipeline
import torch

# === Configuración ===
OUTPUT_DIR = "assets/sprites"
MODEL = "stabilityai/sd-turbo"        # rápido y ligero
DEVICE = "cuda" if torch.cuda.is_available() else "directml"

os.makedirs(OUTPUT_DIR, exist_ok=True)

pipe = StableDiffusionPipeline.from_pretrained(MODEL, torch_dtype=torch.float16)
pipe = pipe.to(DEVICE)

# === Definición de enemigos por tramos ===
tiers = {
    "tier_1": ["Slime Arcano", "Murciélago Etéreo", "Esqueleto Aprendiz", "Gusano de Mana", "Duende Sombrío"],
    "tier_2": ["Guerrero Espectral", "Lobo de Cristal", "Gólem Rúnico", "Hechicero Desgastado", "Sombra Flotante"],
    "tier_3": ["Caballero del Vacío", "Serpiente de Fuego", "Elemental de Hielo", "Mago Abismal", "Corruptor Alado"],
    "tier_4": ["Titán Arcano", "Señor de las Llamas", "Reina del Hielo", "Archimago Perdido", "Dragón Etéreo"],
    "bosses": ["El Conjurador Primigenio", "El Corazón del Vacío", "El Guardián de Runas", "La Entidad Celeste"]
}

def generate_sprite(name, folder):
    prompt = f"funko pop style front-facing {name}, magical fantasy theme, cartoon shading, clean black outline, 64x64 px, transparent background"
    result = pipe(prompt, num_inference_steps=20, guidance_scale=2)
    image = result.images[0]
    filename = f"{name.lower().replace(' ', '_')}.png"
    save_path = os.path.join(OUTPUT_DIR, folder, filename)
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    image.save(save_path)
    return save_path

metadata = {}
for tier, enemies in tiers.items():
    print(f"=== Generando sprites para {tier} ===")
    tier_paths = []
    for e in enemies:
        path = generate_sprite(e, f"enemies/{tier}")
        tier_paths.append({"name": e, "path": path})
    metadata[tier] = tier_paths

# === Generar ítems básicos ===
item_prompts = {
    "xp_orbs/blue_orb": "small glowing blue orb, fantasy experience gem, funko pop style, transparent background",
    "xp_orbs/red_orb": "glowing red orb, magical energy gem, funko pop style, transparent background",
    "chests/chest_closed": "closed wooden chest with metal details, cartoon style",
    "chests/chest_open": "open wooden chest full of glowing mana gems, cartoon style"
}

for key, prompt in item_prompts.items():
    img = pipe(prompt, num_inference_steps=15, guidance_scale=2).images[0]
    path = os.path.join(OUTPUT_DIR, "items", f"{key}.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    metadata[key] = path

# === Guardar metadatos ===
with open(os.path.join(OUTPUT_DIR, "sprites_index.json"), "w", encoding="utf-8") as f:
    json.dump(metadata, f, indent=2, ensure_ascii=False)

print("\n✅ Sprites generados y listos en assets/sprites/")
