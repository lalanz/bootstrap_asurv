
pro print_asurv_stats

  pth='/Users/llanz/Desktop/Projects/NuSTAR/Swift-BAT/'
  ptho=pth + 'asurv_bs/'

  nboots = 1000
  ; See also DataSets.txt
  ; _LL = luminosity vs luminosity and flux vs flux set
  ; _LL_rsp = resampled with replacements instead of within errors
  ; _RpLum = log Rpex vs (Int, IR, Ratio IR/Int, IR Excess, IR Max Excess)
  nme_in = '_apfig_rsp'

  fnme_in = ptho + 'output'+strtrim(nboots,2)+'/bs'+strtrim(nboots,2)+'_stats'+nme_in+'.sav'
  if file_exists(fnme_in) eq 0 then begin
    print, 'A Bootstrap savefile for "'+nme_in+'" and ' +strtrim(nboots,2) + ' samples does not exist. Check your inputs.'
    stop
  endif
  ; restore stat_arr: (prob0, medprob, stdprob, rho0, medrho, stdrho) x npar
  restore, filename=fnme_in


  print, fl_pth
  print, 'RHO Original: ', stat_arr[*, 3]
  print, 'RHO StDev: ', stat_arr[*, 5]
  print, 'RHO Medians: ', stat_arr[*, 4]
  
  print, 'Prob. Original: ', stat_arr[*, 0]
  print, 'Prob. StDev: ', stat_arr[*, 2]
  print, 'Prob. Medians: ', stat_arr[*, 1]
  
  
  
  
  
stop
end