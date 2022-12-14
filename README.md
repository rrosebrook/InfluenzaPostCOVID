# COVID's Influence on Influenza

This project is aimed at investigating the influence of COVID -- and the precautions that have been taken to address its spread -- upon subsequent influenza seasons. We looked at both the infection rates of influenza for the past 12 years and have attempted to predict future infections by state given COVID's impact. We also augmented our data with statistics concerning influenza mortality, in an attempt to glean any novel information there as well.

## Data Collection and Cleaning
### Collection

Data was collected from two sources from the Centers for Disease Control (CDC). Viral surveillance data from both clinical and public health labs were downloaded from the National, Regional, and State Level Outpatient Illness and Viral Surveillance for all states and all available years[^1].
The mortality data were obtained from the Stat of the States' Influenza/Pneumonia Mortality[^2], also from the CDC.

### Cleaning

Data were combined in these four files using the common time series of *annual* reports for these rates. EDA indicated some states and areas with partial or non-existent data. The Virgin Islands were notable for never having influenza infections in the few years they reported things. Regions with missing values were chosen to be eliminated, as that still left us with 40 different regions to look at, and replacing them with anything meaningful would require extensive census data.

## Exploratory Data Analysis

Peeking at the five-number summary statistics for each state shows that infections tend to be all over the place and can range quite a lot between states and the years. States with larger populations, such as California, tended to have larger values, but we can also see the minimums for all the states are quite low, often even in the single digits.  

<img src=https://user-images.githubusercontent.com/31425480/194931899-2c4e4480-ca47-4db0-a49f-434567d84c5e.png width="40%">

If we plot the data we have, we can see how COVID's effects in 2020 were quite profound on the spread of influenza. The drastic measures we took to inhibit the spread of COVID helped inhibit the spread of influenza as well -- both types A and B -- plummeted to near-zero levels. 

<img src=https://user-images.githubusercontent.com/31425480/194933011-9520ee31-0eab-4281-a8e0-e5c35b02e735.png width="50%"><img src=https://user-images.githubusercontent.com/31425480/194933217-8b28c660-8f2a-4fd4-b4e5-ec1677ad2a36.png width="50%">
<img src=https://user-images.githubusercontent.com/31425480/194789390-010b222e-d466-4ee8-b4fb-54ccd3f57db0.png width="70%">

Influenza infections almost appear to be on a biannual cycle for type-B infections, but even the lowest years don't come close to approaching the low levels we saw with COVID. On the other hand, type-A infections seem to have been reported much less often about a decade ago, but similarly, it was still at a relatively high rate compared to what we saw in 2020.

However, there did ultimately end up being a few states who reported the fewest infections in years other than 2020. Of the forty states which we had complete data for, (which notably excludes Florida, a state that typically has not made public their influenza numbers), four states had the fewest type-A -- or total influenza infections -- in years outside of 2020: Alaska (2019), Nevada (2015), New Hampshire (2011), and Wyoming (2011). Alaska has a notoriously late flu season, with infections generally not beginning until after the start of the year (Morales, 2016)[^3] and as such, it would make sense that 2020's infection prevention actions would have been more likely to affect the 2019-2020 flu season for that region, than 2020-2021 as it did in other places. 

For type-B infections, however, it was surprising to see that the majority of states (27) had the fewest infections in 2021. When we look at the historical data for type-B infections, we can see that they're quite variable from year to year and I suspect it may have been that 2020 was prone to have been a more infectious year, and 2021 was prone to less infection. The difference between 2020 and 2021 for all of these states is less than 5%. It appears that type-B can be just as infectious as type-A (Sharma et. al, 2019)[^4], and seems to be more lethal (Craig, 2016)[^5], so perhaps we were super lucky to simply be graced with two very low years of type-B infections during this time.

## Forecasting pre-COVID

First we built ARIMA and linear models to see if they would be able to predict pre-COVID data, to then use those to predict the post-COVID data.  These types of models, with our data, did not produce overwhelming models, however for a few states we were able to achieve MASE rates as low as .886 (Georgia), .867 (Oklahoma), and even .716 (West Virginia).

## Forecasting post-COVID

The purpose of this project was to see if forecasting models made with pre-COVID data would be successful in predicting post-COVID data, with a hunch that they would not be effective. However, it was surprising to see just how poor these models operated on post-COVID data. First, we looked at what simple rolling averages might predict for infections of each type, with two years worth of predictions: 

<img src=https://user-images.githubusercontent.com/31425480/194941312-e4f90fed-311a-4eac-aa21-7b8069f5cfbd.png width="50%"><img src=https://user-images.githubusercontent.com/31425480/194941648-eece228a-8c5d-42ac-a78c-93ac3fc1bb89.png width="50%">
<img src=https://user-images.githubusercontent.com/31425480/194941759-e5059310-c7d9-4662-ab74-2b6132d1c6f5.png width="70%">

If we compare that to our previous graphs, we can see these moving average predictions were far from reality. However, these moving averages are about as simple as we could get for prediction so we attempted both Naive linear regression and AutoRegressive Integrated Moving Average (ARIMA) forecasting. With these, our forecasts fared no better -- when we looked at the accuracy of these, no MASE value for any region scored lower than 3 (Wisconsin) for Naive predictions, and only a single value approached 1 using ARIMA (Tennessee), but it approached 1 from the wrong direction at a value of 1.08. As much as ARIMA almost performed well, it also scored over 11 for Missouri -- Missour's Naive MASE score of 5.03 almost looks respectable in comparison.

