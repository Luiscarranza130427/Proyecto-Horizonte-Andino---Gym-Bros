export function inicialesDe(nombre) {
  const partes = (nombre ?? '').split(' ').filter(Boolean)
  if (partes.length === 0) return '?'

  const primera = partes[0].charAt(0)
  const segunda = partes.length > 1 ? partes[partes.length - 1].charAt(0) : ''

  return (primera + segunda).toUpperCase()
}
