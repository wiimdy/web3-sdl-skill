(function () {
  const meta = window.__REPORT_META__ || {};

  const severityClass = {
    Critical: 'severity-critical',
    High: 'severity-high',
    Medium: 'severity-medium',
    Low: 'severity-low',
    Informational: 'severity-informational',
  };

  const statusClass = {
    Confirmed: 'status-confirmed',
    Candidate: 'status-candidate',
    Rejected: 'status-rejected',
    'Needs-Info': 'status-needs-info',
  };

  const wrapFindingCards = () => {
    const detailSection = document.querySelector('#report-content section#detailed-findings');
    if (!detailSection) {
      return;
    }

    const children = Array.from(detailSection.children);
    const rebuilt = [];
    let currentCard = null;

    for (const child of children) {
      if (child.tagName === 'H2') {
        rebuilt.push(child);
        continue;
      }

      if (child.tagName === 'H3') {
        currentCard = document.createElement('article');
        currentCard.className = 'finding-card';
        currentCard.appendChild(child);
        rebuilt.push(currentCard);
        continue;
      }

      if (currentCard) {
        currentCard.appendChild(child);
      } else {
        rebuilt.push(child);
      }
    }

    detailSection.innerHTML = '';
    for (const node of rebuilt) {
      detailSection.appendChild(node);
    }
  };

  const enhanceFindingMeta = () => {
    document.querySelectorAll('.finding-card').forEach((card) => {
      const metaParagraph = Array.from(card.querySelectorAll('p')).find((paragraph) =>
        paragraph.textContent.includes('Severity:') && paragraph.textContent.includes('Status:')
      );

      if (!metaParagraph) {
        return;
      }

      const html = metaParagraph.innerHTML;
      const patterns = [
        {
          label: 'Severity',
          match: html.match(/Severity:<\/strong>\s*([^<]+?)\s*(?:<br\s*\/?>|$)/i),
          kind: 'severity',
        },
        {
          label: 'Status',
          match: html.match(/Status:<\/strong>\s*([^<]+?)\s*(?:<br\s*\/?>|$)/i),
          kind: 'status',
        },
        {
          label: 'Category',
          match: html.match(/Category:<\/strong>\s*([^<]+?)\s*(?:<br\s*\/?>|$)/i),
          kind: 'plain',
        },
        {
          label: 'Affected Surface',
          match: html.match(/Affected Surface:<\/strong>\s*([\s\S]+)$/i),
          kind: 'plain',
        },
      ];

      const chipContainer = document.createElement('div');
      chipContainer.className = 'finding-meta';

      for (const pattern of patterns) {
        if (!pattern.match) {
          continue;
        }

        const rawValue = pattern.match[1].replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
        if (!rawValue) {
          continue;
        }

        if (pattern.kind === 'severity') {
          const badge = document.createElement('span');
          badge.className = `severity-badge ${severityClass[rawValue] || 'severity-informational'}`;
          badge.textContent = rawValue;
          chipContainer.appendChild(badge);
          continue;
        }

        if (pattern.kind === 'status') {
          const badge = document.createElement('span');
          badge.className = `status-badge ${statusClass[rawValue] || 'status-needs-info'}`;
          badge.textContent = rawValue;
          chipContainer.appendChild(badge);
          continue;
        }

        const chip = document.createElement('span');
        chip.className = 'meta-chip';
        chip.textContent = `${pattern.label}: ${rawValue}`;
        chipContainer.appendChild(chip);
      }

      metaParagraph.replaceWith(chipContainer);
    });
  };

  const decorateSeverityCells = () => {
    document.querySelectorAll('td, th').forEach((cell) => {
      if (cell.children.length > 0) {
        return;
      }

      const value = cell.textContent.trim();
      if (severityClass[value]) {
        cell.innerHTML = `<span class="severity-badge ${severityClass[value]}">${value}</span>`;
      } else if (statusClass[value]) {
        cell.innerHTML = `<span class="status-badge ${statusClass[value]}">${value}</span>`;
      }
    });
  };

  const buildToc = () => {
    const tocRoot = document.getElementById('generated-toc');
    if (!tocRoot) {
      return;
    }

    const sections = Array.from(document.querySelectorAll('#report-content section.level2 > h2'));
    if (sections.length === 0) {
      tocRoot.remove();
      return;
    }

    const title = document.createElement('h2');
    title.textContent = 'Table of Contents';
    tocRoot.appendChild(title);

    const list = document.createElement('ol');
    list.className = 'toc-list';

    sections.forEach((heading, index) => {
      if (!heading.id) {
        heading.id = `section-${index + 1}`;
      }

      const item = document.createElement('li');
      item.className = 'toc-item';

      const link = document.createElement('a');
      link.href = `#${heading.id}`;
      link.textContent = heading.textContent;
      item.appendChild(link);

      const parentSection = heading.parentElement;
      const subHeadings = parentSection
        ? Array.from(parentSection.querySelectorAll(':scope h3'))
        : [];

      if (subHeadings.length > 0) {
        const subList = document.createElement('ol');
        subList.className = 'toc-sublist';
        subHeadings.forEach((subHeading, subIndex) => {
          if (!subHeading.id) {
            subHeading.id = `${heading.id}-sub-${subIndex + 1}`;
          }
          const subItem = document.createElement('li');
          subItem.className = 'toc-item';
          const subLink = document.createElement('a');
          subLink.href = `#${subHeading.id}`;
          subLink.textContent = subHeading.textContent.replace(/`/g, '');
          subItem.appendChild(subLink);
          subList.appendChild(subItem);
        });
        item.appendChild(subList);
      }

      list.appendChild(item);
    });

    tocRoot.appendChild(list);
  };

  const addSectionNotes = () => {
    const summarySection = document.querySelector('#report-content section#executive-summary');
    if (summarySection) {
      const firstTable = summarySection.querySelector('table');
      if (firstTable) {
        const note = document.createElement('p');
        note.className = 'section-note';
        note.textContent = 'Severity counts summarize the findings confirmed in this run.';
        firstTable.insertAdjacentElement('afterend', note);
      }
    }
  };

  const fillCover = () => {
    const cover = document.getElementById('cover-page');
    if (!cover) {
      return;
    }

    const badgeContainer = cover.querySelector('.cover-badges');
    (meta.severity_counts || []).forEach((item) => {
      if (!item.count || item.count === '0') {
        return;
      }

      const badge = document.createElement('span');
      const severityKey = severityClass[item.label] || '';
      badge.className = `cover-badge ${severityKey}`.trim();
      badge.innerHTML = `${item.label}<strong>${item.count}</strong>`;
      badgeContainer.appendChild(badge);
    });
  };

  wrapFindingCards();
  enhanceFindingMeta();
  decorateSeverityCells();
  buildToc();
  addSectionNotes();
  fillCover();

  document.body.dataset.reportReady = '1';
})();
