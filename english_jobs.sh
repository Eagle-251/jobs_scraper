#!/bin/bash

locations=(
  antwerpen-province
  brabant-wallon
  oost-vlaanderen
  vlaams-brabant
  hainaut
  west-vlaanderen
  liege-province
  namur-province
)

constructUrl() {
  baseUrl="https://englishjobs.be/in"
  local location=$1
  local searchQuery=$2
  url="$baseUrl/$location?=$searchQuery" 
}



getRedirects(){
    i=${2:-1}
    read status url <<< "$(curl -H 'Cache-Control: no-cache' -o /dev/null --silent --head --insecure --write-out '%{http_code}\t%{redirect_url}\n' "$1" -I)"
    printf '%d: %s --> %s\n' "$i" "$1" "$status";
    if [ "$1" = "$url" ] || [ "$i" -gt 9 ]; then
        echo "Recursion detected or more redirections than allowed. Stop."
    else
      case $status in
          30*) getRedirects "$url" "$((i+1))"
               ;;
      esac
    fi
}

returnUrls() {
  local pageNum
  # Assign the number of pages to a varible
  pageNum=$(curl -s "$1" | pup --color ".pagination > li > a text{}" | sort -r | head -1 ) 
  # Iterate through the number of pages using the index to template the next pages
  for ((i = 1 ; i < pageNum ; i++ )); do
    local searchResult=$(curl -s "$1&page=$i") 
    # echo $i
    # Loop through each job ad
    for line in $(echo "$searchResult" | pup "#page1 > div:nth-child($i)"); 
     do
       
       # local jobTitle
       # local jobRedirectLink
       # local actualJobLink
       # local company
       # local deadline

      local jobTitle=$(echo "$searchResult" | pup "div:nth-child(1) h3 text{}" )
      local jobRedirectLocation=$(echo "$searchResult" | pup "div:nth-child(1) a attr\{href\}" )
      local company=$(echo "$searchResult" | pup "div:nth-child(2) > div li:first-child text{}")
      local deadline=$(echo "$searchResult" | pup "div:nth-child(2) > div li:nth-child(3) text{}")

      local actualJobLink=$(getRedirects "$baseUrl"/"$jobRedirectLocation") 

       jq --null-input \
         --arg title "$jobTitle" \
         --arg link "$actualJobLink" \
         --arg company "$company" \
         --arg deadline "$deadline" \
         '{
           "job title": $title,
           "link": $link,
           "company": $company,
           "deadline": $deadline
         }'
     done
   done
}




main() { 
  if [ -z "$2" ]; then
    echo "You must provide a search query..."
    main "$@"
  fi
  constructUrl "$1" "$2"
  echo $url
  returnUrls "$url"
}


# returnUrls "$url"

select location in ${locations[*]}
do
  main "$location" "$1" 
  break
done
