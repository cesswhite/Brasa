export class ApiError extends Error {
  constructor(status, code, message) {super(message); this.status=status; this.code=code;}
}
export const invalid = (message) => new ApiError(422, 'INVALID_REQUEST', message);
export function objectKeys(value, allowed) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw invalid('Se requiere un objeto JSON.');
  if (Object.keys(value).some(k => !allowed.includes(k))) throw invalid('El objeto contiene campos no admitidos.');
}
