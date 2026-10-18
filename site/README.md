# Публикация и поисковая индексация

Сайт: https://thedivinelabs.github.io/remanga-api/

Workflow .github/workflows/docs-site.yml собирает три HTML-страницы из актуальных
README.md, API_REFERENCE.md и GUIDE_RU.md. Редактируйте исходные документы:
копии в _site_source генерируются и не коммитятся. В сайт попадают только
явно перечисленные публичные файлы, логотип и шаблоны из site/.

Публикация запускается при изменении документов в main, вручную и после успешного
workflow обновления API. Последний триггер необходим, потому что push с
GITHUB_TOKEN не запускает следующие workflow. Сборка всегда читает main.

Jekyll SEO Tag формирует title, description, canonical, Open Graph и JSON-LD.
Jekyll Sitemap публикует /remanga-api/sitemap.xml; даты изменения берутся из Git.
Генератор API, runner и его конфигурация в сайт не включаются.

## Подключение поисковых кабинетов

Это отдельное действие владельца аккаунтов Google и Яндекса:
1. Добавьте URL-prefix property https://thedivinelabs.github.io/remanga-api/
   в Google Search Console, а тот же URL сайта — в Яндекс Вебмастер.
2. Для HTML meta tag verification добавьте выданное значение в site/_config.yml:
   google_site_verification: "значение" и/или yandex_verification: "значение".
   Это публичные проверочные значения, не пароли и не API-токены.
   Альтернатива — положить выданный HTML-файл в site/.
3. После публикации подтвердите владение и отправьте sitemap:
   https://thedivinelabs.github.io/remanga-api/sitemap.xml.
4. Проверьте главную, /api-reference/ и /guide/ инструментами проверки URL.

robots.txt действует только в корне хоста. Файл внутри /remanga-api/
не управляет обходом, поэтому фиктивный project-level robots.txt не создаётся.
Корневой robots.txt можно менять только в репозитории сайта thedivinelabs.github.io.
Не используйте устаревшие sitemap ping URL, meta keywords или скрытые ключевые слова.

Ссылки из других сайтов и профиля организации помогают обнаружению проекта.
Сам по себе публичный статус, sitemap или запрос переобхода не гарантирует
индексацию и позиции. Настройки canonical/robots GitHub-страницы репозитория
контролирует GitHub; метаданные этого сайта относятся к GitHub Pages.

Источники:
- https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl
- https://yandex.com/support/webmaster/en/robot-workings/sitemap
- https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/about-github-pages-and-jekyll

## Состояние публикации

На момент подготовки сайта политика организации запрещает создание GitHub Pages.
Сборка работает независимо от публикации. Deploy включается переменной репозитория
DOCS_SITE_ENABLED=true только после создания Pages с build_type=workflow.
После успешного deploy обновите Website репозитория и добавьте ссылку на сайт в README.
