function get_val(field) {
	# Searches the current line ($0) for field="value" pattern
	search_term = "([[:space:]]|^)" field "=\"([^\"]*)\""
	if (match($0, search_term, match_array)) {
		return match_array[2]
	}
	return ""
}
BEGIN {
	len = split(RETURNS, keys, ",");
	if (len == 0 || VALUE == "") {
		exit;
	}
	if (FIELD == "") {
		FIELD = "*";
	}
	if (START == "") {
		START = 0;
	}
}
NR > START {
	if (FIELDS != "") {
		for (i = 1; i < NF; i++) {
			printf("%d - %s\n", i, $i);
		}
		exit
	}
	match_found = 0;
	if (FIELD == "*") {
		for (field = 1; field <= NF; field++) {
			if ($field == VALUE) {
				match_found = 1;
				break;
			}
		}
	} else {
		if (get_val(FIELD) == VALUE) {
			match_found = 1
		}
	}
}
match_found == 1 {
	for (i = 1; i <= len; i++) {
		target_field = keys[i]
		printf("%s%s", get_val(target_field), (i == len ? "\n" : ","));
	}
}
