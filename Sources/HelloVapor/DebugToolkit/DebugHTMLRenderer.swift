import Vapor

enum DebugHTMLRenderer {
    static func renderAppHTML(databasePath: String) -> String {
        let escapedPath = htmlEscape(databasePath)

        return """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>SQLite Debug Toolkit</title>
          <style>
            :root {
              --bg: #07111f;
              --bg-accent: #0c1d33;
              --panel: rgba(10, 20, 36, 0.92);
              --panel-strong: rgba(12, 26, 46, 0.98);
              --panel-soft: rgba(16, 31, 54, 0.86);
              --line: rgba(119, 151, 197, 0.18);
              --line-strong: rgba(119, 151, 197, 0.32);
              --text: #edf4ff;
              --muted: #8da4c7;
              --muted-strong: #b4c5df;
              --accent: #5db0ff;
              --accent-strong: #2f84f7;
              --accent-soft: rgba(93, 176, 255, 0.14);
              --success: #35c98f;
              --danger: #ff6b81;
              --warning: #ffbe5c;
              --radius: 18px;
              --radius-sm: 12px;
              --shadow: 0 18px 45px rgba(0, 0, 0, 0.28);
              --font-sans: "SF Pro Display", "Segoe UI", "Helvetica Neue", system-ui, sans-serif;
              --font-mono: "SFMono-Regular", "SF Mono", "IBM Plex Mono", "Cascadia Code", monospace;
            }

            * { box-sizing: border-box; }

            body {
              margin: 0;
              min-height: 100vh;
              background:
                radial-gradient(circle at top left, rgba(47, 132, 247, 0.18), transparent 28%),
                radial-gradient(circle at top right, rgba(53, 201, 143, 0.12), transparent 24%),
                linear-gradient(180deg, var(--bg) 0%, var(--bg-accent) 100%);
              color: var(--text);
              font-family: var(--font-sans);
            }

            button, input, textarea, select {
              font: inherit;
            }

            .app {
              display: grid;
              grid-template-columns: 300px minmax(0, 1fr);
              min-height: 100vh;
            }

            .sidebar {
              padding: 24px 18px;
              background: rgba(7, 15, 27, 0.7);
              border-right: 1px solid var(--line);
              backdrop-filter: blur(14px);
            }

            .brand-block {
              margin-bottom: 18px;
              padding: 18px;
              border: 1px solid var(--line);
              border-radius: var(--radius);
              background: linear-gradient(180deg, rgba(15, 29, 50, 0.92), rgba(10, 21, 37, 0.92));
              box-shadow: var(--shadow);
            }

            .eyebrow {
              display: inline-flex;
              align-items: center;
              gap: 8px;
              color: var(--muted);
              font-size: 12px;
              letter-spacing: 0.08em;
              text-transform: uppercase;
            }

            .dot {
              width: 8px;
              height: 8px;
              border-radius: 50%;
              background: var(--success);
              box-shadow: 0 0 0 4px rgba(53, 201, 143, 0.14);
            }

            .brand {
              margin-top: 10px;
              font-size: 24px;
              font-weight: 750;
              line-height: 1.15;
            }

            .sub {
              margin-top: 8px;
              color: var(--muted);
              font-size: 13px;
              line-height: 1.6;
            }

            .sidebar-actions,
            .action-row,
            .toolbar,
            .path-actions,
            .status-row {
              display: flex;
              gap: 10px;
              flex-wrap: wrap;
            }

            .sidebar-actions {
              margin-bottom: 16px;
            }

            .table-search {
              margin-bottom: 12px;
            }

            button {
              border: 1px solid transparent;
              border-radius: 12px;
              padding: 10px 14px;
              font-weight: 650;
              color: white;
              cursor: pointer;
              background: linear-gradient(135deg, var(--accent), var(--accent-strong));
              box-shadow: 0 10px 24px rgba(47, 132, 247, 0.24);
              transition: transform 0.16s ease, box-shadow 0.16s ease, border-color 0.16s ease, opacity 0.16s ease;
            }

            button:hover {
              transform: translateY(-1px);
              box-shadow: 0 14px 28px rgba(47, 132, 247, 0.3);
            }

            button:disabled {
              opacity: 0.55;
              cursor: not-allowed;
              transform: none;
              box-shadow: none;
            }

            button.secondary {
              color: var(--text);
              background: rgba(255, 255, 255, 0.05);
              border-color: var(--line);
              box-shadow: none;
            }

            button.secondary:hover {
              border-color: var(--line-strong);
              background: rgba(255, 255, 255, 0.08);
            }

            button.ghost {
              color: var(--muted-strong);
              background: transparent;
              border-color: var(--line);
              box-shadow: none;
            }

            button.ghost:hover {
              color: var(--text);
              border-color: var(--line-strong);
              background: rgba(255, 255, 255, 0.04);
            }

            .table-list {
              display: flex;
              flex-direction: column;
              gap: 10px;
              max-height: calc(100vh - 240px);
              overflow: auto;
              padding-right: 4px;
            }

            .table-list[aria-busy="true"] {
              opacity: 0.72;
            }

            .table-item {
              display: block;
              width: 100%;
              padding: 14px 15px;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.03);
              box-shadow: none;
              color: inherit;
              cursor: pointer;
              text-align: left;
              font-weight: inherit;
              transition: border-color 0.16s ease, transform 0.16s ease, background 0.16s ease;
            }

            .table-item:hover {
              transform: translateY(-1px);
              border-color: rgba(93, 176, 255, 0.42);
              background: rgba(93, 176, 255, 0.08);
              box-shadow: none;
            }

            .table-item.active {
              border-color: rgba(93, 176, 255, 0.54);
              background: linear-gradient(135deg, rgba(93, 176, 255, 0.18), rgba(47, 132, 247, 0.12));
            }

            .table-name {
              font-weight: 650;
              color: var(--text);
              word-break: break-word;
            }

            .table-hint {
              margin-top: 4px;
              color: var(--muted);
              font-size: 12px;
            }

            .main {
              padding: 28px;
            }

            .main-grid {
              display: grid;
              gap: 18px;
            }

            .hero {
              display: grid;
              grid-template-columns: minmax(0, 1.6fr) minmax(280px, 0.9fr);
              gap: 18px;
            }

            .panel {
              overflow: hidden;
              border: 1px solid var(--line);
              border-radius: var(--radius);
              background: var(--panel);
              box-shadow: var(--shadow);
            }

            .panel-header {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 12px;
              padding: 16px 18px;
              border-bottom: 1px solid var(--line);
              background: var(--panel-strong);
            }

            .panel-title {
              font-size: 15px;
              font-weight: 720;
            }

            .panel-subtitle {
              margin-top: 4px;
              color: var(--muted);
              font-size: 12px;
            }

            .panel-body {
              padding: 18px;
            }

            .hero-copy {
              padding: 24px;
            }

            .hero-title {
              margin: 10px 0 0;
              font-size: 31px;
              font-weight: 760;
              line-height: 1.08;
              letter-spacing: -0.03em;
            }

            .hero-text {
              margin: 14px 0 0;
              color: var(--muted-strong);
              line-height: 1.75;
              max-width: 68ch;
            }

            .pill-row,
            .meta-row {
              display: flex;
              gap: 10px;
              flex-wrap: wrap;
              margin-top: 18px;
            }

            .badge {
              display: inline-flex;
              align-items: center;
              gap: 8px;
              min-height: 34px;
              padding: 7px 11px;
              border: 1px solid var(--line);
              border-radius: 999px;
              background: rgba(255, 255, 255, 0.04);
              color: var(--muted-strong);
              font-size: 12px;
            }

            .badge strong {
              color: var(--text);
            }

            .path-card {
              display: flex;
              flex-direction: column;
              gap: 14px;
              height: 100%;
            }

            .field-label {
              margin-bottom: 8px;
              display: block;
              color: var(--muted);
              font-size: 12px;
              font-weight: 600;
              letter-spacing: 0.03em;
              text-transform: uppercase;
            }

            .path-value,
            textarea,
            input,
            select {
              width: 100%;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.04);
              color: var(--text);
              outline: none;
            }

            .path-value {
              padding: 14px 15px;
              font-family: var(--font-mono);
              font-size: 13px;
              line-height: 1.7;
              word-break: break-all;
            }

            input, select, textarea {
              padding: 12px 14px;
            }

            input:focus,
            select:focus,
            textarea:focus {
              border-color: rgba(93, 176, 255, 0.52);
              box-shadow: 0 0 0 4px rgba(93, 176, 255, 0.14);
            }

            textarea {
              min-height: 180px;
              resize: vertical;
              line-height: 1.7;
              font-family: var(--font-mono);
              font-size: 13px;
            }

            .two-col {
              display: grid;
              grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
              gap: 18px;
            }

            .toolbar {
              align-items: end;
            }

            .toolbar .field {
              min-width: 120px;
              flex: 0 0 auto;
            }

            .status-card {
              padding: 14px 16px;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.03);
            }

            .status-label {
              color: var(--muted);
              font-size: 12px;
              text-transform: uppercase;
              letter-spacing: 0.05em;
            }

            .status-value {
              margin-top: 8px;
              color: var(--text);
              font-weight: 650;
            }

            .data-wrap {
              overflow: auto;
              border: 1px solid var(--line);
              border-radius: 16px;
              background: rgba(5, 11, 20, 0.34);
            }

            table {
              width: 100%;
              min-width: 720px;
              border-collapse: collapse;
            }

            th, td {
              padding: 11px 13px;
              border-bottom: 1px solid var(--line);
              text-align: left;
              vertical-align: top;
              font-size: 13px;
            }

            th {
              position: sticky;
              top: 0;
              z-index: 1;
              background: rgba(12, 24, 43, 0.98);
              color: #d9e7fb;
            }

            td {
              color: #e2ecfb;
              white-space: pre-wrap;
              word-break: break-word;
            }

            tr:hover td {
              background: rgba(93, 176, 255, 0.04);
            }

            .empty {
              padding: 34px 18px;
              text-align: center;
              color: var(--muted);
            }

            .alert {
              display: none;
              align-items: flex-start;
              justify-content: space-between;
              gap: 14px;
              padding: 13px 15px;
              border: 1px solid var(--line);
              border-radius: 14px;
              background: rgba(255, 255, 255, 0.04);
              color: var(--muted-strong);
              line-height: 1.55;
            }

            .alert.show {
              display: flex;
            }

            .alert.danger {
              border-color: rgba(255, 107, 129, 0.42);
              background: rgba(255, 107, 129, 0.1);
              color: #ffd3da;
            }

            .alert.success {
              border-color: rgba(53, 201, 143, 0.36);
              background: rgba(53, 201, 143, 0.1);
              color: #cbf7e6;
            }

            .alert button {
              flex: 0 0 auto;
            }

            .muted { color: var(--muted); }
            .success-text { color: var(--success); }
            .danger-text { color: var(--danger); }
            .warning-text { color: var(--warning); }
            .mono { font-family: var(--font-mono); }

            .hint-block {
              color: var(--muted);
              font-size: 12px;
              line-height: 1.8;
            }

            .shortcut {
              display: inline-flex;
              align-items: center;
              padding: 3px 8px;
              border-radius: 999px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.04);
              color: var(--muted-strong);
              font-family: var(--font-mono);
              font-size: 11px;
            }

            @media (max-width: 1240px) {
              .hero,
              .two-col {
                grid-template-columns: 1fr;
              }
            }

            @media (max-width: 980px) {
              .app {
                grid-template-columns: 1fr;
              }

              .sidebar {
                border-right: none;
                border-bottom: 1px solid var(--line);
              }

              .table-list {
                max-height: 240px;
              }

              .main {
                padding: 18px;
              }

              .hero-title {
                font-size: 26px;
              }
            }
          </style>
        </head>
        <body>
          <div class="app">
            <aside class="sidebar">
              <div class="brand-block">
                <div class="eyebrow"><span class="dot"></span> Development Only</div>
                <div class="brand">SQLite Debug Toolkit</div>
                <div class="sub">面向本地调试的数据库工作台。用于查看表结构、分页读取数据、执行只读 SQL。</div>
              </div>

              <div class="sidebar-actions">
                <button id="refreshTablesButton" onclick="loadTables()">刷新表列表</button>
                <button class="secondary" onclick="fillCurrentTableQuery()">快速填充查询</button>
                <button class="ghost" onclick="window.location.href='/debug/mock/ui'">Mock 管理</button>
                <button class="ghost" onclick="window.location.href='/debug/image/ui'">图片生成</button>
              </div>

              <div class="table-search">
                <label class="field-label" for="tableSearchInput">Filter tables</label>
                <input id="tableSearchInput" type="search" placeholder="输入表名过滤" autocomplete="off" />
              </div>

              <div id="tableList" class="table-list" aria-live="polite">
                <div class="empty">Loading tables...</div>
              </div>
            </aside>

            <main class="main">
              <div class="main-grid">
                <div id="globalAlert" class="alert" role="status" aria-live="polite">
                  <span id="globalAlertMessage"></span>
                  <button class="ghost" onclick="hideGlobalAlert()">关闭</button>
                </div>

                <section class="hero">
                  <div class="panel hero-copy">
                    <div class="eyebrow"><span class="dot"></span> SQLite Inspector</div>
                    <h1 class="hero-title">更清晰地查看 SQLite 数据、结构与只读查询结果</h1>
                    <p class="hero-text">
                      当前页面直接连接 Vapor 开发环境中的 SQLite 数据库。左侧选择数据表，右侧查看结构与分页数据。
                      SQL 工作台支持 <span class="mono">SELECT</span>、<span class="mono">PRAGMA</span>、<span class="mono">EXPLAIN</span>，
                      并提供更明确的执行反馈与结果摘要。
                    </p>
                    <div class="pill-row">
                      <span class="badge"><strong id="currentTableName">未选择表</strong></span>
                      <span class="badge">总行数 <strong id="rowCountBadge">-</strong></span>
                      <span class="badge">当前页 <strong id="pageBadge">-</strong></span>
                      <span class="badge">SQL 结果 <strong id="sqlCountBadge">-</strong></span>
                    </div>
                  </div>

                  <div class="panel">
                    <div class="panel-header">
                      <div>
                        <div class="panel-title">数据库路径</div>
                        <div class="panel-subtitle">用于快速定位当前 SQLite 文件</div>
                      </div>
                    </div>
                    <div class="panel-body path-card">
                      <div>
                        <label class="field-label">db.sqlite absolute path</label>
                        <div id="databasePath" class="path-value">\(escapedPath)</div>
                      </div>
                      <div class="path-actions">
                        <button class="secondary" onclick="copyDatabasePath()">复制路径</button>
                        <button class="ghost" onclick="copyText(document.getElementById('sqlInput').value, 'SQL 已复制')">复制当前 SQL</button>
                      </div>
                      <div id="pathMessage" class="hint-block">
                        如果你想在终端或外部工具中继续检查数据库，直接复制这条路径即可。
                      </div>
                    </div>
                  </div>
                </section>

                <section class="two-col">
                  <div class="panel">
                    <div class="panel-header">
                      <div>
                        <div class="panel-title">表结构</div>
                        <div class="panel-subtitle">当前表字段、类型、主键与默认值</div>
                      </div>
                    </div>
                    <div class="panel-body">
                      <div id="schemaWrap" class="data-wrap">
                        <div class="empty">请选择左侧表</div>
                      </div>
                    </div>
                  </div>

                  <div class="panel">
                    <div class="panel-header">
                      <div>
                        <div class="panel-title">分页浏览</div>
                        <div class="panel-subtitle">按页查看表数据，适合快速验证写入结果</div>
                      </div>
                    </div>
                    <div class="panel-body">
                      <div class="toolbar">
                        <div class="field">
                          <label class="field-label" for="pageInput">Page</label>
                          <input id="pageInput" type="number" min="1" value="1" />
                        </div>

                        <div class="field">
                          <label class="field-label" for="pageSizeInput">Page Size</label>
                          <select id="pageSizeInput">
                            <option value="20">20</option>
                            <option value="50" selected>50</option>
                            <option value="100">100</option>
                            <option value="200">200</option>
                          </select>
                        </div>

                        <div class="field">
                          <button id="reloadTableButton" onclick="reloadCurrentTable()" disabled>加载当前页</button>
                        </div>

                        <div class="field">
                          <button id="prevPageButton" class="secondary" onclick="prevPage()" disabled>上一页</button>
                        </div>

                        <div class="field">
                          <button id="nextPageButton" class="secondary" onclick="nextPage()" disabled>下一页</button>
                        </div>
                      </div>

                      <div class="meta-row">
                        <div class="status-card">
                          <div class="status-label">Summary</div>
                          <div id="pageSummary" class="status-value">请选择左侧表</div>
                        </div>
                      </div>

                      <div id="tableWrap" class="data-wrap" style="margin-top: 16px;">
                        <div class="empty">请选择左侧表</div>
                      </div>
                    </div>
                  </div>
                </section>

                <section class="panel">
                  <div class="panel-header">
                    <div>
                      <div class="panel-title">SQL 工作台（只读）</div>
                      <div class="panel-subtitle">支持 SELECT / PRAGMA / EXPLAIN，快捷键 <span class="shortcut">Cmd/Ctrl + Enter</span></div>
                    </div>
                  </div>
                  <div class="panel-body">
                    <label class="field-label" for="sqlInput">SQL</label>
                    <textarea id="sqlInput" spellcheck="false">SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;</textarea>

                    <div class="action-row" style="margin-top: 14px;">
                      <button id="runSqlButton" onclick="runSQL()">执行 SQL</button>
                      <button class="secondary" onclick="fillCurrentTableQuery()">查询当前表</button>
                      <button class="ghost" onclick="fillSchemaQuery()">查看 sqlite_master</button>
                    </div>

                    <div class="status-row" style="margin-top: 14px;">
                      <div class="status-card" style="min-width: 220px;">
                        <div class="status-label">Execution</div>
                        <div id="sqlMessage" class="status-value muted">尚未执行 SQL</div>
                      </div>
                    </div>

                    <div id="sqlResult" class="data-wrap" style="margin-top: 16px;">
                      <div class="empty">页面已准备就绪。默认 SQL 会在加载后自动执行一次。</div>
                    </div>
                  </div>
                </section>

                <section class="panel">
                  <div class="panel-header">
                    <div>
                      <div class="panel-title">说明与限制</div>
                      <div class="panel-subtitle">避免把这个页面开放到生产环境</div>
                    </div>
                  </div>
                  <div class="panel-body hint-block">
                    当前页面只执行只读 SQL，不支持变更类语句。<br />
                    如果你感觉“读不到 SQL 内容”，优先看上面的执行状态和错误消息，页面现在会把返回结果数量与失败原因直接显示出来。<br />
                    数据库路径已经暴露在顶部卡片中，便于你用终端、DB Browser 或 sqlite3 继续排查。
                  </div>
                </section>
              </div>
            </main>
          </div>

          <script>
            const state = {
              tables: [],
              currentTable: null,
              isLoadingTables: false,
              lastTableRequestId: 0,
              lastRowsMeta: null
            };

            const requestTimeoutMs = 15000;

            function escapeHtml(value) {
              if (value === null || value === undefined) return '';
              return String(value)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('"', '&quot;')
                .replaceAll("'", '&#039;');
            }

            function getCurrentTable() {
              return state.currentTable;
            }

            function showGlobalAlert(message, tone = 'danger') {
              const alert = document.getElementById('globalAlert');
              const messageEl = document.getElementById('globalAlertMessage');
              alert.className = `alert show ${tone === 'success' ? 'success' : tone === 'danger' ? 'danger' : ''}`;
              messageEl.textContent = message;
            }

            function hideGlobalAlert() {
              const alert = document.getElementById('globalAlert');
              alert.className = 'alert';
              document.getElementById('globalAlertMessage').textContent = '';
            }

            function normalizeErrorMessage(err, fallback = '请求失败') {
              if (!err) return fallback;
              if (err.name === 'AbortError') return '请求超时，请确认 Vapor 服务和数据库连接是否正常。';
              if (err.message === 'Failed to fetch') return '无法连接到 DebugToolkit API，请确认服务仍在运行。';
              return err.message || fallback;
            }

            async function fetchJSON(url, options = {}) {
              const controller = new AbortController();
              const timeout = window.setTimeout(() => controller.abort(), requestTimeoutMs);

              let res;
              let text;

              try {
                res = await fetch(url, { ...options, signal: controller.signal });
                text = await res.text();
              } finally {
                window.clearTimeout(timeout);
              }

              let data;
              try {
                data = JSON.parse(text);
              } catch {
                throw new Error(text || 'Invalid response');
              }

              if (!res.ok) {
                throw new Error(data.reason || data.error || 'Request failed');
              }

              return data;
            }

            function setPathMessage(message, tone = 'muted') {
              const el = document.getElementById('pathMessage');
              el.className = `hint-block ${tone === 'danger' ? 'danger-text' : tone === 'success' ? 'success-text' : ''}`;
              el.textContent = message;
            }

            function setSQLMessage(message, tone = 'muted') {
              const el = document.getElementById('sqlMessage');
              el.className = `status-value ${tone === 'danger' ? 'danger-text' : tone === 'success' ? 'success-text' : tone === 'warning' ? 'warning-text' : 'muted'}`;
              el.textContent = message;
            }

            async function copyText(value, successMessage = '已复制') {
              try {
                await navigator.clipboard.writeText(value);
                setPathMessage(successMessage, 'success');
              } catch {
                setPathMessage('复制失败，请检查浏览器权限', 'danger');
              }
            }

            function copyDatabasePath() {
              const path = document.getElementById('databasePath').textContent;
              copyText(path, '数据库路径已复制');
            }

            async function loadTables() {
              const tableList = document.getElementById('tableList');
              const button = document.getElementById('refreshTablesButton');
              const requestId = ++state.lastTableRequestId;

              state.isLoadingTables = true;
              button.disabled = true;
              tableList.setAttribute('aria-busy', 'true');
              tableList.innerHTML = '<div class="empty">Loading tables...</div>';

              try {
                const data = await fetchJSON('/debug/api/tables');
                if (requestId !== state.lastTableRequestId) return;

                state.tables = data.tables || [];
                renderTableList();
                hideGlobalAlert();

                if (!state.currentTable && state.tables.length > 0) {
                  await selectTable(state.tables[0], { reloadTables: false });
                } else if (state.currentTable && !state.tables.includes(state.currentTable)) {
                  resetSelection();
                  showGlobalAlert('当前选择的表已经不存在，请重新选择表。', 'danger');
                }
              } catch (err) {
                const message = normalizeErrorMessage(err, '加载表列表失败');
                tableList.innerHTML = `
                  <div class="empty danger-text">
                    ${escapeHtml(message)}
                    <div style="margin-top: 12px;"><button class="secondary" onclick="loadTables()">重试</button></div>
                  </div>
                `;
                showGlobalAlert(message, 'danger');
              } finally {
                if (requestId === state.lastTableRequestId) {
                  state.isLoadingTables = false;
                  button.disabled = false;
                  tableList.setAttribute('aria-busy', 'false');
                }
              }
            }

            function renderTableList() {
              const tableList = document.getElementById('tableList');
              const keyword = document.getElementById('tableSearchInput').value.trim().toLowerCase();
              const tables = state.tables.filter(name => name.toLowerCase().includes(keyword));

              if (!state.tables.length) {
                tableList.innerHTML = '<div class="empty">没有找到用户表。请确认迁移是否已执行，或数据库路径是否正确。</div>';
                return;
              }

              if (!tables.length) {
                tableList.innerHTML = '<div class="empty">没有匹配的表</div>';
                return;
              }

              tableList.innerHTML = tables.map(name => {
                const active = name === state.currentTable ? 'active' : '';
                return `
                  <button type="button" class="table-item ${active}" data-table-name="${escapeHtml(name)}">
                    <div class="table-name">${escapeHtml(name)}</div>
                    <div class="table-hint">点击查看结构与分页数据</div>
                  </button>
                `;
              }).join('');
            }

            function resetSelection() {
              state.currentTable = null;
              state.lastRowsMeta = null;
              document.getElementById('currentTableName').textContent = '未选择表';
              document.getElementById('rowCountBadge').textContent = '-';
              document.getElementById('pageBadge').textContent = '-';
              document.getElementById('pageSummary').textContent = '请选择左侧表';
              document.getElementById('schemaWrap').innerHTML = '<div class="empty">请选择左侧表</div>';
              document.getElementById('tableWrap').innerHTML = '<div class="empty">请选择左侧表</div>';
              updatePaginationControls();
              renderTableList();
            }

            function updatePaginationControls() {
              const hasTable = Boolean(state.currentTable);
              const page = Number(document.getElementById('pageInput').value || 1);
              const meta = state.lastRowsMeta;
              const hasNext = meta ? meta.page * meta.pageSize < meta.total : false;

              document.getElementById('reloadTableButton').disabled = !hasTable;
              document.getElementById('prevPageButton').disabled = !hasTable || page <= 1;
              document.getElementById('nextPageButton').disabled = !hasTable || !hasNext;
            }

            function quoteIdentifier(name) {
              return `"${String(name).replaceAll('"', '""')}"`;
            }

            function setLoading(targetId, message) {
              document.getElementById(targetId).innerHTML = `<div class="empty">${escapeHtml(message)}</div>`;
            }

            function setRetryableError(targetId, message, retryCall) {
              document.getElementById(targetId).innerHTML = `
                <div class="empty danger-text">
                  ${escapeHtml(message)}
                  <div style="margin-top: 12px;"><button class="secondary" onclick="${retryCall}">重试</button></div>
                </div>
              `;
            }

            async function selectTable(tableName, options = {}) {
              state.currentTable = tableName;
              state.lastRowsMeta = null;
              document.getElementById('currentTableName').textContent = tableName;
              document.getElementById('pageInput').value = 1;
              renderTableList();
              updatePaginationControls();

              if (options.reloadTables) {
                await loadTables();
              }

              await Promise.all([
                loadSchema(tableName),
                loadTableData(tableName)
              ]);
            }

            async function loadSchema(tableName) {
              const wrap = document.getElementById('schemaWrap');
              setLoading('schemaWrap', 'Loading schema...');

              try {
                const rows = await fetchJSON(`/debug/api/schema/${encodeURIComponent(tableName)}`);
                if (!rows.length) {
                  wrap.innerHTML = '<div class="empty">No schema info</div>';
                  return;
                }

                wrap.innerHTML = renderTable(
                  ['cid', 'name', 'type', 'notNull', 'defaultValue', 'primaryKeyIndex'],
                  rows.map(row => ({
                    cid: row.cid,
                    name: row.name,
                    type: row.type,
                    notNull: row.notNull,
                    defaultValue: row.defaultValue ?? '',
                    primaryKeyIndex: row.primaryKeyIndex
                  }))
                );
              } catch (err) {
                const message = normalizeErrorMessage(err, '加载表结构失败');
                setRetryableError('schemaWrap', message, `loadSchema(${JSON.stringify(tableName)})`);
              }
            }

            async function loadTableData(tableName) {
              const wrap = document.getElementById('tableWrap');
              setLoading('tableWrap', 'Loading rows...');

              const pageInput = document.getElementById('pageInput');
              const page = Math.max(1, Number(pageInput.value || 1));
              const pageSize = Number(document.getElementById('pageSizeInput').value || 50);
              pageInput.value = page;
              updatePaginationControls();

              try {
                const data = await fetchJSON(`/debug/api/tables/${encodeURIComponent(tableName)}?page=${page}&pageSize=${pageSize}`);

                state.lastRowsMeta = {
                  page: data.page,
                  pageSize: data.pageSize,
                  total: data.total
                };

                pageInput.value = data.page;
                document.getElementById('rowCountBadge').textContent = String(data.total);
                document.getElementById('pageBadge').textContent = String(data.page);
                document.getElementById('pageSummary').textContent =
                  `第 ${data.page} 页，每页 ${data.pageSize} 条，共 ${data.total} 条记录`;
                updatePaginationControls();

                if (!data.rows.length) {
                  wrap.innerHTML = data.total === 0
                    ? '<div class="empty">这张表暂时没有数据</div>'
                    : '<div class="empty">当前页没有数据，可能已经超过最后一页</div>';
                  return;
                }

                wrap.innerHTML = renderTable(data.columns, data.rows);
              } catch (err) {
                const message = normalizeErrorMessage(err, '加载表数据失败');
                setRetryableError('tableWrap', message, `loadTableData(${JSON.stringify(tableName)})`);
                document.getElementById('pageSummary').textContent = '加载失败';
                updatePaginationControls();
              }
            }

            function renderTable(columns, rows) {
              if (!columns.length) {
                return '<div class="empty">没有可显示的列</div>';
              }

              const thead = `<thead><tr>${columns.map(col => `<th>${escapeHtml(col)}</th>`).join('')}</tr></thead>`;
              const tbody = `<tbody>${rows.map(row => `
                <tr>
                  ${columns.map(col => `<td>${escapeHtml(row[col] ?? '')}</td>`).join('')}
                </tr>
              `).join('')}</tbody>`;

              return `<table>${thead}${tbody}</table>`;
            }

            async function runSQL() {
              const button = document.getElementById('runSqlButton');
              const sql = document.getElementById('sqlInput').value.trim();
              const result = document.getElementById('sqlResult');

              if (!sql) {
                setSQLMessage('请输入 SQL', 'warning');
                result.innerHTML = '<div class="empty">SQL 输入为空</div>';
                return;
              }

              if (sql.length > 20000) {
                setSQLMessage('SQL 太长，请缩小查询内容', 'warning');
                result.innerHTML = '<div class="empty">为了避免误操作和页面卡顿，SQL 输入限制为 20000 个字符以内。</div>';
                return;
              }

              button.disabled = true;
              setSQLMessage('正在执行查询...', 'muted');
              result.innerHTML = '<div class="empty">Running SQL...</div>';

              try {
                const data = await fetchJSON('/debug/api/sql', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json'
                  },
                  body: JSON.stringify({ sql })
                });

                document.getElementById('sqlCountBadge').textContent = String(data.count);
                setSQLMessage(`执行成功，返回 ${data.count} 条记录`, 'success');

                if (!data.rows.length) {
                  result.innerHTML = '<div class="empty">查询成功，但没有返回结果</div>';
                  return;
                }

                result.innerHTML = renderTable(data.columns, data.rows);
              } catch (err) {
                const message = normalizeErrorMessage(err, 'SQL 执行失败');
                document.getElementById('sqlCountBadge').textContent = '-';
                setSQLMessage(message, 'danger');
                result.innerHTML = `<div class="empty danger-text">${escapeHtml(message)}</div>`;
              } finally {
                button.disabled = false;
              }
            }

            function fillCurrentTableQuery() {
              const currentTable = getCurrentTable();
              if (!currentTable) {
                setSQLMessage('请先在左侧选择一张表', 'warning');
                return;
              }

              document.getElementById('sqlInput').value = `SELECT * FROM ${quoteIdentifier(currentTable)} LIMIT 100`;
              setSQLMessage(`已填入 ${currentTable} 的查询模板`, 'muted');
            }

            function fillSchemaQuery() {
              document.getElementById('sqlInput').value =
                "SELECT name, type, sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name;";
              setSQLMessage('已填入 sqlite_master 查询模板', 'muted');
            }

            function reloadCurrentTable() {
              const currentTable = getCurrentTable();
              if (!currentTable) {
                showGlobalAlert('请先在左侧选择一张表。', 'danger');
                return;
              }

              loadSchema(currentTable);
              loadTableData(currentTable);
            }

            function prevPage() {
              const input = document.getElementById('pageInput');
              const current = Number(input.value || 1);
              input.value = Math.max(1, current - 1);
              reloadCurrentTable();
            }

            function nextPage() {
              const input = document.getElementById('pageInput');
              if (document.getElementById('nextPageButton').disabled) return;
              const current = Number(input.value || 1);
              input.value = current + 1;
              reloadCurrentTable();
            }

            document.getElementById('tableList').addEventListener('click', event => {
              const item = event.target.closest('.table-item');
              if (!item) return;

              const tableName = item.dataset.tableName;
              if (!tableName) return;

              selectTable(tableName, { reloadTables: false });
            });

            document.getElementById('tableSearchInput').addEventListener('input', renderTableList);

            document.getElementById('pageInput').addEventListener('keydown', event => {
              if (event.key === 'Enter') {
                event.preventDefault();
                reloadCurrentTable();
              }
            });

            document.getElementById('pageSizeInput').addEventListener('change', () => {
              document.getElementById('pageInput').value = 1;
              reloadCurrentTable();
            });

            document.getElementById('sqlInput').addEventListener('keydown', event => {
              if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
                event.preventDefault();
                runSQL();
              }
            });

            loadTables().then(() => runSQL());
          </script>
        </body>
        </html>
        """
    }

