'use strict';

(function () {
    document.addEventListener('DOMContentLoaded', function () {
        const contenedorTabs = document.querySelectorAll('.contenedor-tab');
        const contenedorContents = document.querySelectorAll('.contenedor-content');
        let activeContenedor = null;

        // Función para cerrar todas las pestañas
        function closeAllContenedores() {
            contenedorTabs.forEach(tab => tab.classList.remove('active'));
            contenedorContents.forEach(content => content.classList.remove('active'));
            activeContenedor = null;
        }

        // Manejo de clicks en pestañas
        contenedorTabs.forEach(tab => {
            tab.addEventListener('click', function (e) {
                e.preventDefault();
                const contenedorName = this.getAttribute('data-contenedor');
                if (!contenedorName) return;

                const contenedorContent = document.getElementById(`contenedor-${contenedorName}`);
                if (!contenedorContent) return;

                if (activeContenedor === contenedorContent && contenedorContent.classList.contains('active')) {
                    closeAllContenedores();
                    return;
                }

                closeAllContenedores();
                this.classList.add('active');
                contenedorContent.classList.add('active');
                activeContenedor = contenedorContent;
            });
        });

        // Cerrar al hacer click fuera
        document.addEventListener('click', function (e) {
            if (!e.target.closest('.contenedores-container')) {
                closeAllContenedores();
            }
        });

        // --- LÓGICA DE PRODUCTOS DINÁMICOS ---

        const searchInput = document.querySelector('.barra_busqueda');

        // Función para renderizar productos
        function renderProductos(productos, isSearch = false) {
            // Limpiar contenedores
            document.querySelectorAll('.images-grid').forEach(grid => grid.innerHTML = '');

            const normalize = (str) => {
                if (!str) return 'estetica';
                const s = str.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
                // Mapeo específico para Estética Dental -> estetica
                // Y mapeo de fallback para 'General'
                if (s === 'estetica dental' || s === 'general') return 'estetica';
                return s;
            };

            const resultadosPorCategoria = {};

            productos.forEach(prod => {
                const categoriaKey = normalize(prod.categoria);
                const contenedor = document.getElementById(`contenedor-${categoriaKey}`);

                if (contenedor) {
                    if (!resultadosPorCategoria[categoriaKey]) {
                        resultadosPorCategoria[categoriaKey] = 0;
                    }
                    resultadosPorCategoria[categoriaKey]++;

                    const grid = contenedor.querySelector('.images-grid');
                    if (grid) {
                        const card = document.createElement('div');
                        card.className = 'image-item';

                        // Contenedor de imagen
                        const imgContainer = document.createElement('div');
                        imgContainer.style.width = '100%';
                        imgContainer.style.height = '200px';
                        imgContainer.style.overflow = 'hidden';
                        imgContainer.style.backgroundColor = '#f0f0f0'; // Fondo gris suave por defecto
                        imgContainer.style.display = 'flex';
                        imgContainer.style.alignItems = 'center';
                        imgContainer.style.justifyContent = 'center';

                        if (prod.img_url) {
                            const img = document.createElement('img');
                            // Fix path for index.html (which is in /specialized/)
                            // DB stores '../images/...', but index.html needs './images/...'
                            let imgSrc = prod.img_url;
                            if (imgSrc && imgSrc.startsWith('../../')) {
                                imgSrc = imgSrc.substring(6); // Remove '../../' -> 'images/...'
                            } else if (imgSrc && imgSrc.startsWith('../')) {
                                imgSrc = imgSrc.substring(3); // Remove '../' -> 'images/...'
                            }
                            img.src = imgSrc;
                            img.alt = prod.nombre;
                            img.style.width = '100%';
                            img.style.height = '100%';
                            img.style.objectFit = 'cover';

                            // Manejo robusto de errores de imagen
                            img.onerror = function () {
                                // Si falla, reemplazar por placeholder
                                const placeholder = document.createElement('div');
                                placeholder.className = 'image-placeholder';
                                placeholder.style.width = '100%';
                                placeholder.style.height = '100%';
                                placeholder.style.display = 'flex';
                                placeholder.style.alignItems = 'center';
                                placeholder.style.justifyContent = 'center';
                                placeholder.style.backgroundColor = '#e9ecef';
                                placeholder.style.color = '#6c757d';
                                placeholder.style.fontWeight = 'bold';
                                placeholder.textContent = prod.nombre.substring(0, 3).toUpperCase();

                                // Reemplazar la imagen fallida en el DOM
                                if (this.parentNode) {
                                    this.parentNode.replaceChild(placeholder, this);
                                }
                            };

                            imgContainer.appendChild(img);
                        } else {
                            const placeholder = document.createElement('div');
                            placeholder.className = 'image-placeholder';
                            placeholder.style.width = '100%';
                            placeholder.style.height = '100%';
                            placeholder.textContent = prod.nombre.substring(0, 3).toUpperCase();
                            imgContainer.appendChild(placeholder);
                        }

                        const titleDiv = document.createElement('div');
                        titleDiv.className = 'image-title';
                        titleDiv.textContent = prod.nombre;

                        const descDiv = document.createElement('div');
                        descDiv.className = 'image-description';
                        descDiv.textContent = prod.descripcion || 'Producto de alta calidad';

                        card.appendChild(imgContainer);
                        card.appendChild(titleDiv);
                        card.appendChild(descDiv);

                        card.addEventListener('click', function () {
                            this.style.transform = 'scale(0.95)';
                            this.style.boxShadow = '0 2px 10px rgba(8, 125, 78, 0.3)';
                            setTimeout(() => {
                                this.style.transform = '';
                                this.style.boxShadow = '';
                            }, 150);
                            console.log('Producto seleccionado:', prod.nombre);
                        });

                        grid.appendChild(card);
                    }
                } else {
                    console.warn(`Advertencia: No existe contenedor para la categoría normalizada: "${categoriaKey}" (Original: "${prod.categoria}")`);
                }
            });

            // Si es una búsqueda activa, abrir la primera pestaña con resultados
            if (isSearch && productos.length > 0) {
                const categoriasConResultados = Object.keys(resultadosPorCategoria);
                if (categoriasConResultados.length > 0) {
                    const firstCategory = categoriasConResultados[0];
                    const tabToOpen = document.querySelector(`.contenedor-tab[data-contenedor="${firstCategory}"]`);
                    const contentToOpen = document.getElementById(`contenedor-${firstCategory}`);

                    if (tabToOpen && contentToOpen) {
                        closeAllContenedores(); // Cerrar otros
                        tabToOpen.classList.add('active');
                        contentToOpen.classList.add('active');
                        activeContenedor = contentToOpen;

                        // Scroll suave hacia los resultados si es necesario
                        contentToOpen.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                    }
                }
            } else if (isSearch && productos.length === 0) {
                console.log('No se encontraron productos.');
            }
        }

        // Función para cargar datos
        async function cargarProductos(busqueda = '') {
            try {
                const url = `./src/php/api_productos.php?q=${encodeURIComponent(busqueda)}`;
                const response = await fetch(url);
                if (!response.ok) {
                    const errorText = await response.text();
                    alert(`Error API (${response.status}): ${errorText}`); // DEBUG ALERT
                    throw new Error(`Error HTTP ${response.status}: ${errorText}`);
                }

                const productos = await response.json();
                // console.log('Productos recibidos:', productos); // DEBUG

                renderProductos(productos, busqueda.length > 0);
            } catch (error) {
                console.error('Error cargando productos:', error);
            }
        }

        // --- EVENT LISTENERS BÚSQUEDA ---

        const searchBtn = document.querySelector('.search-btn');

        if (searchInput) {
            // Evento al presionar Enter
            searchInput.addEventListener('keypress', function (e) {
                if (e.key === 'Enter') {
                    cargarProductos(this.value);
                }
            });

            // Evento debounce al escribir (opcional)
            let debounceTimer;
            searchInput.addEventListener('input', function (e) {
                // Si el input está vacío, cerrar pestañas inmediatamente
                if (e.target.value.trim() === '') {
                    closeAllContenedores();
                }

                clearTimeout(debounceTimer);
                debounceTimer = setTimeout(() => {
                    cargarProductos(e.target.value);
                }, 400);
            });

            searchInput.addEventListener('focus', function () {
                this.style.transform = 'scale(1.02)';
            });
            searchInput.addEventListener('blur', function () {
                this.style.transform = 'scale(1)';
            });
        }



        // Carga inicial
        cargarProductos();
        initBestSellersCarousel();

    });
})();



