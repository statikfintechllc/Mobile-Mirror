#!/bin/bash
# start_mobile_mirror.sh - Start Mobile Mirror backend with proper conda environment

echo "🚀 Starting Mobile Mirror Backend..."

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR/.."

# Activate conda environment and start the server
/home/statiksmoke8/miniconda3/envs/Mob-Dev/bin/python -c "
import uvicorn
from mobilemirror.backend.app import app

print('✅ Mobile Mirror Backend Starting on http://0.0.0.0:8000')
print('📱 Ready for mobile connections!')

uvicorn.run(
    app, 
    host='0.0.0.0', 
    port=8000, 
    log_level='info',
    reload=False
)
"
