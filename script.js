// Переключение страниц (SPA)
function showPage(pageId) {
  // Скрываем все страницы
  document.querySelectorAll('.page').forEach(page => {
    page.classList.remove('active');
  });

  // Показываем нужную
  const targetPage = document.getElementById(pageId);
  if (targetPage) {
    targetPage.classList.add('active');
  }

  // Обновляем активный пункт меню
  document.querySelectorAll('.nav-link').forEach(link => {
    link.classList.remove('active');
    if (link.getAttribute('data-page') === pageId) {
      link.classList.add('active');
    }
  });
}

document.addEventListener('DOMContentLoaded', function () {

  const bgContainer = document.getElementById('geometricBg');
  if (!bgContainer) {
    console.error('Элемент #geometricBg не найден!');
    return;
  }

  const totalShapes = 70;
  const colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#FFB3BA', '#9F86C0',
    '#A8E6CF', '#FFD3B6'
  ];
  const types = ['square', 'circle', 'triangle', 'diamond'];

  const shapes = [];

  // Создаем фигуры
  for (let i = 0; i < totalShapes; i++) {
    createFloatingShape();
  }

  function createFloatingShape() {
    const shape = document.createElement('div');
    shape.classList.add('shape');

    const type = types[Math.floor(Math.random() * types.length)];
    shape.classList.add(`shape-${type}`);

    const baseSize = 15 + Math.random() * 50;

    if (type === 'triangle') {
      const half = baseSize / 2;
      const height = baseSize * 0.866;
      const color = colors[Math.floor(Math.random() * colors.length)];
      shape.style.width = '0';
      shape.style.height = '0';
      shape.style.borderLeft = `${half}px solid transparent`;
      shape.style.borderRight = `${half}px solid transparent`;
      shape.style.borderBottom = `${height}px solid ${color}`;
      shape.dataset.rotation = 45;
    } else {
      const color = colors[Math.floor(Math.random() * colors.length)];
      shape.style.backgroundColor = color;
      shape.style.width = `${baseSize}px`;
      shape.style.height = `${baseSize}px`;
      shape.dataset.rotation = Math.random() * 360;
    }

    // ✅ Позиция в процентах — чтобы адаптировалось под размер экрана
    const startX = Math.random() * 100;
    const startY = Math.random() * 100;
    shape.style.left = `${startX}%`;
    shape.style.top = `${startY}%`;

    // ✅ Параметры НЕЗАВИСИМОЙ жизни каждой фигуры
    const floatX = (Math.random() - 0.5) * 3; // амплитуда плавания по X (в vw)
    const floatY = (Math.random() - 0.5) * 3; // амплитуда по Y (в vh)
    const speed = 0.8 + Math.random() * 1.2;  // скорость анимации (разная для каждой)
    const phaseX = Math.random() * Math.PI * 2; // начальная фаза по X
    const phaseY = Math.random() * Math.PI * 2; // начальная фаза по Y
    const rotateSpeed = 0.5 + Math.random() * 1; // скорость вращения

    // ✅ Сохраняем всё в dataset
    shape.dataset.floatX = floatX;
    shape.dataset.floatY = floatY;
    shape.dataset.speed = speed;
    shape.dataset.phaseX = phaseX;
    shape.dataset.phaseY = phaseY;
    shape.dataset.rotateSpeed = rotateSpeed;
    shape.dataset.startX = startX;
    shape.dataset.startY = startY;
    shape.dataset.rotation = parseFloat(shape.dataset.rotation);

    bgContainer.appendChild(shape);
    shapes.push(shape);
  }

  // Добавляем новые фигуры каждые 6 секунд
/*  setInterval(() => {
    for (let i = 0; i < 2; i++) {
      createFloatingShape();
    }
  }, 6000); */

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  // Управление мышью — НЕ ПОЗИЦИОНИРОВАНИЕ, а ВЛИЯНИЕ
  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  let mouseX = 50, mouseY = 50; // центр экрана в %
  let targetMouseX = 50, targetMouseY = 50;

  document.addEventListener('mousemove', (e) => {
    // Переводим позицию мыши в проценты
    targetMouseX = (e.clientX / window.innerWidth) * 100;
    targetMouseY = (e.clientY / window.innerHeight) * 100;
  });

  function updateMouse() {
    mouseX += (targetMouseX - mouseX) * 0.05;
    mouseY += (targetMouseY - mouseY) * 0.05;
    requestAnimationFrame(updateMouse);
  }
  requestAnimationFrame(updateMouse);

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  // Основной цикл анимации — КАЖДАЯ ФИГУРА ЖИВЁТ САМА
  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  function animate() {
    const time = Date.now() / 1000; // время в секундах

    shapes.forEach(shape => {
      const floatX = parseFloat(shape.dataset.floatX);
      const floatY = parseFloat(shape.dataset.floatY);
      const speed = parseFloat(shape.dataset.speed);
      const phaseX = parseFloat(shape.dataset.phaseX);
      const phaseY = parseFloat(shape.dataset.phaseY);
      const rotateSpeed = parseFloat(shape.dataset.rotateSpeed);
      const startX = parseFloat(shape.dataset.startX);
      const startY = parseFloat(shape.dataset.startY);
      let rotation = parseFloat(shape.dataset.rotation);

      // 1. Основное плавающее движение (независимая волна)
      const waveX = Math.sin(time * speed + phaseX) * floatX; // в vw
      const waveY = Math.cos(time * speed + phaseY) * floatY; // в vh

      // 2. Влияние мыши — чем ближе курсор, тем сильнее "поддувает" фигуру
      const shapeCenterX = startX + waveX;
      const shapeCenterY = startY + waveY;

      const diffX = mouseX - shapeCenterX;
      const diffY = mouseY - shapeCenterY;
      const distance = Math.sqrt(diffX * diffX + diffY * diffY);
      const maxDistance = 30; // зона влияния мыши (в %)

      let windX = 0, windY = 0;
      if (distance < maxDistance) {
        const force = (1 - distance / maxDistance) * 0.8; // сила ветра от мыши
        windX = (diffX / distance) * force * 0.1; // направление от мыши
        windY = (diffY / distance) * force * 0.1;
      }

      // 3. Итоговое смещение = плавание + лёгкий ветерок от мыши
      const finalX = waveX + windX;
      const finalY = waveY + windY;

      // 4. Вращение
      rotation += rotateSpeed * 0.01;
      shape.dataset.rotation = rotation;

      // ✅ Применяем ТОЛЬКО через transform — left/top остаются базовыми!
      shape.style.transform = `
        translate(${finalX}vw, ${finalY}vh)
        rotate(${rotation}deg)
      `;
    });

    requestAnimationFrame(animate);
  }

  animate(); // Запускаем анимацию

});