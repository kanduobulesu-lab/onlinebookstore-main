FROM tomcat:9.0-jdk17-temurin

COPY target/*.war /usr/local/tomcat/webapps/ROOT.war
