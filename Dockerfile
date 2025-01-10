# Use an official Python lightweight image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install Poetry
RUN pip install poetry

# Copy project files
COPY ./pyproject.toml ./poetry.lock* /app/

# Install dependencies
RUN poetry install --no-dev --no-root

# Copy application code
COPY ./app /app/app

# Expose port 80 to the outside
EXPOSE 80

# Command to run the FastAPI app with Uvicorn
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]