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

            .table-item {
              padding: 14px 15px;
              border-radius: 14px;
              border: 1px solid var(--line);
              background: rgba(255, 255, 255, 0.03);
              cursor: pointer;
              transition: border-color 0.16s ease, transform 0.16s ease, background 0.16s ease;
            }

            .table-item:hover {
              transform: translateY(-1px);
              border-color: rgba(93, 176, 255, 0.42);
              background: rgba(93, 176, 255, 0.08);
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
                <button onclick="loadTables()">刷新表列表</button>
                <button class="secondary" onclick="fillCurrentTableQuery()">快速填充查询</button>
              </div>

              <div id="tableList" class="table-list">
                <div class="empty">Loading tables...</div>
              </div>
            </aside>

            <main class="main">
              <div class="main-grid">
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
                          <button onclick="reloadCurrentTable()">加载当前页</button>
                        </div>

                        <div class="field">
                          <button class="secondary" onclick="prevPage()">上一页</button>
                        </div>

                        <div class="field">
                          <button class="secondary" onclick="nextPage()">下一页</button>
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
            let currentTable = null;

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
              tableList.innerHTML = '<div class="empty">Loading tables...</div>';

              try {
                const data = await fetchJSON('/debug/api/tables');
                if (!data.tables.length) {
                  tableList.innerHTML = '<div class="empty">No tables found</div>';
                  return;
                }

                tableList.innerHTML = data.tables.map(name => {
                  const active = name === currentTable ? 'active' : '';
                  return `
                    <div class="table-item ${active}" onclick="selectTable(${JSON.stringify(name)})">
                      <div class="table-name">${escapeHtml(name)}</div>
                      <div class="table-hint">点击查看结构与分页数据</div>
                    </div>
                  `;
                }).join('');

                if (!currentTable && data.tables.length > 0) {
                  await selectTable(data.tables[0]);
                }
              } catch (err) {
                tableList.innerHTML = `<div class="empty danger-text">${escapeHtml(err.message)}</div>`;
              }
            }

            async function selectTable(tableName) {
              currentTable = tableName;
              document.getElementById('currentTableName').textContent = tableName;
              document.getElementById('pageInput').value = 1;
              await loadTables();
              await loadSchema(tableName);
              await loadTableData(tableName);
            }

            async function loadSchema(tableName) {
              const wrap = document.getElementById('schemaWrap');
              wrap.innerHTML = '<div class="empty">Loading schema...</div>';

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
                wrap.innerHTML = `<div class="empty danger-text">${escapeHtml(err.message)}</div>`;
              }
            }

            async function loadTableData(tableName) {
              const wrap = document.getElementById('tableWrap');
              wrap.innerHTML = '<div class="empty">Loading rows...</div>';

              const page = Number(document.getElementById('pageInput').value || 1);
              const pageSize = Number(document.getElementById('pageSizeInput').value || 50);

              try {
                const data = await fetchJSON(`/debug/api/tables/${encodeURIComponent(tableName)}?page=${page}&pageSize=${pageSize}`);

                document.getElementById('rowCountBadge').textContent = String(data.total);
                document.getElementById('pageBadge').textContent = String(data.page);
                document.getElementById('pageSummary').textContent =
                  `第 ${data.page} 页，每页 ${data.pageSize} 条，共 ${data.total} 条记录`;

                if (!data.rows.length) {
                  wrap.innerHTML = '<div class="empty">当前页没有数据</div>';
                  return;
                }

                wrap.innerHTML = renderTable(data.columns, data.rows);
              } catch (err) {
                wrap.innerHTML = `<div class="empty danger-text">${escapeHtml(err.message)}</div>`;
                document.getElementById('pageSummary').textContent = '加载失败';
              }
            }

            function renderTable(columns, rows) {
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
                document.getElementById('sqlCountBadge').textContent = '-';
                setSQLMessage(err.message || '执行失败', 'danger');
                result.innerHTML = `<div class="empty danger-text">${escapeHtml(err.message || 'Execution failed')}</div>`;
              } finally {
                button.disabled = false;
              }
            }

            function fillCurrentTableQuery() {
              if (!currentTable) {
                setSQLMessage('请先在左侧选择一张表', 'warning');
                return;
              }

              document.getElementById('sqlInput').value = `SELECT * FROM "${currentTable}" LIMIT 100;`;
              setSQLMessage(`已填入 ${currentTable} 的查询模板`, 'muted');
            }

            function fillSchemaQuery() {
              document.getElementById('sqlInput').value =
                "SELECT name, type, sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name;";
              setSQLMessage('已填入 sqlite_master 查询模板', 'muted');
            }

            function reloadCurrentTable() {
              if (!currentTable) {
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
              const current = Number(input.value || 1);
              input.value = current + 1;
              reloadCurrentTable();
            }

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

    private static func htmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#039;")
    }
}
