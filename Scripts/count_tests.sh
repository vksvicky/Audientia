#!/bin/bash
# Script to count all tests in the Audientia project

echo "=== Test Count Summary ==="
echo ""

# Count tests per target
METADATA_TESTS=$(grep -r "func test" Tests --include="*.swift" | grep -i "MetadataEngine" | wc -l | tr -d ' ')
AUDIO_TESTS=$(grep -r "func test" Tests --include="*.swift" | grep -i "AudioCore" | wc -l | tr -d ' ')
DATALAYER_TESTS=$(grep -r "func test" Tests --include="*.swift" | grep -i "DataLayer" | wc -l | tr -d ' ')
SHARED_TESTS=$(grep -r "func test" Tests --include="*.swift" | grep -i "Shared" | wc -l | tr -d ' ')
UI_TESTS=$(grep -r "func test" Tests --include="*.swift" | grep -i "UITests" | wc -l | tr -d ' ')

# Total count
TOTAL_TESTS=$(grep -r "func test" Tests --include="*.swift" | wc -l | tr -d ' ')

echo "MetadataEngineTests:    $METADATA_TESTS tests"
echo "AudioCoreTests:         $AUDIO_TESTS tests"
echo "DataLayerTests:         $DATALAYER_TESTS tests"
echo "SharedTests:            $SHARED_TESTS tests"
echo "UITests:                $UI_TESTS tests"
echo "────────────────────────────────────"
echo "TOTAL:                  $TOTAL_TESTS tests"
echo ""

# Count test files
TEST_FILES=$(find Tests -name "*Tests.swift" -o -name "*BDDTests.swift" -o -name "*BDDScenarios.swift" | wc -l | tr -d ' ')
echo "Test Files:             $TEST_FILES files"
echo ""

# Show breakdown by type
TDD_TESTS=$(find Tests -name "*Tests.swift" ! -name "*BDDTests.swift" -exec grep -h "func test" {} \; | wc -l | tr -d ' ')
BDD_TESTS=$(find Tests \( -name "*BDDTests.swift" -o -name "*BDDScenarios.swift" \) -exec grep -h "func test" {} \; | wc -l | tr -d ' ')

echo "Test Type Breakdown:"
echo "  TDD Tests:            $TDD_TESTS"
echo "  BDD Tests:            $BDD_TESTS"

