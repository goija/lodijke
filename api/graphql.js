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
                { name: 'cmsRecords', description: 'Lijst van CMS archiefrecords (data/cms_records.json)' },
                { name: 'geojsonParcels', description: 'GeoJSON kadastrale percelen (data/geojson_parcels.json)' },
                { name: 'gitSyncLog', description: 'Git synchronisatie status (data/git_sync_log.json)' }
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
      cmsRecords: [
        { id: 'LOD-01', titel: 'Oorkonde Reimerswaal & Lodijke', categorie: 'Archief', datum: '1421-11-19' }
      ],
      geojsonParcels: [
        { id: 'SECTIE-E-1552', naam: 'Scherpenisse Platteweg', oppervlakteM2: 4120.0 }
      ]
    }
  });
}
