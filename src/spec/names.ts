/** `Mesh radio` → `MeshRadio`: a prose name as the identifier a model would declare. */
export function identifierOf(name: string | undefined): string | undefined {
  if (!name) return undefined;
  const id = name
    .split(/[^A-Za-z0-9_]+/)
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join('');
  return id || undefined;
}
