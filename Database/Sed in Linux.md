202206242058
Tags: #linux  #bash_script

---

# Sed in Linux

sed stands for **Stream Editor**

```bash
sed 's/search-pattern/replacement-string/flags'

# flag i - insetsitive
sed 's/search-pattern/replacement-string/i'

# By default replace first occurrence of the search pattern
# flag g - global
sed 's/my wife/sed/ig' love.txt

# -i - in place editing
sed -i 's/my wife/sed/ig' love.txt

# edit love.txt and create backup file with name love.txt.bak
sed -i.bak 's/my wife/sed/ig' love.txt

# create like.txt and replace love to like in file only with lines, that matched to the pattern
sed 's/love/like/gw like.txt' love.txt

# delelimiter '#'
echo '/home/bulat' | sed 's#/home/bulat#/export/users/bulats#'

# deleting line, that match to pattern
sed '/Second/d' love.txt

# delete lines that begin with '#' and empty lines
sed '/^#/d ; /^$/d' some-conf-file

# execute different types of a commands
sed '/^#/d ; /^$/d ; s/HOST/HOSTNAME/g' some-conf-file

# another way ⬆️
sed -e '/^#/d' -e '/^$/d' -e 's/USER/USERNAME/' some-conf-file

# another way ⬆️
echo '/^#/d' > script.sed  
echo '/^$/d' >> script.sed  
echo 's/USER/USERNAME/' >> script.sed  
sed -f script.sed some-conf-file

# replace only on the second line
sed '2 s/my wife/sed/' love.txt

# replace only on the line, where has 'Group' word
sed '/Group/ s/my wife/sed/' love.txt
```

---
## Links