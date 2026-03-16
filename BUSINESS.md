# 📱 White Sound — Product Business Map

> Treated as a real business, not just a hobby project.
> Adapted from the SaaS lifecycle framework to B2C mobile app subscription model.

**App:** White Sound (`id6449785515`) · Live on App Store · v1.4.4 (build 145)  
**Model:** Free download → Engagement-gated paywall → Monthly subscription (RevenueCat / StoreKit 2)  
**Target:** iOS 17.0+ · iPhone + iPad · 30+ locales

---

## Legend

| Символ | Статус |
|---|---|
| ✅ | Зроблено |
| 🔄 | В процесі / частково |
| ❌ | Не зроблено / потрібно |
| 🤖 | AI-скіл доступний для цього етапу |
| ⏩ | Не релевантно для нашої моделі |

---

## 💡 Idea

### Problem Discovery ✅
- **Проблема:** Людям потрібен фоновий звук для сну, фокусу та релаксації, але існуючі рішення або занадто дорогі (Calm, Headspace ~$70/рік), або занадто прості (один звук)
- **Insight:** користувач хоче *мікшувати* звуки під свій настрій — не вибирати один готовий трек
- **Аудиторія:** студенти, remote workers, люди з тривожністю, батьки немовлят

### Market Research ✅
- **Категорія App Store:** Health & Fitness / Productivity
- **Розмір ринку:** глобальний попит — sleep apps = multi-billion market
- **Сезонність:** зростання в осінньо-зимовий період (менше природних звуків)
- ❌ **Немає:** формального документа з дослідженням ринку

### Niche Selection ✅
- **Позиціонування:** ambient sound *mixer* (не meditation app, не sleep stories)
- **Диференціатор:** без аккаунтів, без контенту на підписці, pure utility — платиш за безліміт мікшування
- **Ключова фраза:** "Mix your perfect soundscape"

### Competitor Analysis 🔄
Відомі конкуренти, але не задокументовані формально:

| Конкурент | Ціна | Слабке місце |
|---|---|---|
| Calm | ~$70/рік | Дорого, meditation-focused |
| Headspace | ~$70/рік | Не ambient mixer |
| Noisli | $2/місяць | Слабкий UI, web-first |
| myNoise | Freemium | Складний UI, не iOS-native |
| Rain Rain | Безплатно | Без мікшування категорій |
| A-Soft Murmur | Безплатно | Немає iOS 17 design |

- ❌ **Потрібно:** зробити формальний competitive audit (ціни, reviews, feature gaps)

### Opportunity Mapping ❌
- ❌ **Потрібно:** визначити незайняті ніші — наприклад, ASMR-like sounds, baby sleep, study focus, Pomodoro integration
- ❌ **Потрібно:** аналіз App Store keywords з нульовою конкуренцією

---

## ✅ Validation

> Для нас цей розділ виглядає інакше — ми не робили класичний validation, бо просто запустили і дивимось на дані.

### Demand Testing ✅
- Додаток живий, є реальні користувачі
- Engagement-гейт (2 сесії + 5 хвилин) фільтрує зацікавлених перед показом paywall
- PostHog відслідковує conversion від launched → paywall_shown → purchase

### Customer Interviews ❌
- ❌ **Потрібно:** хоча б 5-10 якісних інтерв'ю з реальними підписниками — *чому вони платять?*
- ❌ **Потрібно:** exit survey — чому не підписуються? (dismiss після paywall)

### Landing Page Test ❌
- Немає окремого маркетингового сайту
- Є лише `docs/` з privacy policy / support — не маркетинг
- ❌ **Потрібно:** landing page з value proposition + App Store badge

### Waitlist / Pre-Sales ⏩
- Не релевантно — app вже в production

---

## 📋 Planning

### Product Roadmap 🔄
- Не задокументований формально
- ❌ **Потрібно:** публічний або приватний roadmap (GitHub Projects?)

