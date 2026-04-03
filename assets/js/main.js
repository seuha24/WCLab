document.addEventListener('DOMContentLoaded', function () {
    const menuItems = document.querySelectorAll('.menu-item');
    const pageContents = document.querySelectorAll('.page-content');

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
    }

    menuItems.forEach(item => {
        item.addEventListener('click', function () {
            showPage(this.dataset.page);
        });
    });

    // expose globally for logo click
    window.showPage = showPage;
});
