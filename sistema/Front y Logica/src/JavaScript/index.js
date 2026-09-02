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

        let isClosingModal = false;

        let activeCategoriaIndex = -1;

        // Función para cerrar el panel desplegable con animación de salida suave
        function closeCategoriaModal(callback) {
            if (!modalView || !modalView.classList.contains('active') || isClosingModal) {
                document.querySelectorAll('.contenedor-tab').forEach(t => {
                    t.classList.remove('active', 'deactivating', 'from-left', 'from-right', 'to-right', 'to-left');
                });
                activeCategoriaKey = null;
                activeCategoriaIndex = -1;
                if (callback) callback();
                return;
            }

            isClosingModal = true;
            
            // Animación de descarga hacia la derecha por defecto
            document.querySelectorAll('.contenedor-tab.active').forEach(t => {
                t.classList.remove('active', 'from-left', 'from-right');
                t.classList.add('deactivating', 'to-right');
                setTimeout(() => t.classList.remove('deactivating', 'to-right', 'to-left'), 450);
            });
            activeCategoriaKey = null;
            activeCategoriaIndex = -1;

            modalView.classList.remove('active');
            modalView.classList.add('closing');

            setTimeout(() => {
                modalView.classList.remove('closing');
                isClosingModal = false;
                if (callback) callback();
            }, 280); // Duración de la animación de salida modalSlideUp
        }

        if (btnClose) {
            btnClose.addEventListener('click', () => closeCategoriaModal());
        }

        // Cerrar al hacer clic fuera del panel y de la barra de pestañas
        document.addEventListener('click', function (e) {
            if (modalView && modalView.classList.contains('active') && !isClosingModal) {
                if (!e.target.closest('.contenedor-content') && !e.target.closest('.contenedores-container') && !e.target.closest('.product-card')) {
                    closeCategoriaModal();
                }
            }
        });

        // Navegación y animación suave para el carrusel de pestañas
        function smoothScroll(element, target, duration = 350) {
            if (!element) return;
            const start = element.scrollLeft;
            const change = target - start;
            if (Math.abs(change) < 2) return;
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

        // Abrir panel desplegable para una categoría con dirección inteligente
        function openCategoria(catKey, catNombre) {
            if (!modalView || !modalGrid) return;

            const normKey = normalize(catKey);
            const meta = categoryMeta[normKey] || {
                icon: 'fa-tooth',
                desc: 'Instrumental y suministros odontológicos de alta calidad certificada.'
            };

            // Si ya está abierta la misma categoría, cerrarla y apagar el botón
            if (activeCategoriaKey === normKey && modalView.classList.contains('active')) {
                closeCategoriaModal();
                return;
            }

            const allTabs = Array.from(document.querySelectorAll('.contenedor-tab'));
            const newIndex = allTabs.findIndex(tab => tab.getAttribute('data-contenedor') === normKey);
            const prevIndex = activeCategoriaIndex;

            // Determinar si nos movemos hacia la derecha o hacia la izquierda
            const goingRight = prevIndex === -1 || newIndex >= prevIndex;

            activeCategoriaKey = normKey;
            activeCategoriaIndex = newIndex;

            // Actualizar textos del header
            if (modalTitle) modalTitle.textContent = `Instrumental de ${catNombre}`;
            if (modalDesc) modalDesc.textContent = meta.desc;

            // Marcar pestaña activa y desplazar con animación ultra suave
            allTabs.forEach(tab => {
                const tabKey = tab.getAttribute('data-contenedor');
                if (tabKey === normKey) {
                    tab.classList.remove('deactivating', 'to-right', 'to-left', 'from-left', 'from-right');
                    // Si nos movemos hacia la derecha -> carga de izquierda a derecha (from-left)
                    // Si nos movemos hacia la izquierda -> carga de derecha a izquierda (from-right)
                    tab.classList.add('active', goingRight ? 'from-left' : 'from-right');

                    // Centrar suavemente la pestaña seleccionada en el contenedor de scroll
                    if (tabsBar) {
                        const itemWrapper = tab.closest('.contenedor-item') || tab;
                        const itemOffset = itemWrapper.offsetLeft;
                        const itemWidth = itemWrapper.offsetWidth;
                        const barWidth = tabsBar.clientWidth;
                        const targetScroll = Math.max(0, itemOffset - (barWidth / 2) + (itemWidth / 2));
                        smoothScroll(tabsBar, targetScroll, 350);
                    }
                } else {
                    if (tab.classList.contains('active')) {
                        tab.classList.remove('active', 'from-left', 'from-right');
                        // La saliente se descarga hacia donde va el flujo (to-right si avanzamos, to-left si retrocedemos)
                        const exitClass = goingRight ? 'to-right' : 'to-left';
                        tab.classList.add('deactivating', exitClass);
                        setTimeout(() => tab.classList.remove('deactivating', 'to-right', 'to-left'), 450);
                    }
                }
            });

            // Filtrar productos de esta categoría usando el catálogo maestro
            const fuenteProductos = catalogoCompleto.length > 0 ? catalogoCompleto : productosList;
            const productosFiltrados = fuenteProductos.filter(prod => {
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

        let catalogoCompleto = [];

        // Función para filtrar productos por texto de forma 100% insensible a tildes y mayúsculas
        function filtrarProductosPorTexto(texto, lista) {
            const tNorm = normalize(texto);
            if (!tNorm) return lista;
            
            // Separar por palabras clave si el usuario escribe "kit cirugia"
            const terminos = tNorm.split(/\s+/).filter(Boolean);

            return lista.filter(prod => {
                const nombre = normalize(prod.nombre);
                const origen = normalize(prod.nombre_origen);
                const cat = normalize(prod.categoria);
                const espec = normalize(prod.especializacion);
                const tipo = normalize(prod.tipo);
                const textoTotal = `${nombre} ${origen} ${cat} ${espec} ${tipo}`;

                // Todas las palabras deben coincidir
                return terminos.every(term => textoTotal.includes(term));
            });
        }

        // Cargar Productos desde API y manejar búsqueda
        async function cargarProductos(busqueda = '') {
            try {
                // Si el catálogo maestro aún no está cargado, lo traemos
                if (catalogoCompleto.length === 0) {
                    const url = `./src/php/api_productos.php?q=`;
                    const response = await fetch(url);
                    if (!response.ok) throw new Error(`HTTP ${response.status}`);
                    const data = await response.json();
                    catalogoCompleto = Array.isArray(data) ? data : [];
                }

                const busqTrim = busqueda.trim();

                // Filtrar con normalización inteligente (tildes, mayúsculas, múltiples palabras)
                if (busqTrim.length > 0) {
                    productosList = filtrarProductosPorTexto(busqTrim, catalogoCompleto);

                    if (modalView && modalGrid) {
                        modalGrid.innerHTML = '';
                        if (modalTitle) modalTitle.textContent = `Resultados para "${busqTrim}"`;
                        if (modalDesc) modalDesc.textContent = `${productosList.length} producto(s) encontrado(s)`;

                        if (productosList.length > 0) {
                            productosList.forEach(prod => {
                                modalGrid.appendChild(crearTarjetaProducto(prod));
                            });
                        } else {
                            modalGrid.innerHTML = `
                                <div class="empty-category-state">
                                    <div class="empty-category-icon"><i class="fas fa-search"></i></div>
                                    <p class="empty-category-text">No se encontraron productos para "${busqTrim}"</p>
                                </div>
                            `;
                        }
                        modalView.classList.add('active');
                    }
                } else {
                    productosList = [...catalogoCompleto];
                }
            } catch (error) {
                console.error('Error cargando productos:', error);
            }
        }

        // Búsqueda y Botón de Limpiar
        const btnClearSearch = document.getElementById('btn-clear-search');

        function toggleClearButton() {
            if (btnClearSearch && searchInput) {
                if (searchInput.value.trim().length > 0) {
                    btnClearSearch.classList.add('visible');
                } else {
                    btnClearSearch.classList.remove('visible');
                }
            }
        }

        if (btnClearSearch && searchInput) {
            btnClearSearch.addEventListener('click', function () {
                searchInput.value = '';
                toggleClearButton();
                closeCategoriaModal();
                // Restaurar catálogo maestro
                productosList = [...catalogoCompleto];
                searchInput.focus();
            });
        }

        if (searchInput) {
            searchInput.addEventListener('keypress', function (e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    cargarProductos(this.value);
                }
            });

            let debounceTimer;
            searchInput.addEventListener('input', function (e) {
                toggleClearButton();
                const valor = e.target.value.trim();
                clearTimeout(debounceTimer);

                if (valor === '') {
                    closeCategoriaModal();
                    // Restaurar el catálogo completo de inmediato
                    productosList = [...catalogoCompleto];
                } else {
                    debounceTimer = setTimeout(() => {
                        cargarProductos(valor);
                    }, 300);
                }
            });

            searchInput.addEventListener('focus', function () {
                this.style.transform = 'scale(1.01)';
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
