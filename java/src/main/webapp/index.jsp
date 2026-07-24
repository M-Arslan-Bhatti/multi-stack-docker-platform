<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Java / Tomcat Container</title>
    <style>
        body { font-family: Arial, sans-serif; background: #7c2d12; color: #fff; text-align: center; padding-top: 100px; }
        h1 { font-size: 3rem; }
        a { color: #fbbf24; }
    </style>
</head>
<body>
    <h1>Sample WAR on Tomcat 10.1</h1>
    <p>Served from a WAR file built with Maven and deployed on <code>tomcat:10.1-jdk17-temurin</code> (port 8080).</p>
    <p>Try the servlet endpoint: <a href="hello">/hello</a></p>
</body>
</html>
