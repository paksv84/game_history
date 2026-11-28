// Поиск: ищет по подписи под картиной (автор и название), прячет остальные разделы
// и выделяет найденное цветом. Пустая строка возвращает всё как было.
const pole = document.getElementById('poisk');
const razdely = document.querySelectorAll('.razdel');

razdely.forEach(razdel => {
  const podpis = razdel.querySelector('figcaption');
  podpis.dataset.tekst = podpis.textContent;
});

pole.oninput = () => {
  const zapros = pole.value.trim().toLowerCase();
  razdely.forEach(razdel => {
    const podpis = razdel.querySelector('figcaption');
    const tekst = podpis.dataset.tekst;
    podpis.textContent = tekst;
    if (zapros === '') {
      razdel.style.display = '';
      return;
    }
    const maly = tekst.toLowerCase();
    if (maly.indexOf(zapros) === -1) {
      razdel.style.display = 'none';
      return;
    }
    razdel.style.display = '';
    // Собираем подпись заново: обычный текст, найденное — в <mark>
    podpis.textContent = '';
    let nachalo = 0;
    let nashli = maly.indexOf(zapros);
    while (nashli !== -1) {
      podpis.append(tekst.slice(nachalo, nashli));
      const metka = document.createElement('mark');
      metka.textContent = tekst.slice(nashli, nashli + zapros.length);
      podpis.append(metka);
      nachalo = nashli + zapros.length;
      nashli = maly.indexOf(zapros, nachalo);
    }
    podpis.append(tekst.slice(nachalo));
  });
};
