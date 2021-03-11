import load_action from "./load_action.js";

const main = () => {
	// dataTabels

	$("#tbl_criteria").DataTable({
		"responsive": true,
		"autoWidth": true,
		"paging": false,
		"searching": false,
		"lengthChange": false,
		"info": false,
	});

	//action
	load_action();
}
export default main;