    static func renderMockAPIHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>Mock API Debug Manager</title>
          <style>
            :root {
              --bg: #07111f;
              --panel: rgba(10, 20, 36, 0.94);
              --panel-strong: rgba(12, 26, 46, 0.98);
              --line: rgba(119, 151, 197, 0.2);
              --line-strong: rgba(119, 151, 197, 0.34);
              --text: #edf4ff;
              --muted: #8da4c7;
              --muted-strong: #b4c5df;
              --accent: #5db0ff;
              --accent-strong: #2f84f7;
              --success: #35c98f;
              --danger: #ff6b81;
              --warning: #ffbe5c;
              --shadow: 0 18px 45px rgba(0, 0, 0, 0.28);
              --font-sans: "SF Pro Display", "Segoe UI", "Helvetica Neue", system-ui, sans-serif;
              --font-mono: "SFMono-Regular", "SF Mono", "IBM Plex Mono", "Cascadia Code", monospace;
            }

            * { box-sizing: border-box; }

            body {
              margin: 0;
              min-height: 100vh;
              background:
                radial-gradient(circle at top left, rgba(47, 132, 247, 0.18), transparent 28%),
                radial-gradient(circle at top right, rgba(53, 201, 143, 0.12), transparent 24%),
                linear-gradient(180deg, var(--bg) 0%, #0c1d33 100%);
              color: var(--text);
              font-family: var(--font-sans);
            }

            button, input, textarea, select {
              font: inherit;
            }

            .page {
              width: min(1440px, 100%);
              margin: 0 auto;
              padding: 28px;
            }

            .topbar,
            .toolbar,
            .actions,
            .filters,
            .form-grid,
            .stats,
            .preview-row {
              display: flex;
              gap: 10px;
              flex-wrap: wrap;
            }

            .topbar {
              align-items: center;
              justify-content: space-between;
              margin-bottom: 18px;
            }

            .title {
              font-size: 30px;
              line-height: 1.1;
              font-weight: 780;
            }

            .subtitle {
              margin-top: 8px;
              color: var(--muted);
              line-height: 1.65;
            }

            .layout {
              display: grid;
              grid-template-columns: minmax(420px, 0.9fr) minmax(0, 1.5fr);
              gap: 18px;
              align-items: start;
            }

            .stats {
              display: grid;
              grid-template-columns: repeat(4, minmax(0, 1fr));
              gap: 12px;
              margin-bottom: 18px;
            }

            .stat {
              border: 1px solid var(--line);
              border-radius: 14px;
              background: rgba(255, 255, 255, 0.04);
              padding: 14px 16px;
            }

            .stat-label {
              color: var(--muted);
              font-size: 12px;
              text-transform: uppercase;
              letter-spacing: 0.04em;
            }

            .stat-value {
              margin-top: 8px;
              color: var(--text);
              font-size: 22px;
              font-weight: 760;
            }

            .panel {
              border: 1px solid var(--line);
              border-radius: 18px;
              background: var(--panel);
              box-shadow: var(--shadow);
              overflow: hidden;
            }

            .panel-header {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 12px;
              padding: 16px 18px;
              border-bottom: 1px solid var(--line);
              background: var(--panel-strong);
            }

            .panel-title {
              font-size: 15px;
              font-weight: 720;
            }

            .panel-subtitle {
              margin-top: 4px;
              color: var(--muted);
              font-size: 12px;
            }

            .panel-body {
              padding: 18px;
            }

            button {
              border: 1px solid transparent;
              border-radius: 12px;
              padding: 10px 14px;
              font-weight: 650;
              color: white;
              cursor: pointer;
              background: linear-gradient(135deg, var(--accent), var(--accent-strong));
              box-shadow: 0 10px 24px rgba(47, 132, 247, 0.24);
            }

            button:disabled {
              opacity: 0.55;
              cursor: not-allowed;
              box-shadow: none;
            }

            button.secondary {
              color: var(--text);
              background: rgba(255, 255, 255, 0.05);
              border-color: var(--line);
              box-shadow: none;
            }

            button.ghost {
              color: var(--muted-strong);
              background: transparent;
              border-color: var(--line);
              box-shadow: none;
            }

            button.danger {
              background: rgba(255, 107, 129, 0.12);
              border-color: rgba(255, 107, 129, 0.42);
              color: #ffd3da;
              box-shadow: none;
            }

            button.compact {
              min-width: 42px;
              min-height: 38px;
              padding: 8px 10px;
              border-radius: 10px;
            }

            button.toggle-on {
              color: #cbf7e6;
              background: rgba(53, 201, 143, 0.12);
              border-color: rgba(53, 201, 143, 0.44);
              box-shadow: none;
            }

            button.toggle-off {
              color: #ffe1b3;
              background: rgba(255, 190, 92, 0.12);
              border-color: rgba(255, 190, 92, 0.44);
              box-shadow: none;
            }

            label {
              display: block;
              margin-bottom: 8px;
              color: var(--muted);
              font-size: 12px;
              font-weight: 650;
              letter-spacing: 0.03em;
              text-transform: uppercase;
            }

            input, select, textarea {
              width: 100%;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.04);
              color: var(--text);
              outline: none;
              padding: 12px 14px;
            }

