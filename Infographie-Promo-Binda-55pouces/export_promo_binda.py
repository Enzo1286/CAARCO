from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1350
ROOT = Path(__file__).resolve().parent.parent
OUT = Path(__file__).resolve().parent
ASSETS = ROOT / 'App' / 'assets'
FONTS = ROOT / 'App' / 'node_modules' / '@expo-google-fonts'

FORET = '#1f3b2a'; BAMBOU = '#3d6b4a'; NERE = '#c89441'; MANIOC = '#fbf9f3'
BRUME = '#ece9e0'; CENDRE = '#6b6f68'; CHARBON = '#1d2420'; FORET30 = '#b4c4b9'

display = ImageFont.truetype(FONTS / 'marcellus' / 'Marcellus_400Regular.ttf', 78)
display_tv = ImageFont.truetype(FONTS / 'marcellus' / 'Marcellus_400Regular.ttf', 95)
body = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_400Regular.ttf', 27)
bold = ImageFont.truetype(FONTS / 'plus-jakarta-sans' / 'PlusJakartaSans_700Bold.ttf', 24)
mono = ImageFont.truetype(FONTS / 'jetbrains-mono' / 'JetBrainsMono_400Regular.ttf', 22)

sheet = Image.open(ASSETS / 'Kako_character_reference.jpeg').convert('RGB')
logo = Image.open(ASSETS / 'Logo CAARCO PNG.png').convert('RGBA')

def rounded_mask(size, radius):
    mask = Image.new('L', size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius, fill=255)
    return mask

def crop_fit(box, size, radius):
    source = sheet.crop(box)
    ratio = max(size[0] / source.width, size[1] / source.height)
    source = source.resize((round(source.width * ratio), round(source.height * ratio)), Image.Resampling.LANCZOS)
    left = (source.width - size[0]) // 2; top = 0
    source = source.crop((left, top, left + size[0], top + size[1])).convert('RGBA')
    source.putalpha(rounded_mask(size, radius))
    return source

canvas = Image.new('RGBA', (W, H), MANIOC)
d = ImageDraw.Draw(canvas)

# Fond et motifs de marque.
d.rounded_rectangle((0, 920, W, H), radius=0, fill=FORET)
d.ellipse((836, 930, 1320, 1414), outline=(255,255,255,24), width=48)
d.ellipse((920, 1030, 1014, 1124), fill=NERE)

# Logo officiel.
mark = logo.resize((84, 84), Image.Resampling.LANCZOS)
canvas.paste(mark, (82, 68), mark)
d.text((1000, 105), 'PROMO LANCEMENT', font=mono, fill=FORET, anchor='ra')
d.rounded_rectangle((82, 174, 382, 228), radius=27, fill='#f1e3c2')
d.text((232, 192), 'PREMIÈRE COURSE', font=bold, fill=FORET, anchor='ma')

# Message principal.
d.text((82, 305), 'Ta première course', font=display, fill=CHARBON)
d.text((82, 390), 'peut te faire gagner', font=display, fill=CHARBON)
d.text((82, 516), 'UN ÉCRAN', font=display_tv, fill=FORET)
d.text((82, 618), '55″ NEUF', font=display_tv, fill=NERE)
d.text((84, 727), 'Commande avec CAARCO. Tente ta chance.', font=body, fill=CENDRE)

# Téléviseur plat flambant neuf + emballage cadeau.
d.rounded_rectangle((82, 785, 566, 1065), radius=22, fill='#1b211e')
d.rounded_rectangle((98, 800, 550, 1028), radius=12, fill='#263e31')
d.rectangle((98, 987, 550, 1028), fill='#173323')
d.line((210, 1066, 240, 1095), fill='#1b211e', width=13)
d.line((440, 1066, 410, 1095), fill='#1b211e', width=13)
d.line((185, 1096, 465, 1096), fill='#1b211e', width=13)
d.rounded_rectangle((112, 818, 536, 970), radius=12, fill='#dbe8de')
d.ellipse((360, 842, 492, 954), fill='#cfe1d1')
d.line((128, 943, 302, 835, 382, 921, 510, 846), fill='#3d6b4a', width=13, joint='curve')
d.ellipse((420, 876, 446, 902), fill=NERE)
d.rounded_rectangle((480, 752, 591, 875), radius=16, fill=NERE)
d.rectangle((524, 752, 547, 875), fill='#f1e3c2')
d.rectangle((480, 800, 591, 824), fill='#f1e3c2')
d.text((324, 1039), 'ÉCRAN PLAT 55″ · NEUF', font=bold, fill=MANIOC, anchor='ma')

# Binda, à droite dans son cadrage officiel ; la planche reste intacte et lisible.
d.rounded_rectangle((630, 742, 1000, 1202), radius=28, fill=BRUME)
binda = crop_fit((990, 0, 1320, 1152), (370, 460), 28)
canvas.alpha_composite(binda, (630, 742))
d.rounded_rectangle((668, 1158, 962, 1210), radius=26, fill=BAMBOU)
d.text((815, 1174), 'BINDA VOUS ACCOMPAGNE', font=bold, fill=MANIOC, anchor='ma')

# CTA et mentions.
d.rounded_rectangle((82, 1148, 540, 1232), radius=42, fill=BAMBOU)
d.text((311, 1175), 'Je participe dans l’app', font=bold, fill=MANIOC, anchor='ma')
d.text((82, 1280), 'Jeu promotionnel soumis à conditions. Voir les modalités dans l’application.', font=mono, fill=FORET30)

OUT.mkdir(parents=True, exist_ok=True)
canvas.convert('RGB').save(OUT / 'promo-binda-ecran-55pouces-4x5.png', quality=96)
print(OUT / 'promo-binda-ecran-55pouces-4x5.png')
