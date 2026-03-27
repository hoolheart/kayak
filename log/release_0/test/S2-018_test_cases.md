# S2-018 Test Cases: 国际化(i18n)基础框架

**Created**: 2026-03-26
**Task**: S2-018 国际化(i18n)基础框架
**Status**: Revised based on sw-tom review feedback

---

## Test Scope

Test Flutter internationalization (i18n) framework:
- i18n configuration and initialization
- Language switching between Chinese and English
- Translation coverage for login page, navigation, and common operations
- Translation file modular organization

**Note**: Pluralization (TC-S2-018-14) and date/time formatting (TC-S2-018-15) are **out of scope** for this task and should be addressed in future enhancements.

---

## Test Cases

### TC-S2-018-01: i18n framework initialization

**Description**: Verify i18n framework initializes correctly on app startup

**Preconditions**: None

**Test Steps**:
1. Launch the Flutter application
2. Verify i18n configuration is loaded
3. Verify default locale is set (system locale or fallback)
4. Verify translation delegates are registered

**Expected Result**: App initializes without errors, default language displays correctly

---

### TC-S2-018-02: AppLocaleSettings singleton access

**Description**: Verify locale settings can be accessed globally via singleton

**Preconditions**: App initialized with i18n

**Test Steps**:
1. Access AppLocaleSettings.instance from different parts of app
2. Verify same instance is returned
3. Verify current locale is accessible
4. Verify locale preference persists across access points

**Expected Result**: Global singleton accessible throughout app with persistent locale

---

### TC-S2-018-03: Language switch from Chinese to English

**Description**: Verify user can switch language from Chinese to English

**Preconditions**: App running in Chinese locale

**Test Steps**:
1. Navigate to **Settings → Language** (or **Drawer → Profile → Language** if implemented)
2. Select English from language options
3. Verify UI updates to English immediately
4. Verify preference is saved

**Expected Result**: All translated strings change to English after switching

---

### TC-S2-018-04: Language switch from English to Chinese

**Description**: Verify user can switch language from English to Chinese

**Preconditions**: App running in English locale

**Test Steps**:
1. Navigate to **Settings → Language** (or **Drawer → Profile → Language** if implemented)
2. Select Chinese from language options
3. Verify UI updates to Chinese immediately
4. Verify preference is saved

**Expected Result**: All translated strings change to Chinese after switching

---

### TC-S2-018-05: Language preference persists across app restart

**Description**: Verify selected language preference is saved and restored

**Preconditions**: Language already switched to non-default

**Test Steps**:
1. Switch language to English
2. Close and restart the app
3. Verify language is still English on relaunch
4. Verify all UI text is in English

**Expected Result**: Language preference persists after app restart

---

### TC-S2-018-06: Login page translations - Chinese

**Description**: Verify login page displays correct Chinese translations

**Preconditions**: App running in Chinese locale

**Test Steps**:
1. Navigate to login page
2. Verify "登录" (Login) title is displayed
3. Verify "用户名" (Username) label is displayed
4. Verify "密码" (Password) label is displayed
5. Verify "登录" button text is displayed
6. Verify "记住我" (Remember me) checkbox label is displayed

**Expected Result**: All login page UI elements display correct Chinese text

---

### TC-S2-018-07: Login page translations - English

**Description**: Verify login page displays correct English translations

**Preconditions**: App running in English locale

**Test Steps**:
1. Navigate to login page
2. Verify "Login" title is displayed
3. Verify "Username" label is displayed
4. Verify "Password" label is displayed
5. Verify "Login" button text is displayed
6. Verify "Remember me" checkbox label is displayed

**Expected Result**: All login page UI elements display correct English text

---

### TC-S2-018-08: Navigation translations - Chinese

**Description**: Verify navigation elements display correct Chinese translations

**Preconditions**: App running in Chinese locale

**Test Steps**:
1. Verify navigation menu shows "首页" (Home)
2. Verify navigation menu shows "工作台" (Dashboard)
3. Verify navigation menu shows "设置" (Settings)
4. Verify back button shows "返回" (Back)
5. Verify drawer menu shows "个人中心" (Profile)

**Expected Result**: All navigation elements display correct Chinese text

---

### TC-S2-018-09: Navigation translations - English

**Description**: Verify navigation elements display correct English translations

**Preconditions**: App running in English locale

**Test Steps**:
1. Verify navigation menu shows "Home"
2. Verify navigation menu shows "Dashboard"
3. Verify navigation menu shows "Settings"
4. Verify back button shows "Back"
5. Verify drawer menu shows "Profile"

**Expected Result**: All navigation elements display correct English text

---

### TC-S2-018-10: Common operation button translations - Chinese

**Description**: Verify common operation buttons display correct Chinese translations

**Preconditions**: App running in Chinese locale

**Test Steps**:
1. Verify "保存" (Save) button text is correct
2. Verify "取消" (Cancel) button text is correct
3. Verify "删除" (Delete) button text is correct
4. Verify "确认" (Confirm) button text is correct
5. Verify "编辑" (Edit) button text is correct
6. Verify "新建" (Create) button text is correct

**Expected Result**: All common operation buttons display correct Chinese text

---

### TC-S2-018-11: Common operation button translations - English

**Description**: Verify common operation buttons display correct English translations

**Preconditions**: App running in English locale

**Test Steps**:
1. Verify "Save" button text is correct
2. Verify "Cancel" button text is correct
3. Verify "Delete" button text is correct
4. Verify "Confirm" button text is correct
5. Verify "Edit" button text is correct
6. Verify "Create" button text is correct

**Expected Result**: All common operation buttons display correct English text

---

