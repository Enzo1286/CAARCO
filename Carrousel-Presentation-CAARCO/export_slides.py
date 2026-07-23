from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1350
ROOT = Path(__file__).resolve().parent.parent
OUT = Path(__file__).resolve().parent / 'exports-4x5'
ASSETS = ROOT / 'App' / 'assets'
FONTS = ROOT / 'App' / 'node_modules' / '@expo-google-fonts'

FORET = '#1f3b2a'; BAMBOU = '#3d6b4a'; NERE = '#c89441'; MANIOC = '#fbf9f3'
BRUME = '#ece9e0'; CENDRE = '#6b6f68'; CHARBON = '#1d2420'; BAMBOU_SOFT = '#cfdbcf'

display = ImageFont.truetype(FONTS / 'marcellus' / 'Marcellus_400Regular.ttf', 88)
display_small = ImageFont.truetype(FONTS / 'marcellus' / 'Marcellus_400Regular.ttf', 30)
body = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_400Regular.ttf', 32)
body_small = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_400Regular.ttf', 23)
bold = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_700Bold.ttf', 24)
bold_card = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_700Bold.ttf', 27)
mono = ImageFont.truetype(FONTS / 'jetbrains-mono' / 'JetBrainsMono_400Regular.ttf', 26)

logo_light = Image.open(ASSETS / 'Logo CAARCO Light PNG.png').convert('RGBA')
logo_dark = Image.open(ASSETS / 'Logo CAARCO PNG.png').convert('RGBA')

def text(draw, xy, value, font, fill, anchor=None):
    draw.text(xy, value, font=font, fill=fill, anchor=anchor)

def lines(draw, x, y, values, font, fill, gap=94):
    for index, value in enumerate(values):
        text(draw, (x, y + index * gap), value, font, fill)

def put_logo(img, light=False):
    source = logo_light if light else logo_dark
    mark = source.resize((84, 84), Image.Resampling.LANCZOS)
    img.alpha_composite(mark, (92, 88))

def header(img, number, dark=False):
    draw = ImageDraw.Draw(img)
    put_logo(img, light=dark)
    text(draw, (988, 138), f'{number} / 04', mono, '#b4c4b9' if dark else CENDRE, anchor='ra')

def footer(draw, left, right, dark=False):
    fill = '#b4c4b9' if dark else CENDRE
    text(draw, (92, 1270), left, mono, fill)
    text(draw, (988, 1270), right, mono, fill, anchor='ra')

def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)

def icon(draw, kind, x, y, size=56, color=FORET, width=5):
    # Icônes linéaires simples et cohérentes (aucun emoji).
    s = size / 108
    def p(a, b): return (x + a * s, y + b * s)
    if kind == 'box':
        draw.line([p(8,26), p(54,5), p(100,26), p(100,78), p(54,99), p(8,78), p(8,26)], fill=color, width=width, joint='curve')
        draw.line([p(8,26), p(54,53), p(100,26)], fill=color, width=width, joint='curve')
        draw.line([p(54,53), p(54,99)], fill=color, width=width)
    elif kind == 'home':
        draw.line([p(8,50), p(54,11), p(100,50), p(100,98), p(8,98), p(8,50)], fill=color, width=width, joint='curve')
        draw.line([p(40,98), p(40,61), p(68,61), p(68,98)], fill=color, width=width)
    elif kind == 'shop':
        draw.rectangle([p(10,43), p(98,98)], outline=color, width=width)
        draw.line([p(5,43), p(15,12), p(93,12), p(103,43)], fill=color, width=width, joint='curve')
        draw.line([p(26,43), p(26,98)], fill=color, width=width)
        draw.line([p(76,43), p(76,98)], fill=color, width=width)
    elif kind == 'route':
        draw.ellipse([p(11,8), p(35,32)], outline=color, width=width)
        draw.ellipse([p(75,76), p(99,100)], outline=color, width=width)
        draw.line([p(30,28), p(40,38), p(34,56), p(46,72), p(70,72), p(82,62)], fill=color, width=width, joint='curve')
    elif kind == 'pin':
        draw.ellipse([p(20,5), p(88,73)], outline=color, width=width)
        draw.polygon([p(28,58), p(54,101), p(80,58)], outline=color)
        draw.ellipse([p(44,29), p(64,49)], outline=color, width=width)
    elif kind == 'check':
        draw.line([p(13,52), p(38,77), p(90,22)], fill=color, width=width, joint='curve')
    elif kind == 'truck':
        draw.rectangle([p(7,29), p(67,79)], outline=color, width=width)
        draw.line([p(67,45), p(86,45), p(100,63), p(100,79), p(67,79)], fill=color, width=width, joint='curve')
        draw.ellipse([p(18,74), p(38,94)], outline=color, width=width)
        draw.ellipse([p(73,74), p(93,94)], outline=color, width=width)

