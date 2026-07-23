from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1080, 1350
ROOT = Path(__file__).resolve().parent.parent
OUT = Path(__file__).resolve().parent / 'exports-4x5'
ASSETS = ROOT / 'App' / 'assets'
FONTS = ROOT / 'App' / 'node_modules' / '@expo-google-fonts'

FORET = '#1f3b2a'; BAMBOU = '#3d6b4a'; NERE = '#c89441'; MANIOC = '#fbf9f3'
BRUME = '#ece9e0'; CENDRE = '#6b6f68'; CHARBON = '#1d2420'; FORET30 = '#b4c4b9'

display = ImageFont.truetype(FONTS / 'marcellus' / 'Marcellus_400Regular.ttf', 86)
display_lg = ImageFont.truetype(FONTS / 'marcellus' / 'Marcellus_400Regular.ttf', 96)
body = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_400Regular.ttf', 31)
body_sm = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_400Regular.ttf', 24)
bold = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_700Bold.ttf', 24)
mono = ImageFont.truetype(FONTS / 'jetbrains-mono' / 'JetBrainsMono_400Regular.ttf', 24)

sheet = Image.open(ASSETS / 'Kako_character_reference.jpeg').convert('RGB')
logo_light = Image.open(ASSETS / 'Logo CAARCO Light PNG.png').convert('RGBA')
logo_dark = Image.open(ASSETS / 'Logo CAARCO PNG.png').convert('RGBA')

def draw_text(d, xy, text, font, fill, anchor=None):
    d.text(xy, text, font=font, fill=fill, anchor=anchor)

def draw_lines(d, x, y, values, font, fill, gap):
    for i, line in enumerate(values): draw_text(d, (x, y + i * gap), line, font, fill)

def paste_logo(canvas, dark=False):
    logo = (logo_light if dark else logo_dark).resize((78, 78), Image.Resampling.LANCZOS)
    canvas.paste(logo, (92, 78), logo)

def header(canvas, number, dark=False):
    d = ImageDraw.Draw(canvas)
    paste_logo(canvas, dark)
    draw_text(d, (988, 124), f'{number} / 04', mono, FORET30 if dark else CENDRE, anchor='ra')

def footer(d, left, right, dark=False):
    fill = FORET30 if dark else CENDRE
    draw_text(d, (92, 1264), left, mono, fill)
    draw_text(d, (988, 1264), right, mono, fill, anchor='ra')

def rounded_mask(size, radius):
    mask = Image.new('L', size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius, fill=255)
    return mask

def crop_fit(box, size, radius=None):
    crop = sheet.crop(box)
    ratio = max(size[0] / crop.width, size[1] / crop.height)
    crop = crop.resize((int(crop.width * ratio), int(crop.height * ratio)), Image.Resampling.LANCZOS)
    x = (crop.width - size[0]) // 2; y = (crop.height - size[1]) // 2
    crop = crop.crop((x, y, x + size[0], y + size[1])).convert('RGBA')
    if radius:
        crop.putalpha(rounded_mask(size, radius))
    return crop

def photo(canvas, box, target, radius=28):
    item = crop_fit(box, target, radius)
    canvas.alpha_composite(item, (target[2], target[3]))

def badge(d, x, y, value, dark=False):
    color = '#284a36' if dark else '#ffffff'
    text_color = NERE if dark else FORET
    d.rounded_rectangle((x, y, x + 206, y + 54), radius=27, fill=color)
    draw_text(d, (x + 103, y + 16), value, bold, text_color, anchor='ma')

def slide1():
    canvas = Image.new('RGBA', (W, H), FORET); d = ImageDraw.Draw(canvas)
    header(canvas, '01', True)
    d.ellipse((605, 710, 1190, 1295), outline=(251,249,243,20), width=52)
    d.ellipse((987, 835, 1080, 928), fill=NERE)
    # Pose entière de Kako, troisième grande pose de la planche.
    item = crop_fit((885, 0, 1375, 1152), (462, 1120))
    canvas.alpha_composite(item, (620, 228))
    draw_text(d, (92, 298), 'LE VISAGE DE CAARCO', bold, NERE)
    draw_lines(d, 92, 406, ['Voici', 'Kako.'], display_lg, MANIOC, 101)
    draw_lines(d, 92, 630, ['Un repère chaleureux pour vous', 'accompagner à chaque étape.'], body, FORET30, 48)
    d.rounded_rectangle((92, 805, 364, 868), radius=32, fill=BAMBOU)
    draw_text(d, (228, 823), 'Bienvenue avec CAARCO', bold, '#ffffff', anchor='ma')
    footer(d, 'Glissez →', 'Votre guide CAARCO', True)
    return canvas

