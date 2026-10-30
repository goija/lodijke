const CMS_RECORDS = [
  { id: 'LOD-1421-01', titel: 'Oorkonde Verdronken Land van Reimerswaal & Lodijke', categorie: 'Oorkonde', datum: '1421-11-19' },
  { id: 'LOD-1530-02', titel: 'Oudelandse Visrecht & Dijkrol Sint-Felixvloed', categorie: 'Visrecht', datum: '1530-11-05' },
  { id: 'SCH-1552-03', titel: 'Kadastrale Legger Scherpenisse Platteweg 3-7', categorie: 'Kadaster', datum: '1832-10-01' }
];

const GEOJSON_PARCELS = [
  { id: 'LOD-1421-01', naam: 'Verdronken Stad Lodijke (Reimerswaal)', rdX: 68450.0, rdY: 387210.0, oppervlakteM2: 14520.5 },
  { id: 'SCH-E-1552', naam: 'Scherpenisse Platteweg 3-7 (Sectie E 1552)', rdX: 64210.0, rdY: 395410.0, oppervlakteM2: 4120.0 }
];

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
  const query = body.query || '';

  if (query.includes('__schema')) {
    return res.status(200).json({
      data: {
        __schema: {
          queryType: { name: 'QueryRoot' },
          mutationType: { name: 'MutationRoot' },
          types: [
            {
              name: 'QueryRoot',
              kind: 'OBJECT',
              fields: [
                { name: 'cmsRecords', description: 'Lijst van Zeeuwse archiefrecords' },
                { name: 'geojsonParcels', description: 'Kadastrale percelen met RD-coördinaten' }
              ]
            }
          ]
        }
      }
    });
  }

  return res.status(200).json({
    data: {
      __typename: 'QueryRoot',
      cmsRecords: CMS_RECORDS,
      geojsonParcels: GEOJSON_PARCELS
    }
  });
}
