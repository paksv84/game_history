#!/usr/bin/env bash
# Проверка задания 4 — сайт о физике.
#
#     ./check.sh            проверяет папку fizika/
#     ./check.sh <папка>    проверяет другую папку. Так можно испортить копию
#                           сайта и убедиться, что проверка умеет быть красной.
#
# Проверяет ровно четыре предиката из zadanie-4.md — их строки «Уточнено:».
# На каждый предикат одна строка: ДА или НЕТ. Под строкой НЕТ — что именно не нашлось.
#
# ЧЕГО ЭТА ПРОВЕРКА НЕ УМЕЕТ. Она читает файлы, но не открывает браузер:
# не нажимает кнопки, не двигает ползунки, не видит анимацию и свечение.
# Такие части предикатов отмечены ниже словом ГЛАЗАМИ — их смотришь сам.
# Зелёная проверка значит «в файлах всё на месте», а не «на экране всё работает».
#
# Только bash и стандартные команды: grep, sed, awk.

set -uo pipefail

DIR=${1:-fizika}
PAGE="$DIR/index.html"
CSS="$DIR/style.css"
JS_VKLADKI="$DIR/vkladki.js"
JS_SIM="$DIR/simulyacii.js"
FAIL=0
PRICHINY=()

g() { printf '\033[32m%s\033[0m' "$1"; }
r() { printf '\033[31m%s\033[0m' "$1"; }

# Запомнить причину, по которой текущий предикат не выполнен.
net() { PRICHINY+=("$1"); }

