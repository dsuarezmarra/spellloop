#!/usr/bin/env python3
"""
🎨 BIOME TEXTURE RESAMPLER
Redimensiona automáticamente las texturas de biomas basándose en su nombre.

Reglas:
  - Texturas con "base" en el nombre → 1920x1080 PNG
  - Texturas con "decor" en el nombre → 256x256 PNG
  - Detecta automáticamente el tamaño actual
  - Reemplaza el archivo original manteniendo el nombre
  - Convierte a PNG si es necesario

Uso:
  python resample_biome_textures.py [ruta_biomes]
  
Ejemplo:
  python resample_biome_textures.py "C:/Users/dsuarez1/git/spellloop/project/assets/textures/biomes"
"""

import os
import sys
from pathlib import Path
from PIL import Image


class BiomeTextureResampler:
    """Redimensiona texturas de biomas automáticamente"""
    
    # Tamaños objetivo según tipo
    TEXTURE_SIZES = {
        "base": (1920, 1080),
        "decor": (256, 256)
    }
    
    # Formatos de imagen soportados
    SUPPORTED_FORMATS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff"}
    
    def __init__(self, biomes_path: str):
        """Inicializa el resampler"""
        self.biomes_path = Path(biomes_path)
        
        if not self.biomes_path.exists():
            raise FileNotFoundError(f"La carpeta no existe: {self.biomes_path}")
        
        self.processed_count = 0
        self.skipped_count = 0
        self.error_count = 0
        self.total_size_original = 0
        self.total_size_new = 0
    
    def get_texture_type(self, filename: str) -> str:
        """
        Detecta el tipo de textura por su nombre
        Retorna: "base", "decor", o None
        """
        lower_name = filename.lower()
        
        if "base" in lower_name:
            return "base"
        elif "decor" in lower_name:
            return "decor"
        
        return None
    
    def get_target_size(self, texture_type: str) -> tuple:
        """Obtiene el tamaño objetivo para el tipo de textura"""
        return self.TEXTURE_SIZES.get(texture_type)
    
    def process_image(self, image_path: Path) -> bool:
        """
        Procesa una imagen individual
        Retorna: True si se procesó exitosamente
        """
        try:
            # Obtener tipo de textura
            texture_type = self.get_texture_type(image_path.name)
            
            if texture_type is None:
                print(f"⏭️  OMITIDO: {image_path.name} (no es 'base' ni 'decor')")
                self.skipped_count += 1
                return False
            
            # Obtener tamaño objetivo
            target_size = self.get_target_size(texture_type)
            if not target_size:
                print(f"⚠️  ERROR: Tamaño desconocido para tipo '{texture_type}'")
                self.error_count += 1
                return False
            
            # Cargar imagen original
            print(f"\n📂 Procesando: {image_path.name}")
            original_image = Image.open(image_path)
            original_size = original_image.size
            original_format = original_image.format
            
            print(f"   📏 Tamaño original: {original_size[0]}x{original_size[1]} ({original_format})")
            print(f"   🎯 Tipo detectado: {texture_type.upper()}")
            print(f"   📐 Tamaño objetivo: {target_size[0]}x{target_size[1]} (PNG)")
            
            # Si ya tiene el tamaño correcto, solo convertir a PNG si es necesario
            if original_size == target_size and original_format == "PNG":
                print(f"   ✅ Ya está en formato y tamaño correcto")
                self.skipped_count += 1
                return False
            
            # Resamplear la imagen
            resized_image = original_image.resize(target_size, Image.Resampling.LANCZOS)
            
            # Crear ruta de salida (siempre como PNG)
            output_path = image_path.with_suffix(".png")
            
            # Guardar como PNG
            resized_image.save(output_path, "PNG", quality=95)
            
            # Obtener información de archivos
            original_size_bytes = image_path.stat().st_size
            new_size_bytes = output_path.stat().st_size
            
            self.total_size_original += original_size_bytes
            self.total_size_new += new_size_bytes
            
            # Si la ruta es diferente (conversión de formato), eliminar original
            if output_path != image_path and image_path.exists():
                image_path.unlink()
                print(f"   🗑️  Eliminado archivo original (.{image_path.suffix})")
            
            print(f"   ✅ Guardado como PNG")
            print(f"   💾 Tamaño: {original_size_bytes:,} bytes → {new_size_bytes:,} bytes")
            
            self.processed_count += 1
            return True
            
        except Exception as e:
            print(f"   ❌ ERROR: {str(e)}")
            self.error_count += 1
            return False
    
    def run(self):
        """Ejecuta el resampling para todas las texturas"""
        print("\n" + "="*70)
        print("🎨 RESAMPLER DE TEXTURAS DE BIOMAS")
        print("="*70)
        print(f"\n📁 Carpeta: {self.biomes_path}\n")
        
        # Buscar todas las imágenes en subcarpetas
        image_files = []
        for biome_folder in sorted(self.biomes_path.iterdir()):
            if biome_folder.is_dir():
                for image_file in sorted(biome_folder.glob("*")):
                    if image_file.is_file() and image_file.suffix.lower() in self.SUPPORTED_FORMATS:
                        image_files.append(image_file)
        
        if not image_files:
            print("⚠️  No se encontraron imágenes para procesar")
            return
        
        print(f"🔍 Encontradas {len(image_files)} imágenes\n")
        
        # Procesar cada imagen
        for image_path in image_files:
            self.process_image(image_path)
        
        # Resumen final
        self.print_summary()
    
    def print_summary(self):
        """Imprime un resumen del procesamiento"""
        print("\n" + "="*70)
        print("📊 RESUMEN")
        print("="*70)
        print(f"✅ Procesadas: {self.processed_count} imágenes")
        print(f"⏭️  Omitidas: {self.skipped_count} imágenes")
        print(f"❌ Errores: {self.error_count} imágenes")
        
        if self.total_size_original > 0:
            reduction = ((self.total_size_original - self.total_size_new) / self.total_size_original) * 100
            print(f"\n💾 Tamaño original: {self.format_bytes(self.total_size_original)}")
            print(f"💾 Tamaño nuevo: {self.format_bytes(self.total_size_new)}")
            print(f"📉 Reducción: {reduction:.1f}%")
        
        print("="*70 + "\n")
    
    @staticmethod
    def format_bytes(bytes_size: int) -> str:
        """Convierte bytes a formato legible"""
        for unit in ["B", "KB", "MB", "GB"]:
            if bytes_size < 1024.0:
                return f"{bytes_size:.2f} {unit}"
            bytes_size /= 1024.0
        return f"{bytes_size:.2f} TB"


def main():
    """Función principal"""
    # Detectar ruta
    if len(sys.argv) > 1:
        biomes_path = sys.argv[1]
    else:
        # Ruta por defecto
        default_path = r"C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"
        print(f"ℹ️  Usando ruta por defecto: {default_path}")
        biomes_path = default_path
    
    try:
        resampler = BiomeTextureResampler(biomes_path)
        resampler.run()
        print("✨ ¡Proceso completado exitosamente!")
    
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
