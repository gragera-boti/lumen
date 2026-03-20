// Nav scroll effect
const nav = document.querySelector('.nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
}, { passive: true });

// Scroll-triggered fade-in animations
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.15, rootMargin: '0px 0px -60px 0px' });

// Apply fade-in to sections
document.querySelectorAll(
  '.feature-card, .gallery-phone, .philosophy-card, .pricing-card, .proof-item, .section-eyebrow, .section-title, .section-subtitle, .pricing-lifetime-banner'
).forEach(el => {
  el.classList.add('fade-in');
  observer.observe(el);
});

// Stagger feature cards
document.querySelectorAll('.feature-card').forEach((card, i) => {
  card.style.transitionDelay = `${i * 80}ms`;
});

// Stagger pricing cards
document.querySelectorAll('.pricing-card').forEach((card, i) => {
  card.style.transitionDelay = `${i * 100}ms`;
});

// Stagger gallery phones (center first, then sides)
document.querySelectorAll('.gallery-phone').forEach((phone, i) => {
  const order = i === 1 ? 0 : (i === 0 ? 1 : 2);
  phone.style.transitionDelay = `${order * 150}ms`;
});

// Mobile menu toggle
const toggle = document.querySelector('.nav-toggle');
const navLinks = document.querySelector('.nav-links');
if (toggle) {
  toggle.addEventListener('click', () => {
    const open = navLinks.classList.toggle('open');
    toggle.classList.toggle('active');
    toggle.setAttribute('aria-expanded', open);
  });
  navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      navLinks.classList.remove('open');
      toggle.classList.remove('active');
      toggle.setAttribute('aria-expanded', 'false');
    });
  });
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', (e) => {
    const target = document.querySelector(anchor.getAttribute('href'));
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});
