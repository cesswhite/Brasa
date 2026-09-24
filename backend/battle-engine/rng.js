// Derived portions retain Apache-2.0 / MIT; see ../../THIRD_PARTY_NOTICES.md.
// Modified for Brasa: JavaScript/BigInt port with Godot-compatible float32 behavior.
// PCG XSH RR, matching Godot 4.7.2 ed1daf0bf RandomNumberGenerator.
// Algorithm: M.E. O'Neill, Apache-2.0. Godot floating adaptation: MIT.
export const RNG_VERSION = 'godot-pcg32-ed1daf0bf';
const MASK = (1n<<64n)-1n;
const SEQUENCE = 1442695040888963407n;
const f32 = Math.fround;
export function normalizeSeed(seed) {
  if(typeof seed!=='string' || !/^(0|[1-9][0-9]{0,19})$/.test(seed)) throw new TypeError('Seed must be an unsigned decimal uint64 string');
  const n=BigInt(seed); if(n>MASK) throw new RangeError('Seed exceeds uint64'); return n.toString();
}
export class GodotRng {
  constructor(seed) { this.seed=normalizeSeed(seed); this.state=0n; this.inc=(SEQUENCE<<1n)|1n; this.draws=0; this.randi(); this.state=(this.state+BigInt(this.seed))&MASK; this.randi(); this.draws=0; }
  randi() {
    const old=this.state; this.state=(old*6364136223846793005n+(this.inc|1n))&MASK;
    const x=Number(BigInt.asUintN(32,((old>>18n)^old)>>27n)); const rot=Number(old>>59n);
    this.draws++; return ((x>>>rot)|(x<<((-rot)&31)))>>>0;
  }
  randf() { const exponent=this.randi(); if(exponent===0)return 0; const significand=(this.randi()|0x80000001)>>>0; return f32(f32(significand)*2**(-32-Math.clz32(exponent))); }
  randf_range(from,to) { from=f32(from); to=f32(to); return f32(f32(this.randf()*f32(to-from))+from); }
  randi_range(from,to) {
    from=Math.trunc(from);to=Math.trunc(to); if(from===to)return from;
    const min=Math.min(from,to),max=Math.max(from,to),bound=max-min+1;
    if(bound===4294967296)return min+this.randi();
    const threshold=(4294967296-bound)%bound; let value; do{value=this.randi();}while(value<threshold); return min+value%bound;
  }
}
