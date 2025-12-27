#!/usr/bin/env bash
#
# Run CrucibleTrain examples
#
# Usage:
#   ./examples/run_all.sh        # Run local examples only
#   ./examples/run_all.sh --all  # Run all examples including cloud services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

run_example() {
    local name="$1"
    local file="$2"

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running: ${name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Use --no-start to avoid starting apps that require external services
    if mix run --no-start "examples/${file}"; then
        echo -e "\n${GREEN}✓ ${name} completed successfully${NC}"
        return 0
    else
        echo -e "\n${RED}✗ ${name} failed${NC}"
        return 1
    fi
}

# Local examples (no external services required)
LOCAL_EXAMPLES=(
    "JSON Logger|json_logger_example.exs"
    "PrettyPrint Logger|pretty_print_logger_example.exs"
    "Multiplex Logger|multiplex_logger_example.exs"
    "Scoring Functions|scoring_example.exs"
    "Batch Runner|batch_runner_example.exs"
    "LR Scheduling|lr_scheduling_example.exs"
)

# Cloud examples (require API keys)
CLOUD_EXAMPLES=(
    "W&B Logger|wandb_logger_example.exs"
    "Neptune Logger|neptune_logger_example.exs"
)

run_all=false
if [[ "$1" == "--all" ]]; then
    run_all=true
fi

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           CrucibleTrain Examples Runner                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

# Ensure dependencies are available
echo -e "\n${YELLOW}Checking dependencies...${NC}"
mix deps.get --check 2>/dev/null || mix deps.get

passed=0
failed=0
skipped=0

echo -e "\n${YELLOW}Running local examples...${NC}"

for example in "${LOCAL_EXAMPLES[@]}"; do
    IFS='|' read -r name file <<< "$example"
    if run_example "$name" "$file"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
done

if $run_all; then
    echo -e "\n${YELLOW}Running cloud service examples...${NC}"

    for example in "${CLOUD_EXAMPLES[@]}"; do
        IFS='|' read -r name file <<< "$example"
        if run_example "$name" "$file"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
    done
else
    echo -e "\n${YELLOW}Skipping cloud service examples (use --all to include)${NC}"

    for example in "${CLOUD_EXAMPLES[@]}"; do
        IFS='|' read -r name _ <<< "$example"
        echo -e "  ${YELLOW}○ ${name} (skipped)${NC}"
        skipped=$((skipped + 1))
    done

    echo -e "\n${YELLOW}To run cloud examples, set these environment variables:${NC}"
    echo "  W&B:     export WANDB_API_KEY=\"your-key\""
    echo "  Neptune: export NEPTUNE_API_TOKEN=\"your-token\""
    echo "           export NEPTUNE_PROJECT=\"workspace/project\""
fi

# Summary
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Passed:${NC}  $passed"
echo -e "  ${RED}Failed:${NC}  $failed"
echo -e "  ${YELLOW}Skipped:${NC} $skipped"

if [ $failed -gt 0 ]; then
    exit 1
fi
