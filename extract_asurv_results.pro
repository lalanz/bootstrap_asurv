;-----------------------------------------------------------------------------------------
; NAME:     extract_asurv_results.pro                           IDL Procedure
;
; PURPOSE: Extract coefficients and probability from the ASURV output files, plot histograms
; of both, and calculate statistics
;
; CALLING SEQUENCE: extract_asurv_results, nboots, out_dir, nme_out, flg_ow
;
; INPUTS:
;    nboots - integer number of the number of bootstrap samples
;    out_dir - working directory
;    nme_out - data set name
;    flg_ow - flag to prevent overwriting without checking  (0 = no, 1 = yes), default to 0
;
; OUTPUTS: - IDL savefile with the results of the Spearman tests (with name given in variable fname_out)
;          - Histogram plots of the Spearman coefficient and probability
;          - Output to screen of original data value, distribution median and stdev for rho and probability
;          - IDL savefile with the statistics that were printed to the screen (with name given in variable fout)
;
; EXAMPLES:  extract_asurv_results, 1000, './bsa_test', '_test', 0
;
; REVISION HISTORY:
;   2018-Oct  Written by Lauranne Lanz (Dartmouth)
;-----------------------------------------------------------------------------------------
pro extract_asurv_results, nboots, out_dir, nme_out, flg_ow

  ; restore the bootstrap array
  pth_wr = out_dir + 'input'+strtrim(nboots,2)+'/'
  fname_bsarr = pth_wr + 'bs'+strtrim(nboots,2)+'_array'+nme_out+'.sav'
  restore, filename=fname_bsarr ; gets us npar, n_mt, and fl_pth variables

  spr_arr = make_array(npar, nboots+1, 3, /double) ; rho (0) and prob (1) and special handling flag
  
  for np = 0, npar-1 do begin
    pthw = out_dir + 'output'+strtrim(nboots,2)+'/'+fl_pth[np]+'/'

    for bs = 0, nboots do begin

      if bs lt 10 then begin
        bsn = '000'+strtrim(bs, 2)
      endif else begin
        if bs lt 100 then begin
          bsn = '00'+strtrim(bs, 2)
        endif else begin
          if bs lt 1000 then begin
            bsn = '0'+strtrim(bs, 2)
          endif else begin
            bsn = strtrim(bs, 2)
          endelse
        endelse
      endelse
      nmr = pthw + 'r'+bsn+'.dat'

      openr, lun, nmr, /get_lun
      lrho=''
      lprob=''
      ind = 0
      lin=''
      while not eof(lun) do begin
        readf, lun, lin
        if ind eq 18 then lrho = lin
        if ind eq 19 then lprob = lin
        ind++
      endwhile
      close, lun
      free_lun, lun

      parse_rho=strsplit(lrho, ' ', /extract)
      rho_val = double(parse_rho[3])
      parse_prob = strsplit(lprob, ' ', /extract)
      prb_val = double(parse_prob[2])
      sph_flg = 0

      if prb_val eq 0 then begin ;
        zval = rho_val * sqrt(n_mt - 1)
        prb_val = erfc(zval/sqrt(2.))   ; based on the equation used in the fortran sub-program of ASURV called AGAUSS (fails for Z>5)
        sph_flg = 1
      endif

      spr_arr[np, bs, 0] = rho_val
      spr_arr[np, bs, 1] = prb_val
      spr_arr[np, bs, 2] = sph_flg
    endfor
  endfor

  fname_out = out_dir + 'output'+strtrim(nboots,2)+'/'+'bs'+strtrim(nboots,2)+'_spearman'+nme_out+'.sav'
  save, filename=fname_out, spr_arr, npar, n_mt,  nboots, fl_pth, nme_out

  nstat = 6 ; log orig prob; log median prob; stdev of log prob; orig. rho, median rho, rho stdev)
  stat_arr = make_array(npar, nstat)

  set_plot, 'ps'
  if file_exists(out_dir+'plots/') eq 0 then spawn, 'mkdir '+out_dir+'plots/'
  
  for np=0, npar-1 do begin

    phist = reform(spr_arr[np, 1:nboots-1, 1])
    rhist = reform(spr_arr[np, 1:nboots-1, 0])
    p0 = alog10(spr_arr[np, 0, 1])
    r0 = spr_arr[np, 0, 0]
    medp = median(alog10(phist))
    stdp = stdev(alog10(phist))
    medr = median(rhist)
    stdr = stdev(rhist)

    stat_arr[np, 0] = p0
    stat_arr[np, 1] = medp
    stat_arr[np, 2] = stdp
    stat_arr[np, 3] = r0
    stat_arr[np, 4] = medr
    stat_arr[np, 5] = stdr
  
    fname =  out_dir + 'plots/bs'+strtrim(nboots,2)+'_'+fl_pth[np]+'_phist.eps'
    fname2 = out_dir + 'plots/bs'+strtrim(nboots,2)+'_'+fl_pth[np]+'_rhist.eps'

    rrng = [-1.0, 1.0]
    prng = [-8, 0]
    bn=0.25
    bn2=0.05
    
    device, filename=fname, /encapsulate, /color, xs=6, ys=3, /inches

    plothist, alog10(phist), bin=bn, xrange=prng, /xsty, /ysty, /peak, /fill
    oploterror, [medp, medp, medp], [0, 0.5, nboots], [0, stdp, 0], 0*[medp, medp, medp], linestyle=0, color=cgcolor('Red'), thick=3
    oplot, [p0, p0], [0, nboots], linestyle=2, color=cgcolor('Green'), thick=3
    oplot, alog10([3e-3, 3e-3]), [0, nboots], linestyle=0, color=cgcolor('black'), thick=5

    device, /close

    device, filename=fname2, /encapsulate, /color, xs=6, ys=3, /inches

    plothist, rhist, bin=bn2, xrange=rrng, /xsty, /ysty, /peak, /fill
    oploterror, [medr, medr, medr], [0, 0.5, nboots], [0, stdr, 0], 0*[medp, medp, medp], linestyle=0, color=cgcolor('Red'), thick=3
    oplot, [r0, r0], [0, nboots], linestyle=2, color=cgcolor('Green'), thick=3

    device, /close
    
    print, fl_pth[np]
    print, 'RHO Original: ', stat_arr[np, 3]
    print, 'RHO StDev: ', stat_arr[np, 5]
    print, 'RHO Medians: ', stat_arr[np, 4]

    print, 'Prob. Original: ', stat_arr[np, 0]
    print, 'Prob. StDev: ', stat_arr[np, 2]
    print, 'Prob. Medians: ', stat_arr[np, 1]
    print, ' '

  endfor

  set_plot, 'x'
  fout = out_dir+ 'output'+strtrim(nboots,2)+'/bs'+strtrim(nboots,2)+'_stats'+nme_out+'.sav'
  save, filename=fout, stat_arr, nboots, fl_pth

end