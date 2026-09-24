export const clamp = (x, min, max) => Math.min(max, Math.max(min, x));
export const round = x => x < 0 ? -Math.floor(-x + 0.5) : Math.floor(x + 0.5);
export const approximatelyEqual = (a,b) => a===b || Math.abs(a-b)<Math.max(0.00001,0.00001*Math.abs(a));
export const empty = value => Object.keys(value).length===0;
export function clone(value) {
  if (Array.isArray(value)) return value.map(clone);
  if (value && typeof value==='object') return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,clone(v)]));
  return value;
}
export function deepFreeze(value) {
  if (value && typeof value==='object' && !Object.isFrozen(value)) { Object.freeze(value); for(const child of Object.values(value)) deepFreeze(child); }
  return value;
}