            textarea {
              min-height: 280px;
              resize: vertical;
              line-height: 1.65;
              font-family: var(--font-mono);
              font-size: 13px;
            }

            input:focus,
            select:focus,
            textarea:focus {
              border-color: rgba(93, 176, 255, 0.52);
              box-shadow: 0 0 0 4px rgba(93, 176, 255, 0.14);
            }

            .form-grid {
              display: grid;
              grid-template-columns: 120px minmax(0, 1fr) 140px;
              gap: 12px;
            }

            .field {
              min-width: 0;
            }

            .full {
              grid-column: 1 / -1;
            }

            .span-two {
              grid-column: span 2;
            }

            .list {
              display: flex;
              flex-direction: column;
              gap: 10px;
            }

            .mock-item {
              width: 100%;
              display: grid;
              grid-template-columns: auto minmax(0, 1fr) auto;
              gap: 12px;
              align-items: center;
              padding: 14px;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.03);
              color: inherit;
              box-shadow: none;
              text-align: left;
            }

            .mock-item:hover {
              border-color: rgba(93, 176, 255, 0.46);
              background: rgba(93, 176, 255, 0.07);
            }

            .mock-item.active {
              border-color: rgba(93, 176, 255, 0.6);
              background: rgba(93, 176, 255, 0.1);
            }

            .method {
              min-width: 68px;
              padding: 6px 8px;
              border-radius: 999px;
              border: 1px solid var(--line);
              color: var(--muted-strong);
              text-align: center;
              font-family: var(--font-mono);
              font-size: 12px;
              font-weight: 700;
            }

            .path {
              color: var(--text);
              font-family: var(--font-mono);
              font-size: 13px;
              word-break: break-all;
            }

            .meta {
              margin-top: 6px;
              color: var(--muted);
              font-size: 12px;
            }

            .mock-actions {
              display: flex;
              align-items: center;
              justify-content: flex-end;
              gap: 8px;
              min-width: 178px;
            }

            .alert {
              display: none;
              margin-bottom: 14px;
              padding: 13px 15px;
              border: 1px solid var(--line);
              border-radius: 14px;
              color: var(--muted-strong);
              background: rgba(255, 255, 255, 0.04);
            }

            .alert.show { display: block; }
            .alert.success { color: #cbf7e6; border-color: rgba(53, 201, 143, 0.36); background: rgba(53, 201, 143, 0.1); }
            .alert.danger { color: #ffd3da; border-color: rgba(255, 107, 129, 0.42); background: rgba(255, 107, 129, 0.1); }
            .empty { padding: 28px 12px; text-align: center; color: var(--muted); }
            .mono { font-family: var(--font-mono); }
            .hint { color: var(--muted); font-size: 12px; line-height: 1.7; }
            .template-row { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 10px; }
            .tester-result {
              margin-top: 12px;
              padding: 14px;
              border: 1px solid var(--line);
              border-radius: 14px;
              background: rgba(5, 11, 20, 0.35);
              color: var(--muted-strong);
              font-family: var(--font-mono);
              font-size: 12px;
              white-space: pre-wrap;
              word-break: break-word;
              max-height: 220px;
              overflow: auto;
            }
            .insights {
              margin-bottom: 18px;
              padding: 14px;
              border: 1px solid var(--line);
              border-radius: 14px;
              background: rgba(255, 255, 255, 0.025);
            }
            .insights-header {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 12px;
              margin-bottom: 12px;
            }
            .insights-title {
              font-size: 14px;
              font-weight: 720;
            }
            .insights-grid {
              display: grid;
              grid-template-columns: repeat(3, minmax(0, 1fr));
              gap: 10px;
              margin-bottom: 12px;
            }
            .mini-stat {
              min-height: 74px;
              border: 1px solid var(--line);
              border-radius: 12px;
              padding: 12px;
              background: rgba(5, 11, 20, 0.3);
            }
            .mini-stat-label {
              color: var(--muted);
              font-size: 11px;
              text-transform: uppercase;
              letter-spacing: 0.04em;
            }
            .mini-stat-value {
              margin-top: 8px;
              color: var(--text);
              font-size: 18px;
              font-weight: 760;
              word-break: break-word;
            }
            .request-log {
              display: flex;
              flex-direction: column;
              gap: 8px;
              max-height: 260px;
              overflow: auto;
            }
            .request-log-row {
              display: grid;
              grid-template-columns: minmax(120px, 0.45fr) minmax(110px, 0.5fr) minmax(0, 1fr) auto;
              gap: 10px;
              align-items: start;
              padding: 10px;
              border: 1px solid var(--line);
              border-radius: 12px;
              background: rgba(5, 11, 20, 0.26);
              font-family: var(--font-mono);
              font-size: 12px;
            }
            .request-log-time,
            .request-log-meta {
              color: var(--muted);
            }
            .request-log-ip,
            .request-log-path {
              color: var(--muted-strong);
              word-break: break-word;
            }
            .dirty {
              color: var(--warning);
            }

            @media (max-width: 980px) {
              .page { padding: 18px; }
              .layout { grid-template-columns: 1fr; }
              .form-grid { grid-template-columns: 1fr; }
              .span-two { grid-column: 1; }
              .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
              .mock-item { grid-template-columns: 1fr; }
              .mock-actions { justify-content: flex-start; min-width: 0; }
              .insights-grid { grid-template-columns: 1fr; }
              .request-log-row { grid-template-columns: 1fr; }
            }
          </style>
        </head>
        <body>
          <div class="page">
            <header class="topbar">
              <div>
                <div class="title">Mock API 管理</div>
                <div class="subtitle">用于管理测试专用 mock 响应。这里的配置会被 <span class="mono">MockAPIMiddleware</span> 命中并直接返回。</div>
              </div>
              <div class="actions">
                <button class="secondary" onclick="window.location.href='/debug/ui'">返回 SQLite Debug</button>
                <button class="secondary" onclick="window.location.href='/debug/image/ui'">图片生成</button>
                <button onclick="loadMocks()">刷新</button>
              </div>
            </header>

            <div id="alert" class="alert"></div>

            <section class="stats">
              <div class="stat">
                <div class="stat-label">Total</div>
                <div id="totalCount" class="stat-value">0</div>
              </div>
              <div class="stat">
                <div class="stat-label">Enabled</div>
                <div id="enabledCount" class="stat-value">0</div>
              </div>
              <div class="stat">
                <div class="stat-label">Disabled</div>
                <div id="disabledCount" class="stat-value">0</div>
              </div>
              <div class="stat">
                <div class="stat-label">Methods</div>
                <div id="methodCount" class="stat-value">0</div>
              </div>
            </section>

            <main class="layout">
              <section class="panel">
                <div class="panel-header">
                  <div>
                    <div class="panel-title">Mock 列表</div>
                    <div class="panel-subtitle">选择一条记录后可编辑、禁用或删除</div>
                  </div>
                  <button class="ghost" onclick="newMock()">新建</button>
                </div>
                <div class="panel-body">
                  <div class="filters">
                    <div class="field" style="flex: 1 1 220px;">
                      <label for="filterInput">Filter</label>
                      <input id="filterInput" type="search" placeholder="按 path / method 过滤" autocomplete="off" />
                    </div>
                    <div class="field" style="flex: 0 0 120px;">
                      <label for="methodFilterInput">Method</label>
                      <select id="methodFilterInput">
                        <option value="">全部</option>
                        <option>GET</option>
                        <option>POST</option>
                        <option>PUT</option>
                        <option>PATCH</option>
                        <option>DELETE</option>
                      </select>
                    </div>
                    <div class="field" style="flex: 0 0 120px;">
                      <label for="enabledFilterInput">Enabled</label>
                      <select id="enabledFilterInput">
                        <option value="">全部</option>
                        <option value="true">启用</option>
                        <option value="false">禁用</option>
                      </select>
                    </div>
                  </div>
                  <div id="mockList" class="list" style="margin-top: 14px;">
                    <div class="empty">Loading mocks...</div>
                  </div>
                </div>
              </section>

              <section class="panel">
                <div class="panel-header">
                  <div>
                    <div class="panel-title">编辑 Mock</div>
                    <div id="formSubtitle" class="panel-subtitle">正在创建新 mock</div>
                  </div>
                  <span id="selectedID" class="hint mono">new</span>
                </div>
                <div class="panel-body">
                  <section class="insights">
                    <div class="insights-header">
                      <div>
                        <div class="insights-title">请求观测</div>
                        <div class="hint">选中 mock 后查看命中次数、请求来源和最近访问记录</div>
                      </div>
                      <div class="actions">
                        <button class="ghost compact" onclick="loadSelectedMetrics()">刷新</button>
                        <button id="clearLogsButton" class="danger compact" onclick="clearSelectedLogs()" disabled>清空日志</button>
                      </div>
                    </div>
                    <div class="insights-grid">
                      <div class="mini-stat">
                        <div class="mini-stat-label">Total Requests</div>
                        <div id="mockRequestCount" class="mini-stat-value">-</div>
                      </div>
                      <div class="mini-stat">
                        <div class="mini-stat-label">Unique IPs</div>
                        <div id="mockUniqueIPCount" class="mini-stat-value">-</div>
                      </div>
                      <div class="mini-stat">
                        <div class="mini-stat-label">Last Hit</div>
                        <div id="mockLastHit" class="mini-stat-value">-</div>
                      </div>
                    </div>
                    <div id="requestLogList" class="request-log">
                      <div class="empty">选择一个 mock 后显示最近请求。</div>
                    </div>
                  </section>

                  <div class="form-grid">
                    <div class="field">
                      <label for="methodInput">Method</label>
                      <select id="methodInput">
                        <option>GET</option>
                        <option>POST</option>
                        <option>PUT</option>
                        <option>PATCH</option>
                        <option>DELETE</option>
                      </select>
                    </div>

                    <div class="field">
                      <label for="pathInput">Path</label>
                      <input id="pathInput" placeholder="/api/example" autocomplete="off" />
                    </div>

                    <div class="field">
                      <label for="statusInput">Status</label>
                      <input id="statusInput" type="number" min="100" max="599" value="200" />
                    </div>

                    <div class="field span-two">
                      <label for="contentTypeInput">Content-Type</label>
                      <select id="contentTypeInput">
                        <option value="application/json">application/json</option>
                        <option value="text/plain; charset=utf-8">text/plain; charset=utf-8</option>
                        <option value="text/html; charset=utf-8">text/html; charset=utf-8</option>
                        <option value="application/xml">application/xml</option>
                      </select>
                    </div>

                    <div class="field">
                      <label for="enabledInput">Enabled</label>
                      <select id="enabledInput">
                        <option value="true">启用</option>
                        <option value="false">禁用</option>
                      </select>
                    </div>

                    <div class="field">
                      <label>Preview</label>
                      <button class="secondary" onclick="openPreview()">打开路径</button>
                    </div>

                    <div class="field full">
                      <label for="bodyInput">Response Body</label>
                      <div class="template-row">
                        <button class="ghost compact" onclick="applyTemplate('success')">成功模板</button>
                        <button class="ghost compact" onclick="applyTemplate('list')">列表模板</button>
                        <button class="ghost compact" onclick="applyTemplate('error')">错误模板</button>
                      </div>
                      <textarea id="bodyInput" spellcheck="false">{"message":"mock response"}</textarea>
                    </div>
                  </div>

                  <div class="toolbar" style="margin-top: 14px;">
                    <button id="saveButton" onclick="saveMock()">保存</button>
                    <button class="secondary" onclick="formatJSON()">格式化 JSON</button>
                    <button class="secondary" onclick="copyCurl()">复制 curl</button>
                    <button class="secondary" onclick="duplicateSelected()">复制为新 Mock</button>
                    <button class="secondary" onclick="testSelected()">测试请求</button>
                    <button class="ghost" onclick="newMock()">清空表单</button>
                    <button id="deleteButton" class="danger" onclick="deleteSelected()" disabled>删除</button>
                  </div>

                  <div id="testerResult" class="tester-result">还没有执行测试请求。</div>

                  <div class="hint" style="margin-top: 14px;">
                    管理接口路径 <span class="mono">/debug/api/mocks</span> 不会被 mock 中间件拦截。JSON 类型会在保存前校验响应体。
                  </div>
                </div>
              </section>
            </main>
          </div>

          <script>
            const state = {
              mocks: [],
              selectedId: null,
              metrics: null,
              dirty: false
            };

            function escapeHtml(value) {
              if (value === null || value === undefined) return '';
              return String(value)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('"', '&quot;')
                .replaceAll("'", '&#039;');
            }

            async function fetchJSON(url, options = {}) {
              const res = await fetch(url, options);
              const text = await res.text();
              let data = null;

              if (text) {
                try {
                  data = JSON.parse(text);
                } catch {
                  throw new Error(text);
                }
              }

              if (!res.ok) {
                throw new Error((data && (data.reason || data.error)) || 'Request failed');
              }

              return data;
            }

            function showAlert(message, tone = 'success') {
              const alert = document.getElementById('alert');
              alert.textContent = message;
              alert.className = `alert show ${tone}`;
            }

            function hideAlert() {
              document.getElementById('alert').className = 'alert';
            }

            function setDirty(value) {
              state.dirty = value;
              const subtitle = document.getElementById('formSubtitle');
              const selected = selectedMock();
              const base = selected ? '正在编辑已有 mock' : '正在创建新 mock';
              subtitle.textContent = value ? `${base} · 有未保存修改` : base;
              subtitle.className = value ? 'panel-subtitle dirty' : 'panel-subtitle';
            }

            function normalizePath(value) {
              const trimmed = String(value || '').trim().replace(/^\\/+|\\/+$/g, '');
              return '/' + trimmed;
            }

            function payloadFromMock(mock, overrides = {}) {
              return {
                method: mock.method,
                path: mock.path,
                statusCode: mock.statusCode,
                contentType: mock.contentType,
                isEnabled: mock.isEnabled,
                responseBody: mock.responseBody,
                ...overrides
              };
            }

            function selectedMock() {
              return state.mocks.find(mock => mock.id === state.selectedId) || null;
            }

            function formatDateTime(value) {
              if (!value) return '-';
              const date = new Date(value);
              if (Number.isNaN(date.getTime())) return value;
              return date.toLocaleString();
            }

            function clearMetrics(message = '选择一个 mock 后显示最近请求。') {
              state.metrics = null;
              document.getElementById('mockRequestCount').textContent = '-';
              document.getElementById('mockUniqueIPCount').textContent = '-';
              document.getElementById('mockLastHit').textContent = '-';
              document.getElementById('clearLogsButton').disabled = true;
              document.getElementById('requestLogList').innerHTML = `<div class="empty">${escapeHtml(message)}</div>`;
            }

            function renderMetrics(metrics) {
              state.metrics = metrics;
              document.getElementById('mockRequestCount').textContent = metrics.totalRequests;
              document.getElementById('mockUniqueIPCount').textContent = metrics.uniqueIPCount;
              document.getElementById('mockLastHit').textContent = formatDateTime(metrics.lastRequestedAt);
              document.getElementById('clearLogsButton').disabled = !state.selectedId || metrics.totalRequests === 0;

              const list = document.getElementById('requestLogList');
              if (!metrics.recentRequests.length) {
                list.innerHTML = '<div class="empty">还没有请求命中这个 mock。</div>';
                return;
              }

              list.innerHTML = metrics.recentRequests.map(item => {
                const query = item.query ? `?${item.query}` : '';
                const agent = item.userAgent || '-';
                return `
                  <div class="request-log-row">
                    <div class="request-log-time">${escapeHtml(formatDateTime(item.requestedAt))}</div>
                    <div class="request-log-ip">${escapeHtml(item.requestIP)}</div>
                    <div>
                      <div class="request-log-path">${escapeHtml(item.method)} ${escapeHtml(item.path + query)}</div>
                      <div class="request-log-meta">${escapeHtml(agent)}</div>
                    </div>
                    <div class="method">${escapeHtml(item.statusCode)}</div>
                  </div>
                `;
              }).join('');
            }

            async function loadSelectedMetrics() {
              if (!state.selectedId) {
                clearMetrics();
                return;
              }

              document.getElementById('requestLogList').innerHTML = '<div class="empty">Loading request logs...</div>';
              try {
                const metrics = await fetchJSON(`/debug/api/mocks/${state.selectedId}/metrics`);
                renderMetrics(metrics);
              } catch (err) {
                clearMetrics(err.message);
                showAlert(err.message, 'danger');
              }
            }

            async function clearSelectedLogs() {
              if (!state.selectedId) return;
              if (!confirm('确认清空这个 mock 的请求日志吗？')) return;

              try {
                await fetchJSON(`/debug/api/mocks/${state.selectedId}/logs`, { method: 'DELETE' });
                await loadSelectedMetrics();
                showAlert('请求日志已清空', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            async function loadMocks() {
              const list = document.getElementById('mockList');
              list.innerHTML = '<div class="empty">Loading mocks...</div>';

              try {
                state.mocks = await fetchJSON('/debug/api/mocks');
                renderStats();
                renderList();
                hideAlert();
              } catch (err) {
                list.innerHTML = `<div class="empty">${escapeHtml(err.message)}</div>`;
                showAlert(err.message, 'danger');
              }
            }

            function renderStats() {
              const total = state.mocks.length;
              const enabled = state.mocks.filter(mock => mock.isEnabled).length;
              const methods = new Set(state.mocks.map(mock => mock.method)).size;

              document.getElementById('totalCount').textContent = total;
              document.getElementById('enabledCount').textContent = enabled;
              document.getElementById('disabledCount').textContent = total - enabled;
              document.getElementById('methodCount').textContent = methods;
            }

            function renderList() {
              const list = document.getElementById('mockList');
              const keyword = document.getElementById('filterInput').value.trim().toLowerCase();
              const method = document.getElementById('methodFilterInput').value;
              const enabled = document.getElementById('enabledFilterInput').value;
              const mocks = state.mocks.filter(mock => {
                const matchesKeyword = mock.path.toLowerCase().includes(keyword) || mock.method.toLowerCase().includes(keyword);
                const matchesMethod = !method || mock.method === method;
                const matchesEnabled = !enabled || String(mock.isEnabled) === enabled;
                return matchesKeyword && matchesMethod && matchesEnabled;
              });

              if (!mocks.length) {
                list.innerHTML = '<div class="empty">没有匹配的 mock</div>';
                return;
              }

              list.innerHTML = mocks.map(mock => {
                const active = mock.id === state.selectedId ? 'active' : '';
                const toggleClass = mock.isEnabled ? 'toggle-on' : 'toggle-off';
                const toggleText = mock.isEnabled ? '关闭' : '启用';

                return `
                  <div class="mock-item ${active}" data-id="${escapeHtml(mock.id)}" tabindex="0">
                    <span class="method">${escapeHtml(mock.method)}</span>
                    <span>
                      <div class="path">${escapeHtml(mock.path)}</div>
                    </span>
                    <span class="mock-actions">
                      <button class="secondary compact" data-action="visit" title="访问或测试这个 mock">访问</button>
                      <button class="${toggleClass} compact" data-action="toggle" title="立即${toggleText}这个 mock">${toggleText}</button>
                    </span>
                  </div>
                `;
              }).join('');
            }

            function setContentType(value) {
              const select = document.getElementById('contentTypeInput');
              const exists = Array.from(select.options).some(option => option.value === value);
              if (!exists && value) {
                const option = document.createElement('option');
                option.value = value;
                option.textContent = value;
                select.appendChild(option);
              }
              select.value = value || 'application/json';
            }

            function fillForm(mock) {
              state.selectedId = mock ? mock.id : null;
              document.getElementById('selectedID').textContent = mock ? mock.id : 'new';
              document.getElementById('methodInput').value = mock ? mock.method : 'GET';
              document.getElementById('pathInput').value = mock ? mock.path : '/api/example';
              document.getElementById('statusInput').value = mock ? mock.statusCode : 200;
              setContentType(mock ? mock.contentType : 'application/json');
              document.getElementById('enabledInput').value = mock && !mock.isEnabled ? 'false' : 'true';
              document.getElementById('bodyInput').value = mock ? mock.responseBody : '{\\n  "message": "mock response"\\n}';
              document.getElementById('deleteButton').disabled = !mock;
              document.getElementById('testerResult').textContent = '还没有执行测试请求。';
              if (mock) {
                loadSelectedMetrics();
              } else {
                clearMetrics();
              }
              setDirty(false);
              renderList();
            }

            function readForm() {
              return {
                method: document.getElementById('methodInput').value,
                path: normalizePath(document.getElementById('pathInput').value),
                statusCode: Number(document.getElementById('statusInput').value),
                contentType: document.getElementById('contentTypeInput').value.trim(),
                isEnabled: document.getElementById('enabledInput').value === 'true',
                responseBody: document.getElementById('bodyInput').value
              };
            }

            async function saveMock() {
              const payload = readForm();
              if (!payload.path || payload.path === '/') {
                showAlert('Path 不能为空，也不能只是 /。', 'danger');
                return;
              }

              const isEdit = Boolean(state.selectedId);
              const url = isEdit ? `/debug/api/mocks/${state.selectedId}` : '/debug/api/mocks';
              const method = isEdit ? 'PUT' : 'POST';

              try {
                const saved = await fetchJSON(url, {
                  method,
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify(payload)
                });

                await loadMocks();
                fillForm(saved);
                setDirty(false);
                showAlert('Mock 已保存', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            async function deleteSelected() {
              if (!state.selectedId) return;
              if (!confirm('确认删除这个 mock 吗？')) return;

              try {
                await fetchJSON(`/debug/api/mocks/${state.selectedId}`, { method: 'DELETE' });
                await loadMocks();
                newMock();
                showAlert('Mock 已删除', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            function newMock() {
              if (state.dirty && !confirm('当前表单有未保存修改，确认清空吗？')) return;
              fillForm(null);
            }

            function formatJSON() {
              const body = document.getElementById('bodyInput');
              try {
                body.value = JSON.stringify(JSON.parse(body.value), null, 2);
                showAlert('JSON 已格式化', 'success');
              } catch {
                showAlert('当前内容不是合法 JSON', 'danger');
              }
            }

            async function copyCurl() {
              const payload = readForm();
              const origin = window.location.origin;
              const bodyPart = ['GET', 'DELETE'].includes(payload.method)
                ? ''
                : ` \\\\\\n  -H 'Content-Type: ${payload.contentType}' \\\\\\n  -d '${payload.responseBody.replaceAll("'", "'\\\\''")}'`;
              const command = `curl -i -X ${payload.method} '${origin}${payload.path}'${bodyPart}`;

              try {
                await navigator.clipboard.writeText(command);
                showAlert('curl 已复制', 'success');
              } catch {
                showAlert(command, 'success');
              }
            }

            function openPreview() {
              const payload = readForm();
              if (payload.method !== 'GET') {
                showAlert('只有 GET mock 可以直接在浏览器打开预览。其他方法请复制 curl 测试。', 'danger');
                return;
              }

              window.open(payload.path, '_blank');
            }

            async function visitMock(mock) {
              if (mock.method === 'GET') {
                window.open(mock.path, '_blank');
                return;
              }

              await testMock(mock);
            }

            async function toggleMock(mock) {
              try {
                const saved = await fetchJSON(`/debug/api/mocks/${mock.id}`, {
                  method: 'PUT',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify(payloadFromMock(mock, { isEnabled: !mock.isEnabled }))
                });

                await loadMocks();
                if (state.selectedId === mock.id) fillForm(saved);
                if (state.selectedId === mock.id) await loadSelectedMetrics();
                showAlert(saved.isEnabled ? 'Mock 已启用' : 'Mock 已关闭', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            function duplicateSelected() {
              const mock = selectedMock();
              if (!mock) {
                showAlert('请先选择一个 mock。', 'danger');
                return;
              }

              fillForm({
                ...mock,
                id: null,
                path: `${mock.path}-copy`,
                isEnabled: false
              });
              setDirty(true);
              showAlert('已复制到表单，保存后会创建为新 mock。', 'success');
            }

            async function testSelected() {
              await testMock(readForm());
            }

            async function testMock(mock) {
              const result = document.getElementById('testerResult');
              result.textContent = 'Running request...';

              try {
                const options = {
                  method: mock.method,
                  headers: {}
                };

                if (!['GET', 'DELETE'].includes(mock.method)) {
                  options.headers['Content-Type'] = mock.contentType;
                  options.body = mock.responseBody;
                }

                const startedAt = performance.now();
                const res = await fetch(mock.path, options);
                const text = await res.text();
                const elapsed = Math.round(performance.now() - startedAt);
                result.textContent = [
                  `${res.status} ${res.statusText} · ${elapsed}ms`,
                  `content-type: ${res.headers.get('content-type') || '-'}`,
                  '',
                  text || '(empty body)'
                ].join('\\n');
                if (state.selectedId) await loadSelectedMetrics();
              } catch (err) {
                result.textContent = err.message || 'Request failed';
              }
            }

            function applyTemplate(name) {
              const statusInput = document.getElementById('statusInput');
              const bodyInput = document.getElementById('bodyInput');
              setContentType('application/json');

              if (name === 'success') {
                statusInput.value = 200;
                bodyInput.value = JSON.stringify({ errorCode: 0, errorMsg: '', data: { id: 1, name: 'mock item' } }, null, 2);
              } else if (name === 'list') {
                statusInput.value = 200;
                bodyInput.value = JSON.stringify({ errorCode: 0, errorMsg: '', data: [{ id: 1, title: 'mock item' }] }, null, 2);
              } else {
                statusInput.value = 500;
                bodyInput.value = JSON.stringify({ errorCode: 500, errorMsg: 'mock error', data: null }, null, 2);
              }

              setDirty(true);
            }

            document.getElementById('mockList').addEventListener('click', async event => {
              const item = event.target.closest('.mock-item');
              if (!item) return;

              const mock = state.mocks.find(candidate => candidate.id === item.dataset.id);
              if (!mock) return;

              const action = event.target.closest('[data-action]')?.dataset.action;
              if (action === 'visit') {
                await visitMock(mock);
                return;
              }
              if (action === 'toggle') {
                await toggleMock(mock);
                return;
              }

              if (state.dirty && state.selectedId !== mock.id && !confirm('当前表单有未保存修改，确认切换吗？')) return;
              fillForm(mock);
            });

            document.getElementById('filterInput').addEventListener('input', renderList);
            document.getElementById('methodFilterInput').addEventListener('change', renderList);
            document.getElementById('enabledFilterInput').addEventListener('change', renderList);

            ['methodInput', 'pathInput', 'statusInput', 'contentTypeInput', 'enabledInput', 'bodyInput'].forEach(id => {
              document.getElementById(id).addEventListener('input', () => setDirty(true));
              document.getElementById(id).addEventListener('change', () => setDirty(true));
            });

            loadMocks().then(() => {
              if (state.mocks.length > 0) {
                fillForm(state.mocks[0]);
              } else {
                newMock();
              }
            });
          </script>
        </body>
        </html>
        """
    }

    static func renderImageGeneratorHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>Image Generator Manager</title>
          <style>
            :root {
              --bg: #08111c;
              --panel: rgba(13, 23, 38, 0.95);
              --panel-strong: rgba(15, 30, 49, 0.98);
              --line: rgba(136, 160, 190, 0.22);
              --line-strong: rgba(136, 160, 190, 0.36);
              --text: #eef5ff;
              --muted: #91a6c2;
              --muted-strong: #bfd0e6;
              --accent: #43b7a8;
              --accent-strong: #2678e8;
              --success: #36c98d;
              --danger: #ff6e85;
              --warning: #ffc15c;
              --shadow: 0 18px 46px rgba(0, 0, 0, 0.28);
              --font-sans: "SF Pro Display", "Segoe UI", "Helvetica Neue", system-ui, sans-serif;
              --font-mono: "SFMono-Regular", "SF Mono", "IBM Plex Mono", "Cascadia Code", monospace;
            }

            * { box-sizing: border-box; }

            body {
              margin: 0;
              min-height: 100vh;
              background:
                linear-gradient(135deg, rgba(67, 183, 168, 0.14), transparent 30%),
                linear-gradient(225deg, rgba(38, 120, 232, 0.16), transparent 32%),
                linear-gradient(180deg, var(--bg) 0%, #111827 100%);
              color: var(--text);
              font-family: var(--font-sans);
            }

            button, input, textarea, select { font: inherit; }

            .page {
              width: min(1480px, 100%);
              margin: 0 auto;
              padding: 28px;
            }

            .topbar,
            .actions,
            .filters,
            .toolbar,
            .chips,
            .preview-actions {
              display: flex;
              gap: 10px;
              flex-wrap: wrap;
            }

            .topbar {
              align-items: center;
              justify-content: space-between;
              margin-bottom: 18px;
            }

            .title {
              font-size: 30px;
              line-height: 1.1;
              font-weight: 780;
            }

            .subtitle {
              margin-top: 8px;
              max-width: 900px;
              color: var(--muted);
              line-height: 1.65;
            }

            .stats {
              display: grid;
              grid-template-columns: repeat(4, minmax(0, 1fr));
              gap: 12px;
              margin-bottom: 18px;
            }

            .stat {
              border: 1px solid var(--line);
              border-radius: 14px;
              background: rgba(255, 255, 255, 0.04);
              padding: 14px 16px;
            }

            .stat-label {
              color: var(--muted);
              font-size: 12px;
              text-transform: uppercase;
              letter-spacing: 0.04em;
            }

            .stat-value {
              margin-top: 8px;
              font-size: 22px;
              font-weight: 760;
            }

            .layout {
              display: grid;
              grid-template-columns: minmax(420px, 0.9fr) minmax(0, 1.55fr);
              gap: 18px;
              align-items: start;
            }

            .panel {
              border: 1px solid var(--line);
              border-radius: 18px;
              background: var(--panel);
              box-shadow: var(--shadow);
              overflow: hidden;
            }

            .panel-header {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 12px;
              padding: 16px 18px;
              border-bottom: 1px solid var(--line);
              background: var(--panel-strong);
            }

            .panel-title {
              font-size: 15px;
              font-weight: 720;
            }

            .panel-subtitle {
              margin-top: 4px;
              color: var(--muted);
              font-size: 12px;
            }

            .panel-body { padding: 18px; }

            button {
              border: 1px solid transparent;
              border-radius: 12px;
              padding: 10px 14px;
              font-weight: 650;
              color: white;
              cursor: pointer;
              background: linear-gradient(135deg, var(--accent), var(--accent-strong));
              box-shadow: 0 10px 24px rgba(38, 120, 232, 0.2);
            }

            button:disabled {
              opacity: 0.55;
              cursor: not-allowed;
              box-shadow: none;
            }

            button.secondary {
              color: var(--text);
              background: rgba(255, 255, 255, 0.05);
              border-color: var(--line);
              box-shadow: none;
            }

            button.ghost {
              color: var(--muted-strong);
              background: transparent;
              border-color: var(--line);
              box-shadow: none;
            }

            button.danger {
              background: rgba(255, 110, 133, 0.12);
              border-color: rgba(255, 110, 133, 0.42);
              color: #ffd6dd;
              box-shadow: none;
            }

            button.toggle-on {
              color: #cdf7e5;
              background: rgba(54, 201, 141, 0.12);
              border-color: rgba(54, 201, 141, 0.44);
              box-shadow: none;
            }

            button.toggle-off {
              color: #ffe1b5;
              background: rgba(255, 193, 92, 0.12);
              border-color: rgba(255, 193, 92, 0.44);
              box-shadow: none;
            }

            button.compact {
              min-width: 42px;
              min-height: 38px;
              padding: 8px 10px;
              border-radius: 10px;
            }

            label {
              display: block;
              margin-bottom: 8px;
              color: var(--muted);
              font-size: 12px;
              font-weight: 650;
              letter-spacing: 0.03em;
              text-transform: uppercase;
            }

            input, select, textarea {
              width: 100%;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.04);
              color: var(--text);
              outline: none;
              padding: 12px 14px;
            }

            textarea {
              min-height: 76px;
              resize: vertical;
              line-height: 1.55;
            }

            input:focus,
            select:focus,
            textarea:focus {
              border-color: rgba(67, 183, 168, 0.56);
              box-shadow: 0 0 0 4px rgba(67, 183, 168, 0.14);
            }

            .form-grid {
              display: grid;
              grid-template-columns: repeat(4, minmax(0, 1fr));
              gap: 12px;
            }

            .field { min-width: 0; }
            .span-two { grid-column: span 2; }
            .full { grid-column: 1 / -1; }

            .list {
              display: flex;
              flex-direction: column;
              gap: 10px;
            }

            .preset-item {
              width: 100%;
              display: grid;
              grid-template-columns: 58px minmax(0, 1fr) auto;
              gap: 12px;
              align-items: center;
              padding: 14px;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.03);
              color: inherit;
              box-shadow: none;
              text-align: left;
            }

            .preset-item:hover {
              border-color: rgba(67, 183, 168, 0.48);
              background: rgba(67, 183, 168, 0.07);
            }

            .preset-item.active {
              border-color: rgba(67, 183, 168, 0.64);
              background: rgba(67, 183, 168, 0.1);
            }

            .thumb {
              width: 58px;
              height: 42px;
              border-radius: 10px;
              border: 1px solid var(--line-strong);
              background: #1f2937;
              object-fit: cover;
            }

            .preset-name {
              font-weight: 720;
              word-break: break-word;
            }

            .meta {
              margin-top: 6px;
              color: var(--muted);
              font-size: 12px;
              line-height: 1.45;
              word-break: break-word;
            }

            .badge {
              display: inline-flex;
              align-items: center;
              gap: 6px;
              border-radius: 999px;
              border: 1px solid var(--line);
              padding: 5px 8px;
              color: var(--muted-strong);
              font-size: 12px;
            }

            .badge.off {
              color: #ffe1b5;
              border-color: rgba(255, 193, 92, 0.4);
              background: rgba(255, 193, 92, 0.1);
            }

            .preview-shell {
              display: grid;
              gap: 12px;
              padding: 14px;
              border: 1px solid var(--line);
              border-radius: 16px;
              background: rgba(5, 11, 20, 0.3);
            }

            .preview-frame {
              min-height: 280px;
              display: grid;
              place-items: center;
              border-radius: 14px;
              border: 1px solid var(--line);
              background:
                linear-gradient(45deg, rgba(255,255,255,0.04) 25%, transparent 25%),
                linear-gradient(-45deg, rgba(255,255,255,0.04) 25%, transparent 25%),
                linear-gradient(45deg, transparent 75%, rgba(255,255,255,0.04) 75%),
                linear-gradient(-45deg, transparent 75%, rgba(255,255,255,0.04) 75%);
              background-size: 24px 24px;
              background-position: 0 0, 0 12px, 12px -12px, -12px 0;
              overflow: hidden;
            }

            .preview-frame img {
              display: block;
              max-width: 100%;
              max-height: 520px;
              border-radius: 12px;
              box-shadow: 0 14px 36px rgba(0, 0, 0, 0.28);
            }

            .url-box {
              padding: 12px;
              border: 1px solid var(--line);
              border-radius: 12px;
              color: var(--muted-strong);
              background: rgba(255, 255, 255, 0.035);
              font-family: var(--font-mono);
              font-size: 12px;
              line-height: 1.55;
              word-break: break-all;
            }

            .alert {
              display: none;
              margin-bottom: 14px;
              padding: 13px 15px;
              border: 1px solid var(--line);
              border-radius: 14px;
              color: var(--muted-strong);
              background: rgba(255, 255, 255, 0.04);
            }

            .alert.show { display: block; }
            .alert.success { color: #cdf7e5; border-color: rgba(54, 201, 141, 0.36); background: rgba(54, 201, 141, 0.1); }
            .alert.danger { color: #ffd6dd; border-color: rgba(255, 110, 133, 0.42); background: rgba(255, 110, 133, 0.1); }
            .empty { padding: 28px 12px; text-align: center; color: var(--muted); }
            .hint { color: var(--muted); font-size: 12px; line-height: 1.7; }
            .mono { font-family: var(--font-mono); }
            .dirty { color: var(--warning); }

            @media (max-width: 1080px) {
              .page { padding: 18px; }
              .layout { grid-template-columns: 1fr; }
              .form-grid { grid-template-columns: 1fr; }
              .span-two { grid-column: 1; }
              .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
              .preset-item { grid-template-columns: 1fr; }
              .thumb { width: 100%; height: 120px; }
            }
          </style>
        </head>
        <body>
          <div class="page">
            <header class="topbar">
              <div>
                <div class="title">Image Generator 管理</div>
                <div class="subtitle">
                  管理 URL 驱动的图片生成模板，覆盖纯色、渐变、MeshGradient、文本、形状、边框和输出格式。
                  模板保存后可直接复制图片 URL 给前端、设计稿或 Mock API 使用。
                </div>
              </div>
              <div class="actions">
                <button class="secondary" onclick="window.location.href='/debug/ui'">SQLite Debug</button>
                <button class="secondary" onclick="window.location.href='/debug/mock/ui'">Mock 管理</button>
                <button onclick="loadPresets()">刷新</button>
              </div>
            </header>

            <div id="alert" class="alert"></div>

            <section class="stats">
              <div class="stat">
                <div class="stat-label">Total Presets</div>
                <div id="totalCount" class="stat-value">0</div>
              </div>
              <div class="stat">
                <div class="stat-label">Enabled</div>
                <div id="enabledCount" class="stat-value">0</div>
              </div>
              <div class="stat">
                <div class="stat-label">Mesh</div>
                <div id="meshCount" class="stat-value">0</div>
              </div>
              <div class="stat">
                <div class="stat-label">Formats</div>
                <div id="formatCount" class="stat-value">0</div>
              </div>
            </section>

            <main class="layout">
              <section class="panel">
                <div class="panel-header">
                  <div>
                    <div class="panel-title">生成模板</div>
                    <div class="panel-subtitle">按业务用途维护可复用图片配置</div>
                  </div>
                  <button class="ghost" onclick="newPreset()">新建</button>
                </div>
                <div class="panel-body">
                  <div class="filters">
                    <div class="field" style="flex: 1 1 220px;">
                      <label for="filterInput">Filter</label>
                      <input id="filterInput" type="search" placeholder="按名称 / 主题 / 描述过滤" autocomplete="off" />
                    </div>
                    <div class="field" style="flex: 0 0 140px;">
                      <label for="backgroundFilterInput">Background</label>
                      <select id="backgroundFilterInput">
                        <option value="">全部</option>
                        <option value="solid">纯色</option>
                        <option value="gradient">渐变</option>
                        <option value="mesh">Mesh</option>
                      </select>
                    </div>
                    <div class="field" style="flex: 0 0 120px;">
                      <label for="enabledFilterInput">Enabled</label>
                      <select id="enabledFilterInput">
                        <option value="">全部</option>
                        <option value="true">启用</option>
                        <option value="false">停用</option>
                      </select>
                    </div>
                  </div>
                  <div id="presetList" class="list" style="margin-top: 14px;">
                    <div class="empty">Loading presets...</div>
                  </div>
                </div>
              </section>

              <section class="panel">
                <div class="panel-header">
                  <div>
                    <div class="panel-title">编辑图片模板</div>
                    <div id="formSubtitle" class="panel-subtitle">正在创建新模板</div>
                  </div>
                  <span id="selectedID" class="hint mono">new</span>
                </div>
                <div class="panel-body">
                  <div class="preview-shell" style="margin-bottom: 16px;">
                    <div class="preview-frame">
                      <img id="previewImage" alt="Image generator preview" />
                    </div>
                    <div id="previewURL" class="url-box"></div>
                    <div class="preview-actions">
                      <button class="secondary" onclick="refreshPreview()">刷新预览</button>
                      <button class="secondary" onclick="openPreview()">打开图片</button>
                      <button class="secondary" onclick="copyURL()">复制 URL</button>
                      <button class="secondary" onclick="copyMarkdown()">复制 Markdown</button>
                    </div>
                  </div>

                  <div class="form-grid">
                    <div class="field span-two">
                      <label for="nameInput">Name</label>
                      <input id="nameInput" placeholder="mesh-sunset-card" autocomplete="off" />
                    </div>
                    <div class="field">
                      <label for="enabledInput">Enabled</label>
                      <select id="enabledInput">
                        <option value="true">启用</option>
                        <option value="false">停用</option>
                      </select>
                    </div>
                    <div class="field">
                      <label for="formatInput">Format</label>
                      <select id="formatInput">
                        <option value="png">png</option>
                        <option value="jpg">jpg</option>
                      </select>
                    </div>

                    <div class="field full">
                      <label for="descriptionInput">Description</label>
                      <textarea id="descriptionInput" placeholder="用于首页卡片、头像背景、封面图等场景"></textarea>
                    </div>

                    <div class="field">
                      <label for="widthInput">Width</label>
                      <input id="widthInput" type="number" min="1" max="4096" value="800" />
                    </div>
                    <div class="field">
                      <label for="heightInput">Height</label>
                      <input id="heightInput" type="number" min="1" max="4096" value="400" />
                    </div>
                    <div class="field">
                      <label for="shapeInput">Shape</label>
                      <select id="shapeInput">
                        <option value="rect">rect</option>
                        <option value="circle">circle</option>
                      </select>
                    </div>
                    <div class="field">
                      <label for="radiusInput">Radius</label>
                      <input id="radiusInput" type="number" min="0" max="2048" value="0" />
                    </div>

                    <div class="field">
                      <label for="backgroundInput">Background</label>
                      <select id="backgroundInput">
                        <option value="solid">solid</option>
                        <option value="gradient">gradient</option>
                        <option value="mesh">mesh</option>
                      </select>
                    </div>
                    <div class="field">
                      <label for="themeInput">Mesh Theme</label>
                      <select id="themeInput">
                        <option value="sunset">sunset</option>
                        <option value="aurora">aurora</option>
                        <option value="ocean">ocean</option>
                        <option value="candy">candy</option>
                        <option value="neon">neon</option>
                        <option value="forest">forest</option>
                        <option value="grape">grape</option>
                      </select>
                    </div>
                    <div class="field">
                      <label for="fromColorInput">From / Solid</label>
                      <input id="fromColorInput" placeholder="ff6b6b" autocomplete="off" />
                    </div>
                    <div class="field">
                      <label for="toColorInput">To</label>
                      <input id="toColorInput" placeholder="4d96ff" autocomplete="off" />
                    </div>

                    <div class="field span-two">
                      <label for="textInput">Text</label>
                      <input id="textInput" placeholder="Profile" autocomplete="off" />
                    </div>
                    <div class="field">
                      <label for="foregroundInput">Foreground</label>
                      <input id="foregroundInput" placeholder="ffffff" autocomplete="off" />
                    </div>
                    <div class="field">
                      <label for="borderColorInput">Border Color</label>
                      <input id="borderColorInput" placeholder="ffffff" autocomplete="off" />
                    </div>

                    <div class="field">
                      <label for="borderWidthInput">Border Width</label>
                      <input id="borderWidthInput" type="number" min="0" max="128" value="0" />
                    </div>
                    <div class="field span-two">
                      <label>Quick Presets</label>
                      <div class="chips">
                        <button class="ghost compact" onclick="applyQuickPreset('avatar')">头像</button>
                        <button class="ghost compact" onclick="applyQuickPreset('hero')">封面</button>
                        <button class="ghost compact" onclick="applyQuickPreset('card')">卡片</button>
                        <button class="ghost compact" onclick="applyQuickPreset('error')">错误图</button>
                      </div>
                    </div>
                  </div>

                  <div class="toolbar" style="margin-top: 14px;">
                    <button id="saveButton" onclick="savePreset()">保存</button>
                    <button class="secondary" onclick="duplicateSelected()">复制为新模板</button>
                    <button class="secondary" onclick="newPreset()">清空表单</button>
                    <button id="deleteButton" class="danger" onclick="deleteSelected()" disabled>删除</button>
                  </div>

                  <div class="hint" style="margin-top: 14px;">
                    图片生成运行时路径是 <span class="mono">/img/:size</span>。这里保存的是团队可复用模板，当前不会拦截或覆盖运行时图片接口。
                  </div>
                </div>
              </section>
            </main>
          </div>

          <script>
            const state = {
              presets: [],
              selectedId: null,
              dirty: false
            };

            function escapeHtml(value) {
              if (value === null || value === undefined) return '';
              return String(value)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('"', '&quot;')
                .replaceAll("'", '&#039;');
            }

            async function fetchJSON(url, options = {}) {
              const res = await fetch(url, options);
              const text = await res.text();
              let data = null;

              if (text) {
                try {
                  data = JSON.parse(text);
                } catch {
                  throw new Error(text);
                }
              }

              if (!res.ok) {
                throw new Error((data && (data.reason || data.error)) || 'Request failed');
              }

              return data;
            }

            function showAlert(message, tone = 'success') {
              const alert = document.getElementById('alert');
              alert.textContent = message;
              alert.className = `alert show ${tone}`;
            }

            function hideAlert() {
              document.getElementById('alert').className = 'alert';
            }

            function selectedPreset() {
              return state.presets.find(preset => preset.id === state.selectedId) || null;
            }

            function setDirty(value) {
              state.dirty = value;
              const subtitle = document.getElementById('formSubtitle');
              const selected = selectedPreset();
              const base = selected ? '正在编辑已有模板' : '正在创建新模板';
              subtitle.textContent = value ? `${base} · 有未保存修改` : base;
              subtitle.className = value ? 'panel-subtitle dirty' : 'panel-subtitle';
            }

            function cleanHex(value, fallback) {
              const raw = String(value || fallback || '').trim().replace(/^#/, '');
              return raw || fallback;
            }

            function presetURL(preset, absolute = false) {
              if (preset.publicURL && preset.isEnabled) {
                return absolute ? `${window.location.origin}${preset.publicURL}` : preset.publicURL;
              }

              if (preset.imageURL) {
                return absolute ? `${window.location.origin}${preset.imageURL}` : preset.imageURL;
              }

              const params = new URLSearchParams();
              const background = preset.background === 'solid' ? cleanHex(preset.fromColor, 'e5e7eb') : preset.background;
              params.set('bg', background);
              params.set('fg', cleanHex(preset.foreground, '111827'));
              params.set('shape', preset.shape || 'rect');
              params.set('format', preset.format || 'png');

              if (preset.text) params.set('text', preset.text);
              if (Number(preset.radius) > 0) params.set('radius', String(preset.radius));
              if (Number(preset.borderWidth) > 0) {
                params.set('border', String(preset.borderWidth));
                params.set('borderColor', cleanHex(preset.borderColor, '111827'));
              }

              if (preset.background === 'gradient' || preset.background === 'linear') {
                params.set('from', cleanHex(preset.fromColor, 'ff6b6b'));
                params.set('to', cleanHex(preset.toColor, '4d96ff'));
              }

              if (preset.background === 'mesh') {
                params.set('theme', preset.theme || 'sunset');
              }

              const path = `/img/${preset.width}x${preset.height}?${params.toString()}`;
              return absolute ? `${window.location.origin}${path}` : path;
            }

            function previewSource(preset) {
              return preset.snapshotURL || presetURL(preset);
            }

            function publicPresetURL(preset, absolute = false) {
              if (preset.publicURL) {
                return absolute ? `${window.location.origin}${preset.publicURL}` : preset.publicURL;
              }
              return presetURL(preset, absolute);
            }

            function readForm() {
              return {
                name: document.getElementById('nameInput').value.trim(),
                description: document.getElementById('descriptionInput').value.trim(),
                width: Number(document.getElementById('widthInput').value),
                height: Number(document.getElementById('heightInput').value),
                background: document.getElementById('backgroundInput').value,
                fromColor: cleanHex(document.getElementById('fromColorInput').value, 'e5e7eb'),
                toColor: cleanHex(document.getElementById('toColorInput').value, '4d96ff'),
                theme: document.getElementById('themeInput').value,
                foreground: cleanHex(document.getElementById('foregroundInput').value, '111827'),
                text: document.getElementById('textInput').value.trim() || null,
                shape: document.getElementById('shapeInput').value,
                borderWidth: Number(document.getElementById('borderWidthInput').value),
                borderColor: cleanHex(document.getElementById('borderColorInput').value, '111827'),
                radius: Number(document.getElementById('radiusInput').value),
                format: document.getElementById('formatInput').value,
                isEnabled: document.getElementById('enabledInput').value === 'true'
              };
            }

            function renderPreview() {
              const preset = readForm();
              const url = presetURL(preset);
              document.getElementById('previewURL').textContent = url;
              document.getElementById('previewImage').src = `${url}&_t=${Date.now()}`;
            }

            function refreshPreview() {
              renderPreview();
              showAlert('预览已刷新', 'success');
            }

            async function loadPresets() {
              const list = document.getElementById('presetList');
              list.innerHTML = '<div class="empty">Loading presets...</div>';

              try {
                state.presets = await fetchJSON('/debug/api/image-presets');
                renderStats();
                renderList();
                hideAlert();
              } catch (err) {
                list.innerHTML = `<div class="empty">${escapeHtml(err.message)}</div>`;
                showAlert(err.message, 'danger');
              }
            }

            function renderStats() {
              const total = state.presets.length;
              const enabled = state.presets.filter(preset => preset.isEnabled).length;
              const mesh = state.presets.filter(preset => preset.background === 'mesh').length;
              const formats = new Set(state.presets.map(preset => preset.format)).size;

              document.getElementById('totalCount').textContent = total;
              document.getElementById('enabledCount').textContent = enabled;
              document.getElementById('meshCount').textContent = mesh;
              document.getElementById('formatCount').textContent = formats;
            }

            function renderList() {
              const list = document.getElementById('presetList');
              const keyword = document.getElementById('filterInput').value.trim().toLowerCase();
              const background = document.getElementById('backgroundFilterInput').value;
              const enabled = document.getElementById('enabledFilterInput').value;
              const presets = state.presets.filter(preset => {
                const text = [preset.name, preset.description, preset.theme, preset.text, preset.background].join(' ').toLowerCase();
                const matchesKeyword = text.includes(keyword);
                const matchesBackground = !background || preset.background === background;
                const matchesEnabled = !enabled || String(preset.isEnabled) === enabled;
                return matchesKeyword && matchesBackground && matchesEnabled;
              });

              if (!presets.length) {
                list.innerHTML = '<div class="empty">没有匹配的图片模板</div>';
                return;
              }

              list.innerHTML = presets.map(preset => {
                const active = preset.id === state.selectedId ? 'active' : '';
                const status = preset.isEnabled ? '<span class="badge">启用</span>' : '<span class="badge off">停用</span>';
                const toggleClass = preset.isEnabled ? 'toggle-on' : 'toggle-off';
                const toggleText = preset.isEnabled ? '关闭' : '启用';
                const storage = preset.snapshotStorage === 'file' ? 'File' : 'DB';
                const snapshot = preset.snapshotBytes ? ` · ${storage} ${Math.round(preset.snapshotBytes / 1024)}KB` : '';
                const meta = `${preset.width}x${preset.height} · ${preset.background}${preset.theme ? `/${preset.theme}` : ''} · ${preset.format}${snapshot}`;
                return `
                  <div class="preset-item ${active}" data-id="${escapeHtml(preset.id)}" tabindex="0">
                    <img class="thumb" src="${escapeHtml(previewSource(preset))}" alt="" loading="lazy" />
                    <span>
                      <div class="preset-name">${escapeHtml(preset.name)}</div>
                      <div class="meta">${escapeHtml(meta)}</div>
                      <div class="meta">${escapeHtml(preset.description || 'No description')}</div>
                    </span>
                    <span class="chips">
                      ${status}
                      <button class="secondary compact" data-action="open">打开</button>
                      <button class="${toggleClass} compact" data-action="toggle">${toggleText}</button>
                    </span>
                  </div>
                `;
              }).join('');
            }

            function fillForm(preset) {
              state.selectedId = preset ? preset.id : null;
              document.getElementById('selectedID').textContent = preset ? preset.id : 'new';
              document.getElementById('nameInput').value = preset ? preset.name : 'mesh-sunset-card';
              document.getElementById('descriptionInput').value = preset ? preset.description : '用于 UI 调试的 MeshGradient 卡片背景';
              document.getElementById('widthInput').value = preset ? preset.width : 800;
              document.getElementById('heightInput').value = preset ? preset.height : 400;
              document.getElementById('backgroundInput').value = preset ? preset.background : 'mesh';
              document.getElementById('fromColorInput').value = preset ? (preset.fromColor || 'ff6b6b') : 'ff6b6b';
              document.getElementById('toColorInput').value = preset ? (preset.toColor || '4d96ff') : '4d96ff';
              document.getElementById('themeInput').value = preset ? (preset.theme || 'sunset') : 'sunset';
              document.getElementById('foregroundInput').value = preset ? preset.foreground : 'ffffff';
              document.getElementById('textInput').value = preset ? (preset.text || '') : 'Preview';
              document.getElementById('shapeInput').value = preset ? preset.shape : 'rect';
              document.getElementById('borderWidthInput').value = preset ? preset.borderWidth : 0;
              document.getElementById('borderColorInput').value = preset ? preset.borderColor : 'ffffff';
              document.getElementById('radiusInput').value = preset ? preset.radius : 16;
              document.getElementById('formatInput').value = preset ? preset.format : 'png';
              document.getElementById('enabledInput').value = preset && !preset.isEnabled ? 'false' : 'true';
              document.getElementById('deleteButton').disabled = !preset;
              setDirty(false);
              renderPreview();
              renderList();
            }

            function payloadFromPreset(preset, overrides = {}) {
              return {
                name: preset.name,
                description: preset.description,
                width: preset.width,
                height: preset.height,
                background: preset.background,
                fromColor: preset.fromColor,
                toColor: preset.toColor,
                theme: preset.theme,
                foreground: preset.foreground,
                text: preset.text,
                shape: preset.shape,
                borderWidth: preset.borderWidth,
                borderColor: preset.borderColor,
                radius: preset.radius,
                format: preset.format,
                isEnabled: preset.isEnabled,
                ...overrides
              };
            }

            async function savePreset() {
              const payload = readForm();
              if (!payload.name) {
                showAlert('Name 不能为空。', 'danger');
                return;
              }

              const isEdit = Boolean(state.selectedId);
              const url = isEdit ? `/debug/api/image-presets/${state.selectedId}` : '/debug/api/image-presets';
              const method = isEdit ? 'PUT' : 'POST';

              try {
                const saved = await fetchJSON(url, {
                  method,
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify(payload)
                });

                await loadPresets();
                fillForm(saved);
                showAlert('图片模板已保存', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            async function deleteSelected() {
              if (!state.selectedId) return;
              if (!confirm('确认删除这个图片模板吗？')) return;

              try {
                await fetchJSON(`/debug/api/image-presets/${state.selectedId}`, { method: 'DELETE' });
                await loadPresets();
                newPreset();
                showAlert('图片模板已删除', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            async function togglePreset(preset) {
              try {
                const saved = await fetchJSON(`/debug/api/image-presets/${preset.id}`, {
                  method: 'PUT',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify(payloadFromPreset(preset, { isEnabled: !preset.isEnabled }))
                });

                await loadPresets();
                if (state.selectedId === preset.id) fillForm(saved);
                showAlert(saved.isEnabled ? '图片模板已启用' : '图片模板已关闭', 'success');
              } catch (err) {
                showAlert(err.message, 'danger');
              }
            }

            function newPreset() {
              if (state.dirty && !confirm('当前表单有未保存修改，确认清空吗？')) return;
              fillForm(null);
            }

            function duplicateSelected() {
              const preset = selectedPreset();
              if (!preset) {
                showAlert('请先选择一个图片模板。', 'danger');
                return;
              }

              fillForm({
                ...preset,
                id: null,
                name: `${preset.name}-copy`,
                isEnabled: false
              });
              setDirty(true);
              showAlert('已复制到表单，保存后会创建为新模板。', 'success');
            }

            function applyQuickPreset(name) {
              const presets = {
                avatar: {
                  name: 'avatar-mesh-aurora',
                  description: '头像和用户占位图背景',
                  width: 300,
                  height: 300,
                  background: 'mesh',
                  theme: 'aurora',
                  text: 'AI',
                  shape: 'circle',
                  radius: 0,
                  borderWidth: 4,
                  borderColor: 'ffffff',
                  foreground: 'ffffff'
                },
                hero: {
                  name: 'hero-mesh-sunset',
                  description: '首页和活动页大尺寸封面',
                  width: 1200,
                  height: 480,
                  background: 'mesh',
                  theme: 'sunset',
                  text: 'Dev Toolkit',
                  shape: 'rect',
                  radius: 24,
                  borderWidth: 0,
                  borderColor: 'ffffff',
                  foreground: 'ffffff'
                },
                card: {
                  name: 'dashboard-card-ocean',
                  description: 'Dashboard 卡片背景',
                  width: 800,
                  height: 500,
                  background: 'mesh',
                  theme: 'ocean',
                  text: 'Preview',
                  shape: 'rect',
                  radius: 18,
                  borderWidth: 1,
                  borderColor: 'dbeafe',
                  foreground: 'ffffff'
                },
                error: {
                  name: 'error-state-gradient',
                  description: '错误状态和空状态占位图',
                  width: 640,
                  height: 360,
                  background: 'gradient',
                  fromColor: 'ff6b81',
                  toColor: '111827',
                  text: 'Error',
                  shape: 'rect',
                  radius: 16,
                  borderWidth: 0,
                  borderColor: 'ffffff',
                  foreground: 'ffffff'
                }
              };

              const preset = { ...readForm(), ...presets[name], id: state.selectedId, isEnabled: true, format: 'png' };
              fillForm(preset);
              state.selectedId = null;
              document.getElementById('selectedID').textContent = 'new';
              document.getElementById('deleteButton').disabled = true;
              setDirty(true);
            }

            function openPreview() {
              const preset = selectedPreset();
              window.open(preset ? publicPresetURL(preset) : presetURL(readForm()), '_blank');
            }

            async function copyURL() {
              const preset = selectedPreset();
              const url = preset ? publicPresetURL(preset, true) : presetURL(readForm(), true);
              try {
                await navigator.clipboard.writeText(url);
                showAlert('图片 URL 已复制', 'success');
              } catch {
                showAlert(url, 'success');
              }
            }

            async function copyMarkdown() {
              const preset = readForm();
              const selected = selectedPreset();
              const markdown = `![${preset.name}](${selected ? publicPresetURL(selected, true) : presetURL(preset, true)})`;
              try {
                await navigator.clipboard.writeText(markdown);
                showAlert('Markdown 已复制', 'success');
              } catch {
                showAlert(markdown, 'success');
              }
            }

            document.getElementById('presetList').addEventListener('click', event => {
              const item = event.target.closest('.preset-item');
              if (!item) return;

              const preset = state.presets.find(candidate => candidate.id === item.dataset.id);
              if (!preset) return;

              const action = event.target.closest('[data-action]')?.dataset.action;
              if (action === 'open') {
                window.open(publicPresetURL(preset), '_blank');
                return;
              }
              if (action === 'toggle') {
                togglePreset(preset);
                return;
              }

              if (state.dirty && state.selectedId !== preset.id && !confirm('当前表单有未保存修改，确认切换吗？')) return;
              fillForm(preset);
            });

            document.getElementById('filterInput').addEventListener('input', renderList);
            document.getElementById('backgroundFilterInput').addEventListener('change', renderList);
            document.getElementById('enabledFilterInput').addEventListener('change', renderList);

            [
              'nameInput',
              'descriptionInput',
              'widthInput',
              'heightInput',
              'backgroundInput',
              'themeInput',
              'fromColorInput',
              'toColorInput',
              'foregroundInput',
              'textInput',
              'shapeInput',
              'borderWidthInput',
              'borderColorInput',
              'radiusInput',
              'formatInput',
              'enabledInput'
            ].forEach(id => {
              const element = document.getElementById(id);
              element.addEventListener('input', () => {
                setDirty(true);
                renderPreview();
              });
              element.addEventListener('change', () => {
                setDirty(true);
                renderPreview();
              });
            });

            loadPresets().then(() => {
              if (state.presets.length > 0) {
                fillForm(state.presets[0]);
              } else {
                newPreset();
              }
            });
          </script>
        </body>
        </html>
        """
    }

    private static func htmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#039;")
    }
}
