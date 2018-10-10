;-----------------------------------------------------------------------------------------
; NAME:  run_asurv                                                                    IDL Procedure
;
; PURPOSE: run each of the bootstrap trials for each of the parameter pairs 
;
; CALLING SEQUENCE: run_asurv, nboots, out_dir, nme_out, flg_ow
;
; INPUTS:
;    nboots - integer number of the number of bootstrap samples
;    out_dir - working directory
;    nme_out - data set name
;    flg_ow - flag to prevent overwriting without checking  (0 = no, 1 = yes), default to 0
;
; OUTPUTS: r????.dat files containing the output of the ASURV runs placed into output directories
;
; EXAMPLES: run_asurv, 1000, './bsa_test', '_test', 0
;
; REVISION HISTORY:
;   2018-Oct  Written by Lauranne Lanz (Dartmouth)
;-----------------------------------------------------------------------------------------
pro run_asurv, nboots, out_dir, nme_out, flg_ow

  ; restore the bootstrap array 
  pth_wr = out_dir + 'input'+strtrim(nboots,2)+'/'
  fname_bsarr = pth_wr + 'bs'+strtrim(nboots,2)+'_array'+nme_out+'.sav'
  restore, filename=fname_bsarr ; gets us npar, n_mt, fl_pth
  pth_run = pth_wr+fl_pth[0]+'/'

  for np = 0, npar-1 do begin
    flg_run = 0 ; reset (just in case)

    cd, pth_run  ; this might be an issue outside of idlde
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

      nma = 'a'+bsn+'_input.dat'
      nmr = 'r'+bsn+'.dat'

      if file_exists(pth_run+nmr) eq 1 then begin ; output file already exists
        case flg_ow of
          0:begin
            flg_run = 0 ; run this one, but in order to avoid an abort, we need to remove the existing one
            print, 'Are you sure you want to delete and overwrite?'
            stop
            spawn, 'rm '+pth_run+nmr
          end
          1: begin ; only use this option if you're sure you want to overwrite all of the ones that alreay exist
            flg_run = 0 ; run this one, but in order to avoid an abort, we need to remove the existing one
            spawn, 'rm '+pth_run+nmr
          end
        endcase
      endif

      if flg_run eq 0 then begin  ;do run it
        spawn, 'cat '+nma + ' | asurv'
      endif   
    endfor
    if np lt npar-1 then pth_run = '../../../'+pth_wr+fl_pth[np+1]+'/'
  endfor

  cd, '../../..'
  pth_out = out_dir + 'output'+strtrim(nboots,2)+'/'
  if file_exists(pth_out) eq 0 then spawn, 'mkdir '+pth_out ; create the directory if needed
  ndiv = 1000
  n1000 = nboots/ndiv
  
  for np = 0, npar-1 do begin
     pth_wr = pth_out+fl_pth[np]+'/'
     pth_cp = out_dir + 'input'+strtrim(nboots,2)+'/'+fl_pth[np]+'/'
     if file_exists(pth_wr) eq 0 then spawn, 'mkdir '+pth_wr
     
     for n1=0, n1000-1 do begin
       spawn, 'mv '+pth_cp+'r'+strtrim(n1,2)+'*.dat '+pth_wr
     endfor
     spawn, 'mv '+pth_cp+'r*.dat '+pth_wr
  endfor


end