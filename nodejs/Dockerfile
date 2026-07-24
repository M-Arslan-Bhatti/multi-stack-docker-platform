FROM node:20-slim

# Create a non-root user/group to run the app
RUN groupadd -r appgroup && useradd -r -g appgroup -m appuser

WORKDIR /app

# Install dependencies first so this layer is cached separately
# from application code changes
COPY package.json ./
RUN npm install --omit=dev

# Now copy application code
COPY server.js ./

# Ensure the non-root user owns the app directory
RUN chown -R appuser:appgroup /app

USER appuser

ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]
