BSA_wrapper.pro is an IDL program that calls the four programs necessary 
to run a bootstrap analysis with the ASURV survival analysis software in 
order to determine the Spearman rank correlation coefficient and 
correlation probability for a data set possibly containing upper limits 
in one or both of the independent and dependent variables.

BSA_wrapper assumes that ASURV has been installed in ~/bin/asurv. The ASURV software can be obtained at: http://www.astrostatistics.psu.edu/statcodes/.

The inputs for BSA_wrapper are:

- mfile: an ASCII metadata file detailing the comparisons to be done (see below)
- dfile: an ASCII data file containing up to 5 pairs of columns containing value 
		and flag (0=value, 1 = upper limit)
- nboots: an integer indicating the number of bootstrap trials to run

Metadata file should contain (on separate lines)
  - Integer number of independent parameters in the data set 
	(currently accepts a maximum of 5, but this is can be 
	changed if asurv_prep_data.pro is revised)
  - Integer number of parameter pairs to be tested
  - Array of names for these parameter pairs, preferably in the 
	format YvX and with short names for X and Y (e.g., IntvIR 
	for Intrinsic Hard X-ray Luminosity vs. IR Luminosity). Do 
	not include ' '	 around each name.
  - Array of integer pairs connecting [X,Y] of pairs to be 
	examined with the order of the data columns in dfile. 
	Index starts at 0, next parameter (value, flag) is index 1.
  - String for overall data set name

Example data and metadata files are provided: test_data.dat and test_meta.dat

A trial run with nboots = 10 is recommended before trying to run nboots=1000 or 10,000.

If a path other than './' is desired, this can also be defined with the optional pth input.
Similarly, the flgow optional parameter sets a flag to allow overwriting of existing files of
the same name without further checks.


BSA_wrapper calls four programs:

asurv_prep_data.pro: an IDL function that reads in the data and meta data and creates
			an IDL savefile with the data in the expected format and
 			metadata placed in the appropriate variable. It returns the
 			name of that savefile

asurv_prep_files_resamp.pro: an IDL procedure that generates bootstrap samples via 
				selection with replacement. These are saved in an IDL 
				savefile. This procedure also creates three ASCII files
				per bootstrap sample/parameter pair. 
				- b####.dat: the bootstrapped data and flag
				- c####.dat: the command file for ASURV
				- a####_input.dat: the terminal input to run ASURV

run_asurv.pro: an IDL procedure that uses the files prepared above to run each 
		iteration of ASURV and moves the resulting output files to a separate 
		directory (to simplify deleting input files if desired later).

extract_asurv_results.pro: an IDL procedure that extracts the results from the output
			    ASCII files and places them into an IDL array, saved
			    into an IDL savefile. The procedure also plots histogram
			    of the Spearman rho parameter and the associated
			    probability of the absence of a correlation, saved into a 
			    new plots directory. The median and standard deviation of 
			    these distribution are calculated and saved into an IDL
			    savefile, along with the parameter and probability for the 
			    test run on the original dataset.

Acknowledgements: 

If you use this software for your work you should cite one of the following articles 
explaining the ASURV software:

- Feigelson, E. D. and Nelson, P. I. 1985, Astrophyscal Journal 293, 192-206, 
	"Statistical Methods for Astronomical Data with Upper Limits: I. Univariate 
	Distributions"
- Isobe, T., Feigelson, E. D., and Nelson, P. I. 1986, Astrophysical Journal, 306, 
	490-507, "Statistical Methods for Astronomical Data with Upper Limits: II. 
	Correlation and Regression"
- LaValley, M., Isobe, T. and Feigelson, E.D. 1990, Bulletin American Astronomical 
	Society (Software Reports), 22, 917-918, "ASURV", 				

Please also cite the following paper for which this bootstrap code calling ASURV 
was developed:
- Lanz, L., Hickox, R.C., Balokovic, M. et al. 2018, Astrophysical Journal, 
	"A Joint Study of X-ray and IR Reprocessing in Obscured Swift/BAT AGN"
				



	