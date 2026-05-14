# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /apps

# Copy the current directory contents into the container at /apps

COPY . /apps

# Install any needed packages specified in requirements.txt
RUN pip install --upgrade pip
RUN pip --version >> test2.txt

# RUN pip install -r requirements.txt

# Command to run the application
CMD ["echo", "Hola Mundo"]
