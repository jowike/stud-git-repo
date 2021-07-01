from careerjet_api import CareerjetAPIClient
import http.client
import ast
import geocoder
from datetime import datetime
import pandas as pd
import numpy as np
import os

## OUTPUT DIR
OUTPUT_DIR = '../data/'

## COVID INFO
print('Downloading covid data, this might take a while...')
#covid = pd.read_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")
#covid.to_csv(OUTPUT_DIR+'us-counties.csv')
covid = pd.read_csv(OUTPUT_DIR+'us-counties.csv')
print('Covid data downloaded')

## GEOGRAPHY DIMENSION
if os.path.isfile(OUTPUT_DIR+'GeographyDimension.csv'):
    print('Skipping geography dimension generation')
else:
    geogDim = covid[['state', 'county']].drop_duplicates().reset_index(drop=True).reset_index().rename(columns={'index': 'Geography_ID'})
    geogDim.to_csv(OUTPUT_DIR+'GeographyDimension.csv', index=False)
    print('Geography Dimension created successfully')

# processing date and diffs for deaths and cases
date = covid['date']
year = date.str.slice(0, 4)
month = date.str.slice(5, 7)
day = date.str.slice(8)
dateID = year+month+day

covid['dateID'] = dateID

covid.sort_values(['date', 'fips'], inplace=True)
covid.reset_index(drop=True)
covid = covid.dropna()

covid['cases'] = covid.groupby(['fips'])['cases'].diff().fillna(0)
covid['deaths'] = covid.groupby(['fips'])['deaths'].diff().fillna(0)
print('Covid data processed')

# shaping data into dwh ready state

geog = pd.read_csv(OUTPUT_DIR+'GeographyDimension.csv')

output = covid.merge(geog, 'left', on = ['county','state'])
CovidID = pd.Series(range(0, len(output)))
output['CovidID'] = CovidID

output = output[['CovidID', 'dateID', 'Geography_ID', 'cases', 'deaths']]
output.columns = ['Covid_ID', 'Date_ID', 'Geography_ID', 'number_of_cases', 'number_of_deaths']

output['number_of_cases'] = output['number_of_cases'].astype(int)
output['number_of_deaths'] = output['number_of_deaths'].astype(int)

output.to_csv(OUTPUT_DIR+'us_counties.csv', index=False)
print('Covid data saved')



## CAREER JET
cj  =  CareerjetAPIClient("en_US")

result_json = cj.search({
                        'location'    : 'usa',
                        'affid'       : '213e213hd12344552',
                        'pagesize'    : '99',
                        'user_ip'     : '11.22.33.44',
                        'url'         : 'http://www.example.com/jobsearch?l=usa',
                        'user_agent'  : 'Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0'
                      })

cj_offers = result_json['jobs']
cj_df = pd.DataFrame(cj_offers)
print('CareerJet data downloaded succesfully')

## Jobble 
us_cities = pd.read_csv("../data/table-2.csv")
us_cities = us_cities.City
us_cities = [city.split("[",1)[0] for city in us_cities]
us_cities = us_cities[:50] # ograniczenia na rzecz testów

df = pd.DataFrame({})

host = 'jooble.org'
key = 'a586cb70-9cc8-44df-95f4-c6ee8973712f'

for city in us_cities:
    page = 1
    #while True: Ograniczenie na rzecz testów
    while page == 1:
        connection = http.client.HTTPConnection(host)

        #request headers
        headers = {"Content-type": "application/json"}

        #json query
        body = '{"location": "' + city.lower() + '", "page": "' + str(page) + '"}' # 57*20+4 = 1144
        connection.request('POST','/api/' + key, body.encode('utf-8'), headers)
        response = connection.getresponse()
        
        bytes_array = response.read()
        
        if bytes_array ==  b'':
            break
            
        jobble_data = ast.literal_eval(bytes_array.decode("utf-8"))
        jobble_offers = jobble_data['jobs']
        
        if not jobble_offers:
            break

        jobble_df = pd.DataFrame(jobble_offers)
        
        
        colnames = jobble_df.columns.tolist()
        colnames = colnames[-1:] + colnames[:-1]
        jobble_df = jobble_df[colnames]
        jobble_df.updated = pd.to_datetime(jobble_df['updated'])
        jobble_df['time'] = [d.time() for d in jobble_df['updated']]
        jobble_df['date'] = [d.date() for d in jobble_df['updated']]
        jobble_df = jobble_df.drop(['updated'], axis=1)
        
        df = pd.concat([df, jobble_df])
        
        page += 1
jb_df = df
print('Jobble data downloaded succesfully')

## Synthetic salary generation
keys = 'python|java| c |c\+\+|javascript| js |ruby|software|golang|typescript|react|web developer|machine learning|data science|data scientist|matlab|sql|haskel|data base|blockchain|php|bash|c\#|frontend|backend|android'