// ========== CARRUSEL DE PRODUCTOS MÁS VENDIDOS ==========
async function initBestSellersCarousel() {
    const track = document.getElementById('best-sellers-track');
    const dotsContainer = document.getElementById('carousel-dots');
    const prevBtn = document.querySelector('.carousel-btn.prev');
    const nextBtn = document.querySelector('.carousel-btn.next');

    if (!track) return;

    try {
        const response = await fetch('./src/php/api_top_vendidos.php');
        const result = await response.json();

        if (result.success && result.data.length > 0) {
            renderBestSellers(result.data, track, dotsContainer);
            setupCarouselBehavior(track, dotsContainer, prevBtn, nextBtn);
        } else {
            track.innerHTML = '<p>No hay productos destacados en este momento.</p>';
        }
    } catch (error) {
        console.error('Error cargando carrusel:', error);
        track.innerHTML = '<p>Error al cargar productos.</p>';
    }
}

function renderBestSellers(products, track, dotsContainer) {
    track.innerHTML = '';
    dotsContainer.innerHTML = '';

    products.forEach((product, index) => {
        // Fix path for index.html (DB stores '../images/...', but index.html needs './images/...')
        let imgSrc = product.img_url;
        if (imgSrc && imgSrc.startsWith('../../')) {
            imgSrc = imgSrc.substring(6);
        } else if (imgSrc && imgSrc.startsWith('../')) {
            imgSrc = imgSrc.substring(3);
        }
        if (!imgSrc) imgSrc = './images/placeholder.png';

        // Crear Slide
        const slide = document.createElement('li');
        slide.className = 'carousel-slide';
        slide.innerHTML = `
            <div class="slide-img-container">
                <img src="${imgSrc}" alt="${product.titulo}" onerror="this.src='./images/placeholder.png'">
            </div>
            <h3 class="slide-title">${product.titulo}</h3>
            <p class="slide-price">$${parseFloat(product.precio).toLocaleString('es-CO')}</p>
            <button class="slide-btn">Ver Detalle</button>
        `;
        track.appendChild(slide);

        // Crear Dot
        const dot = document.createElement('button');
        dot.className = `carousel-dot ${index === 0 ? 'active' : ''}`;
        dot.setAttribute('aria-label', `Ir al producto ${index + 1}`);
        dotsContainer.appendChild(dot);
    });
}

