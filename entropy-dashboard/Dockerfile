# Use an official Node.js runtime as a parent image
FROM node:24

# Set the working directory in the container
WORKDIR /app

# Copy the package.json and package-lock.json to the container
COPY package*.json ./

# Install project dependencies
RUN npm install

# Create and set permissions for the vite cache directory
RUN mkdir -p /app/node_modules/.vite && \
    chown -R node:node /app/node_modules/.vite && \
    chmod -R 755 /app/node_modules/.vite

# Copy the rest of the application code to the container
COPY . .

# Command to run the application
CMD ["npm", "run", "dev", "--", "--host"]
