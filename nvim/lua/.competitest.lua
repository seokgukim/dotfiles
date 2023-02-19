-- .competitest.lua content
return {
	multiple_testing = 3,
	maximum_time = 2500,
	testcases_input_file_format = "in_$(TCNUM).txt",
	testcases_output_file_format = "ans_$(TCNUM).txt",
	testcases_single_file_format = "$(FNOEXT).tc",
}