### Feature Prioritization 🔄
Відома пріоритизація з коду та рефакторингу, але не формальна:

**Зроблено:**
- Multi-sound mixer з variant switcher
- Sleep timer (10 пресетів + custom)
- Background playback + Lock screen controls
- Adaptive iPad layout
- 30+ locалізацій
- Paywall з free trial + engagement gate
- PostHog analytics + Sentry monitoring

**Можливий наступний крок:**
- ❌ Favorites / custom sound presets (збереження улюблених комбінацій)
- ❌ Pomodoro mode (робота + звук)
- ❌ Widget для Control Center / Home Screen
- ❌ Apple Watch companion
- ❌ More sound categories (ASMR, city sounds, café)
- ❌ iCloud sync preferences

### MVP Scope ✅
- MVP визначений і доставлений — v1.0 до v1.4.4 ітеративно

### Tech Stack ✅
| Шар | Технологія |
|---|---|
| UI | SwiftUI + `@Observable` + `@MainActor` |
| Audio | AVFoundation (looping `.m4a`) |
| Monetization | RevenueCat + StoreKit 2 |
| Analytics | PostHog EU |
| Crash reporting | Sentry |
| Config | `.xcconfig` (secrets не в репо) |
| Локалізація | `.xcstrings` + 30 locale screenshot sets |

### Development Plan 🔄
- `refactoring/` директорія містить плани міграції сервісів
- Є документація в `MEMORY_BANK.md` та `docs/`
- ❌ Немає sprint-планування

---

## 🎨 Design

### UI Design ✅
- Glass morphism design system (`Theme/` директорія)
- Dark/Light mode підтримка
- Animated transitions + haptic feedback
- iPad adaptive layout (3-4 column grid)

### Design System 🔄
- `Theme/` folder з константами кольорів та шрифтів
- ❌ Немає Figma файлу або задокументованих компонентів публічно

### UX Flows ✅
Основний flow: `Launch → Sound Grid → Toggle Sound → Adjust Volume → Timer (optional) → Background`  
Монетизація flow: `Launch → Listen ≥5min × ≥2sessions → Paywall → Trial/Subscribe → Unlimited`

### Wireframes ❌
- Немає артефактів wireframes в репо

### Prototype ⏩
- Не потрібно — додаток живий

---

## 💻 Development

> 🤖 **Скіли:** `swiftui-mvvm-architecture`, `swift-concurrency`, `gcd-operationqueue`

### Frontend ✅
- SwiftUI MVVM з `@Observable` (iOS 17+)
- `WhiteNoisesViewModel` з 5 extension-файлами (SRP)
- Protocol-first DI для testability
- Factory pattern для sound instances

### Backend ⏩
- **Не потрібен** — serverless архітектура
- RevenueCat = subscription backend
- PostHog = analytics backend
- Sentry = error backend

### APIs ✅
- RevenueCat SDK (entitlement management)
- PostHog SDK (product analytics, EU)
- Sentry SDK (crash + performance)
- `UNUserNotificationCenter` (trial reminders)
- `MPRemoteCommandCenter` (Lock Screen controls)

### Database ✅
- `UserDefaults` — звукові налаштування, volumes, variants
- `Keychain` — entitlement override timestamps
- RevenueCat cloud — subscription state

### Authentication ✅
- Без user accounts — zero friction
- RevenueCat handles purchase identity (anonymous)
- Restore purchases → re-link entitlements

### Integrations ✅
- `SoundConfiguration.json` — data-driven sound library (не hardcoded)
- App Store Connect (ASC CLI для releases)

---

## 🏗️ Infrastructure

> 🤖 **Скіли:** `ios-security-audit`

### Cloud Hosting ✅
- App Store distribution
- RevenueCat cloud (subscription state)
- PostHog EU cloud (GDPR-compliant analytics)
- Sentry cloud (error tracking + profiling)

