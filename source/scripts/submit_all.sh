#!/bin/bash
#
# Script to submit a job for every single experiment that needs to be done.
#
# David Duvenaud
# March 2011
# ==================================


for K in 10
do
	for Seed in 1
	do
		for fold in {1..10}
		do
			# Regression jobs
			for dataSetNum in {1..6}
			do
				for methodNum in {1..6}
				do
				    qsub -l lr=0 -o "logs/run_log_reg_$methodNum_$dataSetNum_$fold.txt" -e "logs/error_log_reg_$methodNum_$dataSetNum_$fold.txt" run_one_job.sh $methodNum $dataSetNum $K $fold $Seed
				done
			done
		done
	done
done