function setupCarouselBehavior(track, dotsContainer, prevBtn, nextBtn) {
    const slides = Array.from(track.children);
    const dots = Array.from(dotsContainer.children);
    let currentIndex = 0;

    const updateCarousel = (index) => {
        const slideWidth = slides[0].getBoundingClientRect().width;
        const gap = 30; // Coincide con el gap en CSS
        track.style.transform = `translateX(-${index * (slideWidth + gap)}px)`;
        
        // Actualizar dots
        dots.forEach(d => d.classList.remove('active'));
        dots[index].classList.add('active');
        currentIndex = index;
    };

    nextBtn.addEventListener('click', () => {
        const itemsVisible = window.innerWidth > 992 ? 3 : (window.innerWidth > 600 ? 2 : 1);
        const maxIndex = slides.length - itemsVisible;
        if (currentIndex < maxIndex) {
            updateCarousel(currentIndex + 1);
        } else {
            updateCarousel(0); // Reset
        }
    });

    prevBtn.addEventListener('click', () => {
        if (currentIndex > 0) {
            updateCarousel(currentIndex - 1);
        } else {
            const itemsVisible = window.innerWidth > 992 ? 3 : (window.innerWidth > 600 ? 2 : 1);
            updateCarousel(slides.length - itemsVisible); // Ir al final
        }
    });

    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => updateCarousel(index));
    });

    // Auto-play opcional
    setInterval(() => {
        const itemsVisible = window.innerWidth > 992 ? 3 : (window.innerWidth > 600 ? 2 : 1);
        const maxIndex = slides.length - itemsVisible;
        if (currentIndex < maxIndex) {
            updateCarousel(currentIndex + 1);
        } else {
            updateCarousel(0);
        }
    }, 5000);
}

// Inicializar al cargar el DOM
document.addEventListener('DOMContentLoaded', () => {
    // initBestSellersCarousel(); // Ya llamado arriba
});
