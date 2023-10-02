check:
	$(CWD)/../.combine_results.py

cleanall: check clean
	@rm -rf __pycache__
	@rm -rf results.xml
	@rm -rf combined_results.xml
	@rm -rf log.txt
	@rm -rf sim_build
	@rm -rf .coverage
	@rm -rf htmlcov
	@rm -rf dump.vcd
