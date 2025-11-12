// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Copy contract address function
function copyContract() {
    const contractAddress = document.getElementById('contract').textContent;
    navigator.clipboard.writeText(contractAddress).then(() => {
        const btn = document.querySelector('.copy-btn');
        const originalText = btn.textContent;
        btn.textContent = 'COPIED!';
        btn.style.background = 'var(--primary-red)';

        setTimeout(() => {
            btn.textContent = originalText;
            btn.style.background = 'transparent';
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy:', err);
    });
}

// Glitch effect on hover
const glitchElements = document.querySelectorAll('.glitch');
glitchElements.forEach(element => {
    element.addEventListener('mouseenter', function() {
        this.style.animation = 'glitch 0.3s infinite';
    });

    element.addEventListener('mouseleave', function() {
        this.style.animation = 'glitch 3s infinite';
    });
});

// Random glitch effect on page load
function randomGlitch() {
    const elements = document.querySelectorAll('h2, h1');
    const randomElement = elements[Math.floor(Math.random() * elements.length)];

    if (randomElement) {
        randomElement.style.transform = 'translate(2px, -2px)';
        setTimeout(() => {
            randomElement.style.transform = 'translate(0, 0)';
        }, 100);
    }
}

// Trigger random glitches occasionally
setInterval(randomGlitch, 5000);

// Typewriter effect for hero text
const typewriterText = document.querySelector('.typewriter');
if (typewriterText) {
    const text = typewriterText.textContent;
    typewriterText.textContent = '';
    typewriterText.style.width = '0';

    let i = 0;
    const typeSpeed = 100;

    function typeWriter() {
        if (i < text.length) {
            typewriterText.textContent += text.charAt(i);
            typewriterText.style.width = 'auto';
            i++;
            setTimeout(typeWriter, typeSpeed);
        }
    }

    // Start typing after a short delay
    setTimeout(typeWriter, 1000);
}

// Parallax effect for hero section
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const hero = document.querySelector('.hero-content');

    if (hero && scrolled < window.innerHeight) {
        hero.style.transform = `translateY(${scrolled * 0.5}px)`;
        hero.style.opacity = 1 - (scrolled / window.innerHeight);
    }
});

// Add reveal animation on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.animation = 'fadeIn 1s ease-in';
            entry.target.style.opacity = '1';
        }
    });
}, observerOptions);

// Observe sections
document.querySelectorAll('section').forEach(section => {
    section.style.opacity = '0';
    observer.observe(section);
});

// Add fade in animation
const style = document.createElement('style');
style.textContent = `
    @keyframes fadeIn {
        from {
            opacity: 0;
            transform: translateY(30px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
`;
document.head.appendChild(style);

// Button click effects
document.querySelectorAll('button, .social-btn').forEach(btn => {
    btn.addEventListener('click', function(e) {
        const ripple = document.createElement('span');
        ripple.style.position = 'absolute';
        ripple.style.width = '20px';
        ripple.style.height = '20px';
        ripple.style.background = 'rgba(255, 0, 0, 0.5)';
        ripple.style.borderRadius = '50%';
        ripple.style.transform = 'scale(0)';
        ripple.style.animation = 'ripple 0.6s ease-out';
        ripple.style.pointerEvents = 'none';

        const rect = this.getBoundingClientRect();
        ripple.style.left = e.clientX - rect.left - 10 + 'px';
        ripple.style.top = e.clientY - rect.top - 10 + 'px';

        this.style.position = 'relative';
        this.style.overflow = 'hidden';
        this.appendChild(ripple);

        setTimeout(() => ripple.remove(), 600);
    });
});

// Add ripple animation
const rippleStyle = document.createElement('style');
rippleStyle.textContent = `
    @keyframes ripple {
        to {
            transform: scale(10);
            opacity: 0;
        }
    }
`;
document.head.appendChild(rippleStyle);

// Console easter egg
console.log('%c PROJECT MAYHEM ', 'background: #ff0000; color: #fff; font-size: 20px; padding: 10px;');
console.log('%c You are not your console logs ', 'color: #999; font-size: 12px;');
console.log('%c The first rule of Project Mayhem is: You do not ask questions ', 'color: #ff0000; font-size: 14px;');
