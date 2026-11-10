/* OMorals Media — interactions.
   Loader, smooth scroll, cursor, scroll choreography, video reel, contact form.
   The WebGL scene lives in scene.js and talks to this file through window.OM. */
(() => {
  'use strict';

  const CONFIG = {
    projectId: 'omorals',
    apiKey: 'AIzaSyCLAygfuVBSHd3IkCuhJeqwQab5nMh7UuA', // Firebase web key: public by design
    email: 'info@omorals.com',
  };

  const html = document.documentElement;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const fine = matchMedia('(hover: hover) and (pointer: fine)').matches;
  const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

  html.classList.add('js');
  if (reduce) html.classList.add('no-motion');

  // Shared state for scene.js
  const OM = (window.OM = {
    pointer: { x: 0, y: 0 },
    intro: { v: reduce ? 1 : 0 },
    reduce,
    tasks: { fonts: false, scene: false, videos: false, load: false },
    done(key) { this.tasks[key] = true; },
  });

  gsap.registerPlugin(ScrollTrigger, SplitText);
  gsap.defaults({ ease: 'expo.out', duration: 1 });

  /* ───────────── Smooth scroll ───────────── */
  let lenis = null;
  if (!reduce && window.Lenis) {
    lenis = new Lenis({ lerp: 0.095, wheelMultiplier: 1, smoothWheel: true });
    lenis.on('scroll', ScrollTrigger.update);
    gsap.ticker.add((t) => lenis.raf(t * 1000));
    gsap.ticker.lagSmoothing(0);
    lenis.stop();
  }
  const scrollTo = (target) => {
    if (lenis) lenis.scrollTo(target, { duration: 1.4, easing: (t) => 1 - Math.pow(1 - t, 4) });
    else (typeof target === 'number' ? window.scrollTo(0, target) : target.scrollIntoView());
  };

  /* ───────────── Loader ───────────── */
  const loader = $('#loader');
  const ring = $('#loaderRing');
  const count = $('#loaderCount');
  const started = performance.now();
  const seen = (() => { try { return sessionStorage.getItem('om-seen') === '1'; } catch { return false; } })();
  const minTime = seen ? 700 : 1900;
  let shown = 0;
  let finished = false;
  let lastTick = performance.now();

  (document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve()).then(() => OM.done('fonts'));
  if (document.readyState === 'complete') OM.done('load');
  else window.addEventListener('load', () => OM.done('load'));
  setTimeout(() => Object.keys(OM.tasks).forEach((k) => OM.done(k)), 7000); // never trap the visitor

  function loaderTick() {
    if (finished) return;
    const keys = Object.keys(OM.tasks);
    const real = keys.filter((k) => OM.tasks[k]).length / keys.length;
    const timed = clamp((performance.now() - started) / minTime, 0, 1);
    const target = Math.min(real, timed);
    const now = performance.now();
    shown += (target - shown) * (1 - Math.exp(-(now - lastTick) / 160)); // time-based, so slow frames do not stall it
    lastTick = now;
    if (target === 1 && shown > 0.992) shown = 1;
    ring.style.strokeDashoffset = String(100 - shown * 100);
    count.textContent = String(Math.round(shown * 100)).padStart(3, '0');
    if (shown === 1) return finishLoader();
    requestAnimationFrame(loaderTick);
  }

  function finishLoader() {
    finished = true;
    try { sessionStorage.setItem('om-seen', '1'); } catch { /* private mode */ }
    const done = () => {
      loader.classList.add('is-done');
      html.classList.remove('is-loading');
      if (lenis) lenis.start();
      ScrollTrigger.refresh();
    };
    if (reduce) { done(); intro(0); return; }

    const hole = Math.hypot(innerWidth, innerHeight) / 2 + 40;
    gsap.timeline({ defaults: { ease: 'expo.inOut' } })
      .fromTo('.loader__play', { scale: 0, opacity: 1, svgOrigin: '104 100' }, { scale: 1, duration: 0.6, ease: 'back.out(2.2)' })
      .to('#loaderCount', { yPercent: -110, duration: 0.8 }, 0.1)
      .to('.loader__top, .loader__hint', { opacity: 0, duration: 0.5, ease: 'power2.out' }, 0.1)
      .to('.loader__mark svg', { scale: 0.86, duration: 0.5, ease: 'power3.inOut' }, 0.15)
      .to('.loader__mark svg', { scale: 7, rotate: 90, duration: 1.5 }, 0.6)
      .to(loader, { '--hole': hole + 'px', duration: 1.5 }, 0.6)
      .add(() => intro(0), 1.05)
      .add(done);
  }

  /* ───────────── Hero intro ───────────── */
  function intro(delay) {
    if (reduce) { gsap.set('.hero [data-reveal]', { opacity: 1, y: 0 }); return; }
    gsap.timeline({ delay })
      .to(OM.intro, { v: 1, duration: 2.2, ease: 'expo.out' }, 0)
      .to('.hero .line__in', { y: 0, duration: 1.4, stagger: 0.11 }, 0.05)
      .to('.hero [data-reveal]', { opacity: 1, y: 0, duration: 1.2, stagger: 0.09 }, 0.45)
      .from('.nav > *', { y: -24, opacity: 0, duration: 1, stagger: 0.07 }, 0.5);
  }

  /* ───────────── Cursor ───────────── */
  if (fine && !reduce) {
    const cur = $('.cursor');
    const dot = $('.cursor-dot');
    const label = $('.cursor__label');
    const cx = gsap.quickTo(cur, 'x', { duration: 0.55, ease: 'power3' });
    const cy = gsap.quickTo(cur, 'y', { duration: 0.55, ease: 'power3' });
    const dx = gsap.quickSetter(dot, 'x', 'px');
    const dy = gsap.quickSetter(dot, 'y', 'px');
    window.addEventListener('pointermove', (e) => {
      html.classList.add('has-cursor');
      cx(e.clientX); cy(e.clientY); dx(e.clientX); dy(e.clientY);
    }, { passive: true });
    document.addEventListener('pointerover', (e) => {
      const t = e.target instanceof Element ? e.target : null;
      const tagged = t && t.closest('[data-cursor]');
      const link = t && t.closest('a, button, label, .pick span');
      cur.classList.toggle('is-label', !!tagged);
      cur.classList.toggle('is-link', !tagged && !!link);
      if (tagged) label.textContent = tagged.dataset.cursor;
    });
    document.addEventListener('pointerdown', () => gsap.to(cur, { scale: 0.8, duration: 0.25 }));
    document.addEventListener('pointerup', () => gsap.to(cur, { scale: 1, duration: 0.5, ease: 'elastic.out(1, 0.5)' }));
    document.addEventListener('pointerleave', () => html.classList.remove('has-cursor'));
  }

  window.addEventListener('pointermove', (e) => {
    OM.pointer.x = (e.clientX / innerWidth) * 2 - 1;
    OM.pointer.y = (e.clientY / innerHeight) * 2 - 1;
  }, { passive: true });

  /* ───────────── Magnetic buttons & tilt ───────────── */
  if (fine && !reduce) {
    $$('[data-magnetic]').forEach((el) => {
      const x = gsap.quickTo(el, 'x', { duration: 0.6, ease: 'power3' });
      const y = gsap.quickTo(el, 'y', { duration: 0.6, ease: 'power3' });
      el.addEventListener('pointermove', (e) => {
        const r = el.getBoundingClientRect();
        x((e.clientX - (r.left + r.width / 2)) * 0.32);
        y((e.clientY - (r.top + r.height / 2)) * 0.42);
      });
      el.addEventListener('pointerleave', () => {
        gsap.to(el, { x: 0, y: 0, duration: 1, ease: 'elastic.out(1, 0.38)' });
      });
    });
  }

  function tilt(el, max = 9) {
    if (!fine || reduce) return;
    const rx = gsap.quickTo(el, 'rotationX', { duration: 0.6, ease: 'power3' });
    const ry = gsap.quickTo(el, 'rotationY', { duration: 0.6, ease: 'power3' });
    gsap.set(el, { transformPerspective: 1100 });
    el.addEventListener('pointermove', (e) => {
      const r = el.getBoundingClientRect();
      const px = (e.clientX - r.left) / r.width;
      const py = (e.clientY - r.top) / r.height;
      ry((px - 0.5) * max * 2);
      rx((0.5 - py) * max * 2);
      el.style.setProperty('--mx', px * 100 + '%');
      el.style.setProperty('--my', py * 100 + '%');
    });
    el.addEventListener('pointerleave', () => { rx(0); ry(0); });
  }
  $$('[data-tilt]').forEach((el) => tilt(el));

  /* ───────────── Nav ───────────── */
  const nav = $('#nav');
  const bar = $('#progressBar');
  let lastY = 0;
  function onScroll() {
    const y = window.scrollY;
    const max = document.documentElement.scrollHeight - innerHeight;
    bar.style.transform = `scaleX(${max > 0 ? clamp(y / max, 0, 1) : 0})`;
    nav.classList.toggle('is-solid', y > 40);
    if (!html.classList.contains('menu-open')) {
      if (y > lastY + 4 && y > 300) nav.classList.add('is-hidden');
      else if (y < lastY - 4) nav.classList.remove('is-hidden');
    }
    lastY = y;
    trackSection();
  }
  window.addEventListener('scroll', onScroll, { passive: true });

  const burger = $('#burger');
  const menu = $('#menu');
  function setMenu(open) {
    html.classList.toggle('menu-open', open);
    burger.setAttribute('aria-expanded', String(open));
    burger.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    menu.setAttribute('aria-hidden', String(!open));
    if (lenis) open ? lenis.stop() : lenis.start();
  }
  burger.addEventListener('click', () => setMenu(!html.classList.contains('menu-open')));
  window.addEventListener('keydown', (e) => { if (e.key === 'Escape') setMenu(false); });

  document.addEventListener('click', (e) => {
    const a = e.target instanceof Element ? e.target.closest('a[href^="#"]') : null;
    if (!a) return;
    const id = a.getAttribute('href');
    const target = id === '#top' ? 0 : $(id);
    if (target === null) return;
    e.preventDefault();
    setMenu(false);
    scrollTo(target);
    if (typeof target !== 'number') history.replaceState(null, '', id);
  });

  /* ───────────── Section awareness (glow colour, active link) ───────────── */
  const glowSections = $$('[data-glow]');
  const navLinks = $$('.nav__links a');
  let activeSection = null;
  function trackSection() {
    const mid = innerHeight * 0.5;
    let current = glowSections[0];
    for (const sec of glowSections) if (sec.getBoundingClientRect().top <= mid) current = sec;
    if (current === activeSection) return;
    activeSection = current;
    document.body.dataset.glow = current.dataset.glow;
    navLinks.forEach((a) => a.classList.toggle('is-active', a.getAttribute('href') === '#' + current.id));
  }

  /* ───────────── Text & reveal choreography ───────────── */
  if (!reduce) {
    $$('[data-split]').forEach((el) => {
      SplitText.create(el, {
        type: 'lines', mask: 'lines', autoSplit: true,
        onSplit: (self) => gsap.from(self.lines, {
          yPercent: 112, duration: 1.25, stagger: 0.09,
          scrollTrigger: { trigger: el, start: 'top 86%', once: true },
        }),
      });
    });

    const manifesto = SplitText.create('#manifesto', { type: 'words', wordsClass: 'w' });
    gsap.to(manifesto.words, {
      opacity: 1, ease: 'none', stagger: 0.12,
      scrollTrigger: { trigger: '#manifesto', start: 'top 78%', end: 'bottom 52%', scrub: 0.4 },
    });

    ScrollTrigger.batch($$('main [data-reveal]').filter((el) => !el.closest('.hero')), {
      start: 'top 88%', once: true,
      onEnter: (els) => gsap.to(els, { opacity: 1, y: 0, duration: 1.2, stagger: 0.1, overwrite: 'auto' }),
    });
    $$('[data-reveal-list]').forEach((list) => {
      gsap.to(list.children, {
        opacity: 1, y: 0, duration: 1.1, stagger: 0.07,
        scrollTrigger: { trigger: list, start: 'top 86%', once: true },
      });
    });

    // Oversized chapter numbers drift against the scroll
    $$('.craft__num').forEach((n) => {
      gsap.fromTo(n, { yPercent: 14 }, {
        yPercent: -14, ease: 'none',
        scrollTrigger: { trigger: n.parentElement, start: 'top bottom', end: 'bottom top', scrub: true },
      });
    });

    // Horizontal process rail
    const rail = $('#rail');
    const railBar = $('#railBar');
    const dist = () => Math.max(0, rail.offsetWidth - innerWidth);
    gsap.to(rail, {
      x: () => -dist(), ease: 'none',
      scrollTrigger: {
        trigger: '.process', start: 'top top', end: () => '+=' + (dist() + innerHeight * 0.25),
        pin: '.process__pin', scrub: 0.7, invalidateOnRefresh: true, anticipatePin: 1,
        onUpdate: (self) => { railBar.style.transform = `scaleX(${self.progress})`; },
      },
    });

    // Workspace mock straightens up as it scrolls through
    gsap.fromTo('#mock',
      { rotationX: 34, rotationY: -26, rotationZ: 6, y: 80, scale: 0.92 },
      {
        rotationX: 6, rotationY: -8, rotationZ: 1, y: 0, scale: 1, ease: 'none',
        scrollTrigger: { trigger: '.board', start: 'top 90%', end: 'center 45%', scrub: 0.8 },
      });
    gsap.to('.mock__card--lift', {
      z: 70, rotation: -4, ease: 'none',
      scrollTrigger: { trigger: '.board', start: 'top 60%', end: 'bottom 40%', scrub: 0.8 },
    });

    // Footer wordmark rises into place
    gsap.from('.footer__word', {
      yPercent: 40, ease: 'none',
      scrollTrigger: { trigger: '.footer', start: 'top bottom', end: 'bottom bottom', scrub: 0.6 },
    });

    // Ambient glows lean toward the pointer
    if (fine) {
      const ga = gsap.quickTo('.stage__glow--a', 'x', { duration: 2, ease: 'power2' });
      const gb = gsap.quickTo('.stage__glow--b', 'x', { duration: 2.4, ease: 'power2' });
      window.addEventListener('pointermove', (e) => {
        const p = e.clientX / innerWidth - 0.5;
        ga(p * 90); gb(p * -70);
      }, { passive: true });
    }
  } else {
    gsap.set('#rail', { clearProps: 'all' });
    $('.process__pin').style.overflowX = 'auto';
  }

  /* ───────────── Marquee ───────────── */
  (() => {
    const track = $('#marquee');
    track.innerHTML += track.innerHTML;
    if (reduce) return;
    let x = 0;
    let dir = -1;
    let half = track.scrollWidth / 2;
    new ResizeObserver(() => { half = track.scrollWidth / 2; }).observe(track);
    gsap.ticker.add((_, dt) => {
      const v = lenis ? lenis.velocity : 0;
      if (Math.abs(v) > 0.4) dir = v > 0 ? -1 : 1;
      x += dir * (0.045 * dt + Math.abs(v) * 0.55);
      if (x <= -half) x += half;
      if (x > 0) x -= half;
      track.style.transform = `translate3d(${x}px,0,0)`;
    });
  })();

  /* ───────────── Video reel ───────────── */
  (async () => {
    const reel = $('#reel');
    try {
      const res = await fetch('/videos.json', { cache: 'no-cache' });
      const data = await res.json();
      const fmt = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
      (data.videos || []).slice(0, 12).forEach((v, i) => {
        if (!/^[\w-]{6,20}$/.test(v.id)) return;
        const a = document.createElement('a');
        a.className = 'vid';
        a.href = 'https://www.youtube.com/watch?v=' + v.id;
        a.target = '_blank';
        a.rel = 'noopener';
        a.dataset.cursor = 'Play';
        a.draggable = false;

        const thumb = document.createElement('div');
        thumb.className = 'vid__thumb';
        const img = new Image();
        img.loading = 'lazy'; img.decoding = 'async'; img.alt = ''; img.draggable = false;
        img.referrerPolicy = 'no-referrer';
        img.src = `https://i.ytimg.com/vi/${v.id}/hq720.jpg`;
        img.onerror = () => { img.onerror = null; img.src = `https://i.ytimg.com/vi/${v.id}/mqdefault.jpg`; };
        const n = document.createElement('span');
        n.className = 'vid__n';
        n.textContent = String(i + 1).padStart(2, '0');
        const play = document.createElement('span');
        play.className = 'vid__play';
        thumb.append(img, n, play);

        const h = document.createElement('h4');
        h.textContent = v.title;
        const meta = document.createElement('small');
        const d = new Date(v.published);
        meta.textContent = isNaN(d) ? 'Original Morals' : fmt.format(d);
        a.append(thumb, h, meta);
        reel.append(a);
        tilt(a, 6);
      });
    } catch {
      reel.innerHTML = '';
      const a = document.createElement('a');
      a.className = 'link';
      a.href = 'https://www.youtube.com/channel/UCdBiq4YsDqFGBrX1s1JCc4w';
      a.target = '_blank'; a.rel = 'noopener';
      a.textContent = 'See every video on YouTube ↗';
      reel.append(a);
    }
    OM.done('videos');
    ScrollTrigger.refresh();

    // drag to scroll with a little inertia
    let down = false, moved = false, startX = 0, startLeft = 0, lastX = 0, vel = 0, raf = 0;
    reel.addEventListener('pointerdown', (e) => {
      if (e.pointerType !== 'mouse' || e.button !== 0) return;
      down = true; moved = false; startX = lastX = e.clientX; startLeft = reel.scrollLeft; vel = 0;
      cancelAnimationFrame(raf);
    });
    window.addEventListener('pointermove', (e) => {
      if (!down) return;
      const dx = e.clientX - startX;
      if (!moved && Math.abs(dx) > 5) { moved = true; reel.classList.add('is-drag'); }
      if (moved) { reel.scrollLeft = startLeft - dx; vel = e.clientX - lastX; lastX = e.clientX; }
    });
    window.addEventListener('pointerup', () => {
      if (!down) return;
      down = false;
      const glide = () => {
        if (Math.abs(vel) < 0.4) { reel.classList.remove('is-drag'); return; }
        reel.scrollLeft -= vel; vel *= 0.94; raf = requestAnimationFrame(glide);
      };
      if (moved) glide();
    });
    reel.addEventListener('click', (e) => { if (moved) { e.preventDefault(); moved = false; } }, true);
    reel.addEventListener('dragstart', (e) => e.preventDefault());
  })();

  /* ───────────── Contact form → Firestore ───────────── */
  (() => {
    const form = $('#contactForm');
    const note = $('#formNote');
    const btn = $('button[type="submit"]', form);
    const say = (text, cls) => { note.textContent = text; note.className = 'form__note' + (cls ? ' ' + cls : ''); };

    form.addEventListener('input', (e) => {
      const f = e.target.closest('.field');
      if (f) f.classList.remove('is-bad');
    });

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(form);
      const name = String(fd.get('name') || '').trim();
      const contact = String(fd.get('contact') || '').trim();
      const service = String(fd.get('service') || 'other');
      const message = String(fd.get('message') || '').trim();
      if (fd.get('company_site')) { say('Thank you. We have your message.', 'is-ok'); return; } // bots

      let bad = false;
      if (!name) { $('#f-name').closest('.field').classList.add('is-bad'); bad = true; }
      if (contact.length < 5) { $('#f-contact').closest('.field').classList.add('is-bad'); bad = true; }
      if (bad) { say('Please add your name and a way to reach you.', 'is-err'); return; }

      const local = ['localhost', '127.0.0.1'].includes(location.hostname);
      const base = local ? 'http://localhost:8080/v1' : 'https://firestore.googleapis.com/v1';
      const url = `${base}/projects/${CONFIG.projectId}/databases/(default)/documents/inquiries` +
        (local ? '' : `?key=${CONFIG.apiKey}`);
      const s = (v) => ({ stringValue: v });

      btn.disabled = true;
      say('Sending…');
      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fields: {
              name: s(name.slice(0, 80)), contact: s(contact.slice(0, 120)), service: s(service),
              message: s(message.slice(0, 2000)), status: s('new'), source: s('website'),
              createdAt: { timestampValue: new Date().toISOString() },
            },
          }),
        });
        if (!res.ok) throw new Error(String(res.status));
        form.reset();
        say(`Thank you, ${name.split(' ')[0]}. Your message is with our team.`, 'is-ok');
        if (!reduce) gsap.fromTo(note, { y: 10, opacity: 0 }, { y: 0, opacity: 1, duration: 0.8 });
      } catch {
        say(`That did not send. Please email ${CONFIG.email} instead.`, 'is-err');
      } finally {
        btn.disabled = false;
      }
    });
  })();

  /* ───────────── Footer clock ───────────── */
  (() => {
    const el = $('#clock');
    const fmt = new Intl.DateTimeFormat('en-IN', { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Asia/Kolkata' });
    const tick = () => { el.textContent = fmt.format(new Date()); };
    tick();
    setInterval(tick, 15000);
    $('#year').textContent = String(new Date().getFullYear());
  })();

  onScroll();
  requestAnimationFrame(loaderTick);
})();