### TC-S2-018-12: Translation file modular organization

**Description**: Verify translation files are organized by module

**Preconditions**: None

**Test Steps**:
1. Verify translation file structure exists
2. Verify separate file for login module translations
3. Verify separate file for navigation module translations
4. Verify separate file for common operations translations
5. Verify main/app translation file imports all modules

**Expected Result**: Translation files are modular and well-organized

---

### TC-S2-018-13: Missing key fallback behavior

**Description**: Verify app handles missing translation keys gracefully

**Preconditions**: Translation file with a missing key entry

**Test Steps**:
1. Request a translation for a non-existent key (e.g., "missing_key")
2. Verify app doesn't crash
3. Verify fallback returns the **key name itself** (e.g., "missing_key") for debugging purposes
4. Verify error is not thrown to user

**Expected Result**: App handles missing keys gracefully by returning the key name, enabling easier debugging

---

### TC-S2-018-14: Translation completeness - Login Module

**Description**: Verify all expected translation keys exist for the login module

**Preconditions**: App initialized with i18n

**Test Steps**:
1. Load login module translations for Chinese locale
2. Verify all required keys exist: `login.title`, `login.username`, `login.password`, `login.submit`, `login.rememberMe`
3. Repeat for English locale
4. Verify no keys are missing or null

**Expected Result**: All expected translation keys exist in both locales

---

### TC-S2-018-15: Translation completeness - Navigation Module

**Description**: Verify all expected translation keys exist for the navigation module

**Preconditions**: App initialized with i18n

**Test Steps**:
1. Load navigation module translations for Chinese locale
2. Verify all required keys exist: `nav.home`, `nav.dashboard`, `nav.settings`, `nav.back`, `nav.profile`
3. Repeat for English locale
4. Verify no keys are missing or null

**Expected Result**: All expected translation keys exist in both locales

---

### TC-S2-018-16: Translation completeness - Common Operations Module

**Description**: Verify all expected translation keys exist for the common operations module

**Preconditions**: App initialized with i18n

**Test Steps**:
1. Load common operations module translations for Chinese locale
2. Verify all required keys exist: `common.save`, `common.cancel`, `common.delete`, `common.confirm`, `common.edit`, `common.create`
3. Repeat for English locale
4. Verify no keys are missing or null

**Expected Result**: All expected translation keys exist in both locales

---

### TC-S2-018-17: System locale fallback (non-CN/EN)

**Description**: Verify app falls back correctly when system locale is neither Chinese nor English

**Preconditions**: Device/system locale set to unsupported locale (e.g., French, Japanese)

**Test Steps**:
1. Set device system locale to French (fr-FR) or Japanese (ja-JP)
2. Launch the Flutter application
3. Verify app does NOT crash
4. Verify app falls back to a default locale (English recommended)
5. Verify all UI text displays in the fallback language

**Expected Result**: App gracefully falls back to English when system locale is not CN or EN

---

### TC-S2-018-18: Pluralization support (OUT OF SCOPE)

**Description**: ~~Verify i18n framework supports plural translations~~

**Status**: **OUT OF SCOPE** - This feature is not required for S2-018. Reserved for future enhancement.

**Note**: If pluralization is needed later, this test should verify:
- count=0 returns: "No items" / "0个项目"
- count=1 returns: "1 item" / "1个项目"
- count=5 returns: "5 items" / "5个项目"

---

### TC-S2-018-19: Date/time formatting localization (OUT OF SCOPE)

**Description**: ~~Verify date and time formats adapt to locale~~

**Status**: **OUT OF SCOPE** - This feature is not required for S2-018. Reserved for future enhancement.

**Note**: If date/time formatting is needed later, this test should verify:
- Chinese locale: YYYY年MM月DD日 format
- English locale: MM/DD/YYYY or DD/MM/YYYY format based on region

---

## Test Execution Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-S2-018-01 | i18n framework initialization | Pending |
| TC-S2-018-02 | AppLocaleSettings singleton access | Pending |
| TC-S2-018-03 | Language switch Chinese to English | Pending |
| TC-S2-018-04 | Language switch English to Chinese | Pending |
| TC-S2-018-05 | Language preference persistence | Pending |
| TC-S2-018-06 | Login page translations Chinese | Pending |
| TC-S2-018-07 | Login page translations English | Pending |
| TC-S2-018-08 | Navigation translations Chinese | Pending |
| TC-S2-018-09 | Navigation translations English | Pending |
| TC-S2-018-10 | Common operations Chinese | Pending |
| TC-S2-018-11 | Common operations English | Pending |
| TC-S2-018-12 | Translation file modular organization | Pending |
| TC-S2-018-13 | Missing key fallback behavior | Pending |
| TC-S2-018-14 | Translation completeness - Login Module | Pending |
| TC-S2-018-15 | Translation completeness - Navigation Module | Pending |
| TC-S2-018-16 | Translation completeness - Common Ops Module | Pending |
| TC-S2-018-17 | System locale fallback (non-CN/EN) | Pending |
| TC-S2-018-18 | Pluralization support | **OUT OF SCOPE** |
| TC-S2-018-19 | Date/time formatting localization | **OUT OF SCOPE** |

**Total**: 19 test cases (15 active + 4 out of scope)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-03-26 | sw-mike | Initial revision |
| 2.0 | 2026-03-26 | sw-mike | Addressed sw-tom review feedback: Added TC-S2-018-16/17 for translation completeness and system locale fallback; clarified navigation paths in TC-S2-018-03/04; defined exact fallback behavior (key name) in TC-S2-018-13; marked TC-S2-018-14/15 as out of scope |

(End of file - total 403 lines)
