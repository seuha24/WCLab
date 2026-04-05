const PAGES = ['home', 'research', 'member', 'achievements', 'recruit', 'contact'];
const DEFAULT_PAGE = 'home';

const contentEl = document.querySelector('.content');
const menuItems = document.querySelectorAll('.menu-item');
const pageCache = {};

function getPageId() {
    const hash = location.hash.slice(1);
    return PAGES.includes(hash) ? hash : DEFAULT_PAGE;
}

function updateActiveMenu(pageId) {
    menuItems.forEach(item => {
        item.classList.toggle('active', item.dataset.page === pageId);
    });
}

async function loadPage(pageId) {
    updateActiveMenu(pageId);

    if (pageCache[pageId]) {
        contentEl.innerHTML = pageCache[pageId];
    } else {
        const res = await fetch(`pages/${pageId}.html`);
        const html = await res.text();
        pageCache[pageId] = html;
        contentEl.innerHTML = html;
    }

    initPageScripts();
}

function initPageScripts() {
    contentEl.querySelectorAll('.recruit-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            contentEl.querySelectorAll('.recruit-tab').forEach(t => t.classList.remove('active'));
            contentEl.querySelectorAll('.recruit-tab-content').forEach(c => c.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
        });
    });
}

function navigate(pageId) {
    location.hash = pageId;
}

menuItems.forEach(item => {
    item.addEventListener('click', () => navigate(item.dataset.page));
});

window.addEventListener('hashchange', () => loadPage(getPageId()));

document.querySelector('.logo-section').addEventListener('click', () => navigate(DEFAULT_PAGE));

loadPage(getPageId());