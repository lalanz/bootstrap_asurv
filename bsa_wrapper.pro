;-----------------------------------------------------------------------------------------
; NAME: BSA_wrapper                                                                
;
; PURPOSE: Program which calls the different functions necessary to 
; determine the Spearman rank correlation coefficient and probability
; as well as the uncertainty on both in the presence of upper limits
; in either or both the dependent and independent variables
;
; CALLING SEQUENCE: BSA_wrapper, mfile, dfile, pth=, flgow=
; 
;
; INPUTS:
;    mfile  - metadata file (see comments)
;    dfile  - filename containing columns of parameter, parameter flag 
;                 (0 = value, 1 = upper limit)
;                 program can handle at this time no more than 5 parameters (see comments)
;    nboots - integer number of the number of bootstrap samples 
;
; OPTIONAL INPUTS:
;    pth    - path to directory in which to create working directories and read in mfile, 
;               dfile (assumed to be . if not specified)
;    flgow  - flag about overwriting output if already exists (0 = no, 1 = yes), 
;               default to 0
;    
;
; OUTPUTS: - IDL savefile with the results of the Spearman tests
;          - Histogram plots of the Spearman coefficient and probability
;          - Output to screen of original data value, distribution median and stdev for 
;               rho and probability
;
; COMMENTS:
; This is a wrapper program to do a bootstrap analysis to estimate the
; confidence range of the Spearman rank correlation coefficient and probability
; using the ASURV survival analysis program. It is assumed that ASURV has been installed
; in the following path ~/bin.
; 
; Meta File should contain (on separate lines):
;     - Number of parameters in data set (will be nindp; max of 5)
;     - Number of parameter pairs to be tested (will be npar)
;     - Array of names for parameter pairs; no spaces allowed/include the 'v' in 
;         XvY name (will be fl_pth)
;     - Array connecting parameters pairs in [X,Y] order and data cols in dfile 
;         (will be par_ind)
;     - Name for the total data set (will be nme_out)
;
; Currently can handle a maximum of 5 independent parameters, but program can be 
; adjusted to add more if desired
; 
; Bootstrap samples are selected by picking samples with replacement the size of 
; the original dataset.
;
; EXAMPLES: bsa_wrapper, 'test_meta.txt', 'test_data.dat', 1000, flgow=1
;
; PROCEDURES CALLED: 
;   - asurv_prep_data.pro  : import the data and metadata and put into necessary 
;                               format/variables
;   - asurv_prep_files_resamp.pro : prepare bootstrap samples and files to run ASURV
;   - run_asurv.pro: actual run all the ASURV trials
;   - extract_asurv_results.pro : extract values from the ASURV output files and 
;                                 run statistics
;
; REVISION HISTORY:
;   2018-Oct  Written by Lauranne Lanz (Dartmouth)
;-----------------------------------------------------------------------------------------
pro BSA_wrapper, mfile, dfile, nboots, pth = pthin, flgow = flg_ow

if n_elements(pthin) eq 0 then pthin = './' ; default to current directory
if n_elements(flg_ow) eq 0 then flg_ow = 0  ; default to stop if going to overwrite
nboots = fix(nboots) ; make nboots into integer if it wasn't already
if nboots gt 10000 then begin
  print, 'This many bootstrap samples may cause some unintended crashes. Check the results carefully.'
  print, 'Try no more than 1000 to get an initial sense.'
  stop
endif

; import and prepare data and metadata
dt_ar_name = asurv_prep_data(pthin, mfile, dfile, flg_ow)

; Gets nme_out, out_dir parameters
restore, dt_ar_name

; create the files necessary to run 
asurv_prep_files_resamp, nboots, dt_ar_name, flg_ow

; actually run ASURV
run_asurv, nboots, out_dir, nme_out, flg_ow

; extract the ASURV results, plot the results, and calculate the associated statistics
extract_asurv_results, nboots, out_dir, nme_out, flg_ow

end