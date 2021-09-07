import get_data from "./get_data.js";
const data = new get_data();

const load_action = () => {
	function toggle(button){
		switch(button.value){
			case "0":
				button.value = "1";
				break;
			case "1":
				button.value = "0";
				break;
		}
	}
}
export default load_action;