def slide1():
    img = Image.new('RGBA', (W, H), FORET)
    draw = ImageDraw.Draw(img)
    header(img, '01', True)
    draw.ellipse((660, 780, 1236, 1356), outline=(251,249,243,22), width=58)
    draw.ellipse((972, 902, 1068, 998), fill=NERE)
    # Mockup de l’application.
    rounded(draw, (636, 640, 970, 1224), 48, BRUME, MANIOC, 14)
    rounded(draw, (738, 640, 868, 662), 0, CHARBON)
    rounded(draw, (650, 690, 956, 935), 34, BAMBOU_SOFT)
    draw.line([(662, 820), (755, 770), (835, 830), (940, 754)], fill=MANIOC, width=18, joint='curve')
    draw.ellipse((737, 751, 787, 801), fill=NERE)
    draw.ellipse((754, 768, 770, 784), fill=MANIOC)
    text(draw, (670, 990), 'VOTRE COURSE', bold, BAMBOU)
    text(draw, (670, 1032), 'Où allons-nous ?', display_small, CHARBON)
    rounded(draw, (666, 1070, 940, 1128), 16, '#ffffff')
    draw.ellipse((690, 1095, 704, 1109), fill=NERE)
    text(draw, (724, 1087), 'Point de départ', body_small, CHARBON)
    rounded(draw, (666, 1142, 940, 1200), 16, '#ffffff')
    draw.ellipse((690, 1167, 704, 1181), fill=BAMBOU)
    text(draw, (724, 1159), 'Destination', body_small, CHARBON)
    text(draw, (92, 356), 'L’APPLICATION CAARCO', bold, NERE)
    lines(draw, 92, 470, ['Le transport', 'qui avance', 'avec vous.'], display, MANIOC)
    lines(draw, 92, 780, ['Pour déplacer un colis, des meubles', 'ou les livraisons de votre activité,', 'simplement.'], body, '#b4c4b9', 48)
    rounded(draw, (92, 954, 188, 964), 5, NERE)
    footer(draw, 'Glissez →', 'CAARCO · Cameroun', True)
    return img

def usage_card(draw, x, y, kind, values, cream=False):
    rounded(draw, (x, y, x+420, y+220), 24, BRUME if cream else '#ffffff')
    icon(draw, kind, x+30, y+28, 58)
    lines(draw, x+30, y+150, values, bold_card, FORET, 34)

def slide2():
    img = Image.new('RGBA', (W, H), MANIOC)
    draw = ImageDraw.Draw(img)
    header(img, '02')
    text(draw, (92, 314), 'UNE APP, QUATRE USAGES', bold, NERE)
    lines(draw, 92, 414, ['Tout ce que', 'vous transportez.'], display, CHARBON)
    lines(draw, 92, 617, ['Une solution claire pour les besoins du', 'quotidien et de votre activité.'], body, CENDRE, 48)
    usage_card(draw, 92, 730, 'box', ['Livraison', 'express'])
    usage_card(draw, 548, 730, 'home', ['Déménagement'], True)
    usage_card(draw, 92, 980, 'shop', ['Logistique', 'entreprises'], True)
    usage_card(draw, 548, 980, 'route', ['Transport', 'ponctuel'])
    footer(draw, 'CAARCO', 'Transporter l’essentiel')
    return img

def step(draw, number, y, kind, label):
    text(draw, (92, y+50), number, mono, NERE)
    rounded(draw, (188, y, 988, y+104), 18, '#ffffff', BRUME)
    icon(draw, kind, 218, y+26, 52)
    text(draw, (300, y+34), label, bold_card, CHARBON)

def slide3():
    img = Image.new('RGBA', (W, H), MANIOC)
    draw = ImageDraw.Draw(img)
    header(img, '03')
    text(draw, (92, 314), 'SIMPLE DE BOUT EN BOUT', bold, NERE)
    lines(draw, 92, 414, ['Votre course', 'en quatre temps.'], display, CHARBON)
    step(draw, '01', 650, 'pin', 'Indiquez le trajet')
    step(draw, '02', 794, 'check', 'Recevez une estimation')
    step(draw, '03', 938, 'truck', 'Un transporteur accepte')
    step(draw, '04', 1082, 'route', 'Suivez la livraison')
    footer(draw, 'CAARCO', 'Clair · direct · suivi')
    return img

def slide4():
    img = Image.new('RGBA', (W, H), FORET)
    draw = ImageDraw.Draw(img)
    header(img, '04', True)
    draw.ellipse((665, 785, 1195, 1315), fill=BAMBOU_SOFT)
    icon(draw, 'route', 795, 915, 166, FORET, 8)
    draw.ellipse((600, 720, 1260, 1380), outline=(251,249,243,20), width=52)
    text(draw, (92, 340), 'PRÊT À PARTIR ?', bold, NERE)
    lines(draw, 92, 448, ['Transportez mieux.', 'Dès aujourd’hui.'], display, MANIOC)
    lines(draw, 92, 672, ['CAARCO rapproche les personnes, les commerces', 'et les transporteurs au Cameroun.'], body, '#b4c4b9', 48)
    rounded(draw, (92, 840, 618, 932), 46, BAMBOU)
    icon(draw, 'truck', 122, 859, 42, '#ffffff', 4)
    text(draw, (188, 867), 'Téléchargez CAARCO', bold_card, '#ffffff')
    footer(draw, '@caarco.cm', 'À votre service', True)
    return img

OUT.mkdir(parents=True, exist_ok=True)
slides = [slide1(), slide2(), slide3(), slide4()]
for idx, image in enumerate(slides, start=1):
    image.convert('RGB').save(OUT / f'presentation-caarco-{idx:02d}-4x5.png', quality=95)

preview = Image.new('RGB', (1128, 398), MANIOC)
for idx, image in enumerate(slides):
    thumb = image.convert('RGB').resize((270, 338), Image.Resampling.LANCZOS)
    preview.paste(thumb, (18 + idx * 279, 30))
preview.save(OUT / 'apercu-carrousel.png', quality=95)
print(f'Export terminé : {OUT}')