# Industry and salary per industry random parameters
industries = ['medical', 'sales', 'art', 'education', 'finance', 'consulting', 'energy', 'sport', 'science', 'logistics', 'retail', 'HR', 'administration']
weights = np.array([10, 20, 2, 5, 25, 15, 5, 1, 10, 10, 30, 5, 10])
means = [1180, 460, 600, 850, 750, 450, 1020, 650, 800, 790, 290, 690, 1080, 1200] # IT will be appended
stds = [200, 70, 85, 120, 100, 70, 180, 90, 110, 109, 50, 90 , 190, 210]

# Jobble
ind = np.random.choice(industries, size = len(jb_df), replace = True, p = weights/weights.sum())
ind[jb_df['snippet'].str.lower().str.contains(keys)] = 'IT'
jb_df['industry'] = ind
industries.append('IT')

salary = []
for i in range(len(ind)):
    currInd = ind[i]
    idx = np.where(np.array(industries) == currInd)[0][0]
    salary.append(int(np.random.normal(loc=means[idx], scale=stds[idx]))*100)
jb_df['salary'] = np.array(salary)

print('Jobble salaries and industries generated succesfully')
industries.pop()

# CareerJet
ind = np.random.choice(industries, size = len(cj_df), replace = True, p = weights/weights.sum())
ind[cj_df['description'].str.lower().str.contains(keys)] = 'IT'
cj_df['industry'] = ind
industries.append('IT')

salary = []
for i in range(len(ind)):
    currInd = ind[i]
    idx = np.where(np.array(industries) == currInd)[0][0]
    salary.append(int(np.random.normal(loc=means[idx], scale=stds[idx]))*100)
cj_df['salary'] = np.array(salary)

print('CareerJet salaries and industries generated succesfully')

## Prepare location dictionaries

# Jobble
iter_num = 1
locations_array = jb_df.location.unique()
locations_dicts = []

for location in locations_array:
    location_geo = geocoder.google(location, key="AIzaSyDsNzHSM2eoGcEVq_WgBUtMLg5bLS2_0ps")
    case = {'location': str(location), 'location_code': location_geo}
    locations_dicts.append(case)
    iter_num += 1

jobble_geo_df = pd.DataFrame(locations_dicts)
jobble_geo_df['county'] = jobble_geo_df.location_code.apply(lambda x: x.county)
jobble_geo_df['county'] = jobble_geo_df.county.apply(lambda x: str(x)[:-7])
jobble_geo_df.loc[jobble_geo_df['location']=='New York, NY', 'county'] = 'New York City'
jobble_geo_df.loc[jobble_geo_df['county']=='', 'county'] = 'Unknown'

print('Jooble location dictionary generated')

# CareerJet
iter_num = 1
locations_array = cj_df.locations.unique()
locations_dicts = []

for location in locations_array:
    location_geo = geocoder.google(location, key="AIzaSyDsNzHSM2eoGcEVq_WgBUtMLg5bLS2_0ps")
    case = {'location': str(location), 'location_code': location_geo}
    locations_dicts.append(case)
    iter_num += 1
    
careerjet_geo_df = pd.DataFrame(locations_dicts)
careerjet_geo_df['county'] = careerjet_geo_df.location_code.apply(lambda x: x.county)
careerjet_geo_df['county'] = careerjet_geo_df.county.apply(lambda x: str(x)[:-7])
careerjet_geo_df.loc[careerjet_geo_df['location']=='New York City, NY', 'county'] = 'New York City'
careerjet_geo_df.loc[careerjet_geo_df['county']=='', 'county'] = 'Unknown'

print('CareerJet location dictionary generated')

## Map locations to counties
jb_df['location'] = jb_df.merge(jobble_geo_df, on='location', how='left')['county']
cj_df['locations'] = cj_df.merge(careerjet_geo_df, left_on='locations', right_on='location', how='left')['county']

print('Locations mapped to counties successfully')

## Process date and time
cj_df.date = pd.to_datetime(cj_df['date'])

cj_df['time'] = [d.time() for d in cj_df['date']]
cj_df['date'] = [d.date() for d in cj_df['date']]

print('CareerJet date and time processed successfully')

jb_df.date = pd.to_datetime(jb_df['date'])

jb_df['time'] = [d.time() for d in jb_df['date']]
jb_df['date'] = [d.date() for d in jb_df['date']]

print('Jobble date and time processed successfully')

## Drop unnecessary columns and append old data
cj_old = pd.read_csv(OUTPUT_DIR+'careerjet_data_industry.csv', sep='\t')
cj_df = cj_df.append(cj_old)
cj_df = cj_df.drop(['description'], axis=1)
cj_df.loc[cj_df['locations'].isna(), 'locations'] = 'Unknown'
cj_df.to_csv(OUTPUT_DIR+'careerjet_data_industry.csv', sep = '\t', index = False)

jb_old = pd.read_csv(OUTPUT_DIR+'jobble_data_industry.csv', sep='\t')
jb_df = jb_df.append(jb_old)
jb_df = jb_df.drop(['snippet'], axis=1)
jb_df.loc[jb_df['location'].isna(), 'location'] = 'Unknown'
jb_df.to_csv(OUTPUT_DIR+'/jobble_data_industry.csv', sep = '\t', index = False)

print('Data saved successfully')