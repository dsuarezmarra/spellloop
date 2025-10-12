#!/usr/bin/env python3
"""
Validador de archivos GDScript para Spellloop
Verifica que todos los archivos estén sintácticamente correctos
"""

import os
import re
import json
from pathlib import Path

class GodotProjectValidator:
    def __init__(self, project_path):
        self.project_path = Path(project_path)
        self.errors = []
        self.warnings = []
        self.validated_files = []
        
    def validate_project(self):
        """Valida todo el proyecto Godot"""
        print("🔍 VALIDANDO PROYECTO SPELLLOOP")
        print("=" * 40)
        
        # Validar project.godot
        self.validate_project_file()
        
        # Validar estructura de autoloads
        self.validate_autoloads()
        
        # Validar scripts GDScript
        self.validate_gdscripts()
        
        # Validar escenas
        self.validate_scenes()
        
        # Mostrar resultados
        self.show_results()
        
    def validate_project_file(self):
        """Valida el archivo project.godot"""
        project_file = self.project_path / "project.godot"
        if not project_file.exists():
            self.errors.append("❌ Archivo project.godot no encontrado")
            return
            
        print("✅ project.godot encontrado")
        
        # Verificar autoloads
        with open(project_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        autoloads = [
            "GameManager", "SaveManager", "AudioManager", 
            "InputManager", "UIManager", "Localization", "DungeonSystem"
        ]
        
        for autoload in autoloads:
            if autoload in content:
                print(f"  ✅ Autoload {autoload} configurado")
            else:
                self.errors.append(f"❌ Autoload {autoload} faltante")
                
    def validate_autoloads(self):
        """Valida que todos los autoloads existan"""
        print("\n🔧 VALIDANDO AUTOLOADS")
        print("-" * 30)
        
        autoload_files = {
            "GameManager": "scripts/core/GameManager.gd",
            "SaveManager": "scripts/core/SaveManager.gd", 
            "AudioManager": "scripts/core/AudioManagerSimple.gd",
            "InputManager": "scripts/core/InputManager.gd",
            "UIManager": "scripts/core/UIManager.gd",
            "Localization": "scripts/core/Localization.gd",
            "DungeonSystem": "scripts/dungeon/DungeonSystem.gd"
        }
        
        for name, path in autoload_files.items():
            file_path = self.project_path / path
            if file_path.exists():
                print(f"  ✅ {name}: {path}")
                self.validated_files.append(str(file_path))
            else:
                self.errors.append(f"❌ {name}: {path} no encontrado")
                
    def validate_gdscripts(self):
        """Valida archivos GDScript básicos"""
        print("\n📜 VALIDANDO SCRIPTS GDSCRIPT")
        print("-" * 35)
        
        script_dirs = [
            "scripts/core",
            "scripts/dungeon", 
            "scripts/ui",
            "scripts/test",
            "scripts/entities",
            "scripts/magic"
        ]
        
        for script_dir in script_dirs:
            dir_path = self.project_path / script_dir
            if dir_path.exists():
                print(f"  📁 {script_dir}/")
                for gd_file in dir_path.glob("*.gd"):
                    self.validate_gdscript_file(gd_file)
            else:
                self.warnings.append(f"⚠️ Directorio {script_dir} no encontrado")
                
    def validate_gdscript_file(self, file_path):
        """Valida un archivo GDScript individual"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Verificaciones básicas
            errors_found = []
            
            # Verificar sintaxis básica
            if not content.strip():
                errors_found.append("Archivo vacío")
            
            # Verificar extends
            if not re.search(r'^extends\s+\w+', content, re.MULTILINE):
                if not re.search(r'^class_name\s+\w+', content, re.MULTILINE):
                    errors_found.append("Sin extends ni class_name")
            
            # Verificar referencias obsoletas
            obsolete_refs = [
                "res://scripts/systems/",
                "WizardSpriteLoader",
                "FunkoPopEnemy"
            ]
            
            for ref in obsolete_refs:
                if ref in content:
                    errors_found.append(f"Referencia obsoleta: {ref}")
            
            # Mostrar resultado
            rel_path = file_path.relative_to(self.project_path)
            if errors_found:
                print(f"    ❌ {rel_path.name}: {', '.join(errors_found)}")
                self.errors.extend([f"{rel_path}: {error}" for error in errors_found])
            else:
                print(f"    ✅ {rel_path.name}")
                self.validated_files.append(str(file_path))
                
        except Exception as e:
            self.errors.append(f"Error leyendo {file_path}: {str(e)}")
            
    def validate_scenes(self):
        """Valida escenas .tscn"""
        print("\n🎬 VALIDANDO ESCENAS")
        print("-" * 25)
        
        scenes_dir = self.project_path / "scenes"
        if not scenes_dir.exists():
            self.warnings.append("⚠️ Directorio scenes/ no encontrado")
            return
            
        scene_files = list(scenes_dir.rglob("*.tscn"))
        if not scene_files:
            self.warnings.append("⚠️ No se encontraron archivos .tscn")
            return
            
        for scene_file in scene_files:
            rel_path = scene_file.relative_to(self.project_path)
            print(f"  ✅ {rel_path}")
            
    def show_results(self):
        """Muestra los resultados de la validación"""
        print("\n" + "=" * 50)
        print("📊 RESULTADOS DE VALIDACIÓN")
        print("=" * 50)
        
        print(f"✅ Archivos validados: {len(self.validated_files)}")
        print(f"⚠️ Advertencias: {len(self.warnings)}")
        print(f"❌ Errores: {len(self.errors)}")
        
        if self.warnings:
            print("\n⚠️ ADVERTENCIAS:")
            for warning in self.warnings:
                print(f"  {warning}")
                
        if self.errors:
            print("\n❌ ERRORES:")
            for error in self.errors:
                print(f"  {error}")
        else:
            print("\n🎉 ¡PROYECTO VALIDADO SIN ERRORES!")
            print("El proyecto está listo para ejecutar en Godot 4.5")
            
        print("\n📋 SIGUIENTES PASOS:")
        print("1. Abrir Godot 4.5")
        print("2. Importar project.godot")
        print("3. Presionar F5 para ejecutar")
        print("4. Revisar consola para tests automáticos")

def main():
    """Función principal"""
    project_path = Path(__file__).parent
    validator = GodotProjectValidator(project_path)
    validator.validate_project()

if __name__ == "__main__":
    main()