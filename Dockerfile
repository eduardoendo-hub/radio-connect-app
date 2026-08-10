# ===== Build =====
# SDK do Flutter. Pesado, mas só existe em tempo de build — o runtime é nginx.
#
# Usamos `stable` porque a imagem não publica tag para a 3.44.8. O CI trava a versão
# exata na análise e nos testes, então uma divergência aqui aparece lá antes de chegar
# em produção. Quando a tag existir, vale fixar.
FROM ghcr.io/cirruslabs/flutter:stable AS build
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

# --pwa-strategy=none desliga o service worker.
#
# O service worker do Flutter cacheia tudo por conta própria e IGNORA os cabeçalhos
# do servidor: depois de uma visita, o app fica preso naquela versão mesmo com o
# nginx mandando no-store. Num produto que ainda muda todo dia, isso é veneno.
#
# Quando o app for para as lojas isso deixa de importar — lá quem versiona é a loja.
RUN flutter build web --release \
      --pwa-strategy=none \
      --dart-define=API_URL=$API_URL \
      --dart-define=TENANT=$TENANT \
      --dart-define=STREAM_URL=$STREAM_URL

# ===== Runtime =====
# Só arquivos estáticos: nginx serve e acabou.
FROM nginx:1.27-alpine AS runtime
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
