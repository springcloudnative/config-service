FROM adoptopenjdk/openjdk11:latest AS builder

# Changes the current working directory to "workspace".
WORKDIR workspace

# Build argument specifying the location of the application JAR file in the project
ARG JAR_FILE=target/*-SNAPSHOT.jar

# Copy the application JAR file from the local machine into the image
COPY ${JAR_FILE} config-service.jar

# Extracts the layers from the archive applying the layered-JAR mode.
RUN java -Djarmode=layertools -jar config-service.jar extract

# OpenJDK base image for the second stage.
FROM adoptopenjdk/openjdk11:latest
RUN useradd spring

# Creates a "spring" user.
USER spring

# Configures "spring" as the current user.
WORKDIR workspace

# Copies each JAR layer from the first build to the second build inside the "workspace" folder.
COPY --from=builder workspace/dependencies/ ./
COPY --from=builder workspace/spring-boot-loader/ ./
COPY --from=builder workspace/snapshot-dependencies/ ./
COPY --from=builder workspace/application/ ./

# Uses the Spring Boot Launcher to start the application from the layers rather than an uber-JAR.
CMD [ "sh", "-c", "java org.springframework.boot.loader.JarLauncher" ]