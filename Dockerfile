# Set the python version as a build-time argument
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Create a virtual environment
RUN python -m venv /opt/venv

# Set the virtual environment as the current location
ENV PATH=/opt/venv/bin:$PATH

# Upgrade pip
RUN pip install --upgrade pip

# Set Python-related environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install OS dependencies for our mini VM
RUN apt-get update && apt-get install -y \
    libpq-dev \  
    libjpeg-dev \ 
    libcairo2 \   
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /code

# Copy project files
COPY ./src /code
COPY requirements.txt /code/requirements.txt

# Install dependencies
RUN pip install -r requirements.txt

# Expose Django port
EXPOSE 8000

# Set Django environment variables
ARG DJANGO_SECRET_KEY
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

ARG DJANGO_DEBUG=0
ENV DJANGO_DEBUG=${DJANGO_DEBUG}

# Set the Django default project name
ARG PROJ_NAME="cfehome"

# Create a script to run migrations and start the server
RUN printf "#!/bin/bash\n" > ./entrypoint.sh && \
    printf "RUN_PORT=\"\${PORT:-8000}\"\n\n" >> ./entrypoint.sh && \
    printf "python manage.py migrate --no-input\n" >> ./entrypoint.sh && \
    printf "python manage.py collectstatic --noinput\n" >> ./entrypoint.sh && \
    printf "gunicorn ${PROJ_NAME}.wsgi:application --bind \"0.0.0.0:\$RUN_PORT\"\n" >> ./entrypoint.sh

# Make the script executable
RUN chmod +x entrypoint.sh

# Run the Django project when the container starts
CMD ["./entrypoint.sh"]
