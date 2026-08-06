# ===== Build =====
# Imagem oficial com o SDK do Flutter. Pesada, mas só existe em tempo de build.
FROM ghcr.io/cirruslabs/flutter:3.44.8 AS build
WORKDIR /app

# Camada de dependências separada: muda pouco, então o cache aproveita.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# A configuração entra no build porque o Flutter web compila para JavaScript
# estático. Trocar de emissora é trocar estes valores e recompilar.
ARG API_URL=https://api.radioconnect.technowhub.ai/v1
ARG TENANT=bandfm
ARG STREAM_URL=

RUN flutter build web --release \
      --dart-define=API_URL=$API_URL \
      --dart-define=TENANT=$TENANT \
      --dart-define=STREAM_URL=$STREAM_URL

# ===== Runtime =====
# Só arquivos estáticos: nginx serve e acabou.
FROM nginx:1.27-alpine AS runtime
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
