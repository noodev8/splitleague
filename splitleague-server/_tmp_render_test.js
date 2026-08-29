// Throwaway: render the public page for a started and a not-started league.
const express = require('express');
const app = express();
app.use('/l', require('./routes/public_league'));
const server = app.listen(3998, async () => {
  for (const code of ['1231', '9911']) {
    const r = await fetch('http://localhost:3998/l/' + code);
    const html = await r.text();
    console.log('\n########## /l/' + code + '  status=' + r.status + ' ##########');
    const m = html.match(/<section class="cta">[\s\S]*?<\/section>/);
    console.log(m ? m[0] : '!! NO CTA BLOCK FOUND !!');
    const hdr = html.match(/<div class="code">.*?<\/div>/);
    console.log('HEADER:', hdr ? hdr[0] : 'none');
    console.log('CTA position:', html.indexOf('class="cta"') < html.indexOf('>Standings<') ? 'BEFORE standings' : 'AFTER standings');
  }
  server.close();
});
