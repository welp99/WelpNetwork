// Fonction pour déclencher l'animation lorsque l'élément devient visible
function animateProgressBarOnScroll() {
    const progressBarElements = document.querySelectorAll('.progress-bar');

    progressBarElements.forEach((bar) => {
        // Calculez la position de l'élément par rapport à la fenêtre visible
        const elementPosition = bar.getBoundingClientRect();
        const viewportHeight = window.innerHeight || document.documentElement.clientHeight;

        if (elementPosition.top < viewportHeight) {
            // L'élément est visible, activez l'animation en définissant la largeur appropriée
            bar.style.width = bar.getAttribute('aria-valuenow') + '%';
        }
    });
}

// Écoutez l'événement de défilement de la fenêtre
window.addEventListener('scroll', animateProgressBarOnScroll);

// Déclenchez l'animation lorsque la page est chargée (si nécessaire)
window.addEventListener('load', animateProgressBarOnScroll);
