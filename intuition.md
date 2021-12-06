---
title: "Understanding Consequences of Low Statistical Power in the NHST Framework"
description: |
  An Imaginary but Illustrative Experiment.
author:
  - name: Vincent Bagilet 
    url: https://vincentbagilet.github.io/
    affiliation: Columbia University
    affiliation_url: https://www.columbia.edu/
  - name: Léo Zabrocki 
    url: https://www.parisschoolofeconomics.eu/en/
    affiliation: Paris School of Economics
    affiliation_url: https://www.parisschoolofeconomics.eu/en/
date: "2021-12-06"
output:
  distill::distill_article:
    keep_md: true
    toc: true
    toc_depth: 2
editor_options: 
  chunk_output_type: console
---

<style>
body {
text-align: justify}
</style>




Researchers working in the null hypothesis significance testing framework (NHST) are often unaware that statistically significant estimates cannot be trusted when their studies have a low statistical power. As explained by [Andrew Gelman and John Carlin (2014)](https://journals.sagepub.com/doi/full/10.1177/1745691614551642), when a study has a low statistical power (i.e., a low probability to get a statistically significant estimate), researchers have a higher chance to get statistically significant estimates that are inflated and of the wrong sign compared to the true effect size they are trying to capture. [Andrew Gelman and John Carlin (2014)](https://journals.sagepub.com/doi/full/10.1177/1745691614551642) call these two issues Type M (for magnitude) and S (for sign) errors. Studies on the acute health effects of air pollution may be prone to such matters as effect sizes are considered to be relatively small ([Michelle L. Bell et al. (2004)](https://www.annualreviews.org/doi/pdf/10.1146/annurev.publhealth.25.102802.124329), [Roger D. Peng Francesca Dominici (2008)](https://www.springer.com/gp/book/9780387781662)).


In this document, we simulate a fictional randomized experiment on the impact of fine particulate matters PM$_{2.5}$ on daily mortality to help researchers build their intuition on the consequences of low statistical power.

Should you have any questions or find coding errors, please do not hesitate to reach use at **vincent.bagilet@columbia.edu** and **leo.zabrocki@psemail.eu**.

# Loading Packages

We first load the packages:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># loading packages</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://here.r-lib.org/'>here</a></span><span class='op'>)</span> <span class='co'># for files paths organization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='op'>)</span> <span class='co'># for data manipulation and visualization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'>lmtest</span><span class='op'>)</span> <span class='co'># for inference of estimated coefficients</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://sandwich.R-Forge.R-project.org/'>sandwich</a></span><span class='op'>)</span> <span class='co'># for robust standard errors</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://patchwork.data-imaginist.com'>patchwork</a></span><span class='op'>)</span> <span class='co'># for combining plots</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://yihui.org/knitr/'>knitr</a></span><span class='op'>)</span> <span class='co'># for building the document</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://github.com/rstudio/DT'>DT</a></span><span class='op'>)</span> <span class='co'># for building nice table</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://vincentbagilet.github.io/mediocrethemes/'>mediocrethemes</a></span><span class='op'>)</span>

<span class='fu'><a href='https://rdrr.io/r/base/Random.html'>set.seed</a></span><span class='op'>(</span><span class='fl'>42</span><span class='op'>)</span>

<span class='fu'><a href='https://vincentbagilet.github.io/mediocrethemes/reference/set_mediocre_all.html'>set_mediocre_all</a></span><span class='op'>(</span><span class='op'>)</span>
</code></pre></div>

</div>


# Setting-up the Experiment

Imagine that a mad scientist implements a randomized experiment experiment to measure the short-term effect of air pollution on daily mortality. The experiment takes place in a major city over the 366 days of a leap year. The treatment is an increase of particulate matter with a diameter below 2.5 $\mu m$ (PM$_{2.5}$) by 10 $\mu g/m^{3}$. The scientist randomly allocates half of the days to the treatment group and the other half to the control group. 

To simulate the experiment, we create a Science Table where we observe the potential outcomes of each day, i.e., the count of individuals dying from non-accidental causes with and without the scientist' intervention:

* We draw the distribution of non-accidental mortality counts $Y_i(0)$ from a Negative Binomial distribution with a mean of 106 and a dispersion of 38 (parameter `size` in the `rnbinom` function). The variance is equal to $\simeq$ 402. We choose the parameters to approximate the distribution of non-accidental mortality counts in a major European city.
* Our average treatment effect of the air pollutant increase leads to about 1 additional death, which represents a 1% increase in the mean of the outcome. It is a larger effect than what has been found in a very large study based on 625 cities. C. Liu *et al*. (New England Journal of Medecine, 2019) found that a 10 $\mu g/m^{3}$ in PM$_{2.5}$ was associated with an increase of 0.68% (95% CI, 0.59 to 0.77) in daily all-cause mortality.

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># create science table</span>
<span class='va'>data_science_table</span> <span class='op'>&lt;-</span>
  <span class='fu'>tibble</span><span class='op'>(</span>index <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fl'>366</span><span class='op'>)</span>, y_0 <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/stats/NegBinomial.html'>rnbinom</a></span><span class='op'>(</span><span class='fl'>366</span>, mu <span class='op'>=</span> <span class='fl'>106</span>, size <span class='op'>=</span> <span class='fl'>38</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>y_1 <span class='op'>=</span> <span class='va'>y_0</span> <span class='op'>+</span> <span class='fu'><a href='https://rdrr.io/r/stats/Poisson.html'>rpois</a></span><span class='op'>(</span><span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span>, <span class='fu'><a href='https://rdrr.io/r/base/mean.html'>mean</a></span><span class='op'>(</span><span class='va'>y_0</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>1</span> <span class='op'>/</span> <span class='fl'>100</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


We display below the Science Table:

<div class="layout-chunk" data-layout="l-body">

```{=html}
<div id="htmlwidget-c1224ac588fb7a02f3fe" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-c1224ac588fb7a02f3fe">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204","205","206","207","208","209","210","211","212","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234","235","236","237","238","239","240","241","242","243","244","245","246","247","248","249","250","251","252","253","254","255","256","257","258","259","260","261","262","263","264","265","266","267","268","269","270","271","272","273","274","275","276","277","278","279","280","281","282","283","284","285","286","287","288","289","290","291","292","293","294","295","296","297","298","299","300","301","302","303","304","305","306","307","308","309","310","311","312","313","314","315","316","317","318","319","320","321","322","323","324","325","326","327","328","329","330","331","332","333","334","335","336","337","338","339","340","341","342","343","344","345","346","347","348","349","350","351","352","353","354","355","356","357","358","359","360","361","362","363","364","365","366"],[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366],[122,94,96,141,153,94,131,123,88,160,114,80,93,128,87,97,101,100,86,97,108,106,116,116,75,118,129,95,134,75,128,121,123,94,97,93,89,134,103,112,71,128,112,105,107,98,101,86,60,86,103,98,120,97,116,118,82,90,85,112,105,114,94,119,136,101,105,65,115,97,145,92,112,101,123,102,105,120,82,86,134,86,121,84,103,101,104,113,80,96,122,103,111,123,71,86,133,137,96,111,103,106,78,77,86,123,68,102,102,91,111,89,79,101,98,136,72,96,102,122,87,95,115,101,80,97,97,81,101,105,128,113,90,104,100,72,107,146,88,106,132,110,108,122,109,87,101,152,107,135,108,96,111,136,110,92,137,106,83,102,89,80,108,112,75,71,59,113,52,95,99,74,103,76,76,117,125,98,99,69,66,100,149,111,75,115,94,119,73,76,118,117,134,87,98,112,111,81,102,110,122,78,91,121,121,110,79,121,107,121,84,106,106,76,106,78,138,81,66,128,125,87,143,98,113,95,139,90,68,93,90,96,99,92,113,105,63,106,131,113,94,127,99,134,94,114,110,126,132,105,103,122,92,92,115,99,122,121,116,124,109,84,102,134,120,92,98,96,84,76,81,75,97,157,82,95,75,113,92,88,100,102,106,139,130,111,110,126,93,92,104,95,89,89,124,98,106,69,107,114,129,114,98,113,134,103,97,116,125,113,91,82,97,89,117,103,106,95,100,102,106,133,73,141,109,49,88,95,99,116,96,86,69,91,92,138,65,91,128,109,100,94,106,72,76,81,90,82,110,102,113,101,96,102,123,95,118,97,61,90,110,133,113,96,98,143],[124,96,98,143,154,94,135,124,90,160,116,82,94,129,89,99,102,102,88,97,109,107,118,116,76,119,130,97,134,75,128,121,123,94,99,93,89,136,105,113,71,128,114,106,109,98,101,87,60,88,103,99,120,99,118,121,83,90,88,112,106,114,98,120,136,103,106,67,115,99,147,94,113,103,126,103,106,120,84,86,137,87,121,87,103,104,105,113,81,96,123,106,112,123,72,86,133,139,96,114,103,109,79,78,87,125,70,103,102,92,113,89,79,103,98,136,73,98,102,122,88,95,115,103,80,98,97,87,102,107,129,115,91,106,100,72,107,146,88,108,134,112,110,123,113,87,103,155,107,135,108,96,114,140,111,93,139,108,85,103,91,80,109,112,75,72,60,113,54,95,100,76,106,77,77,118,125,100,100,69,67,102,151,111,75,115,94,119,73,77,118,118,134,90,98,113,113,83,104,113,122,78,92,122,122,110,81,123,108,121,85,106,107,77,106,79,139,82,68,129,125,87,145,99,114,98,140,91,69,93,93,96,100,92,113,105,64,106,131,113,94,129,99,136,95,115,110,126,134,105,103,123,93,93,116,100,123,122,116,126,111,85,103,135,123,93,102,99,86,76,81,78,98,158,82,96,78,114,95,88,100,102,107,140,130,112,112,126,94,93,106,95,89,92,125,99,106,69,109,115,131,115,98,115,135,104,97,116,126,113,91,82,101,90,121,104,108,95,101,102,108,134,73,141,109,49,89,95,99,116,96,88,70,91,94,139,67,91,130,109,100,95,108,73,77,83,93,83,110,103,114,105,97,102,124,95,118,97,62,91,110,135,113,97,98,144],["+ 2","+ 2","+ 2","+ 2","+ 1","+ 0","+ 4","+ 1","+ 2","+ 0","+ 2","+ 2","+ 1","+ 1","+ 2","+ 2","+ 1","+ 2","+ 2","+ 0","+ 1","+ 1","+ 2","+ 0","+ 1","+ 1","+ 1","+ 2","+ 0","+ 0","+ 0","+ 0","+ 0","+ 0","+ 2","+ 0","+ 0","+ 2","+ 2","+ 1","+ 0","+ 0","+ 2","+ 1","+ 2","+ 0","+ 0","+ 1","+ 0","+ 2","+ 0","+ 1","+ 0","+ 2","+ 2","+ 3","+ 1","+ 0","+ 3","+ 0","+ 1","+ 0","+ 4","+ 1","+ 0","+ 2","+ 1","+ 2","+ 0","+ 2","+ 2","+ 2","+ 1","+ 2","+ 3","+ 1","+ 1","+ 0","+ 2","+ 0","+ 3","+ 1","+ 0","+ 3","+ 0","+ 3","+ 1","+ 0","+ 1","+ 0","+ 1","+ 3","+ 1","+ 0","+ 1","+ 0","+ 0","+ 2","+ 0","+ 3","+ 0","+ 3","+ 1","+ 1","+ 1","+ 2","+ 2","+ 1","+ 0","+ 1","+ 2","+ 0","+ 0","+ 2","+ 0","+ 0","+ 1","+ 2","+ 0","+ 0","+ 1","+ 0","+ 0","+ 2","+ 0","+ 1","+ 0","+ 6","+ 1","+ 2","+ 1","+ 2","+ 1","+ 2","+ 0","+ 0","+ 0","+ 0","+ 0","+ 2","+ 2","+ 2","+ 2","+ 1","+ 4","+ 0","+ 2","+ 3","+ 0","+ 0","+ 0","+ 0","+ 3","+ 4","+ 1","+ 1","+ 2","+ 2","+ 2","+ 1","+ 2","+ 0","+ 1","+ 0","+ 0","+ 1","+ 1","+ 0","+ 2","+ 0","+ 1","+ 2","+ 3","+ 1","+ 1","+ 1","+ 0","+ 2","+ 1","+ 0","+ 1","+ 2","+ 2","+ 0","+ 0","+ 0","+ 0","+ 0","+ 0","+ 1","+ 0","+ 1","+ 0","+ 3","+ 0","+ 1","+ 2","+ 2","+ 2","+ 3","+ 0","+ 0","+ 1","+ 1","+ 1","+ 0","+ 2","+ 2","+ 1","+ 0","+ 1","+ 0","+ 1","+ 1","+ 0","+ 1","+ 1","+ 1","+ 2","+ 1","+ 0","+ 0","+ 2","+ 1","+ 1","+ 3","+ 1","+ 1","+ 1","+ 0","+ 3","+ 0","+ 1","+ 0","+ 0","+ 0","+ 1","+ 0","+ 0","+ 0","+ 0","+ 2","+ 0","+ 2","+ 1","+ 1","+ 0","+ 0","+ 2","+ 0","+ 0","+ 1","+ 1","+ 1","+ 1","+ 1","+ 1","+ 1","+ 0","+ 2","+ 2","+ 1","+ 1","+ 1","+ 3","+ 1","+ 4","+ 3","+ 2","+ 0","+ 0","+ 3","+ 1","+ 1","+ 0","+ 1","+ 3","+ 1","+ 3","+ 0","+ 0","+ 0","+ 1","+ 1","+ 0","+ 1","+ 2","+ 0","+ 1","+ 1","+ 2","+ 0","+ 0","+ 3","+ 1","+ 1","+ 0","+ 0","+ 2","+ 1","+ 2","+ 1","+ 0","+ 2","+ 1","+ 1","+ 0","+ 0","+ 1","+ 0","+ 0","+ 0","+ 4","+ 1","+ 4","+ 1","+ 2","+ 0","+ 1","+ 0","+ 2","+ 1","+ 0","+ 0","+ 0","+ 0","+ 1","+ 0","+ 0","+ 0","+ 0","+ 2","+ 1","+ 0","+ 2","+ 1","+ 2","+ 0","+ 2","+ 0","+ 0","+ 1","+ 2","+ 1","+ 1","+ 2","+ 3","+ 1","+ 0","+ 1","+ 1","+ 4","+ 1","+ 0","+ 1","+ 0","+ 0","+ 0","+ 1","+ 1","+ 0","+ 2","+ 0","+ 1","+ 0","+ 1"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Index<\/th>\n      <th>Y(0)<\/th>\n      <th>Y(1)<\/th>\n      <th>Individual Treatment Effect<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-center","targets":"_all"},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

</div>


And we plot below the full density distribution of the two potential outcomes:

<div class="layout-chunk" data-layout="l-body">
<img src="intuition_files/figure-html5/plot_density_pot_out-1.png" width="85%" style="display: block; margin: auto;" />

</div>






# Running the Experiment and Understanding its Inference Properties

In this section, we make the mad scientist run and analyze his experiment. We then show how to think about the inference properties of the experiment when one works in the null hypothesis testing framework.

### Running One Iteration of the Experiment

The scientist runs a complete experiment where half of the units are randomly assigned to the treatment. We display below the Science Table and the outcomes observed by the scientists. $W$ is a binary variable representing the treatment allocation (i.e., it is equal to 1 is the unit is treated and 0 otherwise) and $Y^{\text{obs}}$ is the potential outcome observed by the scientist given the treatment assignment.

<div class="layout-chunk" data-layout="l-body">

```{=html}
<div id="htmlwidget-5676f91f2139497dabf3" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-5676f91f2139497dabf3">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204","205","206","207","208","209","210","211","212","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234","235","236","237","238","239","240","241","242","243","244","245","246","247","248","249","250","251","252","253","254","255","256","257","258","259","260","261","262","263","264","265","266","267","268","269","270","271","272","273","274","275","276","277","278","279","280","281","282","283","284","285","286","287","288","289","290","291","292","293","294","295","296","297","298","299","300","301","302","303","304","305","306","307","308","309","310","311","312","313","314","315","316","317","318","319","320","321","322","323","324","325","326","327","328","329","330","331","332","333","334","335","336","337","338","339","340","341","342","343","344","345","346","347","348","349","350","351","352","353","354","355","356","357","358","359","360","361","362","363","364","365","366"],[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366],[122,94,96,141,153,94,131,123,88,160,114,80,93,128,87,97,101,100,86,97,108,106,116,116,75,118,129,95,134,75,128,121,123,94,97,93,89,134,103,112,71,128,112,105,107,98,101,86,60,86,103,98,120,97,116,118,82,90,85,112,105,114,94,119,136,101,105,65,115,97,145,92,112,101,123,102,105,120,82,86,134,86,121,84,103,101,104,113,80,96,122,103,111,123,71,86,133,137,96,111,103,106,78,77,86,123,68,102,102,91,111,89,79,101,98,136,72,96,102,122,87,95,115,101,80,97,97,81,101,105,128,113,90,104,100,72,107,146,88,106,132,110,108,122,109,87,101,152,107,135,108,96,111,136,110,92,137,106,83,102,89,80,108,112,75,71,59,113,52,95,99,74,103,76,76,117,125,98,99,69,66,100,149,111,75,115,94,119,73,76,118,117,134,87,98,112,111,81,102,110,122,78,91,121,121,110,79,121,107,121,84,106,106,76,106,78,138,81,66,128,125,87,143,98,113,95,139,90,68,93,90,96,99,92,113,105,63,106,131,113,94,127,99,134,94,114,110,126,132,105,103,122,92,92,115,99,122,121,116,124,109,84,102,134,120,92,98,96,84,76,81,75,97,157,82,95,75,113,92,88,100,102,106,139,130,111,110,126,93,92,104,95,89,89,124,98,106,69,107,114,129,114,98,113,134,103,97,116,125,113,91,82,97,89,117,103,106,95,100,102,106,133,73,141,109,49,88,95,99,116,96,86,69,91,92,138,65,91,128,109,100,94,106,72,76,81,90,82,110,102,113,101,96,102,123,95,118,97,61,90,110,133,113,96,98,143],[124,96,98,143,154,94,135,124,90,160,116,82,94,129,89,99,102,102,88,97,109,107,118,116,76,119,130,97,134,75,128,121,123,94,99,93,89,136,105,113,71,128,114,106,109,98,101,87,60,88,103,99,120,99,118,121,83,90,88,112,106,114,98,120,136,103,106,67,115,99,147,94,113,103,126,103,106,120,84,86,137,87,121,87,103,104,105,113,81,96,123,106,112,123,72,86,133,139,96,114,103,109,79,78,87,125,70,103,102,92,113,89,79,103,98,136,73,98,102,122,88,95,115,103,80,98,97,87,102,107,129,115,91,106,100,72,107,146,88,108,134,112,110,123,113,87,103,155,107,135,108,96,114,140,111,93,139,108,85,103,91,80,109,112,75,72,60,113,54,95,100,76,106,77,77,118,125,100,100,69,67,102,151,111,75,115,94,119,73,77,118,118,134,90,98,113,113,83,104,113,122,78,92,122,122,110,81,123,108,121,85,106,107,77,106,79,139,82,68,129,125,87,145,99,114,98,140,91,69,93,93,96,100,92,113,105,64,106,131,113,94,129,99,136,95,115,110,126,134,105,103,123,93,93,116,100,123,122,116,126,111,85,103,135,123,93,102,99,86,76,81,78,98,158,82,96,78,114,95,88,100,102,107,140,130,112,112,126,94,93,106,95,89,92,125,99,106,69,109,115,131,115,98,115,135,104,97,116,126,113,91,82,101,90,121,104,108,95,101,102,108,134,73,141,109,49,89,95,99,116,96,88,70,91,94,139,67,91,130,109,100,95,108,73,77,83,93,83,110,103,114,105,97,102,124,95,118,97,62,91,110,135,113,97,98,144],[1,1,0,1,1,1,0,1,1,1,0,1,0,0,0,0,1,1,1,0,0,1,0,1,1,1,1,1,0,0,1,0,0,0,0,1,1,0,1,0,0,0,1,0,1,0,1,1,0,1,1,1,0,1,1,1,0,0,0,0,0,1,0,1,1,0,0,1,0,1,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,1,0,1,1,0,0,0,0,1,0,0,0,1,1,1,0,1,1,0,1,0,1,1,0,1,1,1,0,0,1,1,0,1,0,1,0,1,1,1,0,1,0,0,0,0,1,0,1,1,0,1,1,1,1,0,0,1,0,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1,1,0,0,1,0,1,0,1,1,1,0,1,0,0,0,1,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,1,1,1,0,0,0,1,0,1,0,0,1,1,0,0,1,0,1,0,0,0,1,0,1,1,1,1,1,0,0,0,1,1,1,0,1,0,1,0,0,1,0,0,1,1,0,1,0,0,1,0,0,1,1,0,1,0,1,1,1,0,1,1,1,1,0,0,1,1,1,0,0,1,0,1,1,0,1,0,1,0,0,1,0,0,1,1,1,1,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,0,0,1,0,0,1,0,0,0,0,0,1,0,1,1,0,0,0,1,0,1,0,1,1,0,1,1,1,0,0,0,0,1,1,0,0,1,0,1,0,1,1,0,0,0,0,1,1,1,0,1,0,1,0,0,0,1],["+ 2","+ 2","+ 2","+ 2","+ 1","+ 0","+ 4","+ 1","+ 2","+ 0","+ 2","+ 2","+ 1","+ 1","+ 2","+ 2","+ 1","+ 2","+ 2","+ 0","+ 1","+ 1","+ 2","+ 0","+ 1","+ 1","+ 1","+ 2","+ 0","+ 0","+ 0","+ 0","+ 0","+ 0","+ 2","+ 0","+ 0","+ 2","+ 2","+ 1","+ 0","+ 0","+ 2","+ 1","+ 2","+ 0","+ 0","+ 1","+ 0","+ 2","+ 0","+ 1","+ 0","+ 2","+ 2","+ 3","+ 1","+ 0","+ 3","+ 0","+ 1","+ 0","+ 4","+ 1","+ 0","+ 2","+ 1","+ 2","+ 0","+ 2","+ 2","+ 2","+ 1","+ 2","+ 3","+ 1","+ 1","+ 0","+ 2","+ 0","+ 3","+ 1","+ 0","+ 3","+ 0","+ 3","+ 1","+ 0","+ 1","+ 0","+ 1","+ 3","+ 1","+ 0","+ 1","+ 0","+ 0","+ 2","+ 0","+ 3","+ 0","+ 3","+ 1","+ 1","+ 1","+ 2","+ 2","+ 1","+ 0","+ 1","+ 2","+ 0","+ 0","+ 2","+ 0","+ 0","+ 1","+ 2","+ 0","+ 0","+ 1","+ 0","+ 0","+ 2","+ 0","+ 1","+ 0","+ 6","+ 1","+ 2","+ 1","+ 2","+ 1","+ 2","+ 0","+ 0","+ 0","+ 0","+ 0","+ 2","+ 2","+ 2","+ 2","+ 1","+ 4","+ 0","+ 2","+ 3","+ 0","+ 0","+ 0","+ 0","+ 3","+ 4","+ 1","+ 1","+ 2","+ 2","+ 2","+ 1","+ 2","+ 0","+ 1","+ 0","+ 0","+ 1","+ 1","+ 0","+ 2","+ 0","+ 1","+ 2","+ 3","+ 1","+ 1","+ 1","+ 0","+ 2","+ 1","+ 0","+ 1","+ 2","+ 2","+ 0","+ 0","+ 0","+ 0","+ 0","+ 0","+ 1","+ 0","+ 1","+ 0","+ 3","+ 0","+ 1","+ 2","+ 2","+ 2","+ 3","+ 0","+ 0","+ 1","+ 1","+ 1","+ 0","+ 2","+ 2","+ 1","+ 0","+ 1","+ 0","+ 1","+ 1","+ 0","+ 1","+ 1","+ 1","+ 2","+ 1","+ 0","+ 0","+ 2","+ 1","+ 1","+ 3","+ 1","+ 1","+ 1","+ 0","+ 3","+ 0","+ 1","+ 0","+ 0","+ 0","+ 1","+ 0","+ 0","+ 0","+ 0","+ 2","+ 0","+ 2","+ 1","+ 1","+ 0","+ 0","+ 2","+ 0","+ 0","+ 1","+ 1","+ 1","+ 1","+ 1","+ 1","+ 1","+ 0","+ 2","+ 2","+ 1","+ 1","+ 1","+ 3","+ 1","+ 4","+ 3","+ 2","+ 0","+ 0","+ 3","+ 1","+ 1","+ 0","+ 1","+ 3","+ 1","+ 3","+ 0","+ 0","+ 0","+ 1","+ 1","+ 0","+ 1","+ 2","+ 0","+ 1","+ 1","+ 2","+ 0","+ 0","+ 3","+ 1","+ 1","+ 0","+ 0","+ 2","+ 1","+ 2","+ 1","+ 0","+ 2","+ 1","+ 1","+ 0","+ 0","+ 1","+ 0","+ 0","+ 0","+ 4","+ 1","+ 4","+ 1","+ 2","+ 0","+ 1","+ 0","+ 2","+ 1","+ 0","+ 0","+ 0","+ 0","+ 1","+ 0","+ 0","+ 0","+ 0","+ 2","+ 1","+ 0","+ 2","+ 1","+ 2","+ 0","+ 2","+ 0","+ 0","+ 1","+ 2","+ 1","+ 1","+ 2","+ 3","+ 1","+ 0","+ 1","+ 1","+ 4","+ 1","+ 0","+ 1","+ 0","+ 0","+ 0","+ 1","+ 1","+ 0","+ 2","+ 0","+ 1","+ 0","+ 1"],[124,96,96,143,154,94,131,124,90,160,114,82,93,128,87,97,102,102,88,97,108,107,116,116,76,119,130,97,134,75,128,121,123,94,97,93,89,134,105,112,71,128,114,105,109,98,101,87,60,88,103,99,120,99,118,121,82,90,85,112,105,114,94,120,136,101,105,67,115,99,147,94,112,103,126,102,105,120,84,86,137,87,121,84,103,104,104,113,81,96,122,103,111,123,71,86,133,139,96,114,103,109,79,77,87,123,70,103,102,92,113,89,79,101,98,136,72,98,102,122,87,95,115,103,80,98,97,81,101,105,129,113,91,106,100,72,107,146,88,106,132,112,108,122,113,87,103,155,107,135,108,96,114,140,111,92,139,106,85,102,91,80,108,112,75,71,60,113,54,95,100,74,106,76,76,117,125,98,100,69,66,100,151,111,75,115,94,119,73,76,118,118,134,90,98,112,111,81,104,110,122,78,91,122,122,110,79,123,107,121,84,106,106,77,106,79,139,82,68,129,125,87,143,99,114,98,139,91,68,93,90,96,100,92,113,105,64,106,131,113,94,129,99,134,95,115,110,126,132,105,103,123,92,93,116,100,123,121,116,126,111,85,102,134,123,92,102,99,84,76,81,78,97,157,82,95,75,114,95,88,100,102,107,139,130,111,110,126,93,92,104,95,89,89,125,98,106,69,107,115,131,114,98,113,134,104,97,116,126,113,91,82,97,89,121,103,106,95,100,102,108,133,73,141,109,49,88,95,99,116,96,88,70,91,94,139,67,91,128,109,100,95,108,72,76,83,90,83,110,103,114,101,96,102,123,95,118,97,61,91,110,135,113,96,98,144]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Day Index<\/th>\n      <th>Y(0)<\/th>\n      <th>Y(1)<\/th>\n      <th>W<\/th>\n      <th>Individual Treatment Effect<\/th>\n      <th>Yobs<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-center","targets":"_all"},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

</div>


The scientist then estimates the average treatment effect:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># we compute the estimate of the treatment effect</span>
<span class='va'>scientist_result</span> <span class='op'>&lt;-</span> <span class='va'>data_scientist_treatment_assignment</span> <span class='op'>%&gt;%</span>
  <span class='co'># express observed outcomes according to</span>
  <span class='co'># treatment assignment</span>
  <span class='fu'>mutate</span><span class='op'>(</span>y_obs <span class='op'>=</span> <span class='va'>w</span> <span class='op'>*</span> <span class='va'>y_1</span> <span class='op'>+</span> <span class='op'>(</span><span class='fl'>1</span> <span class='op'>-</span> <span class='va'>w</span><span class='op'>)</span> <span class='op'>*</span> <span class='va'>y_0</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='co'># run simple linear regression</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/lm.html'>lm</a></span><span class='op'>(</span><span class='va'>y_obs</span> <span class='op'>~</span> <span class='va'>w</span>, data <span class='op'>=</span> <span class='va'>.</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>lmtest</span><span class='fu'>::</span><span class='fu'><a href='https://rdrr.io/pkg/lmtest/man/coeftest.html'>coeftest</a></span><span class='op'>(</span><span class='va'>.</span>, vcov <span class='op'>=</span> <span class='va'>vcovHC</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>broom</span><span class='fu'>::</span><span class='fu'><a href='https://generics.r-lib.org/reference/tidy.html'>tidy</a></span><span class='op'>(</span><span class='va'>.</span>, conf.int <span class='op'>=</span> <span class='cn'>TRUE</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>term</span> <span class='op'>==</span> <span class='st'>"w"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>select</span><span class='op'>(</span><span class='va'>estimate</span>, <span class='va'>p.value</span>, <span class='va'>conf.low</span>, <span class='va'>conf.high</span><span class='op'>)</span>
</code></pre></div>

</div>


The results are as follows:

<div class="layout-chunk" data-layout="l-body">

| Estimate | p-value | 95% CI Lower Bound | 95% CI Upper Bound |
|:--------:|:-------:|:------------------:|:------------------:|
|   4.16   |  0.04   |        0.16        |        8.17        |

</div>



He obtains an estimate for the treatment effect of 4.16 with a *p*-value of $\simeq$ 0.04. "Hooray", the estimate is statistically significant at the 5% level. The "significant" result fulfills the scientist who immediately starts writing his research paper.

### Replicating the Experiment

Unfortunately for the scientist, we are in position where we have much more information than him. We observe the two potential outcomes of each day and we know that the treatment effect is about +1 daily death. To gauge the inference properties of an experiment with this sample size, we replicate 10,000 additional experiments. We use the following function to carry out one iteration of the experiment:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># first add the treatment vector to the science table</span>
<span class='va'>data_science_table</span> <span class='op'>&lt;-</span> <span class='va'>data_science_table</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>w <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fl'>0</span>, <span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>2</span><span class='op'>)</span>, <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fl'>1</span>, <span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>2</span><span class='op'>)</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># function to run an experiment</span>
<span class='co'># takes the data as input</span>
<span class='va'>function_run_experiment</span> <span class='op'>&lt;-</span> <span class='kw'>function</span><span class='op'>(</span><span class='va'>data</span><span class='op'>)</span> <span class='op'>{</span>
  <span class='va'>data</span> <span class='op'>%&gt;%</span>
    <span class='fu'>mutate</span><span class='op'>(</span>w <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/sample.html'>sample</a></span><span class='op'>(</span><span class='va'>w</span>, replace <span class='op'>=</span> <span class='cn'>FALSE</span><span class='op'>)</span>,
           y_obs <span class='op'>=</span> <span class='va'>w</span> <span class='op'>*</span> <span class='va'>y_1</span> <span class='op'>+</span> <span class='op'>(</span><span class='fl'>1</span> <span class='op'>-</span> <span class='va'>w</span><span class='op'>)</span> <span class='op'>*</span> <span class='va'>y_0</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'><a href='https://rdrr.io/r/stats/lm.html'>lm</a></span><span class='op'>(</span><span class='va'>y_obs</span> <span class='op'>~</span> <span class='va'>w</span>, data <span class='op'>=</span> <span class='va'>.</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>lmtest</span><span class='fu'>::</span><span class='fu'><a href='https://rdrr.io/pkg/lmtest/man/coeftest.html'>coeftest</a></span><span class='op'>(</span><span class='va'>.</span>, vcov <span class='op'>=</span> <span class='va'>vcovHC</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>broom</span><span class='fu'>::</span><span class='fu'><a href='https://generics.r-lib.org/reference/tidy.html'>tidy</a></span><span class='op'>(</span><span class='va'>.</span>, conf.int <span class='op'>=</span> <span class='cn'>TRUE</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>term</span> <span class='op'>==</span> <span class='st'>"w"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>select</span><span class='op'>(</span><span class='va'>estimate</span>, <span class='va'>p.value</span>, <span class='va'>conf.low</span>, <span class='va'>conf.high</span><span class='op'>)</span>
<span class='op'>}</span>
</code></pre></div>

</div>


We run 10,000 experiments with the code below:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># run 1000 additional experiments</span>
<span class='va'>results_10000_experiments</span> <span class='op'>&lt;-</span>
  <span class='fu'>rerun</span><span class='op'>(</span><span class='fl'>10000</span>, <span class='fu'>function_run_experiment</span><span class='op'>(</span><span class='va'>data_science_table</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>bind_rows</span><span class='op'>(</span><span class='op'>)</span>

<span class='co'># make sound when code has finsished to run</span>
<span class='fu'>beepr</span><span class='fu'>::</span><span class='fu'><a href='https://rdrr.io/pkg/beepr/man/beep.html'>beep</a></span><span class='op'>(</span>sound <span class='op'>=</span> <span class='fl'>5</span><span class='op'>)</span>

<span class='co'># save simulation results</span>
<span class='co'># saveRDS(</span>
<span class='co'>#   results_10000_experiments, </span>
<span class='co'>#   here::here("R", "Data_Leo", "data_results_10000_experiments.RDS")</span>
<span class='co'># )</span>
</code></pre></div>

</div>


As it takes few minutes, we load the results that we already stored in the `data_results_10000_experiments.RDS` file:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load results</span>
<span class='va'>data_results_10000_experiments</span> <span class='op'>&lt;-</span>
  <span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>readRDS</a></span><span class='op'>(</span><span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"R"</span>, <span class='st'>"Data_Leo"</span>, <span class='st'>"data_results_10000_experiments.RDS"</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># add scientist's result</span>
<span class='va'>data_results_10000_experiments</span> <span class='op'>&lt;-</span>
  <span class='fu'>bind_rows</span><span class='op'>(</span><span class='va'>scientist_result</span>, <span class='va'>data_results_10000_experiments</span><span class='op'>)</span>
</code></pre></div>

</div>


As done by the [retrodesign](https://andytimm.github.io/2019/02/05/Intro_To_retrodesign.html) R package, we plot the estimates of all experiments and color them according to the 5% statistical significance threshold:

<div class="layout-chunk" data-layout="l-body">
<img src="intuition_files/figure-html5/unnamed-chunk-5-1.png" width="85%" style="display: block; margin: auto;" />

</div>




We can see on this graph that statistically significant estimates overestimate the true effect size. Besides, a fraction of significant estimates are of the wrong sign! As an alternative visualization of the replication exercise, we also plot 100 point estimates with their 95% confidence intervals:

<div class="layout-chunk" data-layout="l-body">
<img src="intuition_files/figure-html5/unnamed-chunk-7-1.png" width="85%" style="display: block; margin: auto;" />

</div>

       
       



### Computing Statistical Power, Type M and S Errors

To understand the inference properties of this experiment, we compute three metrics:

1. The **statistical power**, which is the probability to get a significant result when there is actually an effect.
2. The average **Type M error**, which is the average of the ratio of the absolute value each statistically significant estimate over the true effect size.
3. The probability to make a **Type S error**, which is the fraction of statistically significant estimates in the opposite sign of the true effect.

We consider estimates as statistically significant when their associated *p*-values are inferior or equal to 0.05. First, to compute the statistical power of the experiment, we just need to count the proportion of *p*-values inferior or equal to 0.05:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute power</span>
<span class='va'>power</span> <span class='op'>&lt;-</span> <span class='va'>data_results_10000_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>statistical_power <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>/</span> <span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>100</span>, <span class='fl'>0</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


The statistical power of this experiment is equal to 8%. The scientist had therefore very few chances to get a "statistically significant" result. We can then look at the characteristics of the statistically significant estimates. We compute the average type M error or exaggeration ratio:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute type m error</span>
<span class='va'>type_m</span> <span class='op'>&lt;-</span> <span class='va'>data_results_10000_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>exageration_factor <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/mean.html'>mean</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/MathFun.html'>abs</a></span><span class='op'>(</span><span class='va'>estimate</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>1</span><span class='op'>)</span> <span class='op'>%&gt;%</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='va'>.</span>, <span class='fl'>1</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


On average, statistically significant estimates exaggerate the true effect size by a factor of about 4.9. We also compute the probability to make a type S error:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute type s error</span>
<span class='va'>type_s</span> <span class='op'>&lt;-</span> <span class='va'>data_results_10000_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>probability_type_s_error <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='op'>(</span><span class='va'>estimate</span> <span class='op'>&lt;</span> <span class='fl'>0</span><span class='op'>)</span> <span class='op'>/</span> <span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>100</span>, <span class='fl'>1</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


Nearly 7.8% of statistically significant estimates are negative! Working with such a sample size to detect an average effect of +1 death could lead to very misleading claims. Finally, we can also check if we could trust confidence intervals of statistically significant effects to capture the true effect size. We compute their coverage rate:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute ci coverage rate</span>
<span class='va'>ci_coverage_rate</span> <span class='op'>&lt;-</span> <span class='va'>data_results_10000_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>statistically_significant</span> <span class='op'>==</span> <span class='st'>"True"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>captured <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span><span class='va'>conf.low</span> <span class='op'>&lt;</span> <span class='fl'>1</span> <span class='op'>&amp;</span> <span class='fl'>1</span> <span class='op'>&lt;</span> <span class='va'>conf.high</span>, <span class='fl'>1</span>, <span class='fl'>0</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>proportion_captured <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/mean.html'>mean</a></span><span class='op'>(</span><span class='va'>captured</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>100</span> <span class='op'>%&gt;%</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='va'>.</span>, <span class='fl'>0</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


Only 58.1542351% the intervals capture the true effect size! With lower power, the coverage rate of the confidence intervals of statistically significant estimates is much below its expected value of 95%.

# How Sample Size Influences Power, Type M and S Errors

Now, imagine that the mad scientist is able to triple the sample of his experiment. We add 732 additional observations:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># add extra data</span>
<span class='va'>extra_data</span> <span class='op'>&lt;-</span>
  <span class='fu'>tibble</span><span class='op'>(</span>index <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>367</span><span class='op'>:</span><span class='fl'>1098</span><span class='op'>)</span>,
         y_0 <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/stats/NegBinomial.html'>rnbinom</a></span><span class='op'>(</span><span class='fl'>732</span>, mu <span class='op'>=</span> <span class='fl'>106</span>, size <span class='op'>=</span> <span class='fl'>38</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>y_1 <span class='op'>=</span> <span class='va'>y_0</span> <span class='op'>+</span> <span class='fu'><a href='https://rdrr.io/r/stats/Poisson.html'>rpois</a></span><span class='op'>(</span><span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span>, <span class='fu'><a href='https://rdrr.io/r/base/mean.html'>mean</a></span><span class='op'>(</span><span class='va'>y_0</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>1</span> <span class='op'>/</span> <span class='fl'>100</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># merge with initial data</span>
<span class='va'>data_science_table</span> <span class='op'>&lt;-</span> <span class='fu'>bind_rows</span><span class='op'>(</span><span class='va'>data_science_table</span>, <span class='va'>extra_data</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='co'># add treatment indicator</span>
  <span class='fu'>mutate</span><span class='op'>(</span>w <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fl'>0</span>, <span class='fl'>549</span><span class='op'>)</span>, <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fl'>1</span>, <span class='fl'>549</span><span class='op'>)</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


We run 10,000 experiments for a sample of 1098 daily observations:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># run 10000 additional experiments</span>
<span class='va'>results_large_sample_experiments</span> <span class='op'>&lt;-</span> 
  <span class='fu'>rerun</span><span class='op'>(</span><span class='fl'>10000</span>, <span class='fu'>function_run_experiment</span><span class='op'>(</span><span class='va'>data_science_table</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>bind_rows</span><span class='op'>(</span><span class='op'>)</span>

<span class='co'># make sound when code has finished to run</span>
<span class='fu'>beepr</span><span class='fu'>::</span><span class='fu'><a href='https://rdrr.io/pkg/beepr/man/beep.html'>beep</a></span><span class='op'>(</span>sound <span class='op'>=</span> <span class='fl'>5</span><span class='op'>)</span>

<span class='co'># save simulation results</span>
<span class='co'># saveRDS(</span>
<span class='co'>#   results_large_sample_experiments, </span>
<span class='co'>#   here::here("R", "Data_Leo", "data_results_large_sample_experiments.RDS")</span>
<span class='co'># )</span>
</code></pre></div>

</div>


As it takes few minutes, we load the results that we have already stored in the `data_results_large_sample_experiments.RDS` file.

<div class="layout-chunk" data-layout="l-body">


</div>


We plot the density distribution of the initial and new experiment:

<div class="layout-chunk" data-layout="l-body">
<img src="intuition_files/figure-html5/unnamed-chunk-16-1.png" width="85%" style="display: block; margin: auto;" />

</div>





We compute below the statistical power of this larger experiment:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute statistical power</span>
<span class='va'>power_large_exp</span> <span class='op'>&lt;-</span> <span class='va'>data_results_large_sample_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>statistical_power <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>/</span> <span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>100</span>, <span class='fl'>0</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


The statistical power of this experiment is equal to `r `power_large_exp`%. We compute the average type M error:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute type m error</span>
<span class='va'>type_m_large_exp</span> <span class='op'>&lt;-</span> <span class='va'>data_results_large_sample_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>exageration_factor <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/mean.html'>mean</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/MathFun.html'>abs</a></span><span class='op'>(</span><span class='va'>estimate</span><span class='op'>)</span> <span class='op'>/</span> <span class='fl'>1</span><span class='op'>)</span> <span class='op'>%&gt;%</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='va'>.</span>, <span class='fl'>1</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


On average, statistically significant estimates exaggerate the true effect size by a factor of about 3. We also compute the probability to make a type S error:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute type s error</span>
<span class='va'>type_s_large_exp</span> <span class='op'>&lt;-</span> <span class='va'>data_results_large_sample_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>probability_type_s_error <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='op'>(</span><span class='va'>estimate</span> <span class='op'>&lt;</span> <span class='fl'>0</span><span class='op'>)</span> <span class='op'>/</span> <span class='fu'>n</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>100</span>, <span class='fl'>1</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


Nearly 1.9% of statistically significant effects are negative! We finally check the coverage rate of 95% confidence intervals:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># compute ci coverage rate</span>
<span class='va'>ci_coverage_rate_large_exp</span> <span class='op'>&lt;-</span>
  <span class='va'>data_results_large_sample_experiments</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>p.value</span> <span class='op'>&lt;=</span> <span class='fl'>0.05</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>captured <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span><span class='va'>conf.low</span> <span class='op'>&lt;</span> <span class='fl'>1</span> <span class='op'>&amp;</span> <span class='fl'>1</span> <span class='op'>&lt;</span> <span class='va'>conf.high</span>, <span class='fl'>1</span>, <span class='fl'>0</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>summarise</span><span class='op'>(</span>proportion_captured <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/mean.html'>mean</a></span><span class='op'>(</span><span class='va'>captured</span><span class='op'>)</span> <span class='op'>*</span> <span class='fl'>100</span> <span class='op'>%&gt;%</span> <span class='fu'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='op'>(</span><span class='va'>.</span>, <span class='fl'>0</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


The coverage of 95% confidence intervals is equal to 78.2269504%.


With a sample size three times bigger, the statistical power of the experiment has increased but is still very low. Consequently, the exaggeration factor has decreased from 3 to 3. The probability to make a type S error has been reduced a lot and is close to 1. The coverage rate of confidence intervals has increased but is still far from its 95% theoretical target.
```{.r .distill-force-highlighting-css}
```