### DevOps 🔄
- `scripts/release.sh` — ручний release script
- `scripts/test.sh` — обгортка для `xcodebuild test`
- ❌ **Немає:** GitHub Actions CI pipeline (автобілд + автотести на PR)

### CI/CD 🔄
- ❌ **Потрібно:** автоматичний білд + тести на кожен push
- ❌ **Потрібно:** автоматичний upload до TestFlight після merge в `main`
- Є `.github/` директорія — можливо, частково налаштовано

> 🤖 Скіл `asc-release-flow` покриває pipeline до TestFlight/App Store

### Monitoring ✅
- **PostHog dashboards** — DAU/WAU/MAU, funnel paywall → purchase
- **Sentry alerts** — crash-free rate, performance issues
- `EngagementService` — on-device session tracking

### Security ✅ / 🔄
- ✅ Секрети в `.xcconfig` (не в репо)
- ✅ GDPR-compliant analytics (PostHog EU)
- ✅ No user accounts = no PII at risk
- ✅ `PrivacyInfo.xcprivacy` задекларований
- 🔄 ❌ **Аудит за OWASP MASVS** формально не проводився

> 🤖 Скіл `ios-security-audit` для повного MASVS 2.1.0 аудиту

---

## 🧪 Testing

> 🤖 **Скіли:** `swift-concurrency` (для async test patterns)

### Unit Testing ✅
- `TimerServiceTests.swift` — lifecycle, presets, cancellation
- `EngagementServiceTests.swift` — session counting, thresholds
- `ScreenshotTests.swift` — snapshot tests

### Integration Testing 🔄
- ❌ **Потрібно:** тести для RevenueCat paywall flow (StoreKit mock)
- ❌ **Потрібно:** тести для audio session edge cases

### Beta Testing 🔄
- TestFlight distribution (передбачається через `asc` CLI)
- ❌ **Немає:** структурованого beta feedback process

### Performance Testing ❌
- ❌ **Потрібно:** профілювання пам'яті при 9 одночасних звуках
- ❌ **Потрібно:** battery usage benchmarking (background audio)

### Bug Fixing ✅ (ongoing)
- Sentry алерти на нові crashes
- Refactoring документація оновлюється

---

## 🚀 Launch

> 🤖 **Скіли:** `asc-release-flow`, `asc-shots-pipeline`, `asc-submission-health`, `asc-metadata-sync`, `asc-localize-metadata`

### Public Release ✅
- v1.4.4 (build 145) — живий на App Store
- Universal app (iPhone + iPad)

### Localization ✅
- **30+ локалей** активно підтримуються
- `.xcstrings` для in-app тексту
- Remotion-генеровані screenshots для кожної локалі

### App Store Screenshots ✅
- `screenshots/output/` — 30+ locale sets
- iPhone + iPad варіанти
- Remotion TypeScript pipeline для генерації

### Landing Page ❌
- ❌ **Потрібно:** маркетинговий сайт (не просто privacy/support)
- Можна зробити простий GitHub Pages на основі існуючих `docs/`

### Product Hunt ❌
- ❌ **Потрібно:** підготувати launch на Product Hunt
- Є всі Assets (відео, screenshots, description)
- Best time: Tuesday-Thursday, 00:01 PST

### Early Adopters / Beta Users 🔄
- ❌ **Немає:** структурованого beta community (Discord, Telegram channel)
- ❌ **Немає:** TestFlight public link для органічних бета-юзерів

---

## 📈 Acquisition

> Це найменш розвинутий розділ — основна зона росту.

### ASO (App Store Optimization) 🔄
- ✅ 30+ локалізацій (охоплення глобального ринку)
- ✅ Локалізовані screenshots
- 🔄 ❌ Keyword research не задокументований
- ❌ **Потрібно:** A/B тест іконки та preview video через App Store Connect

> 🤖 Скіл `asc-metadata-sync` для оновлення keywords по локалях