Looking at that exceptionally poorly forecasted state of Missouri -- forecasts are in blue and the actual data has been plotted in red:    
<img src=https://user-images.githubusercontent.com/31425480/194945048-9d8dc338-8d62-4174-967c-710ef577b66f.png width="50%"><img src=https://user-images.githubusercontent.com/31425480/194944810-85e5b8e0-0368-47eb-acb5-d1d38f6ae931.png width="50%">

But even with our standout state of Tennessee, we can see the predictions didn't do well. It's important to note that the scales of Naive vs. ARIMA are drastically different, which is why Naive almost looks like a better prediction at first glance:  
<img src=https://user-images.githubusercontent.com/31425480/194945488-6b7f8254-ab43-4b36-8961-61b4d4709f66.png width="50%"><img src=https://user-images.githubusercontent.com/31425480/194945719-d8ffc91e-a55d-4e66-9440-0b22ca149f4c.png width="50%">

In the future, it may be easier to do influenza forecasting using only post-COVID data, but as we are only barely entering our third flu season since COVID became a thing, we simply do not have enough post-COVID data to use for forecasting, but it's clear that influenza spread hasn't yet returned to the spread we would have seen before COVID.

The code attached creates Naive and ARIMA forecasting images for each of the states we had complete data available, as well as four text files of the MASE errors for each type of model, listed by state.

## Mortality by Influenza Type

While unable to locate public influenza mortality data from post-COVID years, we were able to locate data from the CDC with mortality data overlapping much of our pre-COVID data. We then used this to explore whether type-A or type-B would be more associated with mortality using linear models, grouping our data both by year and by state. Most of the results were unsurprising as we would expect influenza to be related to deaths from influenza, but one interesting finding was for type-B influenza when we looked at it by year. We no longer saw the overwhelming levels of indication of association that we saw in other analyses, instead, the association seems implied but is much more uncertain for all years -- if we required a greater level of confidence, we would be inclined to fail to reject our null hypotheses there.

The code attached also creates text files summarizing linear models both by state and year, for type-A, type-B, and all types of influenza infection as it relates to mortality. Because these are sink dumps, they do not run well as part of the code as a whole but they each run well once the previous code has been run.

## Conclusions

Sometimes it feels like it's been decades since the start of COVID, however through the process of this project it's been painfully clear that there are barely two seasons of flu data at the time of this publication, and we are barely starting upon our third. Because of this lack of data we were ultimately hampered on the level of analysis, we could do on this topic, and it would be worth revisiting once more data has been collected. During the 2020 flu season (and 2019 for Alaska) we saw incredible reductions in influenza infections, but we do see these numbers trending upward with the 2021 flu season. But the data we have is only sufficient to let us know that currently, things are drastically different from pre-pandemic levels -- we will have to wait until we start seeing numbers from this flu season before we can start predicting if these changes will have any sort of lasting effect.  

But we also do need to recognize the limitations of our models on our pre-COVID data.  While we were able to produce significantly better models for these states, this was mostly in relativity.  Dr. Harvey Fineberg, former president of the Institute of Medicine, is quoted as saying: "The flu is very unpredictable when it begins and in how it takes off." And the simpler types of modeling with the data we fed our system proved to be mostly underwhelming from the start. Further research on this topic has indicated promising methods of inflenza prediction using social media mining[^6] and neural networks[^7], so perhaps these would be better avenues worth exploring.




[^1]: https://gis.cdc.gov/grasp/fluview/fluportaldashboard.html
[^2]: https://www.cdc.gov/nchs/pressroom/sosmap/flu_pneumonia_mortality/flu_pneumonia.htm
[^3]: Morales, C. R. (Nov 2016). JBER provides immunizations during Alaska Flu season *Joint Base Elmendorf-Richardson* 
https://www.jber.jb.mil/News/News-Articles/NewsDisplay/Article/993152/jber-provides-immunizations-during-alaska-flu-season/
[^4]: Sharma, L., Rebaza, A., & C. S. Dela Cruz. (2019). When ???B??? becomes ???A???: The emerging threat of influenza B virus. 
*European Respiratory Journal* DOI: 10.1183/13993003.01325-2019
[^5]: Craig, J. (Aug 2016). Mortality rates higher among influenza B patients than influenza A patients. *CHEST Physician* 
https://www.mdedge.com/chestphysician/article/111792/vaccines/mortality-rates-higher-among-influenza-b-patients-influenza
[^6]: Singh, S & H. Kaur. (Feb 2021). Influenza prediction from social media texts using machine learning. *Journal of Physics: Conference Series*. 1950. https://iopscience.iop.org/article/10.1088/1742-6596/1950/1/012018
[^7]: Aiken, E. L., Nguyen, A. T., Viboud, C., & M. Santillana. (Jun 2021). Toward the use of neural networks for influenza prediction at multiple spatial resolutions. *Science Advances, 7*(25). DOI: 10.1126/sciadv.abb1237
