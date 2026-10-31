// Паучок на главной: каждый забег по-новому.
// Случайный край экрана, рывки разной скорости, остановки, шаги назад и развороты.

const pauk = document.querySelector('.pauk');
const RAZMER = 36;   // размер паучка в пикселях
const OTSTUP = 6;    // насколько паучок отступает от края экрана

const pauza = (ms) => new Promise(gotovo => setTimeout(gotovo, ms));
const sluchaino = (ot, doo) => ot + Math.random() * (doo - ot);
const odinIz = (spisok) => spisok[Math.floor(Math.random() * spisok.length)];

// Где паучок сейчас и куда смотрит
let tekX = 0, tekY = 0, ugol = 0;

// Передвинуть паучка в точку (x, y) и повернуть на угол за ms миллисекунд
function postavit(x, y, novyUgol, ms) {
  pauk.style.transition = 'transform ' + ms + 'ms linear';
  pauk.style.transform = 'translate(' + x + 'px, ' + y + 'px) rotate(' + novyUgol + 'deg)';
  tekX = x; tekY = y; ugol = novyUgol;
  return pauza(ms);
}

async function zabeg() {
  const W = window.innerWidth;
  const H = window.innerHeight;

  // 1. Выбираем край и направление
  const kray = odinIz(['verh', 'niz', 'levo', 'pravo']);
  const vdolX = kray === 'verh' || kray === 'niz';   // бежит слева направо или сверху вниз
  const dlina = vdolX ? W : H;
  const znak = Math.random() < 0.5 ? 1 : -1;          // 1 — вперёд по оси, -1 — назад
  const start = znak > 0 ? -RAZMER - 14 : dlina + 10;
  const finish = znak > 0 ? dlina + 10 : -RAZMER - 14;

  // Где проходит край и в какую сторону от него «внутрь» экрана
  const kromka = { verh: OTSTUP, levo: OTSTUP, niz: H - RAZMER - OTSTUP, pravo: W - RAZMER - OTSTUP }[kray];
  const vnutr = kray === 'verh' || kray === 'levo' ? 1 : -1;
  const tochka = (s, sdvig) => vdolX ? [s, kromka + vnutr * sdvig] : [kromka + vnutr * sdvig, s];

  // Голова паучка на рисунке смотрит вверх, поэтому поворачиваем по направлению бега
  const ugolVpered = vdolX ? (znak > 0 ? 90 : -90) : (znak > 0 ? 180 : 0);

  // 2. Мгновенно ставим паучка за край экрана, откуда он выбежит
  let s = start;
  await postavit(...tochka(s, 0), ugolVpered, 0);
  await pauza(50);

  // 3. Бежим рывками, пока не убежим за противоположный край
  while (znak * (finish - s) > 0) {
    let shag = sluchaino(0.08, 0.3) * dlina;
    let ugolShaga = ugolVpered;

    // Иногда паучок сдаёт назад: пятится или разворачивается
    if (s !== start && Math.random() < 0.25) {
      shag = -sluchaino(0.03, 0.1) * dlina;
      if (Math.random() < 0.5) ugolShaga = ugolVpered + 180;
    }

    s += znak * shag;
    if (znak * (s - finish) > 0) s = finish;

    // Резкий разворот на месте
    if (ugolShaga !== ugol) await postavit(tekX, tekY, ugolShaga, 150);

    const skorost = sluchaino(120, 450);                // пикселей в секунду
    const ms = Math.abs(shag) / skorost * 1000;
    pauk.classList.add('idyot');
    await postavit(...tochka(s, sluchaino(0, 14)), ugolShaga, ms);
    pauk.classList.remove('idyot');

    // Иногда замирает
    if (Math.random() < 0.6) await pauza(sluchaino(200, 1200));
  }

  // 4. Прячется и через 3–8 секунд выбегает снова
  await pauza(sluchaino(3000, 8000));
  zabeg();
}

setTimeout(zabeg, 1500);
