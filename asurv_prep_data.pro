;-----------------------------------------------------------------------------------------
; NAME:  asurv_prep_data                                                                    IDL Function
;
; PURPOSE: Import data and metadata from ascii files and put into the expected format and a savefile
;
; CALLING SEQUENCE: asurv_prep_data, pthin, mfile, dfile, flg_ow
;
; INPUTS:
;    mfile  - metadata file (see comments)
;    dfile  - filename containing columns of parameter, parameter flag (0 = value, 1 = upper limit)
;                 program can handle at this time no more than 5 parameters (see comments)
;    pthin    - path to directory in which to create working directories and read in mfile, dfile (assumed to be . if not specified)
;    flg_ow  - flag about overwriting output if already exists (0 = no, 1 = yes), default to 0
;
; OUTPUTS: returns the name of the savefile (sd_fname) created with the data array (data_set) as well as the following 
;     parameters: n_mt, npar, nme_out, fl_pth, nindp, par_ind, out_dir 
;
; COMMENTS: Currently only accepts a maximum of 5 independent parameters in the data file
;           in priniciple can be adjusted without too much difficult at the command sets marked with #NPAR
;  
; Meta File should contain (on separate lines):
;     - Number of parameters in data set (will be nindp; max of 5)
;     - Number of parameter pairs to be tested (will be npar)
;     - Array of names for parameter pairs; no spaces allowed/include the 'v' in XvY name (will be fl_pth)
;     - Array connecting parameters pairs in [X,Y] order and data cols in dfile (will be par_ind)
;     - Name for the total data set (will be nme_out)
;
; REVISION HISTORY:
;   2018-Oct  Written by Lauranne Lanz (Dartmouth)
;-----------------------------------------------------------------------------------------
function asurv_prep_data, pthin, mfile, dfile, flg_ow

  ; read in the meta data file
  openr, lun, pthin+mfile, /get_lun
  rd_ln = ''
  i=0
  while not EOF(lun) do begin
    readf, lun, rd_ln
    ;  ignore comments and empty lines
    if (strmid(rd_ln, 0, 1) ne '#') and (strlen(rd_ln) gt 0) then begin
      ; put data into appropriate parameter
      case i of
        0: nindp = fix(rd_ln)
        1: npar  = fix(rd_ln)
        2: fl_pth_ST = rd_ln
        3: par_ind_ST = rd_ln
        4: nme_out = '_' + rd_ln
        else: ; to avoid crash if additional lines added at the end
      endcase
      i++
    endif
  endwhile
  close, lun
  free_lun, lun

  ; fix the formatting of the fl_pth and par_ind arrays
  splt1 = strsplit(fl_pth_ST, ",", /EXTRACT) ; divide into elements at the commas
  splt1a = strsplit(splt1[0], '[', /EXTRACT) ; remove the leading [
  splt1b = strsplit(splt1[n_elements(splt1)-1], ']', /EXTRACT) ; remove the trailing ]
  fl_pth = [strtrim(splt1a,2), strtrim(splt1[1:n_elements(splt1)-2],2), strtrim(splt1b,2)] ; reconsistute array, remove spaces

  splt2 = strsplit(par_ind_ST, ",", /EXTRACT) ; divide into elements at the commas
  par_ind=make_array(2, npar, /int)
  if (n_elements(splt2) mod 2 ne 0) or n_elements(splt2)/2 ne npar then begin
    print, 'Mismatch in the number of parameters pairs in Meta File: ', mfile
    print, 'npar value does not match number of pairs in par_ind parameter'
    stop
  endif
  for i = 0, npar - 1 do begin
    par_ind[0, i] = fix(strtrim(strsplit(strtrim(splt2[2*i],  2),'[', /EXTRACT),2))
    par_ind[1, i] = fix(strtrim(strsplit(strtrim(splt2[2*i+1],2),']', /EXTRACT),2))
    if par_ind[0,i] ge nindp or par_ind[1,i] ge nindp then begin
      print, 'Mismatch between par_ind identifier and number of independent variables'
      stop
    endif
  endfor



  ; Check whether we need to create an output directory
  out_dir = pthin + 'bsa'+nme_out+'/'
  if file_exists(out_dir) eq 0 then begin ; doesn't exist yet
    spawn, 'mkdir ' + out_dir
  endif else begin
    if flg_ow eq 0 then begin
      print, 'Warning: An output directory with this name already exists.'
      stop
    endif
  endelse

  ; read in the data (if you want more columns, you need to added cases here as well as below) #NPAR
  case nindp of
    2: begin
      readcol, pthin+dfile, val_0, flg_0, val_1, flg_1, format='F,I,F,I', /silent
    end
    3: begin
      readcol, pthin+dfile, val_0, flg_0, val_1, flg_1, val_2, flg_2, format='F,I,F,I,F,I', /silent
    end
    4: begin
      readcol, pthin+dfile, val_0, flg_0, val_1, flg_1, val_2, flg_2, val_3, flg_3, format='F,I,F,I,F,I,F,I', /silent
    end
    5: begin
      readcol, pthin+dfile, val_0, flg_0, val_1, flg_1, val_2, flg_2, val_3, flg_3, val_4, flg_4, format='F,I,F,I,F,I,F,I,F,I', /silent
    end
    else: begin
      print, 'Current version of the code can only handle up to 5 individual parameters. '
      print, 'Change the code where #NPAR is found if you want more'
      stop
    end
  endcase

  n_mt = n_elements(val_0)  ; number of data points

  ; create the dataset variable
  data_set = make_array(npar, n_mt, 3, /double) ; [X,Y,flag] for each variable pairing per object

  for np = 0, npar-1 do begin
    pair_ids = reform(par_ind[*,np])
    if pair_ids[0] eq pair_ids[1] then begin
      print, 'In test ', np, 'X and Y are the same. Is this intended?'
      stop
    endif
    case pair_ids[0] of ; #NPAR
      0: begin
        xval = val_0
        xflg = flg_0
      end
      1: begin
        xval = val_1
        xflg = flg_1
      end
      2: begin
        xval = val_2
        xflg = flg_2
      end
      3: begin
        xval = val_3
        xflg = flg_3
      end
      4: begin
        xval = val_4
        xflg = flg_4
      end
      else: begin
        print, 'Current version of the code can only handle five different parameters.'
        stop
      end
    endcase
    case pair_ids[1] of ; #NPAR
      0: begin
        yval = val_0
        yflg = flg_0
      end
      1: begin
        yval = val_1
        yflg = flg_1
      end
      2: begin
        yval = val_2
        yflg = flg_2
      end
      3: begin
        yval = val_3
        yflg = flg_3
      end
      4: begin
        yval = val_4
        yflg = flg_4
      end
      else: begin
        print, 'Current version of the code can only handle five different parameters.'
        stop
      end
    endcase

    ; Assign the flag and x and y into expected dataset
    ;Flag: 0 = detected; -1 = Y is UL; -2 = X is UL; -3 = both X and Y are UL
    for i = 0, n_mt -1 do begin
      data_set[np, i, 0] = xval[i]
      data_set[np, i, 1] = yval[i]
      if xflg[i] eq 0 then begin
        case yflg[i] of
          0: data_set[np, i, 2] = 0
          1: data_set[np, i, 2] = -1
        endcase
      endif else begin
        case yflg[i] of
          0: data_set[np, i, 2] = -2
          1: data_set[np, i, 2] = -3
        endcase
      endelse
    endfor
  endfor

  ; save the results to a savefile for import int other programs
  sd_fname = out_dir + 'data'+nme_out+'.sav'
  if file_exists(sd_fname) eq 1 then begin
    if flg_ow eq 0 then begin
      print, 'You are about to overwrite the data arrays for '+nme_out
      stop
    endif
  endif
  
  save, filename=sd_fname, data_set, n_mt, npar, nme_out, fl_pth, nindp, par_ind, out_dir


return, sd_fname
end