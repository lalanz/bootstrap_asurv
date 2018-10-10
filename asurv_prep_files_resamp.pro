;-----------------------------------------------------------------------------------------
; NAME:  asurv_prep_files_resamp                                                               IDL Procedure
;
; PURPOSE: Prepare the three files needed to run each bootstrap trial
;
; CALLING SEQUENCE: asurv_prep_files_resamp, nboots, sd_fname, flg_ow
;
; INPUTS:
;    nboots - integer number of the number of bootstrap samples
;    sd_fname - name of the data array save file
;    flg_ow - flag to prevent overwriting without checking  (0 = no, 1 = yes), default to 0
;
;
; OUTPUTS: Directory containing subdirectories for each parameter comparison pair with
;             - a????_input.dat: interactive input for running ASURV with spawn
;             - b????.dat: bootstrapped data 
;             - c????.dat: commands for ASURV
;          IDL savefile with the bootstrap datasets (fname_out)
;
; EXAMPLES: asurv_prep_files_resamp, 1000, data_array.sav, 0
;
;
; REVISION HISTORY:
;   2018-Oct  Written by Lauranne Lanz (Dartmouth)
;-----------------------------------------------------------------------------------------
pro asurv_prep_files_resamp, nboots, sd_fname, flg_ow

; random number setting
randint = 18

; restore the data array savefile to ensure that you have the following parameters
; data_set, n_mt, npar, nme_out, fl_pth, nindp, par_ind, out_dir
restore, sd_fname

noutp = 3 ; flag, bs value X, bs value Y
; number of parameter pairings x number of objects  x number of bootstrap samples x number of output parameters 
boots_set = make_array(npar, n_mt, nboots, noutp) ; bootstrap samples
orig_set = make_array(npar, n_mt, noutp) ; original dataset

; random indices generation
iboots = round(randomu(randint, npar, n_mt, nboots)*(n_mt-1))

; generate bootstrap samples for each pairing
for bs = 0, nboots-1 do begin
  for np = 0, npar - 1 do begin

    ; grab the random indices set for this particular variable
    rand_ind = reform(iboots[np,*, bs]) ; need to keep X and Y constant

    ds  = reform(data_set[np,*,*]) ; grab the dataset subset for one pairing
    boots_set[np, *, bs, 0] = ds[rand_ind,0] 
    boots_set[np, *, bs, 1] = ds[rand_ind, 1]
    boots_set[np, *, bs, 2] = ds[rand_ind, 2] ; flag

    if bs eq 0 then begin
      orig_set[np, *, 0] = ds[*,0] ; X value
      orig_set[np, *, 1] = ds[*,1] ; Y value
      orig_set[np, *, 2] = ds[*,2] ; flag
    endif
  endfor
endfor

; create a savefile with the bootstrap dataset
pth_wr = out_dir + 'input'+strtrim(nboots,2)+'/'
if file_exists(pth_wr) eq 0 then spawn, 'mkdir '+pth_wr ; create the directory if needed

fname_out = pth_wr + 'bs'+strtrim(nboots,2)+'_array'+nme_out+'.sav'
if file_exists(fname_out) eq 1 and flg_ow eq 0 then begin
  print, 'Such a set already exists. Do you want to continue and overwrite it?'
  stop
endif

save, filename=fname_out, boots_set, npar, n_mt,  nboots, orig_set, nme_out, fl_pth

; generate and output text files with the bootstrap data 
for np = 0, npar-1  do begin
  for bs = 0, nboots do begin
    bsi=bs-1 ; do orig with bs = 0 and the bootstraps samples for each next loop, so fix the indexing issue

    ; define filename
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

    pth_wr = out_dir + 'input'+strtrim(nboots,2)+'/'+fl_pth[np]+'/'
    if file_exists(pth_wr) eq 0 then spawn, 'mkdir '+pth_wr else begin ; create the directory if needed
      if flg_ow eq 0 then begin
        print, "Are you sure that you're not about to overwrite files?"
        stop
      endif
    endelse

    nmc1 = 'c'+bsn+'.dat'
    nmi = 'b'+bsn+'.dat'
    nmo = 'r'+bsn+'.dat' ; output file name
    nmb = pth_wr+nmi  ; bootstrap data file
    nmc = pth_wr+nmc1  ; asurv commands (called by asurv input)    
    nma = pth_wr+'a'+bsn+'_input.dat'  ; asurv input (for spawn)

    ; create the b????.dat files with the bootstrap samples
    openw, lun, nmb, /get_lun, width=800
    if bs eq 0 then begin ; original data (flag, X, Y)
      for i=0, n_mt-1 do printf, lun, orig_set[np, i, 2], orig_set[np, i, 0], orig_set[np, i, 1], format='(I4, 2F10.2)'
    endif else begin ; bootstrap samples (flag, X, Y)
      for i=0, n_mt-1 do printf, lun, boots_set[np,i,bsi,2], boots_set[np,i,bsi,0], boots_set[np,i,bsi,1], format='(I4, 2F10.2)'
    endelse
    close, lun
    free_lun, lun

    ; use fl_pth entries to define the names of par1 and par2
    splnme = strsplit(fl_pth[np], 'v', /extract)
    case n_elements(splnme) of 
      2: begin ; just in case fl_pth was not defined using the formalism of YvX (e.g., IntvIR)
          par1 = splnme[0]
          par2 = splnme[1]
         end
   else: begin
           par1 = 'ParY'
           par2 = 'ParX'
         end
    endcase

    ; write the file that will be used within asurv  (c????.dat)
    openw, lun, nmc, /get_lun, width=800

    printf, lun, 'BS '+bsn+' '+fl_pth[np]
    printf, lun, nmi                        ; name of input data file
    printf, lun, '1   1   1', format='(A-10)'    ; one independent variable in column 1; only one method
    printf, lun, 3, format='(I-4)'           ; method 3 = spearman
    printf, lun, par1, par2, format='(2A-10)' ; name of indep and dep parameters
    printf, lun, 0, format='(I-4)'           ; don't print data
    printf, lun, nmo                         ; output file
    printf, lun, 0, format='(I-4)'           ; no other analyses
    printf, lun, '1.0E-5', format='(A-10)'   ; write the tolerance as a string
    printf, lun, 0.0, 0.0, 0.0, 0.0, format='(4F-10.1)' ; coefficient estimates (not relevant for this one I think)
    printf, lun, 50, format='(I-6)'          ; number of iterations (this is the example value)

    close, lun
    free_lun, lun

    ; write the file that will call the appropriate asurv input
    openw, lun, nma, /get_lun, width=800

    printf, lun, '\r', format='(A-6)'
    printf, lun, '\r', format='(A-6)'
    printf, lun, 2, format='(I-4)'
    printf, lun, 'Y', format='(A-6)'
    printf, lun, nmc1                        ; name of input data file
    printf, lun, 'N', format='(A-6)'

    close, lun
    free_lun, lun


  endfor
endfor

end