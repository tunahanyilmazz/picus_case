# Use an official Python runtime as a parent image
# Explicitly specify platform for compatibility with ECS Fargate (linux/amd64)
FROM --platform=linux/amd64 python:3.10-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the requirements file into the container
COPY requirements.txt ./

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Run the app.py when the container launches
# Use a production-ready WSGI server like Gunicorn for ECS deployment
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]