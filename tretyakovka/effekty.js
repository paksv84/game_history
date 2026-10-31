// Общие эффекты для всех страниц сайта

// 1. Приближение картин: нажал на картину — она открывается крупно поверх страницы
const zoom = document.createElement('div');
zoom.className = 'zoom';
zoom.innerHTML = '<button class="zoom-zakryt" aria-label="Закрыть">×</button><img alt=""><p></p>';
document.body.appendChild(zoom);
const zoomKartina = zoom.querySelector('img');
const zoomPodpis = zoom.querySelector('p');

function otkrytKartinu(kartina) {
  zoomKartina.src = kartina.src;
  zoomKartina.alt = kartina.alt;
  // Подпись берём из figcaption, если она есть, иначе из alt
  const figure = kartina.closest('figure');
  zoomPodpis.textContent = figure ? figure.querySelector('figcaption').textContent : kartina.alt;
  zoom.classList.add('otkryto');
}

function zakrytKartinu() {
  zoom.classList.remove('otkryto');
}

document.querySelectorAll('main img').forEach(kartina => {
  kartina.onclick = () => otkrytKartinu(kartina);
});
// Щелчок по фону или по крестику закрывает, щелчок по самой картине — нет
zoom.onclick = (sobytie) => {
  if (sobytie.target !== zoomKartina) zakrytKartinu();
};
document.addEventListener('keydown', (sobytie) => {
  if (sobytie.key === 'Escape') zakrytKartinu();
});

// 2. Разделы появляются, выезжая снизу, когда до них долистали
const razdely = document.querySelectorAll('.razdel');
const nablyudatel = new IntersectionObserver((zapisi) => {
  zapisi.forEach(zapis => {
    if (zapis.isIntersecting) {
      zapis.target.classList.remove('skryt');
      nablyudatel.unobserve(zapis.target);
    }
  });
}, { threshold: 0.15 });

razdely.forEach(razdel => {
  razdel.classList.add('skryt');
  nablyudatel.observe(razdel);
});
