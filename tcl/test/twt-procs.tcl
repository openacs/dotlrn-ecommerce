ad_library {
    tclwebtest based tests for UI
}

aa_register_case course_creation {
    Create a course and section
} {    
    array set user [twt::user::create]
    array set admin_user [twt::user::create -admin]
    # create course
    twt::user::login $admin_user(email) $admin_user(password)
    
    # create section

}

aa_register_case section_apply {
    Create a test user and complete application
} {
    ::tclwebtest::init 

    array set user [twt::user::create]
    array set admin_user [twt::user::create -admin]

    twt::user::login $user(email) $user(password) $user(username)

    
    aa_log "User registered start application process"
    ::tclwebtest::do_request {http://staginghub.partners.org/} 
    ::tclwebtest::link follow {Courses} ;# ~u {http://staginghub.partners.org/catalog}
    ::tclwebtest::assert text {Course Catalog}
    ::tclwebtest::link follow {apply for course} ~u {724690}
    ::tclwebtest::assert text {Applications}
    ::tclwebtest::form find ~n {show_item_form}
    ::tclwebtest::field fill {Test Data 1168437700} ;# ~n {response_to_item.6963} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168437700} ;# ~n {response_to_item.6973} ;# type of field = text 
    ::tclwebtest::field fill {admin@solutiongrove.com} ;# ~n {response_to_item.12640} ;# type of field = text 
    ::tclwebtest::field select -index 5 ;# ~n {response_to_item.7705} ;# selected <MGH Institute of Health Professions>
    ::tclwebtest::field fill {} ;# ~n {response_to_item.106584} ;# type of field = text 
    ::tclwebtest::field select -index 20 ;# ~n {response_to_item.13763} ;# selected <Neurology>
    ::tclwebtest::field fill {} ;# ~n {response_to_item.11392} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.12339} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.21097} ;# type of field = text 
    ::tclwebtest::field fill {} ;# ~n {response_to_item.11152} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.21089} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.21094} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.21109} ;# type of field = text 
::tclwebtest::form submit 
    ns_log notice "Next Page [tclwebtest::response body]"
    ::tclwebtest::form find ~n {show_item_form}
    ::tclwebtest::field select -index 1 ;# ~n {response_to_item.499511}
    ::tclwebtest::field fill {} ;# ~n {response_to_item.4599} ;# type of field = text 
    ::tclwebtest::field select -index 1 ;# ~n {response_to_item.499530}
    ::tclwebtest::field fill {} ;# ~n {response_to_item.4715} ;# type of field = text 
    ::tclwebtest::field select -index 1 ;# ~n {response_to_item.16685}
    ::tclwebtest::field fill {} ;# ~n {response_to_item.4642} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.4661} ;# type of field = text 
    ::tclwebtest::field select -index 1 ;# ~n {response_to_item.499546}
    ::tclwebtest::field select -index 1 ;# ~n {response_to_item.4731}
::tclwebtest::form submit 
    ::tclwebtest::form find ~n {show_item_form}
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.22463} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.22460} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.22457} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.22454} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.22451} ;# type of field = text 
    ::tclwebtest::field fill {Test Data 1168434083593} ;# ~n {response_to_item.22448} ;# type of field = text 
    ::tclwebtest::field fill {admin@solutiongrove.com} ;# ~n {response_to_item.11373} ;# type of field = text 
::tclwebtest::form submit 
    ::tclwebtest::form find ~n {show_item_form}
    ::tclwebtest::field select -index 2 ;# ~n {response_to_item.4853}
    ::tclwebtest::field fill {other} ;# ~n {response_to_item.5313} ;# type of field = text 
::tclwebtest::form submit 
    ::tclwebtest::assert text {Course Catalog}
# TODO logout then Login as Admin and check that the user is registered
    ::tclwebtest::link follow {Home} ;# ~u {http://staginghub.partners.org/dotlrn/}
    ::tclwebtest::assert text {Home}
    ::tclwebtest::assert text {Section1168437700321Code}

}

