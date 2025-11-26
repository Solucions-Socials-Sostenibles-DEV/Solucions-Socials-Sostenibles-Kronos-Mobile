#!/bin/bash

# Script para ejecutar todos los tests de SSS Kronos Mobile
# Uso: ./run_tests.sh [opción]

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 SSS Kronos Mobile - Test Runner${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Función para mostrar ayuda
show_help() {
    echo "Uso: ./run_tests.sh [opción]"
    echo ""
    echo "Opciones:"
    echo "  (ninguna)    Ejecutar todos los tests"
    echo "  -v           Ejecutar tests en modo verbose"
    echo "  -c           Ejecutar tests con reporte de cobertura"
    echo "  -w           Ejecutar tests en modo watch"
    echo "  -u           Ejecutar solo tests unitarios"
    echo "  -h           Mostrar esta ayuda"
    echo ""
}

# Procesar argumentos
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--verbose)
        echo -e "${YELLOW}📊 Ejecutando tests en modo verbose...${NC}\n"
        flutter test --reporter expanded
        ;;
    -c|--coverage)
        echo -e "${YELLOW}📈 Ejecutando tests con cobertura de código...${NC}\n"
        flutter test --coverage
        echo -e "\n${GREEN}✅ Reporte de cobertura generado en: coverage/lcov.info${NC}"
        echo -e "${BLUE}Para ver el reporte HTML:${NC}"
        echo -e "  genhtml coverage/lcov.info -o coverage/html"
        echo -e "  open coverage/html/index.html"
        ;;
    -w|--watch)
        echo -e "${YELLOW}👁️  Ejecutando tests en modo watch...${NC}"
        echo -e "${BLUE}Los tests se reejecutarán automáticamente al guardar cambios${NC}\n"
        flutter test --watch
        ;;
    -u|--unit)
        echo -e "${YELLOW}🔬 Ejecutando solo tests unitarios...${NC}\n"
        flutter test test/utils/
        flutter test test/config/
        ;;
    "")
        echo -e "${YELLOW}🚀 Ejecutando todos los tests...${NC}\n"
        flutter test
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: $1${NC}\n"
        show_help
        exit 1
        ;;
esac

# Verificar resultado
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ ¡Todos los tests pasaron exitosamente!${NC}"
    echo -e "${GREEN}🎉 La aplicación está lista para usar${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Algunos tests fallaron${NC}"
    echo -e "${YELLOW}Por favor, revisa los errores arriba${NC}"
    exit 1
fi

