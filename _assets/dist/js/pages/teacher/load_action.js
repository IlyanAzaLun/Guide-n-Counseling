import get_data from "./get_data.js";
const load = new get_data();

const load_action = () => {
	// app_auth.js
$(function (){
	// Validaation

	$('#insert').validate({
		rules: {
		  NIP: {
		    required: true
		  },	
		  homeroom_teacher: {
		    required: true
		  },
		  password: {
		    required: true,
		    minlength: 5
		  },
		  re_password: {
		  	required: true,
		    equalTo: "#password"
		  },
		},
		messages: {
		  
		  NIP: {
		    required: "Please specify your NIP teacher"
		  },
		  homeroom_teacher: {
		    required: "Please enter a name homeroom teacher"
		  },
		  password: {
		    required: "Please provide a password",
		    minlength: "Your password must be at least 5 characters long"
		  },
		  re_password: "Enter Confirm Password Same as Password",
		},
		errorElement: 'span',
		errorPlacement: function (error, element) {
		  error.addClass('invalid-feedback');
		  element.closest('.input-group').append(error);
		},
		highlight: function (element, errorClass, validClass) {
		  $(element).addClass('is-invalid');
		},
		unhighlight: function (element, errorClass, validClass) {
		  $(element).removeClass('is-invalid');
		}
	});

	// swall
	const dataType = $('.flash').data('flashtype');
	if (dataType) {
		const message = dataType.split(',');
		Swal.fire({
			icon: message[0],
			title: message[1],
			text: message[2]
		});
	}
})
}

export default load_action;