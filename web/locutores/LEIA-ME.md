# Fotos dos locutores

As fotos ficam aqui e são servidas pelo nginx do app, no mesmo domínio:

    https://app.radioconnect.technowhub.ai/locutores/<arquivo>

O Studio carrega daqui também — imagem em `<img>` não sofre CORS.

## Como preparar o arquivo

- **Quadrada.** O avatar é um círculo; imagem retangular vai ser cortada de
  qualquer jeito, e é melhor decidir o corte aqui do que deixar para o `cover`.
- **Sem moldura.** Foto exportada do Instagram costuma vir com o anel colorido em
  volta — dentro do círculo do avatar ele vira um aro esquisito. Corte por dentro
  do anel.
- **Rosto centrado.** As duas telas recortam pelo centro do arquivo, sem
  deslocamento — quem decide o enquadramento é quem prepara a imagem. Centralize
  o rosto aqui e o círculo cai certo nos dois lugares.
- **512×512, WebP.** Chega para 60px em tela de alta densidade e pesa pouco —
  importa no Android antigo que a gente precisa atender.

Nomear em minúsculas, sem acento: `marcelo-cafe.webp`, `milena-barros.webp`.

## Como ligar ao locutor

    npm run foto -- "Marcelo Café" /locutores/marcelo-cafe.webp

(no radio-connect-core, com DATABASE_URL apontando para o banco)
