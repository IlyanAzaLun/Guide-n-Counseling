import load_action from "./load_action.js";

const main = () => {
	load_action();
	
	//
	$(document).ready(function(){
    const indexLastColumn = $("#tbl_students").find('tr')[1].cells.length-2;
		$("#tbl_students").DataTable({
			"responsive": true,
			"autoWidth": true,
			"pageLength": 5,
			"lengthMenu": [5, 15, 20, 50, 75, 100 ],
			"order": [[ indexLastColumn, "desc" ]]
		});
	});
	$("input#status").on("click", function(){
		switch(this.value){
			case "0":
				this.value = "1";
				break;
			case "1":
				this.value = "0";
				break;
		}
	});

}

export default main;