def slide2():
    canvas = Image.new('RGBA', (W, H), MANIOC); d = ImageDraw.Draw(canvas)
    header(canvas, '02')
    draw_text(d, (92, 300), 'PLUS QU’UN PERSONNAGE', bold, NERE)
    draw_lines(d, 92, 408, ['Kako vous', 'guide.'], display, CHARBON, 94)
    draw_lines(d, 92, 612, ['Elle rend chaque étape plus claire,', 'de votre demande à la livraison.'], body, CENDRE, 48)
    d.rounded_rectangle((92, 750, 978, 1128), radius=28, fill=BRUME)
    # Grand portrait de référence, cadré à droite pour préserver le regard.
    portrait = crop_fit((1380, 0, 2048, 1152), (372, 378), 28)
    canvas.alpha_composite(portrait, (606, 750))
    for n, (title, sub) in enumerate([('1', 'Un trajet'), ('2', 'Une estimation'), ('3', 'Un transporteur')]):
        x = 132 + n * 152
        d.ellipse((x, 790, x + 70, 860), fill=NERE)
        draw_text(d, (x + 35, 807), title, mono, MANIOC, anchor='ma')
        draw_text(d, (x, 895), sub, bold, FORET)
    d.rounded_rectangle((122, 962, 566, 1042), radius=18, fill='#ffffff')
    draw_text(d, (150, 981), 'Une expérience', body_sm, CENDRE)
    draw_text(d, (150, 1010), 'simple et rassurante.', bold, FORET)
    footer(d, 'CAARCO', 'Un pas à la fois')
    return canvas

def slide3():
    canvas = Image.new('RGBA', (W, H), MANIOC); d = ImageDraw.Draw(canvas)
    header(canvas, '03')
    draw_text(d, (92, 298), 'UNE ÉNERGIE QUI NOUS RESSEMBLE', bold, NERE)
    draw_lines(d, 92, 406, ['Claire.', 'Proche.', 'Fiable.'], display, CHARBON, 92)
    # Quatre détails de poses distinctes, directement issus de la référence.
    cells = [
        ((25, 10, 255, 590), (92, 730)),
        ((265, 10, 505, 590), (316, 730)),
        ((525, 10, 750, 590), (540, 730)),
        ((755, 10, 970, 590), (764, 730)),
    ]
    for src, pos in cells:
        card = crop_fit(src, (190, 330), 24)
        canvas.alpha_composite(card, pos)
    d.rounded_rectangle((92, 1105, 988, 1175), radius=35, fill=FORET)
    draw_text(d, (540, 1126), 'CAARCO, à vos côtés quand cela compte.', bold, MANIOC, anchor='ma')
    footer(d, 'Kako', 'L’esprit CAARCO')
    return canvas

def slide4():
    canvas = Image.new('RGBA', (W, H), FORET); d = ImageDraw.Draw(canvas)
    header(canvas, '04', True)
    d.ellipse((655, 715, 1215, 1275), fill=BAMBOU)
    # Pose debout tenant le téléphone : parfaite pour l'appel à l'action.
    item = crop_fit((36, 0, 270, 600), (438, 900), 28)
    canvas.alpha_composite(item, (600, 415))
    d.ellipse((652, 719, 1210, 1277), outline=(251,249,243,20), width=48)
    draw_text(d, (92, 330), 'ON AVANCE ENSEMBLE', bold, NERE)
    draw_lines(d, 92, 440, ['Transportez', 'ce qui compte.'], display, MANIOC, 96)
    draw_lines(d, 92, 675, ['Avec Kako et CAARCO, votre course', 'commence en toute confiance.'], body, FORET30, 48)
    d.rounded_rectangle((92, 855, 480, 944), radius=45, fill=BAMBOU)
    draw_text(d, (286, 880), 'Téléchargez CAARCO', bold, '#ffffff', anchor='ma')
    footer(d, '@caarco.cm', 'À votre service', True)
    return canvas

OUT.mkdir(parents=True, exist_ok=True)
slides = [slide1(), slide2(), slide3(), slide4()]
for index, image in enumerate(slides, start=1):
    image.convert('RGB').save(OUT / f'kako-caarco-{index:02d}-4x5.png', quality=96)

preview = Image.new('RGB', (1128, 398), MANIOC)
for index, image in enumerate(slides):
    preview.paste(image.convert('RGB').resize((270, 338), Image.Resampling.LANCZOS), (18 + index * 279, 30))
preview.save(OUT / 'apercu-kako.png', quality=96)
print(f'Export terminé : {OUT}')
