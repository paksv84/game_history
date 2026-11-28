// Кнопка «Engl»: переводит на английский только заголовки и меню («← К свиткам»).
// Основной текст остаётся русским. Выбранный язык запоминается между страницами.
const slovar = {
  'Тайны Третьяковской галереи': 'Secrets of the Tretyakov Gallery',
  'Технология рисования': 'Painting Technique',
  'Особенности': 'Features',
  'Художники': 'Artists',
  '← К свиткам': '← Back to the scrolls',
  // Технология рисования
  'Гладкая академическая живопись': 'Smooth academic painting',
  'Этюды и эскизы': 'Studies and sketches',
  'Пленэр — работа на улице': 'Plein air: painting outdoors',
  'Свет через контраст': 'Light through contrast',
  'Свет из окна и живой мазок': 'Window light and lively brushwork',
  'Мастихин и «мозаика»': 'The palette knife and the "mosaic"',
  // Особенности
  'Чьи это медведи?': 'Whose bears are these?',
  'Картина, которую запрещали': 'The painting that was banned',
  'Загадка «Неизвестной»': 'The riddle of "Unknown Woman"',
  'Ворона на снегу': 'The crow on the snow',
  'Двадцать два года работы': 'Twenty-two years of work',
  'Охотничьи байки': "Hunters' tall tales",
  '«Дурочка Алёнушка»': '"Foolish Alyonushka"',
  'Церковь, которая стоит до сих пор': 'The church that still stands',
  // Художники
  'Иван Шишкин': 'Ivan Shishkin',
  'Илья Репин': 'Ilya Repin',
  'Виктор Васнецов': 'Viktor Vasnetsov',
  'Василий Суриков': 'Vasily Surikov',
  'Исаак Левитан': 'Isaac Levitan',
  'Валентин Серов': 'Valentin Serov',
  'Иван Крамской': 'Ivan Kramskoy',
  'Михаил Врубель': 'Mikhail Vrubel'
};

const knopka = document.getElementById('yazyk');
// Что переводим: заголовки h1, h2 (у главной внутри h2 ссылка) и ссылка-меню
const uzly = [];
document.querySelectorAll('h1, h2, a.menu').forEach(el => {
  const uzel = el.querySelector('a') || el;
  uzel.dataset.ru = uzel.textContent.trim();
  uzly.push(uzel);
});

function pokazat(angl) {
  uzly.forEach(uzel => {
    const ru = uzel.dataset.ru;
    uzel.textContent = angl && slovar[ru] ? slovar[ru] : ru;
  });
  document.documentElement.lang = angl ? 'en' : 'ru';
  knopka.textContent = angl ? 'Рус' : 'Engl';
  localStorage.setItem('yazyk', angl ? 'en' : 'ru');
}

knopka.onclick = () => pokazat(localStorage.getItem('yazyk') !== 'en');
pokazat(localStorage.getItem('yazyk') === 'en');
