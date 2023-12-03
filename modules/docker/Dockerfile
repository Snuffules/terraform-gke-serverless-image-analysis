# Use the official MongoDB image
FROM mongo:7.0

# Expose the default MongoDB port
EXPOSE 27017

# Create a directory for the MongoDB keyfile
RUN mkdir /etc/mongo-keyfile && \
    chown mongodb:mongodb /etc/mongo-keyfile && \
    chmod 700 /etc/mongo-keyfile

# Copy the MongoDB keyfile and set the right permissions
COPY mongodb-keyfile /etc/mongo-keyfile
RUN chown mongodb:mongodb /etc/mongo-keyfile/mongodb-keyfile && \
    chmod 600 /etc/mongo-keyfile/mongodb-keyfile

# Set the MongoDB data directory as a volume
VOLUME ["/data/db"]

# Start the MongoDB daemon with the keyfile
CMD ["mongod", "--keyFile", "/etc/mongo-keyfile/mongodb-keyfile", "--replSet", "rs0"]
