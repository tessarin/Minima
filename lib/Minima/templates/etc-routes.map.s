# Main Routes
GET     /               Controller::Main        home

# Specials
@       not_found       Controller::Main        not_found
@       server_error    Controller::Main        error
