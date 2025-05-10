#!/bin/bash

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Initialize database
python -m app.db.init_db

# Run the application
python main.py