# Итог предиката: ДА, если причин нет. Иначе НЕТ и под ним все причины.
itog() {
  if [ ${#PRICHINY[@]} -eq 0 ]; then
    printf '  [ %s ] %s\n' "$(g 'ДА ')" "$1"
  else
    printf '  [ %s ] %s\n' "$(r 'НЕТ')" "$1"
    for p in "${PRICHINY[@]}"; do printf '        -> %s\n' "$p"; done
    FAIL=$((FAIL + 1))
  fi
  PRICHINY=()
}

# Кусок страницы от строки с шаблоном $1 до строки с шаблоном $2.
# Саму строку $2 не берём: она уже начало следующего куска.
kusok() { sed -n "/$1/,/$2/p" "$PAGE" 2>/dev/null | sed '$d'; }

# Раздел страницы: от заголовка <h2>$1</h2> до конца его </section>.
razdel() { sed -n "/<h2>$1<\\/h2>/,/<\\/section>/p" "$PAGE" 2>/dev/null; }

# Правило из style.css: строки между «селектор {» и «}».
pravilo() { awk -v s="$1 {" 'index($0, s) == 1 { f = 1; next } f && /^}/ { f = 0 } f' "$CSS" 2>/dev/null; }

# Номер первой строки страницы с шаблоном (пусто, если такой нет).
stroka() { grep -n -m1 -e "$1" "$PAGE" 2>/dev/null | cut -d: -f1; }

# Сколько раз шаблон встречается в тексте, который пришёл на вход.
skolko() { grep -o -e "$1" | wc -l | tr -d ' '; }

# Цвет #rrggbb, #rgb или rgb(a)(r, g, b, ...) — в три числа «r g b» от 0 до 255.
rgb() {
  local c=$1
  case $c in
    \#???) printf '%d %d %d\n' "0x${c:1:1}${c:1:1}" "0x${c:2:1}${c:2:1}" "0x${c:3:1}${c:3:1}" ;;
    \#*)   printf '%d %d %d\n' "0x${c:1:2}" "0x${c:3:2}" "0x${c:5:2}" ;;
    *)     echo "$c" | grep -oE '[0-9]+' | head -3 | tr '\n' ' '; echo ;;
  esac
}

# Значение цвета-переменной из style.css, например: peremennaya fon → #05060d
peremennaya() { grep -oE -- "--$1: *#[0-9a-fA-F]{6}" "$CSS" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}' | head -1; }

FORMULY=$(kusok 'id="formuly"' 'id="simulyacii"')
SIMULYACII=$(kusok 'id="simulyacii"' 'class="tema niz"')

echo
echo "  Проверка задания 4: сайт о физике ($DIR/)"
echo "  ----------------------------------------------"

# ---------- Предикат 1 ----------
# Вверху страницы есть две вкладки «Формулы» и «Симуляции».
# Нажимаешь на вкладку — показывается её содержимое.
#
# ГЛАЗАМИ: само нажатие. Проверка видит, что кнопки стоят вверху, что у каждой
# есть своё содержимое и подключён скрипт, который обрабатывает нажатия.
# Нажать кнопку bash не может.

if [ ! -f "$PAGE" ]; then
  net "нет файла $PAGE"
else
  MAIN=$(stroka '<main')
  for para in 'formuly:Формулы' 'simulyacii:Симуляции'; do
    id=${para%%:*}
    nazvanie=${para#*:}
    KNOPKA=$(stroka "<button[^>]*data-vkladka=\"$id\"[^>]*>$nazvanie</button>")
    if [ -z "$KNOPKA" ]; then
      net "нет кнопки вкладки «$nazvanie» (<button data-vkladka=\"$id\">)"
    elif [ -n "$MAIN" ] && [ "$KNOPKA" -gt "$MAIN" ]; then
      net "кнопка «$nazvanie» стоит не вверху страницы, а внутри <main>"
    fi
    grep -q "class=\"vkladka[^\"]*\" id=\"$id\"" "$PAGE" ||
      net "нет содержимого вкладки «$nazvanie» (блок class=\"vkladka\" id=\"$id\")"
  done
  grep -q '<script src="vkladki.js">' "$PAGE" ||
    net "страница не подключает vkladki.js — нажатия на вкладки никто не обработает"
fi
if [ ! -f "$JS_VKLADKI" ]; then
  net "нет файла $JS_VKLADKI"
else
  grep -q "addEventListener('click'" "$JS_VKLADKI" ||
    net "в vkladki.js нет обработки нажатия (addEventListener('click'))"
  grep -q 'dataset.vkladka' "$JS_VKLADKI" ||
    net "vkladki.js не узнаёт по кнопке, какую вкладку показать (dataset.vkladka)"
fi
itog "Предикат 1: вверху две вкладки «Формулы» и «Симуляции», у каждой своё содержимое"

# ---------- Предикат 2 ----------
# Фон чёрный или почти чёрный, заголовки и рамки синие и неоново-фиолетовые
# со свечением. Других ярких цветов на странице нет.
#
# ГЛАЗАМИ: «выглядит ли футуристично» и заметно ли свечение на экране.
# Проверка смотрит только на числа цветов в файлах:
#   почти чёрный — красного, зелёного и синего не больше 32 из 255 каждого;
#   синий        — синего больше всех, красного меньше 128;
#   фиолетовый   — много синего и красного, зелёного меньше 128;
#   «чужой» яркий цвет — яркий (самая большая составляющая от 128) и насыщенный
#   (разница между самой большой и самой маленькой от 80), а синего в нём меньше,
#   чем красного или зелёного. Это красный, оранжевый, жёлтый или зелёный.

if [ ! -f "$CSS" ]; then
  net "нет файла $CSS"
else
  FON=$(peremennaya fon)
  SINIY=$(peremennaya siniy)
  FIOLET=$(peremennaya fiolet)

  if [ -z "$FON" ]; then
    net "в style.css нет цвета фона --fon"
  else
    read -r R G B <<< "$(rgb "$FON")"
    [ "$R" -le 32 ] && [ "$G" -le 32 ] && [ "$B" -le 32 ] ||
      net "фон --fon $FON не чёрный: каждая составляющая должна быть не больше 32"
  fi
  pravilo body | grep -q 'background: var(--fon)' ||
    net "у body фон не var(--fon)"

  if [ -z "$SINIY" ]; then
    net "в style.css нет синего цвета --siniy"
  else
    read -r R G B <<< "$(rgb "$SINIY")"
    [ "$B" -ge 192 ] && [ "$B" -gt "$G" ] && [ "$R" -lt 128 ] ||
      net "--siniy $SINIY не синий"
  fi

  if [ -z "$FIOLET" ]; then
    net "в style.css нет фиолетового цвета --fiolet"
  else
    read -r R G B <<< "$(rgb "$FIOLET")"
    [ "$B" -ge 192 ] && [ "$R" -ge 128 ] && [ "$G" -lt 128 ] ||
      net "--fiolet $FIOLET не фиолетовый"
  fi

  pravilo h1 | grep -q 'color: var(--siniy)' && pravilo h1 | grep -q 'text-shadow:.*var(--siniy)' ||
    net "главный заголовок h1 не синий со свечением (color и text-shadow с var(--siniy))"
  pravilo '.tema h2' | grep -q 'color: var(--fiolet)' && pravilo '.tema h2' | grep -q 'text-shadow:.*var(--fiolet)' ||
    net "заголовки тем h2 не фиолетовые со свечением (color и text-shadow с var(--fiolet))"
  pravilo '.tema' | grep -q 'border:.*var(--siniy)' && pravilo '.tema' | grep -q 'box-shadow' ||
    net "рамка карточки темы не синяя со свечением (border и box-shadow в .tema)"
fi

CHUZHIE=""
for f in "$PAGE" "$CSS" "$JS_SIM" "$JS_VKLADKI"; do
  [ -f "$f" ] || continue
  while read -r cvet; do
    [ -n "$cvet" ] || continue
    read -r R G B <<< "$(rgb "$cvet")"
    MAX=$(( R > G ? (R > B ? R : B) : (G > B ? G : B) ))
    MIN=$(( R < G ? (R < B ? R : B) : (G < B ? G : B) ))
    if [ "$MAX" -ge 128 ] && [ $((MAX - MIN)) -ge 80 ] && { [ "$B" -lt "$R" ] || [ "$B" -lt "$G" ]; }; then
      CHUZHIE="$CHUZHIE $cvet ($(basename "$f"))"
    fi
  done < <(grep -oE '#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b|rgba?\([0-9 ,.]+\)' "$f" | sort -u)
  # цвета, записанные словами: color: red, 'green' и т. п.
  for slovo in $(grep -oiE "(:[[:space:]]*|['\"])(red|green|yellow|orange|lime|pink|gold|brown|olive|teal)\b" "$f" |
                 grep -oiE '[a-z]+$' | sort -u); do
    CHUZHIE="$CHUZHIE $slovo ($(basename "$f"))"
  done
done
[ -z "$CHUZHIE" ] || net "есть другие яркие цвета:$CHUZHIE"

itog "Предикат 2: фон чёрный, заголовки и рамки синие и фиолетовые со свечением, чужих ярких цветов нет"

# ---------- Предикат 3 ----------
# Во вкладке «Симуляции» 6 симуляций: машина и трение, бросок под углом, маятник,
# сила Архимеда, подъёмная сила крыла, фотоэффект. В каждой есть ползунок, а рядом
# формула с текущими числами. Во вкладке «Формулы» 12–15 формул: механика,
# гидро- и аэродинамика, немного квантовой физики. У каждой формулы: что значит
# каждая буква, единицы измерения и короткий вывод.
#
# ГЛАЗАМИ: что объект на рисунке правда ведёт себя по-другому, когда двигаешь
# ползунок (например, машина останавливается раньше). Проверка видит, что ползунок
# и формула каждой симуляции упомянуты в simulyacii.js, но анимацию не видит.
# Правильность самой физики — тоже глазами: машина формулы не понимает.

N=$(echo "$SIMULYACII" | skolko 'class="simulyaciya"')
[ "$N" -eq 6 ] || net "во вкладке «Симуляции» $N симуляций, а нужно 6"

grep -q '<script src="simulyacii.js">' "$PAGE" 2>/dev/null ||
  net "страница не подключает simulyacii.js — симуляции не оживут"
[ -f "$JS_SIM" ] || net "нет файла $JS_SIM"

for imya in "Машина и трение" "Бросок под углом" "Маятник" "Сила Архимеда" "Подъёмная сила крыла" "Фотоэффект"; do
  BLOK=$(echo "$SIMULYACII" | awk -v RS='</article>' -v h="<h3>$imya</h3>" 'index($0, h)')
  if [ -z "$BLOK" ]; then
    net "нет симуляции «$imya»"
    continue
  fi
  echo "$BLOK" | grep -q '<canvas' || net "в симуляции «$imya» нет рисунка (<canvas>)"

  POLZUNKI=$(echo "$BLOK" | grep -oE 'type="range" id="[^"]+"' | cut -d'"' -f4)
  if [ -z "$POLZUNKI" ]; then
    net "в симуляции «$imya» нет ползунка"
  fi
  for pid in $POLZUNKI; do
    grep -q "'$pid'" "$JS_SIM" 2>/dev/null ||
      net "ползунок $pid в «$imya» не используется в simulyacii.js — двигать его бесполезно"
  done

  FID=$(echo "$BLOK" | grep -oE 'class="formula-zhivaya" id="[^"]+"' | cut -d'"' -f4)
  if [ -z "$FID" ]; then
    net "в симуляции «$imya» нет формулы с текущими числами (class=\"formula-zhivaya\")"
  elif ! grep -q "'$FID'" "$JS_SIM" 2>/dev/null; then
    net "формулу «$imya» ($FID) никто не пересчитывает в simulyacii.js"
  fi
done

N=$(echo "$FORMULY" | skolko 'class="formula"')
[ "$N" -ge 12 ] && [ "$N" -le 15 ] || net "во вкладке «Формулы» $N формул, а нужно от 12 до 15"

echo "$FORMULY" | grep -qE '<h2>[^<]*(Динамика|Механика)' || net "во вкладке «Формулы» нет темы про механику"
echo "$FORMULY" | grep -qE '<h2>[^<]*Гидро'                 || net "во вкладке «Формулы» нет темы про гидро- и аэродинамику"
echo "$FORMULY" | grep -qE '<h2>[^<]*Квантов'               || net "во вкладке «Формулы» нет темы про квантовую физику"

# Каждая формула: запись, список букв, единицы измерения в этом списке, вывод.
while IFS= read -r prichina; do
  [ -n "$prichina" ] && net "$prichina"
done < <(echo "$FORMULY" | awk '
  BEGIN { RS = "</article>" }
  index($0, "class=\"formula\"") {
    imya = $0; sub(/.*<h3>/, "", imya); sub(/<\/h3>.*/, "", imya)
    if (index($0, "class=\"zapis\"") == 0) print "у формулы «" imya "» нет записи самой формулы (class=\"zapis\")"
    if (index($0, "class=\"bukvy\"") == 0 || index($0, "<li>") == 0) {
      print "у формулы «" imya "» нет списка, что значит каждая буква"
    } else {
      bukvy = $0; sub(/.*class="bukvy">/, "", bukvy); sub(/<\/ul>.*/, "", bukvy)
      if (bukvy !~ /, (м|с|кг|Н|Дж|Па|Гц|эВ)( |<|\/|²|³)/) print "у формулы «" imya "» не указаны единицы измерения"
    }
    if (index($0, "class=\"vyvod\"><b>Вывод") == 0) print "у формулы «" imya "» нет вывода"
  }')

itog "Предикат 3: 6 симуляций с ползунком и живой формулой, 12–15 формул с буквами, единицами и выводом"

# ---------- Предикат 4 ----------
# При смене вкладки старое содержимое плавно (примерно за полсекунды) исчезает,
# а новое появляется. Каждая тема — карточка во всю ширину экрана с коротким
# описанием. Внизу страницы три раздела: «Что такое физика», «Люди физики»
# (минимум 5 учёных) и «Физика в кино» (минимум 3 фильма, среди них «Интерстеллар»
# и гравитационный манёвр).
#
# ГЛАЗАМИ: что смена правда выглядит плавной и карточки на экране широкие.
# Проверка складывает время из чисел в style.css и vkladki.js:
# старая вкладка исчезает за паузу из vkladki.js, новая проявляется за время
# transition из style.css. Вместе должно выйти от 0,3 до 0,7 секунды.
# Ширину проверка понимает так: ни у карточки темы, ни у страницы нет max-width.

PEREHOD=$(pravilo '.vkladka' | grep -oE 'transition:.*opacity [0-9.]+s' | grep -oE '[0-9.]+s$' | tr -d s)
PAUZA=$(grep -oE 'POLOVINA = [0-9]+' "$JS_VKLADKI" 2>/dev/null | grep -oE '[0-9]+$')
if [ -z "$PEREHOD" ]; then
  net "у .vkladka в style.css нет плавного перехода прозрачности (transition: opacity ...)"
elif [ -z "$PAUZA" ]; then
  net "в vkladki.js нет паузы перед показом новой вкладки (POLOVINA = ...)"
else
  VSEGO=$(awk -v p="$PEREHOD" -v z="$PAUZA" 'BEGIN { print int(p * 1000 + z) }')
  [ "$VSEGO" -ge 300 ] && [ "$VSEGO" -le 700 ] ||
    net "смена вкладки длится $VSEGO мс, а нужно примерно 500 (от 300 до 700)"
fi

VKLADKI="$FORMULY$SIMULYACII"
VSE_SEKCII=$(echo "$VKLADKI" | skolko '<section')
TEMY=$(echo "$VKLADKI" | skolko '<section class="tema">')
OPISANIYA=$(echo "$VKLADKI" | skolko 'class="tema-opisanie"')
[ "$TEMY" -gt 0 ] || net "во вкладках нет ни одной карточки темы (<section class=\"tema\">)"
[ "$TEMY" -eq "$VSE_SEKCII" ] || net "во вкладках $VSE_SEKCII разделов, а карточек тем из них только $TEMY"
[ "$OPISANIYA" -eq "$TEMY" ] || net "карточек тем $TEMY, а коротких описаний (class=\"tema-opisanie\") $OPISANIYA"
for sel in body main .tema; do
  pravilo "$sel" | grep -q 'max-width' && net "у $sel есть max-width — карточка темы не во всю ширину экрана"
done

POSLE_VKLADOK=$(stroka 'id="simulyacii"')
for zagolovok in "Что такое физика" "Люди физики" "Физика в кино"; do
  GDE=$(stroka "<h2>$zagolovok</h2>")
  if [ -z "$GDE" ]; then
    net "нет раздела «$zagolovok»"
  elif [ -n "$POSLE_VKLADOK" ] && [ "$GDE" -lt "$POSLE_VKLADOK" ]; then
    net "раздел «$zagolovok» стоит не внизу, а выше вкладок"
  fi
done

razdel "Что такое физика" | grep -q '<p>' || net "в разделе «Что такое физика» нет текста"

N=$(razdel "Люди физики" | skolko 'class="kartochka"')
[ "$N" -ge 5 ] || net "в разделе «Люди физики» $N учёных, а нужно минимум 5"

KINO=$(razdel "Физика в кино")
N=$(echo "$KINO" | skolko 'class="kartochka"')
[ "$N" -ge 3 ] || net "в разделе «Физика в кино» $N фильмов, а нужно минимум 3"
echo "$KINO" | grep -q 'Интерстеллар'  || net "в разделе «Физика в кино» нет «Интерстеллара»"
echo "$KINO" | grep -q 'гравитационн' || net "в разделе «Физика в кино» не объяснён гравитационный манёвр"

itog "Предикат 4: вкладки сменяются плавно (~0,5 с), темы — карточки во всю ширину, внизу три раздела"

echo "  ----------------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  printf '  %s\n\n' "$(g 'ЗЕЛЁНОЕ')"
else
  printf '  %s\n\n' "$(r 'КРАСНОЕ')"
fi

[ "$FAIL" -eq 0 ]
