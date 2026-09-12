export function zonePayload(form) {
  const name = String(form.name || '').trim();
  if (!name) throw new Error('Enter a zone name.');
  if ([form.latitude, form.longitude].some(v => v === '' || v == null)) throw new Error('Choose a meeting point on the map.');
  const latitude = Number(form.latitude), longitude = Number(form.longitude), radius_m = Number(form.radius_m);
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 || !Number.isFinite(longitude) || longitude < -180 || longitude > 180) throw new Error('Invalid coordinates.');
  if (!Number.isSafeInteger(radius_m) || radius_m < 1) throw new Error('Enter a positive whole-number radius.');
  return {name, latitude, longitude, radius_m};
}
