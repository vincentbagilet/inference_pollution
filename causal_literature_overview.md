---
title: "Overview of Results found in the Causal Inference Literature"
author:
  - name: Léo Zabrocki 
    url: https://www.parisschoolofeconomics.eu/
    affiliation: Paris School of Economics
    affiliation_url: https://www.parisschoolofeconomics.eu/
  - name: Vincent Bagilet 
    url: https://vincentbagilet.github.io/
    affiliation: Columbia University - SIPA
    affiliation_url: https://www.sipa.columbia.edu/
date: "2022-04-11"
output:
  distill::distill_article:
    keep_md: true
    toc: true
    toc_depth: 3
editor_options: 
  chunk_output_type: console
---

<style>
body {
text-align: justify}
</style>



In this document, we explore the acute effects of air pollutants on health outcomes found in the causal inference literature. Using an extensive search strategy on Google Scholar, PubMed, Connected Papers and journal websites, we found a corpus of 29 relevant articles. 

For each article, we retrieved the method used by the authors, which health outcome and air pollutant they study, the point estimate and the standard error of the main result. As each paper focuses on different pollutants and outcomes, we standardize the estimates using the standard deviations of the independent and outcome variables (the formula we used is available here [here ](https://stats.stackexchange.com/questions/451358/calculating-the-standard-errors-of-the-standardized-regression-coefficients-from)):

* If we denote $\beta_{unstandardized}$ the unstandardized estimate, SD$_{X}$ the standard deviation of the treatment and SD$_{Y$  the standard deviation of the health outcome, the standardized estimate is equal to $\beta_{standardized} = \beta \times \frac{SD_{X}}{SD_{Y}}$.
* The standardized standard error SE$_{standardized}$ is then equal to $SE_{standardized} = SE_{unstandardized} \times \frac{\beta_{standardized}}{\beta_{unstandardized}}$.

For very few papers, we had to infer the mean and standard deviation of a pollutant or an health outcome with statistics such as the median and the quartiles. We use the formula found [here](https://stats.stackexchange.com/questions/256456/how-to-calculate-mean-and-standard-deviation-from-median-and-quartiles).

Our document is organized as follows:

* In the first section, we explore the distribution of the main metrics we retrieved, such as standardized estimate, sample size, first stage *F*-statistic for instrumental variable design. We also display the relationship between estimated effect sizes and the precision of these estimates.

* In the second section, we draw the forest plots of results by research design.

* In the third section, we compute the statistical power, the type M error and the probability to make a type S error for each paper using different guesses of true effect sizes. For this task, we rely on the very convenient [retrodesign](https://cran.r-project.org/web/packages/retrodesign/vignettes/Intro_To_retrodesign.html) package.

* In the fourth and last section, we mine the texts of the articles to understand to which extent researchers rely on the null hypothesis significance testing framework.


Should you have any questions or find coding errors, please do not hesitate to reach use at **vincent.bagilet@columbia.edu** and **leo.zabrocki@psemail.eu**.

# Loading and Formatting Data

We load the packages:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load packages</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://here.r-lib.org/'>here</a></span><span class='op'>)</span> <span class='co'># for files paths organization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://readxl.tidyverse.org'>readxl</a></span><span class='op'>)</span> <span class='co'># for reading xlsx files</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='op'>)</span> <span class='co'># for data manipulation and visualisation</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://github.com/andytimm/retrodesign'>retrodesign</a></span><span class='op'>)</span> <span class='co'># formulas for type-m and type-s errors</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://docs.ropensci.org/pdftools'>pdftools</a></span><span class='op'>)</span> <span class='co'># for text mining pdf</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://yihui.org/knitr/'>knitr</a></span><span class='op'>)</span> <span class='co'># for tables</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://haozhu233.github.io/kableExtra/'>kableExtra</a></span><span class='op'>)</span> <span class='co'># for building nice tables</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://github.com/eclarke/ggbeeswarm'>ggbeeswarm</a></span><span class='op'>)</span> <span class='co'># for bees swarm plots</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://patchwork.data-imaginist.com'>patchwork</a></span><span class='op'>)</span> <span class='co'># for combining plots</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://www.rforge.net/Cairo/'>Cairo</a></span><span class='op'>)</span> <span class='co'># for printing specific fonts</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://vincentbagilet.github.io/mediocrethemes/'>mediocrethemes</a></span><span class='op'>)</span>

<span class='fu'><a href='https://vincentbagilet.github.io/mediocrethemes/reference/set_mediocre_all.html'>set_mediocre_all</a></span><span class='op'>(</span><span class='op'>)</span>
<span class='co'>#color for beeswarm graphs</span>
<span class='va'>my_blue</span> <span class='op'>&lt;-</span> <span class='st'>"#00313C"</span>
<span class='va'>my_orange</span> <span class='op'>&lt;-</span> <span class='st'>"#FB9637"</span>
</code></pre></div>

</div>


We load the literature review data:

<div class="layout-chunk" data-layout="l-body">
<div data-pagedtable="false">
  <script data-pagedtable-source type="application/json">
{"columns":[{"label":["paper_id"],"name":[1],"type":["chr"],"align":["left"]},{"label":["publication_year"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["field"],"name":[3],"type":["chr"],"align":["left"]},{"label":["context"],"name":[4],"type":["chr"],"align":["left"]},{"label":["model"],"name":[5],"type":["chr"],"align":["left"]},{"label":["outcome"],"name":[6],"type":["chr"],"align":["left"]},{"label":["health_outcome_type"],"name":[7],"type":["chr"],"align":["left"]},{"label":["independent_variable"],"name":[8],"type":["chr"],"align":["left"]},{"label":["temporal_scale"],"name":[9],"type":["chr"],"align":["left"]},{"label":["sample_size"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["increase_independent_variable"],"name":[11],"type":["chr"],"align":["left"]},{"label":["standardized_effect"],"name":[12],"type":["chr"],"align":["left"]},{"label":["mean_outcome"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["sd_outcome"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["mean_independant_variable"],"name":[15],"type":["chr"],"align":["left"]},{"label":["sd_independent_variable"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["estimate"],"name":[17],"type":["dbl"],"align":["right"]},{"label":["standard_error"],"name":[18],"type":["dbl"],"align":["right"]},{"label":["first_stage_statistic"],"name":[19],"type":["chr"],"align":["left"]},{"label":["f_statistic"],"name":[20],"type":["dbl"],"align":["right"]},{"label":["paper_label"],"name":[21],"type":["chr"],"align":["left"]}],"data":[{"1":"Chen","2":"2018","3":"Epidemiology","4":"Toronto, Canada","5":"Reduced-Form","6":"Asthma-Related Emergency Department Visits","7":"Hospital","8":"Air Quality Eligibility","9":"Daily","10":"143","11":"Air Quality Eligibility Dummy","12":"No","13":"26.00000","14":"NA","15":"0.28999999999999998","16":"1.000","17":"-2.05000000","18":"9.948980e-01","19":"__NA__","20":"NA","21":"Chen et al. (2018)"},{"1":"Chen","2":"2018","3":"Epidemiology","4":"Toronto, Canada","5":"Fuzzy RDD","6":"Asthma-Related Emergency Department Visits","7":"Hospital","8":"Air Quality Altert","9":"Daily","10":"143","11":"Air Quality Altert Dummy","12":"No","13":"26.00000","14":"NA","15":"0.43","16":"1.000","17":"-4.73000000","18":"2.132653e+00","19":"__NA__","20":"NA","21":"Chen et al. (2018)"},{"1":"Isphording","2":"2021","3":"Economics","4":"Counties, Germany","5":"Instrumental Variable","6":"Mortality of Covid-19 Positive Male Patients (Age 80+)","7":"Mortality","8":"PM10","9":"Daily","10":"NA","11":"1 µg/m³ Increase In PM10","12":"No","13":"1.04000","14":"6.1400","15":"14.5","16":"7.200","17":"0.16000000","18":"5.612245e-02","19":"__NA__","20":"NA","21":"Isphording et al. (2021)"},{"1":"Zhong","2":"2017","3":"Economics","4":"Beijing, China","5":"First Stage","6":"NO2","7":"NA","8":"Number 4 Day","9":"Daily","10":"3291","11":"Number 4 Day Dummy","12":"No","13":"50.24000","14":"27.3500","15":"__NA__","16":"1.000","17":"5.76000000","18":"2.310000e+00","19":"__NA__","20":"NA","21":"Zhong et al. (2017)"},{"1":"Zhong","2":"2017","3":"Economics","4":"Beijing, China","5":"Reduced-Form","6":"Ambulance Call Rate for Coronary Heart Problem","7":"Ambulance Call","8":"Number 4 Day","9":"Daily","10":"1458","11":"Number 4 Day Dummy","12":"No","13":"0.41600","14":"0.6190","15":"__NA__","16":"1.000","17":"0.08100000","18":"3.100000e-02","19":"__NA__","20":"NA","21":"Zhong et al. (2017)"},{"1":"Zhong","2":"2017","3":"Economics","4":"Beijing, China","5":"Instrumental Variable","6":"Ambulance Call Rate for Coronary Heart Problem","7":"Ambulance Call","8":"NO2","9":"Daily","10":"1377","11":"1 µg/m³ Increase In NO2","12":"No","13":"0.41600","14":"0.6190","15":"50.24","16":"6.140","17":"0.00700000","18":"3.000000e-03","19":"__NA__","20":"NA","21":"Zhong et al. (2017)"},{"1":"Schwartz","2":"2018","3":"Epidemiology","4":"135 Cities, USA","5":"First Stage","6":"PM2.5","7":"NA","8":"Planetary Boundary Layer, Wind Speed, and Air Pressure","9":"Daily","10":"591570","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"R-squared = 18.4%","20":"NA","21":"Schwartz et al. (2018)"},{"1":"Schwartz","2":"2018","3":"Epidemiology","4":"135 Cities, USA","5":"Conventional Time Series","6":"Non-Accidental Mortality","7":"Mortality","8":"PM2.5","9":"Daily","10":"591570","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"22.80000","14":"14.0000","15":"12.8","16":"6.380","17":"0.01368000","18":"2.908163e-03","19":"NA","20":"NA","21":"Schwartz et al. (2018)"},{"1":"Schwartz","2":"2018","3":"Epidemiology","4":"135 Cities, USA","5":"Instrumental Variable","6":"Non-Accidental Mortality","7":"Mortality","8":"PM2.5","9":"Daily","10":"591570","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"22.80000","14":"14.0000","15":"12.8","16":"6.380","17":"0.03420000","18":"5.900000e-03","19":"NA","20":"NA","21":"Schwartz et al. (2018)"},{"1":"Sheldon","2":"2017","3":"Economics","4":"Singapore","5":"First Stage","6":"Pollutant Standards Index","7":"NA","8":"FRP, FRP*Wind speed, PSI Change","9":"Weekly","10":"343","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 26.76","20":"26","21":"Sheldon et al. (2017)"},{"1":"Sheldon","2":"2017","3":"Economics","4":"Singapore","5":"Reduced-Form","6":"Acute Upper Respiratory Tract Infections","7":"Hospital","8":"Indonesian Fire Radiative Power","9":"Weekly","10":"343","11":"1 SD Increase In FRP","12":"Yes","13":"2711.70000","14":"368.9000","15":"7190","16":"17521.200","17":"0.66800000","18":"2.220000e-01","19":"F-statistic = 26.76","20":"26","21":"Sheldon et al. (2017)"},{"1":"Sheldon","2":"2017","3":"Economics","4":"Singapore","5":"Instrumental Variable","6":"Acute Upper Respiratory Tract Infections","7":"Hospital","8":"Pollutant Index","9":"Weekly","10":"343","11":"1 SD Increase In PSI","12":"Yes","13":"2711.70000","14":"368.9000","15":"39.299999999999997","16":"20.800","17":"0.35000000","18":"8.730000e-02","19":"F-statistic = 26.76","20":"26","21":"Sheldon et al. (2017)"},{"1":"Schwartz","2":"2017","3":"Epidemiology","4":"Boston, USA","5":"First Stage","6":"PM2.5","7":"NA","8":"Height Of Planetary Boundary Layer and Wind Speed","9":"Daily","10":"3652","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"R-squared = 18%","20":"NA","21":"Schwartz et al. (2017)"},{"1":"Schwartz","2":"2017","3":"Epidemiology","4":"Boston, USA","5":"Instrumental Variable","6":"Non-Accidental Mortality","7":"Mortality","8":"PM2.5","9":"Daily","10":"3652","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"55.80000","14":"9.5000","15":"9.8000000000000007","16":"5.800","17":"0.07946203","18":"3.001899e-02","19":"R-squared = 18%","20":"NA","21":"Schwartz et al. (2017)"},{"1":"Schwartz","2":"2015","3":"Epidemiology","4":"Boston, USA","5":"First Stage","6":"PM2.5","7":"NA","8":"Back Trajectories of PM2.5","9":"Daily","10":"2191","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"R-squared = 34%","20":"NA","21":"Schwartz et al. (2015)"},{"1":"Schwartz","2":"2015","3":"Epidemiology","4":"Boston, USA","5":"Instrumental Variable","6":"Non-Accidental Mortality","7":"Mortality","8":"PM2.5","9":"Daily","10":"2191","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"53.00000","14":"8.9000","15":"8.3000000000000007","16":"3.780","17":"0.28090000","18":"1.189796e-01","19":"R-squared = 34%","20":"NA","21":"Schwartz et al. (2015)"},{"1":"Moretti","2":"2011","3":"Economics","4":"South California, USA","5":"First Stage","6":"Ozone","7":"NA","8":"Boat Traffic (tons)","9":"Daily","10":"1927187","11":"100,000 Tons Increase In Boat Traffic","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 5","20":"5","21":"Moretti et al. (2011)"},{"1":"Moretti","2":"2011","3":"Economics","4":"South California, USA","5":"Conventional Time Series","6":"Hospital Admissions for Respiratory Illnesses","7":"Hospital","8":"Ozone","9":"Daily","10":"1927187","11":"5-Day Increase in Ozone Of 0.01 ppm (21.4 µg/m³)","12":"No","13":"0.09700","14":"0.3330","15":"0.05","16":"0.018","17":"0.11300000","18":"2.300000e-02","19":"F-statistic = 5","20":"5","21":"Moretti et al. (2011)"},{"1":"Moretti","2":"2011","3":"Economics","4":"South California, USA","5":"Instrumental Variable","6":"Hospital Admissions for Respiratory Illnesses","7":"Hospital","8":"Ozone","9":"Daily","10":"1927187","11":"5-Day Increase in Ozone Of 0.01 ppm (21.4 µg/m³)","12":"No","13":"0.09700","14":"0.3330","15":"0.05","16":"0.018","17":"0.45400000","18":"1.620000e-01","19":"F-statistic = 5","20":"5","21":"Moretti et al. (2011)"},{"1":"Deryugina","2":"2019","3":"Economics","4":"Counties, USA","5":"First Stage","6":"PM2.5","7":"NA","8":"Wind Directions","9":"Daily","10":"1980549","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 298","20":"298","21":"Deryugina et al. (2019)"},{"1":"Deryugina","2":"2019","3":"Economics","4":"Counties, USA","5":"Conventional Time Series","6":"All Causes of Mortality (Age 65+)","7":"Mortality","8":"PM2.5","9":"Daily","10":"1980549","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"388.25000","14":"247.6000","15":"10.48","16":"7.130","17":"0.09500000","18":"2.100000e-02","19":"F-statistic = 298","20":"298","21":"Deryugina et al. (2019)"},{"1":"Deryugina","2":"2019","3":"Economics","4":"Counties, USA","5":"Instrumental Variable","6":"All Causes of Mortality (Age 65+)","7":"Mortality","8":"PM2.5","9":"Daily","10":"1980549","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"388.25000","14":"247.6000","15":"10.48","16":"7.130","17":"0.68500000","18":"6.100000e-02","19":"F-statistic = 298","20":"298","21":"Deryugina et al. (2019)"},{"1":"Schlenker","2":"2016","3":"Economics","4":"California, USA","5":"First Stage","6":"CO","7":"NA","8":"Taxi Time at Airport Is Instrumented with Taxi Time at Three Major Airports in the Eastern US","9":"Daily","10":"179580","11":"Total Taxi Time In 1,000 min","12":"No","13":"576.00000","14":"368.0000","15":"14691","16":"1852.000","17":"44.78000000","18":"5.040000e+00","19":"F-statistic = 14.1","20":"14","21":"Schlenker et al. (2016)"},{"1":"Schlenker","2":"2016","3":"Economics","4":"California, USA","5":"Conventional Time Series","6":"Acute Respiratory Hospitalization","7":"Hospital","8":"CO","9":"Daily","10":"179580","11":"1 ppb Increase in CO","12":"No","13":"608.00000","14":"568.0000","15":"576","16":"368.000","17":"0.04900000","18":"1.800000e-02","19":"NA","20":"NA","21":"Schlenker et al. (2016)"},{"1":"Schlenker","2":"2016","3":"Economics","4":"California, USA","5":"Instrumental Variable","6":"Acute Respiratory Hospitalization","7":"Hospital","8":"CO","9":"Daily","10":"179580","11":"1 ppb Increase in CO","12":"No","13":"608.00000","14":"568.0000","15":"576","16":"368.000","17":"0.39600000","18":"1.250000e-01","19":"F-statistic = 14.1","20":"14","21":"Schlenker et al. (2016)"},{"1":"Halliday","2":"2018","3":"Economics","4":"Hawaii, USA","5":"First Stage","6":"PM2.5","7":"NA","8":"SO2 Emissions From Kilauea Volcano and Wind Direction","9":"Daily","10":"6814","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 29.54","20":"29","21":"Halliday et al. (2018)"},{"1":"Halliday","2":"2018","3":"Economics","4":"Hawaii, USA","5":"Conventional Time Series","6":"ER Admission for Pulmonary Outcomes","7":"Hospital","8":"PM2.5","9":"Daily","10":"17745","11":"1 µg/m³ Increase in PM2.5","12":"No","13":"5.00000","14":"3.2300","15":"6.52","16":"3.300","17":"0.03000000","18":"6.000000e-03","19":"F-statistic = 29.54","20":"29","21":"Halliday et al. (2018)"},{"1":"Halliday","2":"2018","3":"Economics","4":"Hawaii, USA","5":"Instrumental Variable","6":"ER Admission for Pulmonary Outcomes","7":"Hospital","8":"PM2.5","9":"Daily","10":"6195","11":"1 µg/m³ Increase in PM2.5","12":"No","13":"5.00000","14":"3.2300","15":"6.52","16":"3.300","17":"0.55300000","18":"8.700000e-02","19":"F-statistic = 29.54","20":"29","21":"Halliday et al. (2018)"},{"1":"Arceo-Gomez","2":"2015","3":"Economics","4":"Mexico City, Mexico","5":"First Stage","6":"PM10","7":"NA","8":"Thermal Inversions","9":"Weekly","10":"18017","11":"Number of Thermal Inversions","12":"No","13":"43.37000","14":"23.8500","15":"1.68","16":"1.880","17":"3.31100000","18":"5.030000e-01","19":"F-statistic = 43.37","20":"43","21":"Arceo-Gomez et al. (2015)"},{"1":"Arceo-Gomez","2":"2015","3":"Economics","4":"Mexico City, Mexico","5":"Conventional Time Series","6":"Infant Mortality","7":"Infant Mortality","8":"PM10","9":"Weekly","10":"18017","11":"1 µg/m³ Increase In PM10","12":"No","13":"38.21000","14":"56.9300","15":"43.37","16":"23.850","17":"0.06490000","18":"2.340000e-02","19":"F-statistic = 43.37","20":"43","21":"Arceo-Gomez et al. (2015)"},{"1":"Arceo-Gomez","2":"2015","3":"Economics","4":"Mexico City, Mexico","5":"Instrumental Variable","6":"Infant Mortality","7":"Infant Mortality","8":"PM10","9":"Weekly","10":"18017","11":"1 µg/m³ Increase In PM10","12":"No","13":"38.21000","14":"56.9300","15":"43.37","16":"23.850","17":"0.23130000","18":"8.210000e-02","19":"F-statistic = 43.37","20":"43","21":"Arceo-Gomez et al. (2015)"},{"1":"Knittel","2":"2016","3":"Economics","4":"California, USA","5":"First Stage","6":"PM10","7":"NA","8":"Road Traffic Flow And Weather Variables","9":"Weekly","10":"73109698","11":"NA","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 80.51","20":"80","21":"Knittel et al. (2016)"},{"1":"Knittel","2":"2016","3":"Economics","4":"California, USA","5":"Instrumental Variable","6":"Infant Mortality","7":"Infant Mortality","8":"PM10","9":"Weekly","10":"73109698","11":"1 µg/m³ Increase In PM10","12":"No","13":"0.00281","14":"0.0529","15":"28.94","16":"14.940","17":"0.00190000","18":"9.000000e-04","19":"F-statistic = 80.51","20":"80","21":"Knittel et al. (2016)"},{"1":"Bauernschuster","2":"2017","3":"Economics","4":"5 Largest Cities, Germany","5":"Difference in Differences","6":"PM10","7":"NA","8":"Public Transport Strikes Dummy","9":"Hourly","10":"33007","11":"Public Transport Strikes Dummy","12":"No","13":"37.67000","14":"21.2700","15":"NA","16":"1.000","17":"5.10100000","18":"1.336000e+00","19":"NA","20":"NA","21":"Bauernschuster et al. (2017)"},{"1":"Bauernschuster","2":"2017","3":"Economics","4":"5 Largest Cities, Germany","5":"Difference in Differences","6":"Admissions for Abnormalities of Breathing (age below 5)","7":"Hospital","8":"Public Transport Strikes Dummy","9":"Daily","10":"11000","11":"Public Transport Strikes Dummy","12":"No","13":"0.22000","14":"0.4900","15":"NA","16":"1.000","17":"0.07400000","18":"1.800000e-02","19":"NA","20":"NA","21":"Bauernschuster et al. (2017)"},{"1":"Mullins","2":"2014","3":"Economics","4":"Santiago Metropole, Chile","5":"Difference in Differences with Matching","6":"PM10","7":"NA","8":"DiD Interaction","9":"Daily","10":"134","11":"DiD Interaction","12":"No","13":"106.52700","14":"NA","15":"NA","16":"1.000","17":"-36.16400000","18":"7.390000e+00","19":"NA","20":"NA","21":"Mullins et al. (2014)"},{"1":"Mullins","2":"2014","3":"Economics","4":"Santiago Metropole, Chile","5":"Difference in Differences with Matching","6":"Cumulative Deaths (age > 64)","7":"Mortality","8":"DiD Interaction","9":"Daily","10":"119","11":"DiD Interaction","12":"No","13":"64.64100","14":"NA","15":"NA","16":"1.000","17":"-21.82400000","18":"1.032000e+01","19":"NA","20":"NA","21":"Mullins et al. (2014)"},{"1":"Giaccherini","2":"2019","3":"Economics","4":"Municipalities, Italy","5":"First Stage","6":"PM10","7":"NA","8":"Public Transport Strikes Dummy","9":"Daily","10":"121545","11":"Public Transport Strikes Dummy","12":"No","13":"18.62800","14":"10.3700","15":"NA","16":"1.000","17":"1.12000000","18":"2.500000e-01","19":"F-statistic = 26.497","20":"26","21":"Giaccherini et al. (2019)"},{"1":"Giaccherini","2":"2019","3":"Economics","4":"Municipalities, Italy","5":"Conventional Time Series","6":"Respiratory Hospital Admission","7":"Hospital","8":"PM10","9":"Daily","10":"121545","11":"1 µg/m³ Increase In PM10","12":"No","13":"2.04900","14":"1.3080","15":"18.628","16":"10.370","17":"-0.00100000","18":"5.000000e-04","19":"F-statistic = 26.497","20":"26","21":"Giaccherini et al. (2019)"},{"1":"Giaccherini","2":"2019","3":"Economics","4":"Municipalities, Italy","5":"Instrumental Variable","6":"Respiratory Hospital Admission","7":"Hospital","8":"PM10","9":"Daily","10":"121545","11":"1 µg/m³ Increase In PM10","12":"No","13":"2.04900","14":"1.3080","15":"18.628","16":"10.370","17":"0.05270000","18":"1.740000e-02","19":"F-statistic = 26.497","20":"26","21":"Giaccherini et al. (2019)"},{"1":"Godzinski","2":"2019","3":"Economics","4":"10 Cities, France","5":"Difference in Differences","6":"CO","7":"NA","8":"Public Transport Strikes Dummy","9":"Daily","10":"10605","11":"Public Transport Strikes Dummy","12":"No","13":"296.50000","14":"NA","15":"NA","16":"1.000","17":"30.37000000","18":"1.266000e+01","19":"NA","20":"NA","21":"Godzinski et al. (2019)"},{"1":"Godzinski","2":"2019","3":"Economics","4":"10 Cities, France","5":"Difference in Differences","6":"Emergency Admissions for Upper Respiratory System (Age 0-4)","7":"Hospital","8":"Public Transport Strikes Dummy","9":"Daily","10":"13547","11":"Public Transport Strikes Dummy","12":"No","13":"0.82000","14":"1.2400","15":"NA","16":"1.000","17":"0.38600000","18":"1.040000e-01","19":"NA","20":"NA","21":"Godzinski et al. (2019)"},{"1":"He","2":"2016","3":"Economics","4":"34 Urban Districts, China","5":"First Stage","6":"PM10","7":"NA","8":"Regulation Status Indicator and Traffic Control Status Indicator","9":"Monthly","10":"1930","11":"NA","12":"NA","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 25.18","20":"25","21":"He et al. (2016)"},{"1":"He","2":"2016","3":"Economics","4":"34 Urban Districts, China","5":"Instrumental Variable","6":"Monthly Standardized Mortality Rate","7":"NA","8":"PM10","9":"Monthly","10":"1930","11":"1 µg/m³ Increase In PM10","12":"No","13":"4.12000","14":"1.6100","15":"97.99","16":"36.220","17":"0.03444320","18":"1.631520e-02","19":"F-statistic = 25.18","20":"25","21":"He et al. (2016)"},{"1":"Barwick","2":"2018","3":"Economics","4":"All Cities, China","5":"First Stage","6":"PM2.5","7":"NA","8":"Spatial Spillovers of PM2.5","9":"Daily","10":"192586","11":"Spatial Spillovers of PM2.5","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 61.93","20":"61","21":"Barwick et al. (2018)"},{"1":"Barwick","2":"2018","3":"Economics","4":"All Cities, China","5":"Conventional Time Series","6":"Number of Health Spending Transactions","7":"Health Spending","8":"PM2.5","9":"Daily","10":"192586","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"7229.20000","14":"21308.6000","15":"56.33","16":"46.370","17":"79.52120000","18":"1.445840e+01","19":"F-statistic = 61.93","20":"61","21":"Barwick et al. (2018)"},{"1":"Barwick","2":"2018","3":"Economics","4":"All Cities, China","5":"Instrumental Variable","6":"Number of Health Spending Transactions","7":"Health Spending","8":"PM2.5","9":"Daily","10":"192586","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"7229.20000","14":"21308.6000","15":"56.33","16":"46.370","17":"469.89800000","18":"6.506280e+01","19":"F-statistic = 61.93","20":"61","21":"Barwick et al. (2018)"},{"1":"Williams","2":"2018","3":"Economics","4":"USA","5":"Conventional Time Series","6":"Rescue Events","7":"Rescue Events","8":"PM2.5","9":"Daily","10":"2874","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"0.45000","14":"1.7500","15":"8.7100000000000009","16":"4.930","17":"0.00030600","18":"1.246500e-04","19":"NA","20":"NA","21":"Williams et al. (2018)"},{"1":"Jans","2":"2018","3":"Economics","4":"Sweden","5":"First Stage","6":"PM10","7":"NA","8":"Inversion Dummy","9":"Daily","10":"34156","11":"Inversion Dummy","12":"No","13":"18.07000","14":"13.0900","15":"NA","16":"1.000","17":"5.09100000","18":"3.410000e-01","19":"NA","20":"NA","21":"Jans et al. (2018)"},{"1":"Jans","2":"2018","3":"Economics","4":"Sweden","5":"Reduced-Form","6":"Health Care Visits for Respiratory Illness Per 10,000 Children","7":"Hospital","8":"Inversion Dummy","9":"Daily","10":"34156","11":"Inversion Dummy","12":"No","13":"2.07300","14":"1.5900","15":"NA","16":"1.000","17":"0.10400000","18":"2.800000e-02","19":"NA","20":"NA","21":"Jans et al. (2018)"},{"1":"Jia","2":"2019","3":"Economics","4":"South Korea","5":"Reduced-Form","6":"Mortality Rates for Respiratory and Cardiovascular Diseases","7":"Mortality","8":"Dusty Days Times China's AQI","9":"Monthly","10":"28024","11":"Interaction Of Number of Days With Dust With China's Mean AQI (Number Of Days Set To 1 And AQI To 12, Its SD)","12":"No","13":"12.23000","14":"8.2700","15":"NA","16":"1.000","17":"0.03800000","18":"1.600000e-02","19":"NA","20":"NA","21":"Jia et al. (2019)"},{"1":"Baccini","2":"2017","3":"Epidemiology","4":"Milan, Italy","5":"Propensity Score Matching","6":"Non-Accidental Mortality","7":"Mortality","8":"PM10 > 40 µg/m³","9":"Daily","10":"1461","11":"Dummy for PM10 > 40 µg/m³","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"1079.00000000","18":"4.913265e+02","19":"NA","20":"NA","21":"Baccini et al. (2017)"},{"1":"Forastiere","2":"2020","3":"Epidemiology","4":"Milan, Italy","5":"Generalized propensity score","6":"Non-Accidental Mortality","7":"Mortality","8":"Setting The Daily Exposure Levels > To 40 µg/m³ To 40","9":"Daily","10":"1460","11":"Setting The Daily Exposure Levels > 40 µg/m³ To Exactly 40","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"1157.00000000","18":"2.489796e+02","19":"NA","20":"NA","21":"Forastiere et al. (2020)"},{"1":"Beard","2":"2012","3":"Epidemiology","4":"Salt Lake County, USA","5":"Time-stratified case-crossover design","6":"Emergency Visits For Asthma","7":"Hospital","8":"Thermal Inversions","9":"Daily","10":"3425","11":"Inversion Dummy","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"1.14000000","18":"8.163265e-02","19":"NA","20":"NA","21":"Beard et al. (2012)"},{"1":"He","2":"2020","3":"Economics","4":"China","5":"First Stage","6":"PM2.5","7":"NA","8":"Straw Burning","9":"Monthly","10":"1538","11":"1 Straw Burning","12":"No","13":"49.20000","14":"24.2000","15":"2","16":"7.800","17":"0.47900000","18":"8.200000e-02","19":"F-statistic = 16.2","20":"16","21":"He et al. (2020)"},{"1":"He","2":"2020","3":"Economics","4":"China","5":"Reduced-Form","6":"Monthly Number of Deaths for All-Causes","7":"Mortality","8":"Straw Burning","9":"Monthly","10":"1538","11":"1 Straw Burning","12":"No","13":"189.00000","14":"141.0000","15":"2","16":"7.800","17":"0.29484000","18":"1.512000e-01","19":"F-statistic = 16.2","20":"16","21":"He et al. (2020)"},{"1":"He","2":"2020","3":"Economics","4":"China","5":"Instrumental Variable","6":"Monthly Number of Deaths for All-Causes","7":"Mortality","8":"PM2.5","9":"Monthly","10":"1538","11":"1 µg/m³ Increase in PM2.5","12":"No","13":"189.00000","14":"141.0000","15":"49.2","16":"24.200","17":"0.59913000","18":"2.268000e-01","19":"F-statistic = 16.2","20":"16","21":"He et al. (2020)"},{"1":"Kim","2":"2021","3":"Economics","4":"South Korea","5":"First Stage","6":"PM10","7":"NA","8":"Average PM10 Level By Date","9":"Daily","10":"58372","11":"1 µg/m³ Increase in PM10","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistic = 32.13","20":"32","21":"Kim et al. (2021)"},{"1":"Kim","2":"2021","3":"Economics","4":"South Korea","5":"Instrumental Variable","6":"Hospital Admissions for Respiratory Illnesses","7":"Hospital","8":"PM10","9":"Daily","10":"58372","11":"1 µg/m³ Increase in PM10","12":"No","13":"526.23000","14":"659.9700","15":"49.23","16":"30.930","17":"2.12596900","18":"6.683121e-01","19":"F-statistic = 32.13","20":"32","21":"Kim et al. (2021)"},{"1":"Ebenstein","2":"2015","3":"Epidemiology","4":"2 Cities, Israel","5":"First Stage","6":"PM10","7":"NA","8":"Sandstorms","9":"Daily","10":"2011","11":"Sandstorms Dummy","12":"No","13":"55.57500","14":"64.1070","15":"NA","16":"1.000","17":"298.70000000","18":"1.181000e+01","19":"F-statistic = 639.22","20":"639","21":"Ebenstein et al. (2015)"},{"1":"Ebenstein","2":"2015","3":"Epidemiology","4":"2 Cities, Israel","5":"Conventional Time Series","6":"Hospital Admissions Due To Lung Illnesses","7":"Hospital","8":"PM10","9":"Daily","10":"2011","11":"1 µg/m³ Increase In PM10","12":"No","13":"3.87000","14":"2.6670","15":"55.575000000000003","16":"64.107","17":"0.00400000","18":"1.000000e-03","19":"F-statistic = 639.22","20":"639","21":"Ebenstein et al. (2015)"},{"1":"Ebenstein","2":"2015","3":"Epidemiology","4":"2 Cities, Israel","5":"Instrumental Variable","6":"Hospital Admissions Due To Lung Illnesses","7":"Hospital","8":"PM10","9":"Daily","10":"2011","11":"1 µg/m³ Increase In PM10","12":"No","13":"3.87000","14":"2.6670","15":"55.575000000000003","16":"64.107","17":"0.00400000","18":"2.000000e-03","19":"F-statistic = 639.22","20":"639","21":"Ebenstein et al. (2015)"},{"1":"Austin","2":"2020","3":"Economics","4":"Counties, USA","5":"First Stage","6":"PM2.5","7":"NA","8":"Wind Directions","9":"Daily","10":"106957","11":"Wind Directions","12":"No","13":"NA","14":"NA","15":"NA","16":"NA","17":"NA","18":"NA","19":"F-statistics = 248.68","20":"248","21":"Austin et al. (2020)"},{"1":"Austin","2":"2020","3":"Economics","4":"Counties, USA","5":"Instrumental Variable","6":"Rates of Confirmed COVID-19 Deaths","7":"Mortality","8":"PM2.5","9":"Daily","10":"107171","11":"1 µg/m³ Increase In PM2.5","12":"No","13":"0.18900","14":"0.8310","15":"6.7720000000000002","16":"4.610","17":"0.13100000","18":"5.060000e-02","19":"F-statistics = 248.68","20":"248","21":"Austin et al. (2020)"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>
</div>

</div>


We retrieved data for 29 articles. We then compute standardized effects and their associated 99% and 95% confidence intervals.

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute standardized estimates and standard errors</span>
<span class='va'>data</span> <span class='op'>&lt;-</span> <span class='va'>data</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>
    standardized_estimate <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span>
      <span class='va'>standardized_effect</span> <span class='op'>==</span> <span class='st'>"No"</span>,
      <span class='va'>estimate</span> <span class='op'>*</span> <span class='va'>sd_independent_variable</span> <span class='op'>/</span> <span class='va'>sd_outcome</span>,
      <span class='va'>estimate</span>
    <span class='op'>)</span>,
    standardized_standard_error <span class='op'>=</span>  <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span>
      <span class='va'>standardized_effect</span> <span class='op'>==</span> <span class='st'>"No"</span>,
      <span class='va'>standard_error</span> <span class='op'>*</span> <span class='va'>standardized_estimate</span> <span class='op'>/</span> <span class='va'>estimate</span>,
      <span class='va'>standard_error</span>
    <span class='op'>)</span>
  <span class='op'>)</span>

<span class='co'># compute confidence intervals</span>
<span class='va'>data</span> <span class='op'>&lt;-</span> <span class='va'>data</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>
    upper_bound_95 <span class='op'>=</span> <span class='va'>standardized_estimate</span> <span class='op'>+</span> <span class='op'>(</span><span class='op'>-</span><span class='fu'><a href='https://rdrr.io/r/stats/Normal.html'>qnorm</a></span><span class='op'>(</span><span class='op'>(</span><span class='fl'>1</span> <span class='op'>-</span> <span class='fl'>0.95</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>2</span><span class='op'>)</span> <span class='op'>*</span> <span class='va'>standardized_standard_error</span><span class='op'>)</span>,
    lower_bound_95 <span class='op'>=</span> <span class='va'>standardized_estimate</span> <span class='op'>-</span> <span class='op'>(</span><span class='op'>-</span><span class='fu'><a href='https://rdrr.io/r/stats/Normal.html'>qnorm</a></span><span class='op'>(</span><span class='op'>(</span><span class='fl'>1</span> <span class='op'>-</span> <span class='fl'>0.95</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>2</span><span class='op'>)</span> <span class='op'>*</span> <span class='va'>standardized_standard_error</span><span class='op'>)</span>,
    upper_bound_99 <span class='op'>=</span> <span class='va'>standardized_estimate</span> <span class='op'>+</span> <span class='op'>(</span><span class='op'>-</span><span class='fu'><a href='https://rdrr.io/r/stats/Normal.html'>qnorm</a></span><span class='op'>(</span><span class='op'>(</span><span class='fl'>1</span> <span class='op'>-</span> <span class='fl'>0.99</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>2</span><span class='op'>)</span> <span class='op'>*</span> <span class='va'>standardized_standard_error</span><span class='op'>)</span>,
    lower_bound_99 <span class='op'>=</span> <span class='va'>standardized_estimate</span> <span class='op'>-</span> <span class='op'>(</span><span class='op'>-</span><span class='fu'><a href='https://rdrr.io/r/stats/Normal.html'>qnorm</a></span><span class='op'>(</span><span class='op'>(</span><span class='fl'>1</span> <span class='op'>-</span> <span class='fl'>0.99</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>2</span><span class='op'>)</span> <span class='op'>*</span> <span class='va'>standardized_standard_error</span><span class='op'>)</span>,
  <span class='op'>)</span>
</code></pre></div>

</div>


# Overview of Main Metrics Distribution

In this section, we explore the distribution of standardized, sample sizes and first-stage *F*-statistics. We also explore the relationship between estimated effect sizes and the inverse of standard errors, a metric for an estimate's precision.

### Standardized Estimates

We select the standardized estimates for causal inference methods (we omit first stage and conventional time series estimates). We display below the summary statistics for the distribution of standardized estimates:


<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> First Quartile </th>
   <th style="text-align:center;"> Mean </th>
   <th style="text-align:center;"> Median </th>
   <th style="text-align:center;"> Third Quartile </th>
   <th style="text-align:center;"> Maximum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> 0.0045949 </td>
   <td style="text-align:center;"> 0.0674217 </td>
   <td style="text-align:center;"> 0.2636164 </td>
   <td style="text-align:center;"> 0.1308562 </td>
   <td style="text-align:center;"> 0.3839063 </td>
   <td style="text-align:center;"> 1.022553 </td>
  </tr>
</tbody>
</table>

</div>


We draw the beeswarm plot of standardized estimates:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-5-1.png" width="100%" style="display: block; margin: auto;" />

</div>


We see that half of the studies estimated effect sizes below 0.3 standard deviation.  6 studies found very large effect sizes superior to 0.5 standard deviation.

To reduce a bit the the heterogeneity between studies, we plot the same graph by mortality and hospital admission outcomes:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-6-1.png" width="100%" style="display: block; margin: auto;" />

</div>


### Sample Sizes

We display below the distribution of studies' sample sizes:

<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> First Quartile </th>
   <th style="text-align:center;"> Mean </th>
   <th style="text-align:center;"> Median </th>
   <th style="text-align:center;"> Third Quartile </th>
   <th style="text-align:center;"> Maximum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> 343 </td>
   <td style="text-align:center;"> 1950.25 </td>
   <td style="text-align:center;"> 3016484 </td>
   <td style="text-align:center;"> 15782 </td>
   <td style="text-align:center;"> 117951.5 </td>
   <td style="text-align:center;"> 73109698 </td>
  </tr>
</tbody>
</table>

</div>


The median number of observations in the causal inference literature is about 15,000. We display the distribution of sample sizes using a beeswarm plot with a log base 10 scale:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-8-1.png" width="100%" style="display: block; margin: auto;" />

</div>


### First *F*-Statistics


In the causal inference literature, 19 studies are based on an instrumental variable research design. The strength of the instrument is often assessed with the first stage *F*-statistic. We display below descriptive statistics for the first *F*-statistics distribution:

<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> First Quartile </th>
   <th style="text-align:center;"> Mean </th>
   <th style="text-align:center;"> Median </th>
   <th style="text-align:center;"> Third Quartile </th>
   <th style="text-align:center;"> Maximum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> 5 </td>
   <td style="text-align:center;"> 25.25 </td>
   <td style="text-align:center;"> 110.1429 </td>
   <td style="text-align:center;"> 30.5 </td>
   <td style="text-align:center;"> 75.25 </td>
   <td style="text-align:center;"> 639 </td>
  </tr>
</tbody>
</table>

</div>


Half of the first stage *F*-statistics are below 31. We display the distribution of first-stage *F*-Statistics with a beeswarm plot and a log base 10 scale:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-10-1.png" width="100%" style="display: block; margin: auto;" />

</div>


### Estimated Effect Sizes versus Precision

We plot below the relationship between the standardized estimates and the inverse of the standard errors:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-11-1.png" width="100%" style="display: block; margin: auto;" />

</div>


We clearly see a negative linear relationship between estimated effect sizes and precision. To limit a bit the heterogenity between studies, we also reproduce the previous graph but by health outcomes:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-12-1.png" width="100%" style="display: block; margin: auto;" />

</div>



# Forest Plots

In this section, we create forest plots. For each study and empirical strategy, we display the standardized estimates with their associated 95% confidence intervals. We first create the relevant data set.

<div class="layout-chunk" data-layout="l-body">


</div>


### 2SLS Estimates

We display below the forest plot for all 2SLS estimates:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-14-1.png" width="100%" style="display: block; margin: auto;" />

</div>


We display below the forest plot for 2SLS estimates focused on mortality outcomes:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-15-1.png" width="100%" style="display: block; margin: auto;" />

</div>


We display below the forest plot for 2SLS estimates focused on hospital outcomes:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-16-1.png" width="100%" style="display: block; margin: auto;" />

</div>


### Reduced-Form Estimates

For articles based on an instrumental variable strategy, we also display below the reduced-form estimates:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-17-1.png" width="100%" style="display: block; margin: auto;" />

</div>


### Conventional Time Series Estimates

Several papers fit a conventional time series model in order to compare the resulting estimates with those of a 2SLS procedure:  

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-18-1.png" width="100%" style="display: block; margin: auto;" />

</div>


# Statistical Power, Type M and S Errors

In this section, we compute the statistical power, the exaggeration factor (Type M error) and the probability to make a type S error for each study. We rely on the `retrodesign` package.

### Computing Statistical Power, Type M and S errors

To compute the three metrics, we need to make an assumption about the true effect size of each study. We find three different ways to proceed:

1. We first define the true effect sizes as a decreasing fraction of the estimates. We want to see how the overall distribution of the three metrics evolve with as we decrease the hypothesized true effect size.
2. We then take as the true effect size what what was found with a standard OLS model for papers based on instrumental variable design.

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># test type-m and type-s errors</span>
<span class='va'>data_retrodesign</span> <span class='op'>&lt;-</span> <span class='va'>data</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='op'>!</span><span class='op'>(</span><span class='va'>model</span> <span class='op'>%in%</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='st'>"First Stage"</span>, <span class='st'>"Conventional Time Series"</span><span class='op'>)</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>paper_id</span> <span class='op'>!=</span> <span class='st'>"Beard"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>lower_bound_95</span> <span class='op'>&gt;</span> <span class='fl'>0</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>drop_na</span><span class='op'>(</span><span class='va'>health_outcome_type</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>select</span><span class='op'>(</span><span class='va'>paper_label</span>, <span class='va'>model</span>, <span class='va'>estimate</span>, <span class='va'>standard_error</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>model <span class='op'>=</span> <span class='fu'>fct_relevel</span><span class='op'>(</span>
    <span class='va'>model</span>,
    <span class='st'>"Reduced-Form"</span>,
    <span class='st'>"Instrumental Variable"</span>,
    <span class='st'>"Difference in Differences"</span>
  <span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>



### True Effect Sizes as Fractions of Estimates

For each study, we compute the statistical power, the exaggeration factor and the probability to make a type S error by defining their true effect sizes as decreasing fraction of the estimates. 

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute power, type m and s errors for decreasing true effect sizes</span>
<span class='va'>data_retrodesign_fraction</span> <span class='op'>&lt;-</span> <span class='va'>data_retrodesign</span> <span class='op'>%&gt;%</span>
  <span class='fu'>crossing</span><span class='op'>(</span>percentage <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/seq.html'>seq</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fl'>100</span><span class='op'>)</span><span class='op'>/</span><span class='fl'>100</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>hypothetical_effect_size <span class='op'>=</span> <span class='va'>percentage</span><span class='op'>*</span><span class='va'>estimate</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>
    power <span class='op'>=</span> <span class='fu'>map2</span><span class='op'>(</span>
      <span class='va'>hypothetical_effect_size</span>,
      <span class='va'>standard_error</span>,
      <span class='op'>~</span> <span class='fu'><a href='https://rdrr.io/pkg/retrodesign/man/retro_design.html'>retro_design</a></span><span class='op'>(</span><span class='va'>.x</span>, <span class='va'>.y</span><span class='op'>)</span><span class='op'>$</span><span class='va'>power</span> <span class='op'>*</span> <span class='fl'>100</span>
    <span class='op'>)</span>,
    type_s <span class='op'>=</span> <span class='fu'>map2</span><span class='op'>(</span>
      <span class='va'>hypothetical_effect_size</span>,
      <span class='va'>standard_error</span>,
      <span class='op'>~</span> <span class='fu'><a href='https://rdrr.io/pkg/retrodesign/man/retro_design.html'>retro_design</a></span><span class='op'>(</span><span class='va'>.x</span>, <span class='va'>.y</span><span class='op'>)</span><span class='op'>$</span><span class='va'>typeS</span> <span class='op'>*</span> <span class='fl'>100</span>
    <span class='op'>)</span>,
    type_m <span class='op'>=</span> <span class='fu'>map2</span><span class='op'>(</span>
      <span class='va'>hypothetical_effect_size</span>,
      <span class='va'>standard_error</span>,
      <span class='op'>~</span> <span class='fu'><a href='https://rdrr.io/pkg/retrodesign/man/retro_design.html'>retro_design</a></span><span class='op'>(</span><span class='va'>.x</span>, <span class='va'>.y</span><span class='op'>)</span><span class='op'>$</span><span class='va'>typeM</span>
    <span class='op'>)</span>
  <span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>unnest</span><span class='op'>(</span>cols <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='va'>power</span>, <span class='va'>type_s</span>, <span class='va'>type_m</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>percentage</span> <span class='op'>&gt;=</span> <span class='fl'>0.25</span><span class='op'>)</span>
</code></pre></div>

</div>


We plot below the three metrics for the different scenarios:

<div class="layout-chunk" data-layout="l-body">
<img src="causal_literature_overview_files/figure-html5/unnamed-chunk-21-1.png" width="100%" style="display: block; margin: auto;" />

</div>


We display below summary statistics for the scenario where true effect sizes are equal to 75% of observed estimates:

<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:center;"> Metric </th>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> First Quartile </th>
   <th style="text-align:center;"> Mean </th>
   <th style="text-align:center;"> Median </th>
   <th style="text-align:center;"> Third Quartile </th>
   <th style="text-align:center;"> Maximum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> Exaggeration Factor </td>
   <td style="text-align:center;"> 1.0 </td>
   <td style="text-align:center;"> 1.1 </td>
   <td style="text-align:center;"> 1.3 </td>
   <td style="text-align:center;"> 1.3 </td>
   <td style="text-align:center;"> 1.4 </td>
   <td style="text-align:center;"> 1.7 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> Statistical Power (%) </td>
   <td style="text-align:center;"> 32.3 </td>
   <td style="text-align:center;"> 49.8 </td>
   <td style="text-align:center;"> 64.6 </td>
   <td style="text-align:center;"> 59.4 </td>
   <td style="text-align:center;"> 81.0 </td>
   <td style="text-align:center;"> 100.0 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> Type S Probability (%) </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0.1 </td>
  </tr>
</tbody>
</table>

</div>


We also display below summary statistics for the scenario where true effect sizes are equal to 50% of observed estimates:

<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:center;"> Metric </th>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> First Quartile </th>
   <th style="text-align:center;"> Mean </th>
   <th style="text-align:center;"> Median </th>
   <th style="text-align:center;"> Third Quartile </th>
   <th style="text-align:center;"> Maximum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> Exaggeration Factor </td>
   <td style="text-align:center;"> 1 </td>
   <td style="text-align:center;"> 1.4 </td>
   <td style="text-align:center;"> 1.7 </td>
   <td style="text-align:center;"> 1.8 </td>
   <td style="text-align:center;"> 2.0 </td>
   <td style="text-align:center;"> 2.5 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> Statistical Power (%) </td>
   <td style="text-align:center;"> 17 </td>
   <td style="text-align:center;"> 25.6 </td>
   <td style="text-align:center;"> 41.3 </td>
   <td style="text-align:center;"> 31.1 </td>
   <td style="text-align:center;"> 47.4 </td>
   <td style="text-align:center;"> 100.0 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> Type S Probability (%) </td>
   <td style="text-align:center;"> 0 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 0.2 </td>
   <td style="text-align:center;"> 0.1 </td>
   <td style="text-align:center;"> 0.2 </td>
   <td style="text-align:center;"> 0.9 </td>
  </tr>
</tbody>
</table>

</div>


### True Effect Sizes Equal to OLS Estimates for IV Designs

We also computed statistical power, the exaggeration factor and the probability to make a type S error for the 9 articles based on instrumental variables which also displayed the estimates for a standard OLS model:

<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:left;"> Paper </th>
   <th style="text-align:center;"> Statistical Power (%) </th>
   <th style="text-align:center;"> Probability of Type S Error (%) </th>
   <th style="text-align:center;"> Exaggeration Factor </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Schwartz et al. (2018) </td>
   <td style="text-align:center;"> 64.0 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 1.3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Moretti et al. (2011) </td>
   <td style="text-align:center;"> 10.7 </td>
   <td style="text-align:center;"> 3.7 </td>
   <td style="text-align:center;"> 3.5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Deryugina et al. (2019) </td>
   <td style="text-align:center;"> 34.4 </td>
   <td style="text-align:center;"> 0.1 </td>
   <td style="text-align:center;"> 1.7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Schlenker et al. (2016) </td>
   <td style="text-align:center;"> 6.8 </td>
   <td style="text-align:center;"> 13.8 </td>
   <td style="text-align:center;"> 6.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Halliday et al. (2018) </td>
   <td style="text-align:center;"> 6.4 </td>
   <td style="text-align:center;"> 16.6 </td>
   <td style="text-align:center;"> 6.9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Arceo-Gomez et al. (2015) </td>
   <td style="text-align:center;"> 12.4 </td>
   <td style="text-align:center;"> 2.4 </td>
   <td style="text-align:center;"> 3.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Giaccherini et al. (2019) </td>
   <td style="text-align:center;"> 5.0 </td>
   <td style="text-align:center;"> 43.3 </td>
   <td style="text-align:center;"> 40.7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Barwick et al. (2018) </td>
   <td style="text-align:center;"> 23.1 </td>
   <td style="text-align:center;"> 0.3 </td>
   <td style="text-align:center;"> 2.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Ebenstein et al. (2015) </td>
   <td style="text-align:center;"> 51.6 </td>
   <td style="text-align:center;"> 0.0 </td>
   <td style="text-align:center;"> 1.4 </td>
  </tr>
</tbody>
</table>

</div>


# Statistical Inference Narrative

In this section, we mine the text of articles to explore how researcher report their statistical inference procedure. Do they mention issues regarding the statistical power of their study? Do they talk about the precision of their estimates or only report them as "statistically significant"? 

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># get pdf files folder path</span>
<span class='va'>folder_articles</span> <span class='op'>&lt;-</span>
  <span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"1.data"</span>, <span class='st'>"1.selected_articles"</span><span class='op'>)</span>

<span class='co'># get the path for each file and add the associated city name</span>
<span class='va'>data_articles</span> <span class='op'>&lt;-</span>
  <span class='fu'>tibble</span><span class='op'>(</span>file_path_article <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/list.files.html'>list.files</a></span><span class='op'>(</span>
    path <span class='op'>=</span> <span class='va'>folder_articles</span>,
    pattern <span class='op'>=</span> <span class='st'>".pdf"</span>,
    full.names <span class='op'>=</span> <span class='cn'>F</span>
  <span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>paper_id <span class='op'>=</span> <span class='fu'>str_remove</span><span class='op'>(</span>string <span class='op'>=</span> <span class='va'>file_path_article</span>, pattern <span class='op'>=</span> <span class='st'>".pdf"</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># function to convert PDF to text</span>
<span class='va'>function_pdf_to_text</span> <span class='op'>&lt;-</span> <span class='kw'>function</span><span class='op'>(</span><span class='va'>file_path_article</span><span class='op'>)</span> <span class='op'>{</span>
  <span class='fu'>pdftools</span><span class='fu'>::</span><span class='fu'><a href='https://docs.ropensci.org/pdftools/reference/pdftools.html'>pdf_text</a></span><span class='op'>(</span><span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"1.data"</span>, <span class='st'>"1.selected_articles"</span>, <span class='va'>file_path_article</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste</a></span><span class='op'>(</span>sep <span class='op'>=</span> <span class='st'>" "</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>stringr</span><span class='fu'>::</span><span class='fu'><a href='https://stringr.tidyverse.org/reference/str_replace.html'>str_replace_all</a></span><span class='op'>(</span><span class='fu'>fixed</span><span class='op'>(</span><span class='st'>"\n"</span><span class='op'>)</span>, <span class='st'>" "</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>stringr</span><span class='fu'>::</span><span class='fu'><a href='https://stringr.tidyverse.org/reference/str_replace.html'>str_replace_all</a></span><span class='op'>(</span><span class='fu'>fixed</span><span class='op'>(</span><span class='st'>"\r"</span><span class='op'>)</span>, <span class='st'>" "</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>stringr</span><span class='fu'>::</span><span class='fu'><a href='https://stringr.tidyverse.org/reference/str_replace.html'>str_replace_all</a></span><span class='op'>(</span><span class='fu'>fixed</span><span class='op'>(</span><span class='st'>"\t"</span><span class='op'>)</span>, <span class='st'>" "</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>stringr</span><span class='fu'>::</span><span class='fu'><a href='https://stringr.tidyverse.org/reference/str_replace.html'>str_replace_all</a></span><span class='op'>(</span><span class='fu'>fixed</span><span class='op'>(</span><span class='st'>"\""</span><span class='op'>)</span>, <span class='st'>" "</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste</a></span><span class='op'>(</span>sep <span class='op'>=</span> <span class='st'>" "</span>, collapse <span class='op'>=</span> <span class='st'>" "</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>stringr</span><span class='fu'>::</span><span class='fu'><a href='https://stringr.tidyverse.org/reference/str_trim.html'>str_squish</a></span><span class='op'>(</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>stringr</span><span class='fu'>::</span><span class='fu'><a href='https://stringr.tidyverse.org/reference/str_replace.html'>str_replace_all</a></span><span class='op'>(</span><span class='st'>"- "</span>, <span class='st'>""</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'><a href='https://rdrr.io/r/base/chartr.html'>tolower</a></span><span class='op'>(</span><span class='op'>)</span>
<span class='op'>}</span>

<span class='co'># function to retrieve the article's title</span>
<span class='va'>function_pdf_title</span> <span class='op'>&lt;-</span> <span class='kw'>function</span><span class='op'>(</span><span class='va'>file_path_article</span><span class='op'>)</span> <span class='op'>{</span>
  <span class='fu'>pdftools</span><span class='fu'>::</span><span class='fu'><a href='https://docs.ropensci.org/pdftools/reference/pdftools.html'>pdf_info</a></span><span class='op'>(</span><span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"1.data"</span>, <span class='st'>"1.selected_articles"</span>, <span class='va'>file_path_article</span><span class='op'>)</span><span class='op'>)</span><span class='op'>[[</span><span class='st'>"keys"</span><span class='op'>]</span><span class='op'>]</span><span class='op'>[[</span><span class='st'>"Title"</span><span class='op'>]</span><span class='op'>]</span>
<span class='op'>}</span>

<span class='co'># get article titles</span>
<span class='va'>data_articles</span> <span class='op'>&lt;-</span> <span class='va'>data_articles</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>title <span class='op'>=</span> <span class='fu'>map</span><span class='op'>(</span><span class='va'>file_path_article</span>, <span class='op'>~</span> <span class='fu'>function_pdf_title</span><span class='op'>(</span><span class='va'>.</span><span class='op'>)</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># convert all PDFs to texts</span>
<span class='va'>data_articles</span> <span class='op'>&lt;-</span> <span class='va'>data_articles</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>text <span class='op'>=</span> <span class='fu'>map</span><span class='op'>(</span><span class='va'>file_path_article</span>, <span class='op'>~</span> <span class='fu'>function_pdf_to_text</span><span class='op'>(</span><span class='va'>.</span><span class='op'>)</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># count occurence of statistical terms</span>
<span class='va'>data_articles</span> <span class='op'>&lt;-</span> <span class='va'>data_articles</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>
    n_power <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"statistical power"</span><span class='op'>)</span>,
    n_statistically_significant <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"statistically significant"</span><span class='op'>)</span>,
    n_significant <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"significant"</span><span class='op'>)</span>,
    n_insignificant <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"insignificant"</span><span class='op'>)</span>,
    n_precise <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"precise"</span><span class='op'>)</span>,
    n_imprecise <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"imprecise"</span><span class='op'>)</span>,
    n_ci <span class='op'>=</span> <span class='fu'>str_count</span><span class='op'>(</span><span class='va'>text</span>, <span class='st'>"confidence interval"</span><span class='op'>)</span>
  <span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>select</span><span class='op'>(</span><span class='op'>-</span><span class='va'>text</span>,<span class='op'>-</span><span class='va'>title</span><span class='op'>)</span>
</code></pre></div>

</div>


We display the proportion of articles where at least one occurence of a term appears:

<div class="layout-chunk" data-layout="l-body">
<table>
 <thead>
  <tr>
   <th style="text-align:center;"> Power (%) </th>
   <th style="text-align:center;"> Statistically Significant (%) </th>
   <th style="text-align:center;"> significant </th>
   <th style="text-align:center;"> Insignificant (%) </th>
   <th style="text-align:center;"> Precise (%) </th>
   <th style="text-align:center;"> Imprecise (%) </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> NaN </td>
   <td style="text-align:center;"> NaN </td>
   <td style="text-align:center;"> NaN </td>
   <td style="text-align:center;"> NaN </td>
   <td style="text-align:center;"> NaN </td>
   <td style="text-align:center;"> NaN </td>
  </tr>
</tbody>
</table>

</div>


```{.r .distill-force-highlighting-css}
```
