// app_auth.js
$(function (){
	// Validaation
	$('#login').validate({
		rules: {
		  username: {
		    required: true
		  },
		  password: {
		    required: true
		  }
		},
		messages: {
		  
		  username: {
		    required: "Please enter your username"
		  },
		  password: {
		    required: "Please enter your password"
		  },
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

	$('#register').validate({
		rules: {
		  fullname: {
		    required: true
		  },	
		  username: {
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
		  
		  fullname: {
		    required: "Please specify your name"
		  },
		  username: {
		    required: "Please enter a username"
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