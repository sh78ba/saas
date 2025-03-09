# Set the Python version as a build-time argument
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

# Install OS dependencies for AWS EC2
RUN apt-get update && apt-get install -y \
    libpq-dev \  
    libjpeg-dev \  
    libcairo2 \ 
    gcc \  
    && rm -rf /var/lib/apt/lists/*

# Create the project directory
RUN mkdir -p /code

# Set the working directory
WORKDIR /code

# Copy the requirements file
COPY requirements.txt /tmp/requirements.txt

# Copy the project source code
COPY ./src /code

# Install Python dependencies
RUN pip install -r /tmp/requirements.txt

# Set the Django project name
ARG PROJ_NAME="saas"

# Create a bash script to run the Django project
RUN printf "#!/bin/bash\n" > ./aws_runner.sh && \
    printf "RUN_PORT=\"\${PORT:-8000}\"\n\n" >> ./aws_runner.sh && \
    printf "python manage.py migrate --no-input\n" >> ./aws_runner.sh && \
    printf "gunicorn ${PROJ_NAME}.wsgi:application --bind \"0.0.0.0:\$RUN_PORT\"\n" >> ./aws_runner.sh

# Make the bash script executable
RUN chmod +x aws_runner.sh

# Clean up apt cache to reduce image size
RUN apt-get remove --purge -y \  
    && apt-get autoremove -y \  
    && apt-get clean \  
    && rm -rf /var/lib/apt/lists/*

# Run the Django project when the container starts
CMD ./aws_runner.sh
