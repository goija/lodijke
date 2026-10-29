<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabDocumenten = 'docA'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabDocumenten === 'docA' }]">Doc A: Dossier B.W. Schot (1840–1935)</button>
      <button @click="store.subTabs.tabDocumenten = 'docB'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabDocumenten === 'docB' }]">Doc B: Regenten &amp; Hofsteden</button>
      <button @click="store.subTabs.tabDocumenten = 'docC'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabDocumenten === 'docC' }]">Doc C: Akten 1901 &amp; 1913</button>
      <button
        v-for="cd in store.customDocs"
        :key="cd.id"
        @click="store.subTabs.tabDocumenten = cd.id"
        :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabDocumenten === cd.id }]"
      >{{ cd.title }}</button>
      <button @click="store.subTabs.tabDocumenten = 'docNew'" :class="['sub-tab-btn ml-auto', { 'sub-tab-active': store.subTabs.tabDocumenten === 'docNew' }]">+ Nieuw Dossier</button>
    </div>

    <div v-if="store.subTabs.tabDocumenten === 'docA'" class="space-y-3">
      <div class="flex flex-wrap gap-1.5">
        <button @click="store.subTabs.docASub = 'subProfiel'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.docASub === 'subProfiel' }]">1. Profiel &amp; Gezin</button>
        <button @click="store.subTabs.docASub = 'subKruittoren'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.docASub === 'subKruittoren' }]">2. Kruittoren 23 &amp; Loods</button>
        <button @click="store.subTabs.docASub = 'subVloot'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.docASub === 'subVloot' }]">3. Vloot &amp; Perceel 369</button>
        <button @click="store.subTabs.docASub = 'subWatersnood'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.docASub === 'subWatersnood' }]">4. Watersnood 1906 (TH 12)</button>
        <button @click="store.subTabs.docASub = 'subZierikzee'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.docASub === 'subZierikzee' }]">5. Zierikzee 1912</button>
        <button @click="store.subTabs.docASub = 'subChronologie'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.docASub === 'subChronologie' }]">6. Chronologie</button>
      </div>

      <div v-if="store.subTabs.docASub === 'subProfiel'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm space-y-1.5">
        <p><strong>Benjamin Willem Schot</strong> (geb. 26 sep 1840 Tholen – overl. 17 nov 1935 Tholen, 95 jr). Zoon van Jan Schot (1814–1882) en Elisabeth Josina van Dijk (1812–1895).</p>
        <p><strong>1e Huwelijk (1863):</strong> Maria Mathea Bolier (27 aug 1840 Scherpenisse – 1909, 13 kinderen). <strong>2e Huwelijk (1 okt 1915):</strong> Dina Pieternella Kegge (1868–1944, oesterkoopvrouw).</p>
      </div>
      <div v-else-if="store.subTabs.docASub === 'subKruittoren'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm space-y-1.5">
        <p><strong>Kruittoren 23 (Kruistoren 113h / Wijk A 107):</strong> Hoofdvestiging en familiehuizen te Tholen (waaronder het huis van Anna Schot).</p>
        <p><strong>1901 &amp; 1913:</strong> Aanvraag aankoop gemeentegrond Oud-Vossemeersepoort voor 3 woningen (jan 1901) en vergroting oesterloods Contr'Escarpe door C.J. Schot en J. Kegge (juli 1913).</p>
      </div>
      <div v-else-if="store.subTabs.docASub === 'subVloot'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm space-y-1.5">
        <p><strong>Oesterperceel No. 369:</strong> Gelegen op de Bol van Lodijke (Oosterschelde), 12,5 hectare.</p>
        <p><strong>Vloot (Werf Van Duivendijk):</strong> TH 2 "Eben Haëzer" (1902, bevaren door C.J. Schot; vernieuwd in 1918), TH 12 "Niets zonder Gods zegen", en TH 90 "Vijf Gebroeders / Eben Haëzer" (Willem Karel Schot; in 1917 naar kleinzoon Karel Jacob Dingenus Schot).</p>
      </div>
      <div v-else-if="store.subTabs.docASub === 'subWatersnood'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm">
        Tijdens de stormvloed van 12–13 maart 1906 bij Oud-Vossemeer fungeerde de roeiboot van hoogaars <strong>TH 12 "Niets zonder Gods zegen"</strong> van B.W. Schot als een van de voornaamste reddingsboten.
      </div>
      <div v-else-if="store.subTabs.docASub === 'subZierikzee'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm">
        In 1912 pachtten drie zonen (Kees, Jacob en Willem Schot) oester- en mosselgronden te Flauwers onder Zierikzee van mr. Fokker.
      </div>
      <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm">
        1840 Geboorte B.W. Schot • 1863 Huwelijk M.M. Bolier • 1901 Drie woningen Oud-Vossemeersepoort • 1902 Bouw TH 2 • 1906 Watersnoodredding TH 12 • 1912 Expansie Flauwers Zierikzee • 1913 Vergroting loods Contr'Escarpe • 1915 Huwelijk D.P. Kegge • 1917/1918 TH 90 &amp; nieuwe TH 2 • 1935 Overlijden B.W. Schot (95 jr).
      </div>
    </div>

    <div v-else-if="store.subTabs.tabDocumenten === 'docB'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm space-y-1.5">
      <p><strong>Van Vrijberghe &amp; Hofsteden:</strong> Rekenmeester Adriaen van Vrijberghe (1684–1719) en mr. Johan Turcq; Hofstede De Gortzak (Schakerloo Sectie I nr. 360, 122 gemeten), Hofstede Kandia (&gt;76 ha), Molenvliet (43,3 ha) en Watervliet (77 ha).</p>
    </div>

    <div v-else-if="store.subTabs.tabDocumenten === 'docC'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm font-mono space-y-1">
      <div>[1901-01] Verzoek aankoop gemeentegrond Oud-Vossemeersepoort door Jan, Jacob en Cathalina Schot.</div>
      <div>[1913-07] Verzoek vergroting oesterloods Contr'Escarpe door Cornelis Jan Schot en Jacob Kegge.</div>
    </div>

    <div v-else-if="store.subTabs.tabDocumenten === 'docNew'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-2.5">
        <input v-model="newTitle" type="text" placeholder="Titel document..." class="ui-input" />
        <input v-model="newYear" type="text" placeholder="Jaartal" class="ui-input" />
        <textarea v-model="newBody" rows="3" placeholder="Inhoud..." class="ui-input md:col-span-2"></textarea>
      </div>
      <button @click="saveDoc" class="ui-btn bg-meekrab-700 text-white">Document Opslaan</button>
    </div>

    <div
      v-for="cd in store.customDocs"
      :key="cd.id"
      v-show="store.subTabs.tabDocumenten === cd.id"
      class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2"
    >
      <div class="font-bold text-base text-meekrab-800">{{ cd.title }} ({{ cd.year }})</div>
      <p class="text-sm whitespace-pre-line">{{ cd.body }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../../store/archiveStore.js';

const newTitle = ref('');
const newYear = ref('');
const newBody = ref('');

function saveDoc() {
  if (!newTitle.value.trim()) {
    store.showToast('Vul een titel in.');
    return;
  }
  const id = 'docCustom_' + Date.now();
  store.customDocs.push({
    id,
    title: newTitle.value.trim(),
    year: newYear.value.trim() || 'Archief',
    body: newBody.value.trim()
  });
  newTitle.value = '';
  newYear.value = '';
  newBody.value = '';
  store.subTabs.tabDocumenten = id;
  store.showToast('Nieuw dossier aangemaakt.');
}
</script>
