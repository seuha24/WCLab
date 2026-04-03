document.addEventListener('DOMContentLoaded', function () {
    const menuItems = document.querySelectorAll('.menu-item');
    const pageContents = document.querySelectorAll('.page-content');
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const navContainer = document.querySelector('.nav-container');

    function showPage(pageId) {
        menuItems.forEach(item => {
            item.classList.toggle('active', item.dataset.page === pageId);
        });
        pageContents.forEach(content => {
            content.style.display = 'none';
        });
        const target = document.getElementById(pageId + '-content');
        if (target) {
            target.style.display = 'block';
        }
        // 모바일 메뉴 닫기
        navContainer.classList.remove('open');
        mobileMenuBtn.classList.remove('active');
        window.scrollTo(0, 0);
    }

    menuItems.forEach(item => {
        item.addEventListener('click', function () {
            showPage(this.dataset.page);
        });
    });

    // 햄버거 메뉴 토글
    mobileMenuBtn.addEventListener('click', function () {
        this.classList.toggle('active');
        navContainer.classList.toggle('open');
    });

    // expose globally for logo click
    window.showPage = showPage;
});
