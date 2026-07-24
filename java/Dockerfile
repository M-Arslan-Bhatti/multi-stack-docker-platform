# ---- Build stage: compile the sample app into a WAR with Maven ----
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

# Copy pom.xml first so dependency resolution is cached separately
# from source code changes
COPY pom.xml ./
RUN mvn -q -B dependency:go-offline

COPY src ./src
RUN mvn -q -B clean package -DskipTests

# ---- Runtime stage: deploy the WAR on Tomcat ----
FROM tomcat:10.1-jdk17-temurin

# Remove default/sample Tomcat webapps to reduce image size and attack surface
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy as ROOT so the app is served at http://localhost:8080/
COPY --from=build /build/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

# No curl/wget in the base image; use bash's /dev/tcp to probe the port
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD bash -c 'exec 3<>/dev/tcp/localhost/8080' || exit 1

CMD ["catalina.sh", "run"]
