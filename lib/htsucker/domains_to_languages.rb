# encoding: utf-8
# 
# HTTP fetching class with limits and some heuristics
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: Copyright (c) 2009 Paweł Wilk
# License::   LGPL

module DomainsToLanguages
    
    # This hash maps two-letter, top-level domain names to language codes.
    # In most cases these codes refer to spoken languages of the countries
    # assigned to the domains.
    
    @@domain_to_language  =  {
      
      :ad  =>  :es,  :ae  =>  :ar,  :af  =>  :fa,  :ag  =>  :en,  :ai  =>  :en,
      :al  =>  :sq,  :am  =>  :hy,  :an  =>  :nl,  :an  =>  :nl,  :ao  =>  :pt,
      :ar  =>  :es,  :as  =>  :en,  :at  =>  :de,  :au  =>  :en,  :aw  =>  :nl,
      :aw  =>  :nl,  :ax  =>  :sv,  :az  =>  :az,  :ba  =>  :bs,  :bb  =>  :en,
      :bd  =>  :bn,  :be  =>  :nl,  :bf  =>  :fr,  :bg  =>  :bg,  :bh  =>  :ar,
      :bi  =>  :fr,  :bj  =>  :fr,  :bm  =>  :en,  :bn  =>  :ne,  :br  =>  :pt,
      :bs  =>  :en,  :bt  =>  :ne,  :bv  =>  :en,  :bw  =>  :en,  :by  =>  :ru,
      :bz  =>  :es,  :ca  =>  :en,  :cc  =>  :en,  :cd  =>  :sw,  :cf  =>  :fr,
      :cg  =>  :fr,  :ch  =>  :de,  :ci  =>  :fr,  :ck  =>  :en,  :cl  =>  :es,
      :cm  =>  :fr,  :cn  =>  :zh,  :co  =>  :es,  :cr  =>  :es,  :cu  =>  :es,
      :cv  =>  :pt,  :cx  =>  :en,  :cy  =>  :el,  :cz  =>  :cs,  :de  =>  :de,
      :dj  =>  :fr,  :dk  =>  :da,  :dm  =>  :en,  :do  =>  :es,  :dz  =>  :ar,
      :ec  =>  :es,  :ee  =>  :fi,  :eg  =>  :ar,  :eh  =>  :ar,  :er  =>  :ar,
      :es  =>  :es,  :et  =>  :ti,  :fi  =>  :fi,  :fj  =>  :en,  :fk  =>  :en,
      :fm  =>  :en,  :fo  =>  :fo,  :fr  =>  :fr,  :fr  =>  :fr,  :ga  =>  :fr,
      :gb  =>  :en,  :gd  =>  :en,  :ge  =>  :ru,  :gf  =>  :fr,  :gg  =>  :en,
      :gh  =>  :en,  :gi  =>  :es,  :gl  =>  :kl,  :gm  =>  :en,  :gn  =>  :fr,
      :go  =>  :en,  :gp  =>  :fr,  :gq  =>  :es,  :gr  =>  :el,  :gs  =>  :en,
      :gt  =>  :es,  :gu  =>  :en,  :gw  =>  :pt,  :gy  =>  :en,  :hk  =>  :en,
      :hn  =>  :es,  :hr  =>  :hr,  :ht  =>  :fr,  :hu  =>  :hu,  :id  =>  :id,
      :il  =>  :he,  :in  =>  :hi,  :io  =>  :en,  :iq  =>  :ar,  :ir  =>  :fa,
      :is  =>  :is,  :it  =>  :it,  :je  =>  :en,  :jm  =>  :en,  :jo  =>  :ar,
      :jp  =>  :jp,  :ke  =>  :sw,  :kg  =>  :ru,  :kh  =>  :km,  :ki  =>  :en,
      :km  =>  :fr,  :kn  =>  :en,  :kp  =>  :ko,  :kr  =>  :ko,  :kw  =>  :ar,
      :ky  =>  :en,  :kz  =>  :ru,  :la  =>  :en,  :lb  =>  :ar,  :lc  =>  :en,
      :li  =>  :de,  :lk  =>  :en,  :lr  =>  :en,  :ls  =>  :en,  :lt  =>  :lt,
      :lu  =>  :fr,  :lv  =>  :lv,  :ly  =>  :ar,  :ma  =>  :ar,  :mc  =>  :fr,
      :md  =>  :ro,  :me  =>  :sr,  :mg  =>  :fr,  :mh  =>  :en,  :mk  =>  :mk,
      :ml  =>  :fr,  :mm  =>  :ta,  :mn  =>  :kk,  :mo  =>  :pt,  :mp  =>  :en,
      :mr  =>  :ar,  :ms  =>  :en,  :mt  =>  :en,  :mu  =>  :fr,  :mv  =>  :dv,
      :mw  =>  :sw,  :mx  =>  :es,  :my  =>  :zh,  :mz  =>  :pt,  :na  =>  :en,
      :nc  =>  :fr,  :ne  =>  :fr,  :nf  =>  :en,  :ng  =>  :en,  :ni  =>  :es,
      :nl  =>  :nl,  :nl  =>  :nl,  :no  =>  :no,  :np  =>  :ne,  :nr  =>  :en,
      :nu  =>  :en,  :nz  =>  :en,  :om  =>  :ar,  :pa  =>  :es,  :pe  =>  :es,
      :pf  =>  :fr,  :pg  =>  :en,  :ph  =>  :en,  :pk  =>  :en,  :pl  =>  :pl,
      :pm  =>  :fr,  :pn  =>  :en,  :pr  =>  :es,  :ps  =>  :he,  :pt  =>  :pt,
      :pt  =>  :pt,  :pw  =>  :en,  :py  =>  :es,  :qa  =>  :ar,  :re  =>  :fr,
      :ro  =>  :ro,  :rs  =>  :sr,  :ru  =>  :ru,  :rw  =>  :fr,  :sa  =>  :ar,
      :sb  =>  :en,  :sc  =>  :fr,  :sd  =>  :ar,  :se  =>  :sv,  :sg  =>  :zh,
      :sh  =>  :en,  :si  =>  :sl,  :sj  =>  :no,  :sk  =>  :sk,  :sl  =>  :en,
      :sm  =>  :it,  :sn  =>  :fr,  :so  =>  :so,  :sr  =>  :nl,  :st  =>  :pt,
      :su  =>  :ru,  :sv  =>  :es,  :sy  =>  :ar,  :sz  =>  :en,  :tc  =>  :en,
      :td  =>  :fr,  :tf  =>  :fr,  :tf  =>  :fr,  :tg  =>  :fr,  :th  =>  :th,
      :tj  =>  :tg,  :tk  =>  :en,  :tl  =>  :pt,  :tm  =>  :tk,  :tn  =>  :ar,
      :to  =>  :to,  :tr  =>  :tr,  :tr  =>  :tr,  :tt  =>  :en,  :tv  =>  :en,
      :tv  =>  :en,  :tw  =>  :zh,  :tz  =>  :sw,  :ua  =>  :uk,  :ug  =>  :sw,
      :uk  =>  :en,  :us  =>  :en,  :us  =>  :en,  :us  =>  :en,  :uy  =>  :es,
      :uz  =>  :uz,  :va  =>  :it,  :vc  =>  :en,  :ve  =>  :es,  :vg  =>  :en,
      :vi  =>  :en,  :vn  =>  :vi,  :vu  =>  :bi,  :wf  =>  :fr,  :wf  =>  :fr,
      :ws  =>  :en,  :ye  =>  :ar,  :yt  =>  :fr,  :yt  =>  :fr,  :yu  =>  :sr,
      :yu  =>  :sr,  :za  =>  :af,  :zm  =>  :sw,  :zw  =>  :en
    
    }
    
end
