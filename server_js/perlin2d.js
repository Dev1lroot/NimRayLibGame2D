class Perlin2D
{
    constructor(seed = Math.random()-0.5)
    {
        this.p = new Array(512);
        this.permutation = [...Array(256).keys()].sort(()=>seed);
        for (let i=0;i<512;i++) this.p[i]=this.permutation[i%256];
    }
    fade(t){ return t*t*t*(t*(t*6-15)+10); }
    lerp(a,b,t){ return a+(b-a)*t; }
    grad(hash,x,y)
    {
        const h = hash & 3;
        const u = h<2?x:y;
        const v = h<2?y:x;
        return ((h&1)===0?u:-u) + ((h&2)===0?v:-v);
    }
    get(x,y)
    {
        const X = Math.floor(x) & 255;
        const Y = Math.floor(y) & 255;
        x -= Math.floor(x);
        y -= Math.floor(y);
        const u = this.fade(x);
        const v = this.fade(y);
        const A = this.p[X]+Y, AA = this.p[A], AB = this.p[A+1];
        const B = this.p[X+1]+Y, BA = this.p[B], BB = this.p[B+1];
        return this.lerp(this.lerp(this.grad(this.p[AA],x,y), this.grad(this.p[BA],x-1,y),u),
                    this.lerp(this.grad(this.p[AB],x,y-1), this.grad(this.p[BB],x-1,y-1),u),v);
    }
}
export default Perlin2D;