### SEO / Web Presence ❌
- ❌ Немає маркетингового сайту
- ❌ Немає блогу / content marketing
- ❌ Немає backlinks

### Social / Community ❌
- ❌ Немає Twitter/X присутності для продукту
- ❌ Немає Reddit presence (r/productivity, r/sleep, r/ADHD = target communities)
- ❌ Немає TikTok/Instagram reels (ambient sound content добре заходить)

### Paid Acquisition ❌
- ❌ Apple Search Ads не запущено
- ❌ Немає даних про LTV vs CAC

### Referral / Virality 🔄
- ✅ "Share App" кнопка в SettingsView
- ❌ Немає referral програми
- ❌ Немає viral mechanics (наприклад, "share your soundscape")

### Retention 🔄
- ✅ Trial reminder notification (1 день до кінця trial)
- ✅ Engagement gate запобігає передчасному paywall churn
- ❌ **Потрібно:** re-engagement notification для inative users
- ❌ **Потрібно:** "new sounds" push notification при релізі нових варіантів

---

## 📊 Metrics to Track

| Метрика | Джерело | Статус |
|---|---|---|
| DAU / MAU | PostHog | ✅ |
| Paywall conversion rate | PostHog funnel | ✅ |
| Trial → Paid conversion | RevenueCat | ✅ |
| Churn rate | RevenueCat | ✅ |
| Crash-free rate | Sentry | ✅ |
| App Store rating | ASC | 🔄 |
| Keyword rankings | ASC / third party | ❌ |
| LTV (Lifetime Value) | RevenueCat | ❌ (потрібно рахувати) |
| CAC (Cost of Acquisition) | — | ❌ (немає paid) |
| Avg session length | PostHog | ✅ |
| Most played sounds | PostHog events | ✅ |

---

## 🤖 AI Skills Map

Де конкретні скіли в нашому репо вже є та допоможуть:

| Фаза | Скіл | Що вирішує |
|---|---|---|
| Development | `swiftui-mvvm-architecture` | Нові фічі, рефакторинг ViewModels |
| Development | `swift-concurrency` | async/await, Task, actor isolation |
| Infrastructure / Security | `ios-security-audit` | OWASP MASVS 2.1.0 аудит |
| Launch / Release | `asc-release-flow` | TestFlight upload, App Store submit |
| Launch / Screenshots | `asc-shots-pipeline` | Автоматизація screenshot pipeline |
| Launch / Metadata | `asc-metadata-sync` | Синк keywords, опису по локалях |
| Launch / Localization | `asc-localize-metadata` | AI-переклад metadata |
| Release health | `asc-submission-health` | Preflight перед сабмітом |

**Де скілів немає (але варто шукати/створювати):**
- ❌ Market Research / Competitor Analysis → потрібен загальний product strategy скіл
- ❌ App Store Keyword Research → ASO-specific скіл
- ❌ Customer Interview analysis → UX research скіл
- ❌ Paid UA / Apple Search Ads → growth marketing скіл

---

## 🗺️ Пріоритети на найближчий час

### Quick Wins (тиждень)
1. ❌ → ✅ Запустити Product Hunt
2. ❌ → ✅ Додати маркетинговий landing page (GitHub Pages)
3. ❌ → ✅ GitHub Actions CI (автотести на PR)

### Середній горизонт (місяць)
4. ❌ → ✅ Apple Search Ads пілот ($50 тест)
5. ❌ → ✅ Customer interviews з 5-10 підписниками
6. ❌ → ✅ Rivals keyword audit → оновити ASO metadata
7. ❌ → ✅ Reddit presence (органічний posting)

### Довгостроково (квартал)
8. ❌ → ✅ Звукові пресети / favorites feature
9. ❌ → ✅ Apple Watch companion
10. ❌ → ✅ Home Screen widget

---

*Документ версії 1.0 — створено March 2026. Оновлювати при кожному значному релізі або зміні стратегії.*
