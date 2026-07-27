#!/bin/bash
wttr_json=$(curl -s 'wttr.in/?format=j1')
icon=$(curl -s 'wttr.in/?format=%c' | tr -d ' ' | tr -d '\n')
temp=$(echo "$wttr_json" | jq -r '.current_condition[0].temp_C')
feels=$(echo "$wttr_json" | jq -r '.current_condition[0].FeelsLikeC')
chance=$(echo "$wttr_json" | jq -r '.weather[0].hourly[0].chanceofrain')

loc=$(curl -s ipinfo.io/loc)
lat=$(echo $loc | cut -d, -f1)
lon=$(echo $loc | cut -d, -f2)
aqi=$(curl -s "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${lat}&longitude=${lon}&current=us_aqi" | jq '.current.us_aqi')

echo "${icon}|${temp}°C|${feels}°C|${chance}%|${aqi}"
