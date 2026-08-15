const fs = require('fs');
const fetch = require('node-fetch');
const cheerio = require('cheerio');

const centres = [
    { id: 'vauxwest', name: 'VauxWest', url: 'https://londonclimbingcentres.co.uk/centre/vauxwest/' },
    { id: 'vauxeast', name: 'VauxEast', url: 'https://londonclimbingcentres.co.uk/centre/vauxeast/' },
    { id: 'harrowall', name: 'HarrowAll', url: 'https://londonclimbingcentres.co.uk/centre/harrowall/' },
    { id: 'croywall', name: 'CroyWall', url: 'https://londonclimbingcentres.co.uk/centre/croywall/' },
    { id: 'ravenswall', name: 'RavensWall', url: 'https://londonclimbingcentres.co.uk/centre/ravenswall/' },
    { id: 'canarywall', name: 'CanaryWall', url: 'https://londonclimbingcentres.co.uk/centre/canarywall/' },
    { id: 'bethwall', name: 'BethWall', url: 'https://londonclimbingcentres.co.uk/centre/bethwall/' },
    { id: 'eustonwall', name: 'EustonWall', url: 'https://londonclimbingcentres.co.uk/centre/eustonwall/' }
];

async function scrapeCentre(url) {
    try {
        const res = await fetch(url, { headers: { 'User-Agent': 'ClimbingTimesBot/1.0' } });
        const text = await res.text();
        const $ = cheerio.load(text);

        // Find the heading that says 'Opening times' (case-insensitive)
        const heading = $('*:header').filter((i, el) => $(el).text().trim().toLowerCase() === 'opening times').first();

        // If not found via header selector, try h2/h3 with text contains
        let openingHtml = '';
        if (!heading || heading.length === 0) {
            const candidate = $('h1,h2,h3,h4').filter((i, el) => $(el).text().trim().toLowerCase().includes('opening times')).first();
            if (candidate && candidate.length) {
                openingHtml = collectSectionHtml($(candidate));
            }
        } else {
            openingHtml = collectSectionHtml(heading);
        }

        // Fallback: look for a section that contains the phrase 'Opening times' then take the following block
        if (!openingHtml) {
            const candidate = $('*').filter((i, el) => $(el).text().trim().toLowerCase().startsWith('opening times')).first();
            if (candidate && candidate.length) openingHtml = collectSectionHtml($(candidate));
        }

        return openingHtml || null;
    } catch (err) {
        console.error('Fetch error for', url, err.message);
        return null;
    }
}

function collectSectionHtml($heading) {
    const $ = $heading.constructor; // cheerio root isn't directly accessible; pass through
    // Collect siblings until the next H2/H1
    let html = '';
    let el = $heading[0].next;
    // Use cheerio's nextUntil by selecting on the parent
    try {
        const $parent = $heading.parent();
        const nodes = $heading.nextUntil('h1,h2');
        nodes.each((i, node) => {
            html += cheerio.html(node) || '';
        });
        if (!html) {
            // as fallback, get the next element's html
            const next = $heading.next();
            html = next.html() || '';
        }
    } catch (e) {
        html = '';
    }
    return html.trim();
}

(async () => {
    const out = {};
    for (const c of centres) {
        console.log('Scraping', c.url);
        const html = await scrapeCentre(c.url);
        out[c.id] = { name: c.name, url: c.url, opening_html: html };
    }
    fs.writeFileSync('data.json', JSON.stringify(out, null, 2), 'utf8');
    console.log('Wrote data.json with scraped sections.');
})();
