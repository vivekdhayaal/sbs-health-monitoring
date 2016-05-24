##clean_all.sh script can be used to clean up all instance failure happened on a particular day
# it uses a parameter specifying directory where all failures are stored
# Our health script failures are stored in date-wise directories in /tmp/ for each date, we can directly use this script to clean all resource for a day
# e.g. we want to clean all failure happened on 20th may 2016, we can run "./clean_all.sh /tmp/16-05-20"
for filename in $1/*; do
	echo "Clean up started for $filename"
	./clean.sh $filename
	echo "Clean up completed for $filename"
done
