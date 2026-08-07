"""Prepara a foto de um locutor para o avatar circular.

Recebe centro e lado do recorte em pixels da imagem original, gera o WebP 512x512 e
uma prévia já mascarada em círculo — que é como a foto vai de fato aparecer. Conferir
na prévia, e não no quadrado, evita a surpresa de descobrir na tela que o círculo
cortou a testa.
"""
import sys
from PIL import Image, ImageDraw

origem, destino, cx, cy, lado = sys.argv[1], sys.argv[2], *map(int, sys.argv[3:6])
im = Image.open(origem).convert('RGB')
r = lado // 2

# Se o recorte passar da borda, empurra para dentro em vez de deixar faixa preta.
cx = max(r, min(cx, im.size[0] - r))
cy = max(r, min(cy, im.size[1] - r))

corte = im.crop((cx - r, cy - r, cx + r, cy + r)).resize((512, 512), Image.LANCZOS)
corte.save(destino, 'WEBP', quality=88, method=6)

mascara = Image.new('L', (512, 512), 0)
ImageDraw.Draw(mascara).ellipse((0, 0, 512, 512), fill=255)
previa = Image.new('RGB', (512, 512), (10, 10, 10))
previa.paste(corte, (0, 0), mascara)
previa.save(destino.replace('.webp', '-previa.png'))
print(f'{destino}  ({im.size[0]}x{im.size[1]} → recorte {lado}px em {cx},{cy})')
