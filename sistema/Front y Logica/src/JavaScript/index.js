'use strict';

(function () {
    document.addEventListener('DOMContentLoaded', function () {
        const tabsBar = document.getElementById('contenedores-tabs-bar');
        const modalView = document.getElementById('categoria-modal-view');
        const modalTitle = document.getElementById('category-modal-title');
        const modalDesc = document.getElementById('category-modal-desc');
        const modalGrid = document.getElementById('category-modal-grid');
        const btnClose = document.getElementById('btn-close-category');
        const specialtiesGrid = document.getElementById('specialties-grid');
        const searchInput = document.querySelector('.barra_busqueda');

        let categoriasList = [];
        let productosList = [];
        let activeCategoriaKey = null;

        // Mapeo de iconos y descripciones profesionales para cada especialidad
        const categoryMeta = {
            'estetica': {
                icon: 'fa-wand-magic-sparkles',
                desc: 'Todo lo necesario para procedimientos estéticos: blanqueamiento, carillas, resinas y sistemas de fotocurado.'
            },
            'endodoncia': {
                icon: 'fa-tooth',
                desc: 'Instrumental especializado para tratamientos de conducto: limas, motores, localizadores de ápice y obturación.'
            },
            'periodoncia': {
                icon: 'fa-heart-pulse',
                desc: 'Herramientas para el tratamiento periodontal: curetas, sondas, scalers ultrasónicos y microcirugía.'
            },
            'pediatrico': {
                icon: 'fa-child',
                desc: 'Instrumental ergonómico y diseñado especialmente para la atención dental infantil y odontopediatría.'
            },
            'rehabilitacion': {
                icon: 'fa-arrows-rotate',
                desc: 'Equipos y componentes para prótesis dental, implantes, rehabilitación oral fija y removible.'
            },
            'laboratorio': {
                icon: 'fa-flask-vial',
                desc: 'Materiales y herramientas para confección, pulido, articulación y modelado de piezas dentales.'
            },
            'cirugia oral': {
                icon: 'fa-syringe',
                desc: 'Instrumental quirúrgico de máxima precisión: fórceps, elevadores, porta agujas y kits de osteotomía.'
            },
            'operatoria': {
                icon: 'fa-screwdriver-wrench',
                desc: 'Instrumental restaurador de vanguardia: espátulas, bruñidores, condensadores y matrices.'
            },
            'ortodoncia': {
                icon: 'fa-bezier-curve',
                desc: 'Pinzas de corte y conformado, arcos, bandas, brackets y accesorios para ortodoncia de precisión.'
            },
            'examen': {
                icon: 'fa-magnifying-glass',
                desc: 'Herramientas esenciales de diagnóstico: espejos, exploradores, sondas milimetradas y posicionadores.'
            }
        };

        const normalize = (str) => {
            if (!str) return '';
            return str.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim();
        };

        // Función para cerrar el panel desplegable
        function closeCategoriaModal() {
            if (modalView) modalView.classList.remove('active');
            document.querySelectorAll('.contenedor-tab').forEach(t => t.classList.remove('active'));
            activeCategoriaKey = null;
        }

        if (btnClose) {
            btnClose.addEventListener('click', closeCategoriaModal);
        }

        // Cerrar al hacer clic fuera del panel y de la barra de pestañas
        document.addEventListener('click', function (e) {
            if (modalView && modalView.classList.contains('active')) {
                if (!e.target.closest('.contenedor-content') && !e.target.closest('.contenedores-container') && !e.target.closest('.product-card')) {
                    closeCategoriaModal();
                }
            }
        });

        // Abrir panel desplegable para una categoría
        function openCategoria(catKey, catNombre) {
            if (!modalView || !modalGrid) return;

            const normKey = normalize(catKey);
            const meta = categoryMeta[normKey] || {
                icon: 'fa-tooth',
                desc: 'Instrumental y suministros odontológicos de alta calidad certificada.'
            };

            // Si ya está abierta la misma categoría, cerrarla
            if (activeCategoriaKey === normKey && modalView.classList.contains('active')) {
                closeCategoriaModal();
                return;
            }

            activeCategoriaKey = normKey;

            // Actualizar textos del header
            if (modalTitle) modalTitle.textContent = `Instrumental de ${catNombre}`;
            if (modalDesc) modalDesc.textContent = meta.desc;

            // Marcar pestaña activa
            document.querySelectorAll('.contenedor-tab').forEach(tab => {
                if (tab.getAttribute('data-contenedor') === normKey) {
                    tab.classList.add('active');
                } else {
                    tab.classList.remove('active');
                }
            });

            // Filtrar productos de esta categoría
            const productosFiltrados = productosList.filter(prod => {
                const pCat = normalize(prod.categoria);
                const pEspec = normalize(prod.especializacion);
                return pCat.includes(normKey) || pEspec.includes(normKey) || (normKey === 'estetica' && pCat.includes('general'));
            });

            // Renderizar productos o Empty State
            modalGrid.innerHTML = '';
            if (productosFiltrados.length > 0) {
                productosFiltrados.forEach(prod => {
                    modalGrid.appendChild(crearTarjetaProducto(prod));
                });
            } else {
                modalGrid.innerHTML = `
                    <div class="empty-category-state">
                        <div class="empty-category-icon">
                            <i class="fas fa-box-open"></i>
                        </div>
                        <p class="empty-category-text">No existen productos asociados a esta categoría aún</p>
                    </div>
                `;
            }

            modalView.classList.add('active');
            modalView.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }

        // Construir elemento visual de producto
        function crearTarjetaProducto(prod) {
            const card = document.createElement('div');
            card.className = 'image-item';

            const imgContainer = document.createElement('div');
            imgContainer.style.width = '100%';
            imgContainer.style.height = '190px';
            imgContainer.style.overflow = 'hidden';
            imgContainer.style.backgroundColor = '#f8fafc';
            imgContainer.style.display = 'flex';
            imgContainer.style.alignItems = 'center';
            imgContainer.style.justifyContent = 'center';
            imgContainer.style.position = 'relative';

            let imgSrc = prod.img_url;
            if (imgSrc && imgSrc.startsWith('../../')) {
                imgSrc = imgSrc.substring(6);
            } else if (imgSrc && imgSrc.startsWith('../')) {
                imgSrc = imgSrc.substring(3);
            }

            if (imgSrc) {
                const img = document.createElement('img');
                img.src = imgSrc;
                img.alt = prod.nombre;
                img.style.width = '100%';
                img.style.height = '100%';
                img.style.objectFit = 'contain';
                img.style.padding = '10px';

                img.onerror = function () {
                    const placeholder = document.createElement('div');
                    placeholder.className = 'image-placeholder';
                    placeholder.textContent = prod.nombre.substring(0, 3).toUpperCase();
                    if (this.parentNode) {
                        this.parentNode.replaceChild(placeholder, this);
                    }
                };
                imgContainer.appendChild(img);
            } else {
                const placeholder = document.createElement('div');
                placeholder.className = 'image-placeholder';
                placeholder.textContent = prod.nombre.substring(0, 3).toUpperCase();
                imgContainer.appendChild(placeholder);
            }

            // Badge "Nuevo" si corresponde
            if (prod.fec_insert) {
                const createdDate = new Date(prod.fec_insert + 'T00:00:00');
                const twoWeeksAgo = new Date();
                twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
                if (createdDate >= twoWeeksAgo) {
                    const badgeNew = document.createElement('span');
                    badgeNew.innerHTML = '✦ Nuevo';
                    badgeNew.style.cssText = 'position:absolute; top:10px; right:10px; background:linear-gradient(135deg,#087d4e,#00d2ff); color:white; padding:4px 10px; border-radius:12px; font-size:0.7rem; font-weight:bold; z-index:2; box-shadow:0 2px 8px rgba(8,125,78,0.3);';
                    imgContainer.appendChild(badgeNew);
                }
            }

            const titleDiv = document.createElement('div');
            titleDiv.className = 'image-title';
            titleDiv.textContent = prod.nombre;

            const descDiv = document.createElement('div');
            descDiv.className = 'image-description';
            descDiv.textContent = prod.descripcion || 'Instrumental odontológico de alta calidad.';

            card.appendChild(imgContainer);
            card.appendChild(titleDiv);
            card.appendChild(descDiv);

            card.addEventListener('click', function () {
                this.style.transform = 'scale(0.97)';
                setTimeout(() => {
                    this.style.transform = '';
                }, 150);
            });

            return card;
        }

        // Renderizar Pestañas Superiores en la barra de scroll
        function renderCategorias(categorias) {
            categoriasList = categorias;

            if (tabsBar) {
                tabsBar.innerHTML = '';
                categorias.forEach(cat => {
                    const normKey = normalize(cat.nom_espec);
                    const itemDiv = document.createElement('div');
                    itemDiv.className = 'contenedor-item';

                    const tabBtn = document.createElement('button');
                    tabBtn.className = 'contenedor-tab';
                    tabBtn.setAttribute('data-contenedor', normKey);
                    tabBtn.textContent = cat.nom_espec;

                    tabBtn.addEventListener('click', function (e) {
                        e.preventDefault();
                        openCategoria(normKey, cat.nom_espec);
                    });

                    itemDiv.appendChild(tabBtn);
                    tabsBar.appendChild(itemDiv);
                });
            }
        }

        // Navegación con flechas del carrusel de pestañas (Scroll fluido con animación e infinito)
        const navPrev = document.getElementById('tab-nav-prev');
        const navNext = document.getElementById('tab-nav-next');
        const stepScroll = 202; // Ancho pestaña (194px) + gap (8px)

        function smoothScroll(element, target, duration = 350) {
            const start = element.scrollLeft;
            const change = target - start;
            const startTime = performance.now();

            function animateScroll(currentTime) {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);
                // Función de aceleración suave (easeOutCubic)
                const ease = 1 - Math.pow(1 - progress, 3);
                element.scrollLeft = start + change * ease;

                if (progress < 1) {
                    requestAnimationFrame(animateScroll);
                }
            }
            requestAnimationFrame(animateScroll);
        }

        if (navPrev && tabsBar) {
            navPrev.addEventListener('click', () => {
                const maxScrollLeft = tabsBar.scrollWidth - tabsBar.clientWidth;
                if (tabsBar.scrollLeft <= 10) {
                    smoothScroll(tabsBar, maxScrollLeft, 400);
                } else {
                    smoothScroll(tabsBar, Math.max(0, tabsBar.scrollLeft - stepScroll), 300);
                }
            });
        }

        if (navNext && tabsBar) {
            navNext.addEventListener('click', () => {
                const maxScrollLeft = tabsBar.scrollWidth - tabsBar.clientWidth;
                if (tabsBar.scrollLeft >= maxScrollLeft - 10) {
                    smoothScroll(tabsBar, 0, 400);
                } else {
                    smoothScroll(tabsBar, Math.min(maxScrollLeft, tabsBar.scrollLeft + stepScroll), 300);
                }
            });
        }

        // Cargar Categorías desde API
        async function cargarCategorias() {
            try {
                const response = await fetch('./src/php/api_categorias.php');
                const result = await response.json();
                if (result.success && Array.isArray(result.data)) {
                    renderCategorias(result.data);
                } else {
                    console.error('Error en formato de categorías:', result);
                }
            } catch (err) {
                console.error('Error cargando categorías:', err);
            }
        }

        // Cargar Productos desde API
        async function cargarProductos(busqueda = '') {
            try {
                const url = `./src/php/api_productos.php?q=${encodeURIComponent(busqueda)}`;
                const response = await fetch(url);
                if (!response.ok) throw new Error(`HTTP ${response.status}`);

                productosList = await response.json();

                // Si hay una búsqueda activa, abrir el modal con los resultados
                if (busqueda.trim().length > 0) {
                    if (modalView && modalGrid) {
                        modalGrid.innerHTML = '';
                        if (modalTitle) modalTitle.textContent = `Resultados para "${busqueda}"`;
                        if (modalDesc) modalDesc.textContent = `${productosList.length} producto(s) encontrado(s)`;

                        if (productosList.length > 0) {
                            productosList.forEach(prod => {
                                modalGrid.appendChild(crearTarjetaProducto(prod));
                            });
                        } else {
                            modalGrid.innerHTML = `
                                <div class="empty-category-state">
                                    <div class="empty-category-icon"><i class="fas fa-search"></i></div>
                                    <p class="empty-category-text">No se encontraron productos para "${busqueda}"</p>
                                </div>
                            `;
                        }
                        modalView.classList.add('active');
                        modalView.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                    }
                }
            } catch (error) {
                console.error('Error cargando productos:', error);
            }
        }

        // Búsqueda
        if (searchInput) {
            searchInput.addEventListener('keypress', function (e) {
                if (e.key === 'Enter') {
                    cargarProductos(this.value);
                }
            });

            let debounceTimer;
            searchInput.addEventListener('input', function (e) {
                if (e.target.value.trim() === '') {
                    closeCategoriaModal();
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

        // Inicializar animaciones AOS
        if (typeof AOS !== 'undefined') {
            AOS.init({
                once: true,
                offset: 50,
            });
        }

        // Carga inicial de datos
        cargarCategorias().then(() => {
            cargarProductos();
        });
        initBestSellersCarousel();

    });
})();



// ========== CARRUSEL DE PRODUCTOS MÁS VENDIDOS ==========
async function initBestSellersCarousel() {
    const track = document.getElementById('best-sellers-track');

    if (!track) return;

    try {
        const response = await fetch('./src/php/api_top_vendidos.php');
        const result = await response.json();

        if (result.success && result.data.length > 0) {
            renderBestSellers(result.data, track);
            
            // Inicializar Swiper: solo activar loop si hay más elementos que slides visibles
            const totalSlides = result.data.length;
            new Swiper('.mySwiper', {
                slidesPerView: 1,
                spaceBetween: 20,
                loop: totalSlides > 3,
                autoplay: {
                    delay: 2500,
                    disableOnInteraction: false,
                },
                pagination: {
                    el: '.swiper-pagination',
                    clickable: true,
                },
                breakpoints: {
                    600: {
                        slidesPerView: Math.min(2, totalSlides),
                        spaceBetween: 20,
                    },
                    800: {
                        slidesPerView: Math.min(3, totalSlides),
                        spaceBetween: 20,
                    },
                    1024: {
                        slidesPerView: Math.min(3, totalSlides),
                        spaceBetween: 30,
                    },
                }
            });
        } else {
            track.innerHTML = '<div style="width:100%; text-align:center;"><p>No hay productos destacados en este momento.</p></div>';
        }
    } catch (error) {
        console.error('Error cargando carrusel detallado:', error);
        track.innerHTML = `<div style="width:100%; text-align:center; color:red; padding:20px;">
            <p>Error al cargar productos.</p>
            <p style="font-size:12px; font-family:monospace;">Detalle: ${error.message}</p>
        </div>`;
    }
}

function renderBestSellers(products, track) {
    track.innerHTML = '';

    products.forEach((product) => {
        // Fix path for index.html
        let imgSrc = product.img_url;
        if (imgSrc && imgSrc.startsWith('../../')) {
            imgSrc = imgSrc.substring(6);
        } else if (imgSrc && imgSrc.startsWith('../')) {
            imgSrc = imgSrc.substring(3);
        }
        if (!imgSrc) imgSrc = './images/placeholder.png';

        const categoriaText = product.categoria || 'Instrumental';

        // Crear Slide de Swiper
        const slide = document.createElement('div');
        slide.className = 'swiper-slide';
        
        slide.innerHTML = `
            <div class="carousel-slide-content">
                <div class="slide-img-container">
                    <img src="${imgSrc}" alt="${product.titulo}" onerror="this.src='./images/placeholder.png'">
                </div>
                <span class="slide-category">${categoriaText}</span>
                <h3 class="slide-title">${product.titulo}</h3>
            </div>
        `;
        track.appendChild(slide);
    });
}
