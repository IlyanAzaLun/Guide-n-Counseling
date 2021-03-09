import load_action from "./load_action.js";

const main = () => {
	load_action();
	
	//
	$("#tbl_students").DataTable({
		"responsive": true,
		"autoWidth": true,
		"pageLength": 5,
		"lengthMenu": [5, 15, 20, 50, 75, 100 ],
		"order": [[ 3, "asc" ]]
	});

}

export default main;
