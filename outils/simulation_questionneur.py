#!/usr/bin/env python3
"""Simulation du bonus du questionneur (idées n° 10 et 16 du game design).

Le questionneur répond aussi à sa question : bonne réponse, dégâts × (1 + b) ou contre-attaque reçue × (1 − b) ;
mauvaise, l'inverse ; Passer, normal. Combats 3 contre 3 d'Équilibrés (100 PV, 50 Att), règles de Combat.swift,
bonus de vitesse de chaque effet de famille de styles (sans synergie).
Hypothèses : défenseur juste à 65 % en difficulté 1 (−8 points par niveau), questionneur juste à 80 % sur sa
propre spécialité ; mode « ia » : il répond toujours ; mode « humain » : il passe 7 fois sur 10 quand il ne sait pas.
Usage : python3 outils/simulation_questionneur.py
"""
import random, statistics, sys
FAM=['contre','soin','bouclier','savoir','pression']
def degats(a,d,diff): return max(5, round(a*(1+0.1*(diff-1)))-d)
def vitesse(malus):
    r=random.random()
    if malus>=4: return 'rapide' if r<0.45 else 'normale'
    if malus>=2: return 'eclair' if r<0.12 else ('rapide' if r<0.5 else 'normale')
    return 'eclair' if r<0.25 else ('rapide' if r<0.65 else 'normale')
def combat(fA,fB,b,mode,n=3,P=0.65):
    camps=[[dict(pv=100,att=50,df=0,fam=f,j=0,cap=False,bou=0) for _ in range(n)] for f in (fA,fB)]
    act=[0,0]; malus=[0,0]; prem=random.randint(0,1); tours=0
    for t in range(30):
        tours+=1
        a=(t+prem)%2; d=1-a
        at=camps[a][act[a]]; de=camps[d][act[d]]
        diff=random.randint(1,3)
        p=P-0.08*(diff-1)-0.0125*malus[d]
        # réponse du questionneur
        q=min(0.95,P+0.15-0.08*(diff-1))
        if mode=='aucune': rq=None
        else:
            sait=random.random()<q
            if sait: rq=True
            elif mode=='ia' or random.random()<0.3: rq=False
            else: rq=None
        fq = 1 if rq is None else (1+b if rq else 1-b)
        m=malus[d]; malus[d]=0
        if random.random()<p:
            v=vitesse(m); mult=1; cases=0
            if v!='normale':
                e=(v=='eclair')
                if de['fam']=='contre': mult=1.5 if e else 1.25
                elif de['fam']=='soin': de['pv']=min(100,de['pv']+(15 if e else 8))
                elif de['fam']=='bouclier': de['bou']=max(de['bou'],0.3 if e else 0.15)
                elif de['fam']=='savoir': cases=2 if e else 1
                elif de['fam']=='pression': malus[a]=4 if e else 2
            contre=max(5,round(degats(de['att'],at['df'],diff)*0.5*mult*(2-fq if rq is not None else 1)))
            at['pv']-=contre
            de['j']+=1+cases
            if de['j']>=3: de['j']=0; de['cap']=True
        else:
            x=degats(at['att'],de['df'],diff)
            if at['cap']: x*=2; at['cap']=False
            x=max(5,round(x*fq))
            if de['bou']>0: x-=round(x*de['bou']); de['bou']=0
            de['pv']-=x
        for c in (0,1):
            while act[c]<n and camps[c][act[c]]['pv']<=0: act[c]+=1
        if n in act: break
    if act[1]>=n>act[0]: r=1
    elif act[0]>=n>act[1]: r=0
    else:
        s=[sum(max(0,x['pv']) for x in camps[c]) for c in (0,1)]
        r=1 if s[0]>s[1] else 0 if s[0]<s[1] else .5
    return r,tours
def etude(b,mode,N=3000):
    tours=[]; tx={}
    for f in FAM:
        w=[]
        for g in FAM:
            if g==f: continue
            for _ in range(N):
                r,t=combat(f,g,b,mode); w.append(r); tours.append(t)
        tx[f]=sum(w)/len(w)
    lim=sum(1 for t in tours if t>=30)/len(tours)
    return statistics.mean(tours), lim, tx
def avantage(b, ecart=0.15, N=20000):
    """Taux de victoire d'un camp qui connaît mieux ses propres questions (+ecart) contre un camp qui les connaît moins."""
    global combat
    code = open(__file__).read().replace("q=min(0.95,P+0.15-0.08*(diff-1))",
                                         "q=min(0.95,P+0.15-0.08*(diff-1)+(ECART if a==0 else -ECART))")
    ns = {"ECART": ecart}
    exec(code.split("def etude")[0], ns)
    w = [ns['combat'](random.choice(FAM), random.choice(FAM), b, 'humain')[0] for _ in range(N)]
    return sum(w) / len(w)
if __name__=='__main__':
    for mode in ('aucune','ia','humain'):
        for b in ([0] if mode=='aucune' else [0.1,0.2,0.3]):
            m,lim,tx=etude(b,mode)
            print(mode,b,'tours %.1f'%m,'limite %.0f%%'%(lim*100),' '.join(f'{k}:{v:.1%}' for k,v in tx.items()),flush=True)
    for b in (0, 0.1, 0.2, 0.3):
        print(f"avantage du meilleur questionneur, b = {b} : {avantage(b):.1%}", flush=True)
